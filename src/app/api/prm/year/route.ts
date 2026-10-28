import { NextRequest, NextResponse } from "next/server";
import { q, one } from "@/lib/db";
import { getSession, can } from "@/lib/auth";
import { MONTHS_FA } from "@/lib/jalali";

/* سال مالی [فرم: ایجاد سال مالی جدید — acyear] */
export async function GET(req: NextRequest) {
  const s = await getSession();
  if (!s) return NextResponse.json({ ok: false, error: "دسترسی رد شد" }, { status: 401 });
  const companyId = Number(new URL(req.url).searchParams.get("companyId") || 0);
  if (!companyId) return NextResponse.json({ ok: false, error: "شرکت انتخاب نشده" }, { status: 400 });
  const years = await q(
    `SELECT y.*, (SELECT COUNT(*) FROM ACC.AccVoucher h WHERE h.YearId=y.YearId) VchCount
     FROM pob.FiscalYear y WHERE y.CompanyId=@c ORDER BY y.JalaliYear DESC`, { c: companyId });
  const periods = await q(
    `SELECT p.* FROM pob.FiscalPeriod p JOIN pob.FiscalYear y ON y.YearId=p.YearId WHERE y.CompanyId=@c ORDER BY p.YearId, p.MonthNo`, { c: companyId });
  return NextResponse.json({ ok: true, rows: years, periods });
}

export async function POST(req: NextRequest) {
  const s = await getSession();
  if (!s || s.role !== "admin") return NextResponse.json({ ok: false, error: "فقط مدیر سامانه" }, { status: 403 });
  const body = await req.json().catch(() => ({}));
  const companyId = Number(body.CompanyId || 0);
  const jalaliYear = Number(body.JalaliYear || 0);
  if (!companyId || jalaliYear < 1300 || jalaliYear > 1500)
    return NextResponse.json({ ok: false, error: "سال نامعتبر" }, { status: 400 });
  const exists = await one("SELECT YearId FROM pob.FiscalYear WHERE CompanyId=@c AND JalaliYear=@j", { c: companyId, j: jalaliYear });
  if (exists) return NextResponse.json({ ok: false, error: "این سال مالی قبلاً ایجاد شده" }, { status: 400 });

  const row = await one(
    `INSERT INTO pob.FiscalYear (CompanyId, JalaliYear, Title, StartDate, EndDate) VALUES (@c, @j, @t, @s, @e);
     SELECT * FROM pob.FiscalYear WHERE YearId = CAST(SCOPE_IDENTITY() AS smallint)`,
    { c: companyId, j: jalaliYear, t: `سال مالی ${jalaliYear}`, s: `${jalaliYear}/01/01`, e: `${jalaliYear}/12/29` });
  const vals = MONTHS_FA.map((m, i) => `(@y, ${i + 1}, N'${m}')`).join(",");
  await q(`INSERT INTO pob.FiscalPeriod (YearId, MonthNo, Title) VALUES ${vals}`, { y: row.YearId });
  return NextResponse.json({ ok: true, row });
}

/* بستن/بازکردن سال */
export async function PUT(req: NextRequest) {
  const s = await getSession();
  if (!s || s.role !== "admin") return NextResponse.json({ ok: false, error: "فقط مدیر سامانه" }, { status: 403 });
  const body = await req.json().catch(() => ({}));
  const yearId = Number(body.YearId || 0);
  const closed = body.IsClosed ? 1 : 0;
  await q("UPDATE pob.FiscalYear SET IsClosed=@f WHERE YearId=@y", { f: closed, y: yearId });
  return NextResponse.json({ ok: true });
}
