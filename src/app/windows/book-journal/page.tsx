"use client";

import { useCallback, useEffect, useState } from "react";
import Shell from "@/components/Shell";
import { api, fa } from "@/lib/ui";

/* [دفتر روزنامه — خروجی چاپی قانونی: فقط اسناد قطعی + برچسب برگشتی + جمع کل] */
export default function Page() {
  const [rows, setRows] = useState<any[]>([]);
  const [totals, setTotals] = useState<any>(null);
  const [count, setCount] = useState(0);
  const [from, setFrom] = useState(""); const [to, setTo] = useState("");
  const [err, setErr] = useState("");
  const [co, setCo] = useState<any>(null);
  const [loaded, setLoaded] = useState(false);

  const load = useCallback(async () => {
    setLoaded(false);
    try {
      const p = new URLSearchParams(); if (from) p.set("from", from); if (to) p.set("to", to);
      const j = await api(`/api/books/journal?${p}`);
      setRows(j.rows || []); setTotals(j.totals); setCount(j.count || 0); setErr("");
      try { const c = await api("/api/prm/company"); setCo(c.rows || []); } catch { /* - */ }
    } catch (e: any) { setErr(e.message); }
    setLoaded(true);
  }, [from, to]);
  useEffect(() => { load(); }, [load]);

  const coTitle = co && co.length ? co[0].TitleFa : "";

  return (
    <Shell title="دفتر روزنامه" sub="خروجی چاپی قانونی — فقط اسناد قطعی">
      {err && <div className="msg err">{err}</div>}
      <div className="form-grid no-print" style={{ gridTemplateColumns: "130px 130px auto" }}>
        <div className="field"><label>از تاریخ</label><input value={from} onChange={(e) => setFrom(e.target.value)} style={{ direction: "ltr" }} /></div>
        <div className="field"><label>تا تاریخ</label><input value={to} onChange={(e) => setTo(e.target.value)} style={{ direction: "ltr" }} /></div>
        <div className="field"><label>&nbsp;</label><button className="btn" onClick={load}>نمایش</button>{" "}<button className="btn" onClick={() => window.print()}>چاپ</button></div>
      </div>

      <div className="print-head">
        <h2>دفتر روزنامه</h2>
        <p>{coTitle}</p>
        <div className="meta"><span>بازه: {from || "ابتدا"} تا {to || "انتها"}</span><span>تعداد اسناد: {fa(count)}</span></div>
      </div>

      <div className="scrollbox">
        <table className="grid">
          <thead><tr>
            <th>تاریخ</th><th>عطف</th><th>سند</th><th>شرح</th><th>کل</th><th>معین</th>
            <th>تفصیلی</th><th className="num">بدهکار</th><th className="num">بستانکار</th>
          </tr></thead>
          <tbody>
            {rows.map((r, i) => (
              <tr key={i}>
                <td className="num">{i > 0 && rows[i - 1].VchNo === r.VchNo ? "" : r.VchDate}</td>
                <td className="num">{i > 0 && rows[i - 1].VchNo === r.VchNo ? "" : fa(r.FolioNo)}</td>
                <td className="num">{i > 0 && rows[i - 1].VchNo === r.VchNo ? "" : <b>{fa(r.VchNo)}</b>}{r.ReversalOf && i > 0 && rows[i - 1].VchNo !== r.VchNo ? <span className="badge src">برگشتی</span> : null}</td>
                <td>{i > 0 && rows[i - 1].VchNo === r.VchNo ? "" : (r.ItmDescr || r.VchDescr || "—")}</td>
                <td>{r.KolCode} — {r.KolTitle}</td>
                <td>{r.MoeinCode} — {r.MoeinTitle}</td>
                <td>{r.Taf1Title || r.Taf2Title || r.Taf3Title || "—"}</td>
                <td className="num">{Number(r.Dbt) ? fa(r.Dbt) : ""}</td>
                <td className="num">{Number(r.Crt) ? fa(r.Crt) : ""}</td>
              </tr>
            ))}
            {!rows.length && loaded && <tr><td colSpan={9} className="muted" style={{ textAlign: "center", padding: 18 }}>سند قطعی در این بازه نیست</td></tr>}
          </tbody>
        </table>
      </div>
      {totals && (
        <div className="totalbar">
          <span>جمع کل بدهکار: {fa(totals.TDbt)}</span>
          <span>جمع کل بستانکار: {fa(totals.TCrt)}</span>
        </div>
      )}
      <p className="muted no-print" style={{ marginTop: 6 }}>هرگونه دست‌ورزی در خروجی چاپی فاقد اعتبار است.</p>
    </Shell>
  );
}
