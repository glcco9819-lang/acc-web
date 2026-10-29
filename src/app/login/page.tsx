"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { api } from "@/lib/ui";

/* صفحهٔ ورود (v2.4.0) — سبک هیرو سایت YFG: پس‌زمینهٔ شب‌رنگ + شبکه + هالهٔ سبز
   کارت شیشه‌ای روشن + دکمهٔ زمردی برند */
export default function LoginPage() {
  const [u, setU] = useState("");
  const [p, setP] = useState("");
  const [err, setErr] = useState("");
  const [busy, setBusy] = useState(false);
  const router = useRouter();

  const submit = async (e: React.FormEvent) => {
    e.preventDefault(); setBusy(true); setErr("");
    try {
      await api("/api/auth/login", { method: "POST", body: JSON.stringify({ username: u, password: p }) });
      router.replace("/");
    } catch (e: any) { setErr(e.message); }
    setBusy(false);
  };

  return (
    <div className="login-hero">
      <span className="login-glow-a" />
      <span className="login-glow-b" />
      <form onSubmit={submit} className="login-card">
        <div className="login-brand">
          <span className="brand-mark" style={{ fontSize: 11.5, padding: "3px 10px" }}>YFG</span>
          <span className="login-title">ACC-WEB</span>
        </div>
        <p className="login-sub">ماژول حسابداری — گروه فن‌آوران یستا</p>
        <div className="field" style={{ marginBottom: 10 }}>
          <label>نام کاربری</label>
          <input value={u} onChange={(e) => setU(e.target.value)} autoFocus style={{ width: "100%" }} />
        </div>
        <div className="field" style={{ marginBottom: 14 }}>
          <label>رمز عبور</label>
          <input type="password" value={p} onChange={(e) => setP(e.target.value)} style={{ width: "100%" }} />
        </div>
        {err && <div className="msg err">{err}</div>}
        <button className="btn primary" disabled={busy} style={{ width: "100%", padding: 9 }}>
          {busy ? "…" : "ورود به سامانه"}
        </button>
        <div className="login-users">
          کاربران نمونه (رمز همه: <b>1234</b>):<br />
          admin — مدیر سامانه<br />
          karbar1 — ثبت‌کنندهٔ اسناد<br />
          karbar2 — بررسی‌کننده (بررسی/قطعی/برگشت)
        </div>
      </form>
    </div>
  );
}
