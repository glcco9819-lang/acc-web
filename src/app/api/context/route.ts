import { NextRequest, NextResponse } from "next/server";
import { q, one } from "@/lib/db";
import { getSession, can } from "@/lib/auth";

/* کانتکست کاربر: شرکت‌ها + سال‌های مالی + انتخاب جاری (کوکی) + دسترسی‌ها */
export async function GET() {
  const s = await getSession();
  if (!s) return NextResponse.json({ ok: false, error: "لاگین نکرده‌اید" }, { status: 401 });
  const companies = await q("SELECT CompanyId, CompanyCode, TitleFa, CodingMode FROM pob.Companies WHERE IsActive=1 ORDER BY CompanyCode");
  const years = await q(`SELECT y.YearId, y.CompanyId, y.JalaliYear, y.Title, y.StartDate, y.EndDate, y.IsClosed
                         FROM pob.FiscalYear y ORDER BY y.JalaliYear DESC`);
  const store = await (await import("next/headers")).cookies();
  const ctxRaw = store.get("acc_ctx")?.value;
  let ctx: { companyId?: number; yearId?: number } = {};
  try { ctx = ctxRaw ? JSON.parse(ctxRaw) : {}; } catch { /* empty */ }
  if (ctx.companyId && !companies.find((c) => c.CompanyId === ctx.companyId)) ctx = {};
  let year = null;
  if (ctx.yearId) year = years.find((y) => y.YearId === ctx.yearId) || null;
  if (!year && ctx.companyId) year = years.find((y) => y.CompanyId === ctx.companyId) || null;
  return NextResponse.json({ ok: true, user: s, companies, years, current: year, can: {
    issue: can(s, "issue"), review: can(s, "review"), finalize: can(s, "finalize"),
    reverse: can(s, "reverse"), master: can(s, "master"),
    logview: can(s, "logview"), logdelete: can(s, "logdelete"),
  }});
}

export async function POST(req: NextRequest) {
  const s = await getSession();
  if (!s) return NextResponse.json({ ok: false, error: "لاگین نکرده‌اید" }, { status: 401 });
  const body = await req.json().catch(() => ({}));
  const companyId = Number(body.companyId || 0);
  const yearId = Number(body.yearId || 0);
  if (!companyId) return NextResponse.json({ ok: false, error: "شرکت نامعتبر" }, { status: 400 });
  const year = yearId ? await one("SELECT YearId FROM pob.FiscalYear WHERE YearId=@y AND CompanyId=@c", { y: yearId, c: companyId }) : null;
  if (yearId && !year) return NextResponse.json({ ok: false, error: "سال مالی متعلق به این شرکت نیست" }, { status: 400 });
  const res = NextResponse.json({ ok: true });
  res.cookies.set("acc_ctx", JSON.stringify({ companyId, yearId: year ? yearId : 0 }), {
    httpOnly: true, sameSite: "lax", path: "/", maxAge: 60 * 60 * 24 * 30,
  });
  return res;
}
