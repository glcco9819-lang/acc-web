import { NextRequest, NextResponse } from "next/server";
import { q } from "@/lib/db";
import { getSession } from "@/lib/auth";
import { ctxOf } from "@/lib/ctx";

/* فهرست اسناد [فرم: بررسي اسناد — فقط اسناد موقت/بررسی‌شده/… و محدودهٔ سند] */
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

  const rows = await q(
    `SELECT h.VoucherId, h.FolioNo, h.VchNo, h.VchDate, h.Descr, h.State, h.SourceModule, h.ReversalOf,
            h.CreatedBy, h.CheckedBy, h.FinalizedBy,
            t.Title TypeTitle,
            (SELECT COUNT(*) FROM ACC.AccVoucherItm i WHERE i.VoucherId = h.VoucherId) ItemCount,
            (SELECT SUM(i.Dbt) FROM ACC.AccVoucherItm i WHERE i.VoucherId = h.VoucherId) TotalDbt
     FROM ACC.AccVoucher h JOIN ACC.AccVoucherType t ON t.VoucherTypeId = h.VoucherTypeId
     WHERE ${conds.join(" AND ")}
     ORDER BY h.VchNo DESC`, inp);
  return NextResponse.json({ ok: true, rows });
}
