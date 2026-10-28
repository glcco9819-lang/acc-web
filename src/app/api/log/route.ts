import { NextRequest, NextResponse } from "next/server";
import { q, scalar, tx } from "@/lib/db";
import { getSession } from "@/lib/auth";

/* لاگ سیستم — فقط مدیر سامانه
   نمایش با فیلتر: نام کاربری / تاریخ از–تا (شمسی) / سیستم / نوع فعالیت
   حذف بازه‌ای + ثبت خودِ حذف در لاگ */

const RE_JAL = /^\d{4}\/\d{2}\/\d{2}$/;

export async function GET(req: NextRequest) {
  const s = await getSession();
  if (!s) return NextResponse.json({ ok: false, error: "دسترسی رد شد" }, { status: 401 });
  if (s.role !== "admin") return NextResponse.json({ ok: false, error: "لاگ سیستم فقط برای مدیر سامانه" }, { status: 403 });

  const url = new URL(req.url);
  const user = (url.searchParams.get("user") || "").trim().slice(0, 64);
  const from = (url.searchParams.get("from") || "").trim();
  const to = (url.searchParams.get("to") || "").trim();
  const sys = (url.searchParams.get("sys") || "").trim().slice(0, 16);
  const act = Number(url.searchParams.get("act") || 0);
  const page = Math.max(1, Number(url.searchParams.get("page") || 1));
  if ((from && !RE_JAL.test(from)) || (to && !RE_JAL.test(to)))
    return NextResponse.json({ ok: false, error: "قالب تاریخ شمسی: 1405/01/01" }, { status: 400 });

  const W = `WHERE (@u=N'' OR UserName=@u) AND (@f=N'' OR LogDate>=@f) AND (@t=N'' OR LogDate<=@t)
             AND (@sy=N'' OR SubSystem=@sy) AND (@a=0 OR ActivityType=@a)`;
  const p = { u: user, f: from, t: to, sy: sys, a: act };
  const total = Number(await scalar(`SELECT COUNT(*) FROM pob.UserLog ${W}`, p) || 0);
  const rows = await q(
    `SELECT UserLogId, UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType,
            SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue
     FROM pob.UserLog ${W}
     ORDER BY UserLogId DESC OFFSET @off ROWS FETCH NEXT 50 ROWS ONLY`,
    { ...p, off: (page - 1) * 50 });
  const users = await q(`SELECT DISTINCT UserName FROM pob.UserLog ORDER BY UserName`);
  return NextResponse.json({ ok: true, rows, total, page, pageSize: 50, users: users.map((r: any) => r.UserName) });
}

export async function DELETE(req: NextRequest) {
  const s = await getSession();
  if (!s) return NextResponse.json({ ok: false, error: "دسترسی رد شد" }, { status: 401 });
  if (s.role !== "admin") return NextResponse.json({ ok: false, error: "حذف لاگ فقط برای مدیر سامانه" }, { status: 403 });

  const body = await req.json().catch(() => ({}));
  const from = String(body.from || "").trim();
  const to = String(body.to || "").trim();
  if (!from && !to)
    return NextResponse.json({ ok: false, error: "برای حذف، بازهٔ تاریخ را مشخص کنید" }, { status: 400 });
  if ((from && !RE_JAL.test(from)) || (to && !RE_JAL.test(to)))
    return NextResponse.json({ ok: false, error: "قالب تاریخ شمسی: 1405/01/01" }, { status: 400 });

  let n = 0;
  try {
    await tx(async (run) => {
      const c = await run(`SELECT COUNT(*) c FROM pob.UserLog WHERE (@f=N'' OR LogDate>=@f) AND (@t=N'' OR LogDate<=@t)`, { f: from, t: to });
      n = Number(c[0]?.c || 0);
      if (n > 0) {
        await run(`DELETE FROM pob.UserLog WHERE (@f=N'' OR LogDate>=@f) AND (@t=N'' OR LogDate<=@t)`, { f: from, t: to });
        await run(`EXEC pob.UspUserLogAdd @Tbl=N'UserLog', @Act=3, @Doc=@d`,
          { d: `حذف ${n.toLocaleString("fa-IR")} سطر لاگ${from ? ` از ${from}` : ""}${to ? ` تا ${to}` : ""}` });
      }
    });
    return NextResponse.json({ ok: true, deleted: n });
  } catch (e: any) {
    return NextResponse.json({ ok: false, error: String(e.message || e).slice(0, 200) }, { status: 500 });
  }
}
