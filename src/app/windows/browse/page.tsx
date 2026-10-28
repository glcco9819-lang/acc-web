"use client";

import { useEffect } from "react";

/* مرور حساب‌ها به پنجرهٔ کامل «review» منتقل شد (v2.1.0 — بازنویسی مطابق AcVwDef).
   این مسیر فقط برای سازگاریِ بوک‌مارک‌ها نگه داشته شده است. */
export default function Page() {
  useEffect(() => { location.replace("/windows/review"); }, []);
  return <div className="boot">انتقال به پنجرهٔ کامل مرور حساب‌ها…</div>;
}
