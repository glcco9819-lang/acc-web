"use client";

import { useCallback, useEffect, useState } from "react";
import Shell from "@/components/Shell";
import { api, fa } from "@/lib/ui";

/* [دفتر تفصیلی — کارت تفصیلی از سه اسلات سند + برچسب سطح] */
export default function Page() {
  const [rows, setRows] = useState<any[]>([]);
  const [tfs, setTfs] = useState<any>(null);
  const [opening, setOpening] = useState(0);
  const [dls, setDls] = useState<any[]>([]);
  const [moeins, setMoeins] = useState<any[]>([]);
  const [dlId, setDlId] = useState("");
  const [moein, setMoein] = useState("");
  const [from, setFrom] = useState(""); const [to, setTo] = useState("");
  const [err, setErr] = useState("");

  const load = useCallback(async () => {
    if (!dlId || !moein) return;
    try {
      const p = new URLSearchParams({ dlId, moein }); if (from) p.set("from", from); if (to) p.set("to", to);
      const j = await api(`/api/books/tafsili?${p}`);
      setRows(j.rows || []); setTfs(j.tfs); setOpening(j.opening || 0); setErr("");
    } catch (e: any) { setErr(e.message); }
  }, [dlId, moein, from, to]);
  useEffect(() => {
    api("/api/acc/tafsili").then((j) => setDls(j.rows || [])).catch(() => {});
    api("/api/acc/moein").then((j) => setMoeins(j.rows || [])).catch(() => {});
  }, []);

  return (
    <Shell title="دفتر تفصیلی" sub="کارت تفصیلی — ردیف‌های سند از سه اسلات سطح ۴/۵/۶">
      {err && <div className="msg err">{err}</div>}
      <div className="form-grid" style={{ gridTemplateColumns: "220px 200px 120px 120px auto" }}>
        <div className="field"><label>حساب معین</label>
          <select value={moein} onChange={(e) => setMoein(e.target.value)}>
            <option value="">— انتخاب معین —</option>
            {moeins.map((m) => <option key={m.Code} value={m.Code}>{m.Code} — {m.Title}</option>)}
          </select>
        </div>
        <div className="field"><label>تفصیلی</label>
          <select value={dlId} onChange={(e) => setDlId(e.target.value)}>
            <option value="">— انتخاب تفصیلی —</option>
            {dls.map((d) => <option key={d.TafsiliId} value={d.TafsiliId}>{d.Code} — {d.Title}</option>)}
          </select>
        </div>
        <div className="field"><label>از تاریخ</label><input value={from} onChange={(e) => setFrom(e.target.value)} style={{ direction: "ltr" }} /></div>
        <div className="field"><label>تا تاریخ</label><input value={to} onChange={(e) => setTo(e.target.value)} style={{ direction: "ltr" }} /></div>
        <div className="field"><label>&nbsp;</label><button className="btn" onClick={load}>نمایش</button>{" "}<button className="btn" onClick={() => window.print()}>چاپ</button></div>
      </div>
      {tfs && (
        <>
          <p style={{ margin: "6px 0" }}>
            کارت <b>{tfs.Code} — {tfs.Title}</b> <span className="muted">({tfs.TypeTitle})</span>
            {" "}· مانده ابتدا: <b>{fa(opening)}</b>
          </p>
          <div className="scrollbox">
            <table className="grid">
              <thead><tr>
                <th>تاریخ</th><th>سند</th><th>سطح</th><th>حساب</th><th>شرح</th>
                <th className="num">بدهکار</th><th className="num">بستانکار</th><th className="num">مانده</th>
              </tr></thead>
              <tbody>
                {rows.map((r, i) => (
                  <tr key={i}>
                    <td className="num">{r.VchDate}</td>
                    <td className="num">{fa(r.VchNo)}{r.ReversalOf ? <span className="badge src" style={{ marginInlineStart: 3 }}>برگشتی</span> : null}</td>
                    <td>{r.Slot}</td>
                    <td>{r.MoeinCode} — {r.MoeinTitle}</td>
                    <td>{r.ItmDescr || r.VchDescr}</td>
                    <td className="num">{Number(r.Dbt) ? fa(r.Dbt) : ""}</td>
                    <td className="num">{Number(r.Crt) ? fa(r.Crt) : ""}</td>
                    <td className="num"><b>{fa(r.Balance)}</b></td>
                  </tr>
                ))}
                {!rows.length && <tr><td colSpan={8} className="muted" style={{ textAlign: "center", padding: 18 }}>گردشی نیست</td></tr>}
              </tbody>
            </table>
          </div>
          <div className="totalbar"><span>مانده پایان: {fa(rows.length ? rows[rows.length - 1].Balance : opening)}</span></div>
        </>
      )}
    </Shell>
  );
}
