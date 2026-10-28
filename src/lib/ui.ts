"use client";

/* ابزارهای مشترک کلاینت */
export async function api(path: string, init?: RequestInit): Promise<any> {
  const r = await fetch(path, {
    headers: { "Content-Type": "application/json" },
    ...init,
  });
  let j: any = null;
  try { j = await r.json(); } catch { /* - */ }
  if (!r.ok || (j && j.ok === false)) {
    const err = new Error(j?.error || `HTTP ${r.status}`);
    (err as any).code = j?.code;
    throw err;
  }
  return j;
}

export const fa = (n: number | string | null | undefined) =>
  Number(n || 0).toLocaleString("fa-IR", { maximumFractionDigits: 0 });

export const faDate = (s: string | null | undefined) => (s || "").replace(/\//g, "/");

export const STATE_FA = ["", "موقت", "بررسی‌شده", "قطعی"];
export const STATE_CLS = ["", "s1", "s2", "s3"];
export const NATURE_FA = ["", "بدهکار", "بستانکار", "دوطرفه"];

export interface Ctx {
  companyId: number;
  yearId: number;
  company?: { CompanyId: number; CompanyCode: string; TitleFa: string; CodingMode: number };
  year?: { YearId: number; JalaliYear: number; Title: string } | null;
  user?: { username: string; display: string; role: string };
  can?: { issue: boolean; review: boolean; finalize: boolean; reverse: boolean; master: boolean };
}

export function readCtxCookie(): Ctx {
  if (typeof document === "undefined") return { companyId: 0, yearId: 0 };
  const m = document.cookie.match(/(?:^|;\s*)acc_ctx=([^;]+)/);
  try { return m ? JSON.parse(decodeURIComponent(m[1])) : { companyId: 0, yearId: 0 }; }
  catch { return { companyId: 0, yearId: 0 }; }
}
