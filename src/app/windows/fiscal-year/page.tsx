"use client";

import { useCallback, useEffect, useState } from "react";
import Shell from "@/components/Shell";
import { useApp } from "@/components/App";
import { api, fa } from "@/lib/ui";

/* [سال مالی — ایجاد سال مالی جدید / تغییر سال مالی — acyear] */
export default function Page() {
  const app = useApp();
  const [companyId, setCompanyId] = useState(0);
  const [rows, setRows] = useState<any[]>([]);
  const [periods, setPeriods] = useState<any[]>([]);
  const [companies, setCompanies] = useState<any[]>([]);
  const [newYear, setNewYear] = useState("1405");
  const [msg, setMsg] = useState<{ t: "err" | "ok"; s: string } | null>(null);
  const [role, setRole] = useState("");

  const load = useCallback(async (cid: number) => {
    if (!cid) return;
    try {
      const j = await api(`/api/prm/year?companyId=${cid}`);
      setRows(j.rows || []); setPeriods(j.periods || []);
    } catch (e: any) { setMsg({ t: "err", s: e.message }); }
  }, []);
  useEffect(() => {
    api("/api/prm/company").then((j) => { setCompanies(j.rows || []); if (j.rows?.length) { setCompanyId(j.rows[0].CompanyId); load(j.rows[0].CompanyId); } }).catch(() => {});
    api("/api/auth/login").then((j) => setRole(j.user?.role || "")).catch(() => {});
  }, [load]);
  /* v2.4.4 — همگام‌سازی خودکار: با هر تغییر داده، دوره‌های شرکت جاری تازه می‌شوند */
  useEffect(() => { if (companyId) load(companyId); }, [app.rev, companyId, load]);

  const create = async () => {
    setMsg(null);
    try {
      await api("/api/prm/year", { method: "POST", body: JSON.stringify({ CompanyId: companyId, JalaliYear: Number(newYear) }) });
      setMsg({ t: "ok", s: "سال مالی با ۱۲ دوره ایجاد شد" });
      await load(companyId);
    } catch (e: any) { setMsg({ t: "err", s: e.message }); }
  };

  const toggleClose = async (y: any) => {
    setMsg(null);
    try {
      await api("/api/prm/year", { method: "PUT", body: JSON.stringify({ YearId: y.YearId, IsClosed: !y.IsClosed }) });
      await load(companyId);
    } catch (e: any) { setMsg({ t: "err", s: e.message }); }
  };

  return (
    <Shell title="سال مالی" sub="ایجاد سال مالی جدید + تغییر سال مالی (انتخاب از نوار بالا) + بستن سال">
      {msg && <div className={`msg ${msg.t}`}>{msg.s}</div>}
      <div className="form-grid" style={{ gridTemplateColumns: "220px 120px auto" }}>
        <div className="field"><label>شرکت</label>
          <select value={companyId} onChange={(e) => { setCompanyId(Number(e.target.value)); load(Number(e.target.value)); }}>
            {companies.map((c) => <option key={c.CompanyId} value={c.CompanyId}>{c.TitleFa}</option>)}
          </select>
        </div>
        {role === "admin" && (
          <>
            <div className="field"><label>سال جدید (جلالی)</label><input value={newYear} onChange={(e) => setNewYear(e.target.value)} style={{ direction: "ltr" }} /></div>
            <div className="field"><label>&nbsp;</label><button className="btn primary" onClick={create}>ایجاد سال مالی</button></div>
          </>
        )}
      </div>
      <div className="scrollbox">
        <table className="grid">
          <thead><tr><th>عنوان</th><th>از</th><th>تا</th><th className="num">تعداد سند</th><th>وضعیت</th><th style={{ width: 120 }}>عملیات</th></tr></thead>
          <tbody>
            {rows.map((y) => (
              <tr key={y.YearId}>
                <td>{y.Title}</td>
                <td className="num">{y.StartDate}</td>
                <td className="num">{y.EndDate}</td>
                <td className="num">{fa(y.VchCount)}</td>
                <td>{y.IsClosed ? <span className="badge s1">بسته</span> : <span className="badge s3">باز</span>}</td>
                <td>{role === "admin" && <button className="btn" onClick={() => toggleClose(y)} style={{ padding: "1px 10px" }}>{y.IsClosed ? "بازکردن" : "بستن سال"}</button>}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <p className="muted" style={{ margin: "8px 0 4px" }}>دوره‌های ۱۲گانهٔ سال‌ها:</p>
      <div className="scrollbox" style={{ maxHeight: "30vh" }}>
        <table className="grid">
          <thead><tr><th>سال</th><th>ماه</th><th>عنوان دوره</th><th>وضعیت</th></tr></thead>
          <tbody>
            {periods.map((p) => (
              <tr key={p.PeriodId}>
                <td className="num">{rows.find((y) => y.YearId === p.YearId)?.JalaliYear}</td>
                <td className="num">{fa(p.MonthNo)}</td>
                <td>{p.Title}</td>
                <td>{p.IsClosed ? "بسته" : "باز"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </Shell>
  );
}
