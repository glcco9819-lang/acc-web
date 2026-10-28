"use client";

import { useCallback, useEffect, useState } from "react";
import Shell from "@/components/Shell";
import { api, fa } from "@/lib/ui";

/* [آپدیت آنلاین — درخواست کارفرما: برنامه خودش نسخهٔ تازه را از گیت‌هاب می‌گیرد] */
export default function Page() {
  const [info, setInfo] = useState<any>(null);
  const [msg, setMsg] = useState<{ t: "err" | "ok"; s: string } | null>(null);
  const [busy, setBusy] = useState(false);
  const [role, setRole] = useState("");

  const check = useCallback(async () => {
    setBusy(true); setMsg(null);
    try { setInfo(await api("/api/admin/update")); } catch (e: any) { setMsg({ t: "err", s: e.message }); }
    setBusy(false);
  }, []);
  useEffect(() => { check(); api("/api/auth/login").then((j) => setRole(j.user?.role || "")).catch(() => {}); }, [check]);

  const apply = async (force = false) => {
    setBusy(true); setMsg(null);
    try {
      const j = await api("/api/admin/update", { method: "POST", body: JSON.stringify({ action: "apply", force }) });
      setMsg({ t: "ok", s: j.message });
      await check();
    } catch (e: any) { setMsg({ t: "err", s: e.message }); }
    setBusy(false);
  };
  const cancel = async () => {
    try { await api("/api/admin/update", { method: "POST", body: JSON.stringify({ action: "cancel" }) }); await check(); } catch (e: any) { setMsg({ t: "err", s: e.message }); }
  };
  const restart = async () => {
    setBusy(true);
    try { await api("/api/admin/update", { method: "POST", body: JSON.stringify({ action: "restart" }) }); setMsg({ t: "ok", s: "دستور راه‌اندازی مجدد ارسال شد — چند ثانیه صبر و سپس بارگذاری مجدد صفحه" }); }
    catch { setMsg({ t: "ok", s: "سرور در حال راه‌اندازی مجدد است — بعد از چند ثانیه صفحه را دوباره باز کنید" }); }
    setBusy(false);
  };

  return (
    <Shell title="آپدیت آنلاین" sub="بررسی و نصب نسخهٔ تازه از مخزن برنامه">
      {msg && <div className={`msg ${msg.t}`}>{msg.s}</div>}
      <div className="btnrow">
        <button className="btn" onClick={check} disabled={busy}>بررسی نسخهٔ تازه</button>
        {info?.hasUpdate && role === "admin" && !info.pending && <button className="btn primary" onClick={() => apply()} disabled={busy}>دانلود و آماده‌سازی نسخهٔ {info.latest}</button>}
        {!info?.hasUpdate && info?.assetReady && role === "admin" && !info.pending && <button className="btn" onClick={() => apply(true)} disabled={busy}>نصب مجدد همین نسخه (بستهٔ تازهٔ مخزن)</button>}
        {info?.pending && <button className="btn green" onClick={restart} disabled={busy}>راه‌اندازی مجدد و نصب</button>}
        {info?.pending && <button className="btn danger" onClick={cancel} disabled={busy}>لغو آپدیت معلق</button>}
      </div>
      {info && (
        <table className="grid" style={{ maxWidth: 640 }}>
          <tbody>
            <tr><td>نسخهٔ جاری</td><td className="num"><b>{info.current}</b></td></tr>
            <tr><td>آخرین نسخه در مخزن</td><td className="num">{info.latest || "—"}</td></tr>
            <tr><td>وضعیت</td>
              <td>{info.pending ? <span className="badge s1">آپدیت دانلودشده — در انتظار راه‌اندازی مجدد</span>
                : info.hasUpdate ? <span className="badge s2">نسخهٔ تازه موجود است</span>
                  : <span className="badge s3">به‌روز</span>}</td></tr>
            <tr><td>مخزن</td><td style={{ direction: "ltr", textAlign: "left" }}>{info.repo}</td></tr>
            {info.notes && <tr><td>یادداشت نسخه</td><td style={{ whiteSpace: "pre-wrap" }}>{info.notes}</td></tr>}
          </tbody>
        </table>
      )}
      <p className="muted" style={{ marginTop: 10 }}>
        چرخهٔ آپدیت: بررسی ← دانلود بسته ← راه‌اندازی مجدد سرویس (نصب خودکار توسط راه‌انداز).
      </p>
    </Shell>
  );
}
