"use client";

import { useCallback, useEffect, useState } from "react";
import Shell from "@/components/Shell";
import { api, fa } from "@/lib/ui";
import { useSync } from "@/components/App";

/* [دفتر کل — مانده ابتدا/گردش/مانده پایان هر حساب کل + فیلتر بازه و کل] */
export default function Page() {
  const [rows, setRows] = useState<any[]>([]);
  const [kols, setKols] = useState<any[]>([]);
  const [from, setFrom] = useState(""); const [to, setTo] = useState(""); const [kol, setKol] = useState("");
  const [err, setErr] = useState("");

  const load = useCallback(async () => {
    try {
      const p = new URLSearchParams(); if (from) p.set("from", from); if (to) p.set("to", to); if (kol) p.set("kol", kol);
      const j = await api(`/api/books/kol?${p}`);
      setRows(j.rows || []); setErr("");
    } catch (e: any) { setErr(e.message); }
  }, [from, to, kol]);
  useSync(load);
  useEffect(() => { api("/api/acc/kol").then((j) => setKols(j.rows || [])).catch(() => {}); }, []);

  return (
    <Shell title="دفتر کل" sub="گردش و ماندهٔ هر حساب کل — فقط اسناد قطعی + ماندهٔ ابتدای دوره">
      {err && <div className="msg err">{err}</div>}
      <div className="form-grid" style={{ gridTemplateColumns: "130px 130px 240px auto" }}>
        <div className="field"><label>از تاریخ</label><input value={from} onChange={(e) => setFrom(e.target.value)} style={{ direction: "ltr" }} /></div>
        <div className="field"><label>تا تاریخ</label><input value={to} onChange={(e) => setTo(e.target.value)} style={{ direction: "ltr" }} /></div>
        <div className="field"><label>حساب کل</label>
          <select value={kol} onChange={(e) => setKol(e.target.value)}>
            <option value="">همه کل‌ها</option>
            {kols.map((k) => <option key={k.Code} value={k.Code}>{k.Code} — {k.Title}</option>)}
          </select>
        </div>
        <div className="field"><label>&nbsp;</label><button className="btn" onClick={load}>نمایش</button>{" "}<button className="btn" onClick={() => window.print()}>چاپ</button></div>
      </div>
      <div className="scrollbox">
        <table className="grid">
          <thead><tr>
            <th>کد کل</th><th>عنوان</th><th className="num">مانده ابتدا</th>
            <th className="num">گردش بدهکار</th><th className="num">گردش بستانکار</th>
            <th className="num">مانده پایان</th><th className="num">تعداد سند</th>
          </tr></thead>
          <tbody>
            {rows.map((r) => (
              <tr key={r.KolCode}>
                <td className="num">{r.KolCode}</td>
                <td>{r.KolTitle}</td>
                <td className="num">{fa(r.OpBal)}</td>
                <td className="num">{fa(r.Dbt)}</td>
                <td className="num">{fa(r.Crt)}</td>
                <td className="num"><b>{fa(r.EndBal)}</b></td>
                <td className="num">{fa(r.VchCount)}</td>
              </tr>
            ))}
            {!rows.length && <tr><td colSpan={7} className="muted" style={{ textAlign: "center", padding: 18 }}>گردشی نیست</td></tr>}
          </tbody>
        </table>
      </div>
    </Shell>
  );
}
