import { NextRequest, NextResponse } from "next/server";
import { q, one } from "@/lib/db";
import { getSession, can } from "@/lib/auth";

/* تعريف انواع سند [فرم: تعريف انواع سند — نوع سند، شرح لاتين] */
export async function GET() {
  const s = await getSession();
  if (!s) return NextResponse.json({ ok: false, error: "دسترسی رد شد" }, { status: 401 });
  const raw = (await (await import("next/headers")).cookies()).get("acc_ctx")?.value;
  let companyId = 0;
  try { companyId = JSON.parse(raw || "{}").companyId || 0; } catch { /* - */ }
  if (!companyId) return NextResponse.json({ ok: false, error: "شرکت انتخاب نشده", code: "NO_CTX" }, { status: 400 });
  const rows = await q("SELECT VoucherTypeId, Title, LatinTitle FROM ACC.AccVoucherType WHERE CompanyId=@c ORDER BY VoucherTypeId", { c: companyId });
  return NextResponse.json({ ok: true, rows });
}

export async function POST(req: NextRequest) {
  const s = await getSession();
  if (!s || !can(s, "master")) return NextResponse.json({ ok: false, error: "مجوز ندارید" }, { status: 403 });
  const raw = (await (await import("next/headers")).cookies()).get("acc_ctx")?.value;
  let companyId = 0;
  try { companyId = JSON.parse(raw || "{}").companyId || 0; } catch { /* - */ }
  const body = await req.json().catch(() => ({}));
  const title = String(body.Title || "").trim().slice(0, 100);
  const latin = String(body.LatinTitle || "").trim().slice(0, 100) || null;
  if (!title) return NextResponse.json({ ok: false, error: "نوع سند الزامی است" }, { status: 400 });
  try {
    const row = await one(`INSERT INTO ACC.AccVoucherType (CompanyId, Title, LatinTitle) VALUES (@c, @t, @l);
      SELECT * FROM ACC.AccVoucherType WHERE VoucherTypeId = CAST(SCOPE_IDENTITY() AS smallint)`,
      { c: companyId, t: title, l: latin });
    return NextResponse.json({ ok: true, row });
  } catch (e: any) {
    return NextResponse.json({ ok: false, error: String(e.message || e).includes("UNIQUE") ? "نوع تکراری است" : String(e.message).slice(0, 200) }, { status: 400 });
  }
}
