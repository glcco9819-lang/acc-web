import { NextRequest, NextResponse } from "next/server";
import { one } from "@/lib/db";
import { makeToken, hashPass, getSession, can } from "@/lib/auth";

export async function POST(req: NextRequest) {
  try {
    const body = await req.json().catch(() => ({}));
    const username = String(body.username || "").trim();
    const password = String(body.password || "");
    if (!username || !password) {
      return NextResponse.json({ ok: false, error: "نام کاربری و رمز الزامی است" }, { status: 400 });
    }
    const u = await one<{ Username: string; DisplayName: string; RoleCode: string; PassHash: string }>(
      "SELECT Username, DisplayName, RoleCode, PassHash FROM pob.AppUser WHERE Username=@u AND IsActive=1",
      { u: username }
    );
    if (!u || u.PassHash !== hashPass(password)) {
      return NextResponse.json({ ok: false, error: "نام کاربری یا رمز نادرست است" }, { status: 401 });
    }
    const res = NextResponse.json({
      ok: true, user: { username: u.Username, display: u.DisplayName, role: u.RoleCode },
    });
    res.cookies.set("acc_sess", makeToken(u.Username), {
      httpOnly: true, sameSite: "lax", path: "/", maxAge: 60 * 60 * 24 * 7,
    });
    return res;
  } catch (e: any) {
    return NextResponse.json({ ok: false, error: String(e.message || e).slice(0, 200) }, { status: 500 });
  }
}

export async function GET() {
  const s = await getSession();
  if (!s) return NextResponse.json({ ok: false, error: "لاگین نکرده‌اید" }, { status: 401 });
  return NextResponse.json({ ok: true, user: s, can: {
    issue: can(s, "issue"), review: can(s, "review"), finalize: can(s, "finalize"),
    reverse: can(s, "reverse"), master: can(s, "master"),
  }});
}

export async function DELETE() {
  const res = NextResponse.json({ ok: true });
  res.cookies.set("acc_sess", "", { path: "/", maxAge: 0 });
  return res;
}
