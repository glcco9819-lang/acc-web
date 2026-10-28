"use client";

import { useCallback, useEffect, useState } from "react";
import Shell from "@/components/Shell";
import { api, fa } from "@/lib/ui";

/* [دفتر معین — کارت هر معین با مانده در خط + فیلتر کل والد] */
export default function Page() {
  const [rows, setRows] = useState<any[]>([]);
  const [kols, setKols] = useState<any[]>([]);
  const [moeins, setMoeins] = useState<any[]>([]);
  const [from, setFrom] = useState(""); const [to, setTo] = useState("");
  const [kol, setKol] = useState(""); const [moein, setMoein] = useState("");
  const [err, setErr] = useState("");

  const load = useCallback(async () => {
    try {
      const p = new URLSearchParams(); if (from) p.set("from", from); if (to) p.set("to", to);
      if (kol) p.set("kol", kol); if (moein) p.set("moein", moein);
      const j = await api(`/api/books/moein?${p}`);
      setRows(j.rows || []); setErr("");
    } catch (e: any) { setErr(e.message); }
  }, [from, to, kol, moein]);
  useEffect(() => {
    load();
    api("/api/acc/kol").then((j) => setKols(j.rows || [])).catch(() => {});
    api("/api/acc/moein").then((j) => setMoeins(j.rows || [])).catch(() => {});
  }, [load]);

  return (
    <Shell title="دفتر معین" sub="کارت گردش معین با مانده در خط">
      {err && <div className="msg err">{err}</div>}
      <div className="form-grid" style={{ gridTemplateColumns: "130px 130px 200px 220px auto" }}>
        <div className="field"><label>از تاریخ</label><input value={from} onChange={(e) => setFrom(e.target.value)} style={{ direction: "ltr" }} /></div>
        <div className="field"><label>تا تاریخ</label><input value={to} onChange={(e) => setTo(e.target.value)} style={{ direction: "ltr" }} /></div>
        <div className="field"><label>کل والد</label>
          <select value={kol} onChange={(e) => { setKol(e.target.value); setMoein(""); }}>
            <option value="">همه</option>
            {kols.map((k) => <option key={k.Code} value={k.Code}>{k.Code} — {k.Title}</option>)}
          </select>
        </div>
        <div className="field"><label>معین</label>
          <select value={moein} onChange={(e) => setMoein(e.target.value)}>
            <option value="">همه</option>
            {moeins.filter((m) => !kol || m.KolCode === kol).map((m) => <option key={m.Code} value={m.Code}>{m.Code} — {m.Title}</option>)}
          </select>
        </div>
        <div className="field"><label>&nbsp;</label><button className="btn" onClick={load}>نمایش</button>{" "}<button className="btn" onClick={() => window.print()}>چاپ</button></div>
      </div>
      <div className="scrollbox">
        <table className="grid">
          <thead><tr>
            <th>معین</th><th>تاریخ</th><th>سند</th><th>شرح</th><th>تفصیلی</th>
            <th className="num">بدهکار</th><th className="num">بستانکار</th><th className="num">مانده</th>
          </tr></thead>
          <tbody>
            {rows.map((r, i) => (
              <tr key={i}>
                <td>{i === 0 || rows[i - 1].MoeinCode !== r.MoeinCode ? `${r.MoeinCode} — ${r.MoeinTitle}` : ""}</td>
                <td className="num">{r.VchDate}</td>
                <td className="num">{fa(r.VchNo)}{r.ReversalOf ? <span className="badge src" style={{ marginInlineStart: 3 }}>برگشتی</span> : null}</td>
                <td>{r.ItmDescr || r.VchDescr}</td>
                <td>{r.Taf1Title || r.Taf2Title || r.Taf3Title || "—"}</td>
                <td className="num">{Number(r.Dbt) ? fa(r.Dbt) : ""}</td>
                <td className="num">{Number(r.Crt) ? fa(r.Crt) : ""}</td>
                <td className="num"><b>{fa(r.Balance)}</b></td>
              </tr>
            ))}
            {!rows.length && <tr><td colSpan={8} className="muted" style={{ textAlign: "center", padding: 18 }}>گردشی نیست</td></tr>}
          </tbody>
        </table>
      </div>
    </Shell>
  );
}
