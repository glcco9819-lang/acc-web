"use client";

import { Fragment, useCallback, useEffect, useState } from "react";
import Shell from "@/components/Shell";
import { api, fa, exportCsv } from "@/lib/ui";
import { MONTHS_FA } from "@/lib/jalali";

/* [فرم: گزارش تحلیلی تراز ماهانه — AcRepDef]
   ستون اول = ماندهٔ ابتدای دوره، ستون‌های ماهانه = گردش بد/بس، ستون پایان = ماندهٔ پایان بازه */
const LEVELS = [["kol", "به تفکیک کل"], ["moein", "به تفکیک معین"]];

export default function Page() {
  const [rows, setRows] = useState<any[]>([]);
  const [months, setMonths] = useState<string[]>([]);
  const [totals, setTotals] = useState<any>(null);
  const [err, setErr] = useState("");
  const [level, setLevel] = useState("kol");
  const [mFrom, setMFrom] = useState(1); const [mTo, setMTo] = useState(12);
  const [withOpening, setWithOpening] = useState(true); const [onlyBal, setOnlyBal] = useState(true);
  const [loaded, setLoaded] = useState(false);

  const load = useCallback(async () => {
    try {
      const p = new URLSearchParams({ level, mFrom: String(mFrom), mTo: String(mTo), withOpening: withOpening ? "1" : "0", onlyBal: onlyBal ? "1" : "0" });
      const j = await api(`/api/books/taraz-monthly?${p}`);
      setRows(j.rows || []); setMonths(j.months || []); setTotals(j.totals || null); setErr(""); setLoaded(true);
    } catch (e: any) { setErr(e.message); }
  }, [level, mFrom, mTo, withOpening, onlyBal]);
  useEffect(() => { load(); }, [load]);

  const doCsv = () => exportCsv("taraz-monthly.csv",
    ["عنوان حساب", "ماندهٔ ابتدا (بد)", "ماندهٔ ابتدا (بس)",
     ...months.flatMap((m) => [`${MONTHS_FA[Number(m) - 1]} (بد)`, `${MONTHS_FA[Number(m) - 1]} (بس)`]),
     "ماندهٔ پایان (بد)", "ماندهٔ پایان (بس)"],
    rows.map((r) => [r.Title, r.OpDbt, r.OpCrt,
      ...months.flatMap((m: string) => [r.Cells[m].Dbt, r.Cells[m].Crt]),
      r.EndBalDbt, r.EndBalCrt]));

  const colSpan = 1 + months.length * 2 + 4;

  return (
    <Shell title="گزارش تراز ماهانه" sub="گردش بدهکار/بستانکار هر ماه شمسی با ماندهٔ ابتدای دوره و ماندهٔ پایان — فقط اسناد قطعی">
      {err && <div className="msg err">{err}</div>}
      <div className="print-head"><h2>گزارش تراز ماهانه — {LEVELS.find((l) => l[0] === level)?.[1]}</h2>
        <div className="meta"><span>ماه‌های {MONTHS_FA[mFrom - 1]} تا {MONTHS_FA[mTo - 1]}</span><span>YFG ACC-WEB</span></div></div>
      <div className="form-grid no-print" style={{ gridTemplateColumns: "170px 150px 150px auto" }}>
        <div className="field"><label>نوع گزارش</label>
          <select value={level} onChange={(e) => setLevel(e.target.value)}>
            {LEVELS.map(([v, t]) => <option key={v} value={v}>{t}</option>)}
          </select>
        </div>
        <div className="field"><label>از ماه</label>
          <select value={mFrom} onChange={(e) => { const v = Number(e.target.value); setMFrom(v); if (v > mTo) setMTo(v); }}>
            {MONTHS_FA.map((t, i) => <option key={i + 1} value={i + 1}>{t}</option>)}
          </select>
        </div>
        <div className="field"><label>تا ماه</label>
          <select value={mTo} onChange={(e) => { const v = Number(e.target.value); setMTo(v); if (v < mFrom) setMFrom(v); }}>
            {MONTHS_FA.map((t, i) => <option key={i + 1} value={i + 1}>{t}</option>)}
          </select>
        </div>
        <div className="field"><label>&nbsp;</label>
          <span style={{ display: "flex", gap: 10, alignItems: "center", flexWrap: "wrap" }}>
            <label style={{ whiteSpace: "nowrap" }}><input type="checkbox" checked={withOpening} onChange={(e) => setWithOpening(e.target.checked)} /> ماندهٔ ابتدای دوره در ستون اول</label>
            <label style={{ whiteSpace: "nowrap" }}><input type="checkbox" checked={onlyBal} onChange={(e) => setOnlyBal(e.target.checked)} /> حساب‌های با مانده</label>
          </span>
        </div>
      </div>
      <div className="btnrow no-print">
        <button className="btn primary" onClick={load}>اجرای گزارش</button>
        <button className="btn" onClick={doCsv} disabled={!rows.length}>خروجی Excel</button>
        <button className="btn" onClick={() => window.print()} disabled={!rows.length}>چاپ</button>
      </div>
      <div className="scrollbox">
        <table className="grid">
          <thead>
            <tr>
              <th rowSpan={2}>عنوان حساب</th>
              <th colSpan={2}>ماندهٔ ابتدای دوره</th>
              {months.map((m) => <th key={m} colSpan={2}>{MONTHS_FA[Number(m) - 1]}</th>)}
              <th colSpan={2}>ماندهٔ پایان</th>
            </tr>
            <tr>
              <th className="num">بدهکار</th><th className="num">بستانکار</th>
              {months.map((m) => (
                <Fragment key={m}>
                  <th className="num">بد</th><th className="num">بس</th>
                </Fragment>
              ))}
              <th className="num">بدهکار</th><th className="num">بستانکار</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((r) => (
              <tr key={r.Key}>
                <td>{r.Title}</td>
                <td className="num">{r.OpDbt ? fa(r.OpDbt) : "—"}</td>
                <td className="num">{r.OpCrt ? fa(r.OpCrt) : "—"}</td>
                {months.map((m) => (
                  <Fragment key={m}>
                    <td className="num">{r.Cells[m].Dbt ? fa(r.Cells[m].Dbt) : "—"}</td>
                    <td className="num">{r.Cells[m].Crt ? fa(r.Cells[m].Crt) : "—"}</td>
                  </Fragment>
                ))}
                <td className="num"><b>{r.EndBalDbt ? fa(r.EndBalDbt) : "—"}</b></td>
                <td className="num"><b>{r.EndBalCrt ? fa(r.EndBalCrt) : "—"}</b></td>
              </tr>
            ))}
            {!rows.length && <tr><td colSpan={colSpan} className="muted" style={{ textAlign: "center", padding: 18 }}>{loaded ? "گردشی نیست" : "…"}</td></tr>}
          </tbody>
          {totals && rows.length > 0 && (
            <tfoot><tr style={{ background: "#eef2f5", fontWeight: "bold" }}>
              <td>جمع کل</td>
              <td className="num">{fa(totals.OpDbt)}</td><td className="num">{fa(totals.OpCrt)}</td>
              {months.map((m) => (
                <Fragment key={"t" + m}>
                  <td className="num">{fa(totals[`M${m}D`])}</td>
                  <td className="num">{fa(totals[`M${m}C`])}</td>
                </Fragment>
              ))}
              <td className="num">{fa(totals.EndDbt)}</td><td className="num">{fa(totals.EndCrt)}</td>
            </tr></tfoot>
          )}
        </table>
      </div>
    </Shell>
  );
}
