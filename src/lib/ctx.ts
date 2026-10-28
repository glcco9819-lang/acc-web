import { NextRequest } from "next/server";

/* ============================================================================
   خواندن کانتکست شرکت/سال مالی سمت سرور (v2.0.0)
   منبع اصلی: کوکی acc_ctx (JSON: companyId/yearId)
   پشتیبان: پارامترهای companyId/yearId در query یا body — تا اگر کوکی مسیر
   گم شود، درخواست همچنان با کانتکست صریح کار کند (رفع ریشه‌ای خطای
   «شرکت و سال مالی انتخاب نشده» در صدور سند)
   ============================================================================ */

export interface AppCtx { companyId: number; yearId: number }

export function ctxOf(req: NextRequest, body?: unknown): AppCtx {
  let companyId = 0, yearId = 0;
  const raw = req.cookies.get("acc_ctx")?.value;
  try {
    const j = JSON.parse(raw || "{}");
    companyId = Number(j.companyId || 0);
    yearId = Number(j.yearId || 0);
  } catch { /* کوکی خراب — پشتیبان زیر */ }
  /* پشتیبان ۱: query string */
  try {
    const sp = new URL(req.url).searchParams;
    if (!companyId) companyId = Number(sp.get("companyId") || 0);
    if (!yearId) yearId = Number(sp.get("yearId") || 0);
  } catch { /* - */ }
  /* پشتیبان ۲: body JSON */
  if (body && typeof body === "object") {
    const b = body as Record<string, unknown>;
    if (!companyId) companyId = Number(b.companyId || 0);
    if (!yearId) yearId = Number(b.yearId || 0);
  }
  return { companyId, yearId };
}

/* اعتبارسنجی کانتکست در برابر دیتابیس — سال متعلق به شرکت باشد */
export async function ctxValid(companyId: number, yearId: number): Promise<boolean> {
  if (!companyId) return false;
  if (!yearId) return true; /* بعضی مسیرها فقط شرکت لازم دارند */
  const { one } = await import("./db");
  const r = await one("SELECT 1 x FROM pob.FiscalYear WHERE YearId=@y AND CompanyId=@c", { y: yearId, c: companyId });
  return !!r;
}
