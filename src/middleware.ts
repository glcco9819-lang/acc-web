import { NextRequest, NextResponse } from "next/server";

/* گارد مسیرها (v2.0.0): هر مسیر /windows/* بدون کوکی نشست → لاگین */
export function middleware(req: NextRequest) {
  const sess = req.cookies.get("acc_sess")?.value;
  if (!sess) {
    const url = req.nextUrl.clone();
    url.pathname = "/login";
    url.search = "";
    return NextResponse.redirect(url);
  }
  return NextResponse.next();
}

export const config = {
  matcher: ["/windows/:path*"],
};
