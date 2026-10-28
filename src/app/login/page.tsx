"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { api } from "@/lib/ui";

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
    <div style={{ minHeight: "100vh", display: "flex", alignItems: "center", justifyContent: "center", background: "linear-gradient(135deg,#3d5a73,#2b3f52)" }}>
      <form onSubmit={submit} style={{ background: "#f6f4f1", border: "1px solid #c9c2b8", padding: 28, width: 360, boxShadow: "0 8px 30px rgba(0,0,0,.35)" }}>
        <h1 style={{ fontSize: 17, color: "#3d5a73", marginBottom: 2 }}>YFG ACC-WEB</h1>
        <p style={{ fontSize: 12, color: "#6b6b6b", marginBottom: 18 }}>ماژول حسابداری — مطابق فایل‌های اصلی</p>
        <div className="field" style={{ marginBottom: 10 }}>
          <label>نام کاربری</label>
          <input value={u} onChange={(e) => setU(e.target.value)} autoFocus style={{ width: "100%" }} />
        </div>
        <div className="field" style={{ marginBottom: 14 }}>
          <label>رمز عبور</label>
          <input type="password" value={p} onChange={(e) => setP(e.target.value)} style={{ width: "100%" }} />
        </div>
        {err && <div className="msg err">{err}</div>}
        <button className="btn primary" disabled={busy} style={{ width: "100%", padding: 8 }}>
          {busy ? "…" : "ورود"}
        </button>
        <p className="muted" style={{ marginTop: 12, lineHeight: 1.8 }}>
          کاربران نمونه (رمز همه: 1234):<br />
          admin — مدیر سامانه<br />
          karbar1 — ثبت‌کنندهٔ اسناد<br />
          karbar2 — بررسی‌کننده (بررسی/قطعی/برگشت)
        </p>
      </form>
    </div>
  );
}
