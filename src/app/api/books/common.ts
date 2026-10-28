import { NextRequest, NextResponse } from "next/server";
import { q, one } from "@/lib/db";
import { getSession } from "@/lib/auth";

/* شرط مشترک دفاتر: فقط سند قطعی (State=3) — برگشت‌ها با ReversalOf عیناً محاسبه می‌شوند */
export function ctxOf(req: NextRequest): { companyId: number; yearId: number } {
  const raw = req.cookies.get("acc_ctx")?.value;
  try { const j = JSON.parse(raw || "{}"); return { companyId: j.companyId || 0, yearId: j.yearId || 0 }; }
  catch { return { companyId: 0, yearId: 0 }; }
}

/* اگر سند افتتاحیهٔ قطعی‌شده موجود باشد، ماندهٔ جدول OpeningBalance دیگر در «ماندهٔ ابتدا»
   دفاتر منظور نمی‌شود (وگرنه دوبار شمرده می‌شود) — سند افتتاحیه با تاریخ ابتدای سال خودش
   داخل هر بازه‌ای به‌درستی حساب می‌شود */
export async function openingDone(companyId: number, yearId: number): Promise<boolean> {
  const r = await one(
    `SELECT COUNT(*) N FROM ACC.AccVoucher h JOIN ACC.AccVoucherType t ON t.VoucherTypeId=h.VoucherTypeId
     WHERE h.CompanyId=@c AND h.YearId=@y AND h.State=3 AND t.LatinTitle='Opening'`,
    { c: companyId, y: yearId });
  return Number(r?.N || 0) > 0;
}

export async function journal(req: NextRequest) {
  const s = await getSession();
  if (!s) return { status: 401, body: { ok: false, error: "دسترسی رد شد" } };
  const { companyId, yearId } = ctxOf(req);
  if (!companyId || !yearId) return { status: 400, body: { ok: false, error: "شرکت و سال مالی انتخاب نشده", code: "NO_CTX" } };

  const sp = new URL(req.url).searchParams;
  const from = sp.get("from") || "";
  const to = sp.get("to") || "";
  const conds = ["h.CompanyId=@c", "h.YearId=@y", "h.State=3"];
  const inp: Record<string, unknown> = { c: companyId, y: yearId };
  if (from) { conds.push("h.VchDate >= @from"); inp.from = from; }
  if (to) { conds.push("h.VchDate <= @to"); inp.to = to; }

  const rows = await q(
    `SELECT h.VoucherId, h.FolioNo, h.VchNo, h.VchDate, h.Descr VchDescr, h.SourceModule, h.ReversalOf,
            i.RowNo, i.KolCode, k.Title KolTitle, i.MoeinCode, m.Title MoeinTitle,
            d1.Title Taf1Title, d2.Title Taf2Title, d3.Title Taf3Title,
            i.Descr ItmDescr, i.Dbt, i.Crt, t.Title TypeTitle
     FROM ACC.AccVoucher h
     JOIN ACC.AccVoucherType t ON t.VoucherTypeId=h.VoucherTypeId
     JOIN ACC.AccVoucherItm i ON i.VoucherId=h.VoucherId
     JOIN ACC.AccKol k ON k.CompanyId=h.CompanyId AND k.Code=i.KolCode
     JOIN ACC.AccMoein m ON m.CompanyId=h.CompanyId AND m.Code=i.MoeinCode
     LEFT JOIN ACC.AccTafsili d1 ON d1.TafsiliId=i.Taf1Id
     LEFT JOIN ACC.AccTafsili d2 ON d2.TafsiliId=i.Taf2Id
     LEFT JOIN ACC.AccTafsili d3 ON d3.TafsiliId=i.Taf3Id
     WHERE ${conds.join(" AND ")}
     ORDER BY h.VchDate, h.VchNo, i.RowNo`, inp);
  const totals = await one(`SELECT ISNULL(SUM(i.Dbt),0) TDbt, ISNULL(SUM(i.Crt),0) TCrt
    FROM ACC.AccVoucher h JOIN ACC.AccVoucherItm i ON i.VoucherId=h.VoucherId WHERE ${conds.join(" AND ")}`, inp);
  return { status: 200, body: { ok: true, rows, totals, count: (await one(`SELECT COUNT(DISTINCT h.VoucherId) N FROM ACC.AccVoucher h WHERE ${conds.join(" AND ")}`, inp)).N } };
}
