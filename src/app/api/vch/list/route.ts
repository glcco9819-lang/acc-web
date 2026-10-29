import { NextRequest, NextResponse } from "next/server";
import { q, scalar } from "@/lib/db";
import { getSession } from "@/lib/auth";
import { ctxOf } from "@/lib/ctx";

/* فهرست اسناد [فرم: بررسي اسناد — فقط اسناد موقت/بررسی‌شده/… و محدودهٔ سند]
   v2.2.0 — فیلترهای «لیست اسناد»: بازهٔ تاریخ جلالی + نوع سند
   v2.3.0 — صفحه‌بندی (page/pageSize) + تعداد کل + جمع بدهکارِ همهٔ اسناد فیلترشده
   سازگاری عقب: اگر page فرستاده نشود همهٔ ردیف‌ها (تا سقف ۵۰۰۰) برمی‌گردد */

const MAX_ALL = 5000;

export async function GET(req: NextRequest) {
  const s = await getSession();
  if (!s) return NextResponse.json({ ok: false, error: "دسترسی رد شد" }, { status: 401 });
  const { companyId, yearId } = ctxOf(req);
  if (!companyId) return NextResponse.json({ ok: false, error: "شرکت انتخاب نشده", code: "NO_CTX" }, { status: 400 });

  const sp = new URL(req.url).searchParams;
  const state = sp.get("state") || ""; /* 1 موقت | 2 بررسی‌شده | 3 قطعی | خالی=همه */
  const from = sp.get("from") || "";   /* از شماره سند */
  const to = sp.get("to") || "";       /* تا شماره سند */
  const qtext = sp.get("q") || "";
  /* v2.2.0 — فیلترهای «لیست اسناد»: بازهٔ تاریخ جلالی + نوع سند */
  const dFrom = sp.get("dFrom") || "";
  const dTo = sp.get("dTo") || "";
  const typeId = Number(sp.get("typeId") || 0);
  /* v2.3.0 — صفحه‌بندی؛ page=0 یا نبودِ پارامتر یعنی بدون صفحه (سقف MAX_ALL) */
  const pageIn = Number(sp.get("page") || 0);
  const page = Math.max(1, pageIn);
  const pageSize = Math.min(500, Math.max(10, Number(sp.get("pageSize") || 100)));
  const paged = pageIn > 0;

  const conds = ["h.CompanyId=@c"];
  const inp: Record<string, unknown> = { c: companyId };
  if (yearId) { conds.push("h.YearId=@y"); inp.y = yearId; }
  if (state === "1" || state === "2" || state === "3") { conds.push("h.State=@st"); inp.st = Number(state); }
  if (from) { conds.push("h.VchNo >= @from"); inp.from = Number(from) || 0; }
  if (to) { conds.push("h.VchNo <= @to"); inp.to = Number(to) || 0; }
  if (qtext) { conds.push("(h.Descr LIKE @q OR CAST(h.VchNo AS varchar) LIKE @q)"); inp.q = `%${qtext}%`; }
  if (dFrom) { conds.push("h.VchDate >= @dF"); inp.dF = dFrom; }
  if (dTo) { conds.push("h.VchDate <= @dT"); inp.dT = dTo; }
  if (typeId) { conds.push("h.VoucherTypeId=@tp"); inp.tp = typeId; }

  const where = conds.join(" AND ");

  /* تعداد کل و جمع بدهکارِ همهٔ اسنادِ فیلترشده (نه فقط همین صفحه) */
  const total = Number(await scalar(`SELECT COUNT(*) FROM ACC.AccVoucher h WHERE ${where}`, inp) || 0);
  const sumDbt = Number(await scalar(
    `SELECT ISNULL(SUM(i.Dbt),0) FROM ACC.AccVoucher h JOIN ACC.AccVoucherItm i ON i.VoucherId = h.VoucherId WHERE ${where}`,
    inp) || 0);

  const rows = await q(
    `SELECT h.VoucherId, h.FolioNo, h.VchNo, h.VchDate, h.Descr, h.State, h.SourceModule, h.ReversalOf,
            h.CreatedBy, h.CheckedBy, h.FinalizedBy,
            t.Title TypeTitle,
            (SELECT COUNT(*) FROM ACC.AccVoucherItm i WHERE i.VoucherId = h.VoucherId) ItemCount,
            (SELECT SUM(i.Dbt) FROM ACC.AccVoucherItm i WHERE i.VoucherId = h.VoucherId) TotalDbt
     FROM ACC.AccVoucher h JOIN ACC.AccVoucherType t ON t.VoucherTypeId = h.VoucherTypeId
     WHERE ${where}
     ORDER BY h.VchNo DESC
     OFFSET @off ROWS FETCH NEXT @ps ROWS ONLY`,
    paged ? { ...inp, off: (page - 1) * pageSize, ps: pageSize } : { ...inp, off: 0, ps: MAX_ALL });

  return NextResponse.json({
    ok: true, rows, total, sumDbt,
    page: paged ? page : 1,
    pageSize: paged ? pageSize : MAX_ALL,
    pages: paged ? Math.max(1, Math.ceil(total / pageSize)) : 1,
  });
}
