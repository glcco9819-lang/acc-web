import { createHash, randomBytes } from "crypto";
import { cookies } from "next/headers";
import { one, q } from "./db";
import { verifyToken } from "./logctx";

const SECRET = "accweb-sess-2026";

export interface Session {
  username: string;
  display: string;
  role: string;
}

export function makeToken(username: string): string {
  const nonce = randomBytes(8).toString("hex");
  const payload = `${username}.${nonce}`;
  return `${payload}.${verifyTokenSign(payload)}`;
}

function verifyTokenSign(payload: string): string {
  return createHash("sha256").update(payload + SECRET).digest("hex").slice(0, 24);
}

export { verifyToken };

export async function getSession(): Promise<Session | null> {
  const store = await cookies();
  const token = store.get("acc_sess")?.value;
  const username = verifyToken(token);
  if (!username) return null;
  const u = await one<{ Username: string; DisplayName: string; RoleCode: string }>(
    "SELECT Username, DisplayName, RoleCode FROM pob.AppUser WHERE Username=@u AND IsActive=1",
    { u: username }
  );
  if (!u) return null;
  return { username: u.Username, display: u.DisplayName, role: u.RoleCode };
}

export function hashPass(pass: string): string {
  return createHash("sha256").update(`accweb:${pass}`).digest("hex");
}

/* نقش‌ها:
   admin     — همه‌چیز (شامل لاگ سیستم)
   registrar — صدور سند + تعاریف
   checker   — بررسی/قطعی/برگشت (نه صدور)
   لاگ سیستم: فقط admin — مشاهده و حذف */
export function can(user: Session | null, action: string): boolean {
  if (!user) return false;
  if (user.role === "admin") return true;
  switch (action) {
    case "issue": return user.role === "registrar";
    case "review":
    case "finalize": return user.role === "checker";
    /* برگشت سند: ثبت‌کننده می‌تواند سند برگشتی صادر کند؛ زنجیرهٔ بررسی/قطعی طبق روال */
    case "reverse": return user.role === "registrar" || user.role === "checker";
    case "master": return user.role === "registrar" || user.role === "checker";
    /* لاگ سیستم: فقط مدیر سامانه */
    case "logview":
    case "logdelete": return false;
    default: return false;
  }
}
