"use client";

import { useCallback, useEffect, useState } from "react";
import Shell from "@/components/Shell";
import { api, fa } from "@/lib/ui";

/* [معرفی شرکت‌ها — اصل استیجاری: چند شرکت در یک دیتابیس] */
export default function Page() {
  const [rows, setRows] = useState<any[]>([]);
  const [form, setForm] = useState({ CompanyCode: "", TitleFa: "", NationalId: "", EconomicCode: "", CodingMode: "2" });
  const [msg, setMsg] = useState<{ t: "err" | "ok"; s: string } | null>(null);
  const [role, setRole] = useState("");

  const load = useCallback(async () => {
    try { const j = await api("/api/prm/company"); setRows(j.rows || []); } catch (e: any) { setMsg({ t: "err", s: e.message }); }
  }, []);
  useEffect(() => { load(); api("/api/auth/login").then((j) => setRole(j.user?.role || "")).catch(() => {}); }, [load]);

  const save = async () => {
    setMsg(null);
    try {
      await api("/api/prm/company", { method: "POST", body: JSON.stringify(form) });
      setMsg({ t: "ok", s: "شرکت ثبت شد — برای کدینگ، شرکت و سال مالی را از نوار بالا انتخاب کنید" });
      setForm({ CompanyCode: "", TitleFa: "", NationalId: "", EconomicCode: "", CodingMode: "2" });
      await load();
    } catch (e: any) { setMsg({ t: "err", s: e.message }); }
  };

  return (
    <Shell title="معرفی شرکت‌ها" sub="چند شرکت در یک دیتابیس — هر شرکت کدینگ و سال مالی مستقل">
      {msg && <div className={`msg ${msg.t}`}>{msg.s}</div>}
      {role === "admin" && (
        <>
          <div className="form-grid" style={{ gridTemplateColumns: "110px 1fr 160px 160px 150px" }}>
            <div className="field"><label>کد شرکت *</label><input value={form.CompanyCode} onChange={(e) => setForm({ ...form, CompanyCode: e.target.value })} style={{ direction: "ltr" }} /></div>
            <div className="field"><label>نام شرکت *</label><input value={form.TitleFa} onChange={(e) => setForm({ ...form, TitleFa: e.target.value })} /></div>
            <div className="field"><label>شناسه ملی</label><input value={form.NationalId} onChange={(e) => setForm({ ...form, NationalId: e.target.value })} style={{ direction: "ltr" }} /></div>
            <div className="field"><label>کد اقتصادی</label><input value={form.EconomicCode} onChange={(e) => setForm({ ...form, EconomicCode: e.target.value })} style={{ direction: "ltr" }} /></div>
            <div className="field"><label>روش کدینگ</label>
              <select value={form.CodingMode} onChange={(e) => setForm({ ...form, CodingMode: e.target.value })}>
                <option value="2">مطابق accdef (گروه/کل/معین)</option>
                <option value="1">پلکانی (کل/معین)</option>
              </select>
            </div>
          </div>
          <div className="btnrow"><button className="btn primary" onClick={save}>ثبت شرکت</button></div>
        </>
      )}
      <div className="scrollbox">
        <table className="grid">
          <thead><tr><th>کد</th><th>نام شرکت</th><th>شناسه ملی</th><th>کد اقتصادی</th><th>کدینگ</th><th>فعال</th></tr></thead>
          <tbody>
            {rows.map((r) => (
              <tr key={r.CompanyId}>
                <td className="num">{r.CompanyCode}</td>
                <td>{r.TitleFa}</td>
                <td className="num">{r.NationalId || "—"}</td>
                <td className="num">{r.EconomicCode || "—"}</td>
                <td>{r.CodingMode === 2 ? "مطابق accdef" : "پلکانی"}</td>
                <td>{r.IsActive ? "بله" : "خیر"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </Shell>
  );
}
