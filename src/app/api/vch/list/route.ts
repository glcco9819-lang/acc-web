import { NextRequest, NextResponse } from "next/server";
import { q } from "@/lib/db";
import { getSession } from "@/lib/auth";

/* فهرست اسناد [فرم: بررسي اسناد — فقط اسناد موقت/بررسی‌شده/… و محدودهٔ سند] */
export async function GET(req: NextRequest) {
  const s = await getSession();
  if (!s) return NextResponse.json({ ok: false, error: "دسترسی رد شد" }, { status: 401 });
  const raw = (await (await import("next/headers")).cookies()).get("acc_ctx")?.value;
  let companyId = 0, yearId = 0;
  try { const j = JSON.parse(raw || "{}"); companyId = j.companyId || 0; yearId = j.yearId || 0; } catch { /* - */ }
  if (!companyId) return NextResponse.json({ ok: false, error: "شرکت انتخاب نشده", code: "NO_CTX" }, { status: 400 });

  const sp = new URL(req.url).searchParams;
  const state = sp.get("state") || ""; /* 1 موقت | 2 بررسی‌شده | 3 قطعی | خالی=همه */
  const from = sp.get("from") || "";
  const to = sp.get("to") || "";
  const qtext = sp.get("q") || "";

  const conds = ["h.CompanyId=@c"];
  const inp: Record<string, unknown> = { c: companyId };
  if (yearId) { conds.push("h.YearId=@y"); inp.y = yearId; }
  if (state === "1" || state === "2" || state === "3") { conds.push("h.State=@st"); inp.st = Number(state); }
  if (from) { conds.push("h.VchNo >= @from"); inp.from = Number(from) || 0; }
  if (to) { conds.push("h.VchNo <= @to"); inp.to = Number(to) || 0; }
  if (qtext) { conds.push("(h.Descr LIKE @q OR CAST(h.VchNo AS varchar) LIKE @q)"); inp.q = `%${qtext}%`; }

  const rows = await q(
    `SELECT h.VoucherId, h.FolioNo, h.VchNo, h.VchDate, h.Descr, h.State, h.SourceModule, h.ReversalOf,
            h.CreatedBy, h.CheckedBy, h.FinalizedBy,
            t.Title TypeTitle,
            (SELECT COUNT(*) FROM YfgVch.VoucherLine i WHERE i.VoucherId = h.VoucherId) ItemCount,
            (SELECT SUM(i.Dbt) FROM YfgVch.VoucherLine i WHERE i.VoucherId = h.VoucherId) TotalDbt
     FROM YfgVch.Voucher h JOIN YfgVch.VoucherType t ON t.VoucherTypeId = h.VoucherTypeId
     WHERE ${conds.join(" AND ")}
     ORDER BY h.VchNo DESC`, inp);
  return NextResponse.json({ ok: true, rows });
}
