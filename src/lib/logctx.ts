import { createHash } from "crypto";
import { headers } from "next/headers";
import { reverse } from "dns/promises";
import { isIP } from "net";

/* کانتکست لاگ فعالیت کاربران — طبق دستور کارفرما لاگ در پیش‌زمینهٔ دیتابیس (تریگر) پر می‌شود؛
   برنامه فقط سه مقدار کاربر/IP/نام کامپیوتر را با sp_set_session_context به دیتابیس می‌فرستد.
   دسترسی مستقیم به دیتابیس (بدون کانتکست) با نام لاگین SQL ثبت می‌شود. */

const SECRET = "accweb-sess-2026";

function sign(payload: string): string {
  return createHash("sha256").update(payload + SECRET).digest("hex").slice(0, 24);
}

export function verifyToken(token?: string | null): string | null {
  if (!token) return null;
  const parts = token.split(".");
  if (parts.length !== 3) return null;
  const [username, nonce, sig] = parts;
  if (sign(`${username}.${nonce}`) !== sig) return null;
  return username;
}

/* نام کامپیوتر: Reverse-DNS از IP (شبکهٔ داخلی) — با کش و بدون مسدود کردن درخواست */
const pcCache = new Map<string, string>();
const pcTried = new Set<string>();

function lookupPc(ip: string): void {
  if (pcTried.has(ip)) return;
  pcTried.add(ip);
  reverse(ip)
    .then((names) => { if (names && names[0]) pcCache.set(ip, names[0]); })
    .catch(() => { /* نامی یافت نشد — خالی می‌ماند */ });
}

function clientIpFromAls(): string {
  try {
    const als = (globalThis as any).__accAls;
    const st = als?.getStore?.();
    const ip = st?.ip ? String(st.ip) : "";
    return ip.replace(/^::ffff:/, "");
  } catch { return ""; }
}

export interface LogCtx { u: string; ip: string; pc: string; }

export async function getLogCtx(): Promise<LogCtx | null> {
  let ip = clientIpFromAls();
  let cookieRaw = "";
  try {
    const h = await headers();
    if (!ip) ip = String(h.get("x-forwarded-for") || "").split(",")[0].trim().replace(/^::ffff:/, "");
    cookieRaw = h.get("cookie") || "";
  } catch { /* خارج از چرخهٔ درخواست */ }

  if (ip && isIP(ip)) lookupPc(ip);
  const pc = ip ? (pcCache.get(ip) || "") : "";

  let u = "";
  if (cookieRaw) {
    const m = cookieRaw.match(/(?:^|;\s*)acc_sess=([^;]+)/);
    if (m) u = verifyToken(m[1]) || "";
  }
  return { u, ip, pc };
}

/* پیشوند هر بچ SQL: تنظیم کانتکست لاگ روی همان اتصال — تریگرها همان لحظه آن را می‌بینند */
export function logCtxPrefix(ctx: LogCtx, inp: Record<string, unknown>): string {
  inp.__lu = ctx.u || "";
  inp.__ip = ctx.ip || "";
  inp.__pc = ctx.pc || "";
  return (
    "EXEC sp_set_session_context @key=N'LogUser', @value=@__lu;\n" +
    "EXEC sp_set_session_context @key=N'LogIp', @value=@__ip;\n" +
    "EXEC sp_set_session_context @key=N'LogPC', @value=@__pc;\n"
  );
}
