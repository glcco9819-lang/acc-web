"use client";

import { useCallback, useEffect, useState } from "react";
import Shell from "@/components/Shell";
import { api, fa, exportCsv } from "@/lib/ui";

/* [فرم: گزارش تراز اسناد شش سطحي — AcRepDef]
   شش ستون: ماندهٔ ابتدا (بد/بس) + گردش دوره (بد/بس) + ماندهٔ پایان (بد/بس) در سطح انتخابی */
const LEVELS = [
  ["kol", "حساب کل"], ["moein", "حساب معین"], ["taf1", "تفصیلی (سطح ۴)"],
  ["taf2", "تفصیلی (سطح ۵)"], ["taf3", "تفصیلی (سطح ۶)"],
];

export default function Page() {
  const [rows, setRows] = useState<any[]>([]);
  const [totals, setTotals] = useState<any>(null);
  const [kols, setKols] = useState<any[]>([]);
  const [moeins, setMoeins] = useState<any[]>([]);
  const [err, setErr] = useState("");
  const [level, setLevel] = useState("kol");
  const [from, setFrom] = useState(""); const [to, setTo] = useState("");
  const [fromVch, setFromVch] = useState(""); const [toVch, setToVch] = useState("");
  const [kol, setKol] = useState(""); const [moein, setMoein] = useState("");
  const [withOpening, setWithOpening] = useState(true); const [onlyBal, setOnlyBal] = useState(true);
  const [loaded, setLoaded] = useState(false);

  const load = useCallback(async () => {
    try {
      const p = new URLSearchParams({ level, withOpening: withOpening ? "1" : "0", onlyBal: onlyBal ? "1" : "0" });
      if (from) p.set("from", from); if (to) p.set("to", to);
      if (fromVch) p.set("fromVch", fromVch); if (toVch) p.set("toVch", toVch);
      if (kol) p.set("kol", kol); if (moein) p.set("moein", moein);
      const j = await api(`/api/books/taraz-six?${p}`);
      setRows(j.rows || []); setTotals(j.totals || null); setErr(""); setLoaded(true);
    } catch (e: any) { setErr(e.message); }
  }, [level, from, to, fromVch, toVch, kol, moein, withOpening, onlyBal]);
  useEffect(() => { load(); }, [load]);
  useEffect(() => { api("/api/acc/kol").then((j) => setKols(j.rows || [])).catch(() => {}); }, []);
  useEffect(() => {
    if (level === "kol") { setMoeins([]); return; }
    api("/api/acc/moein").then((j) => setMoeins(j.rows || [])).catch(() => setMoeins([]));
  }, [level]);

  const doCsv = () => exportCsv("taraz-six.csv",
    ["کد کل", "کد معین", "عنوان", "ماندهٔ ابتدا (بد)", "ماندهٔ ابتدا (بس)", "گردش دوره (بد)", "گردش دوره (بس)", "ماندهٔ پایان (بد)", "ماندهٔ پایان (بس)"],
    rows.map((r) => [r.KolCode, r.MoeinCode || "", r.Title, r.InitDbt, r.InitCrt, r.Dbt, r.Crt, r.EndDbt, r.EndCrt]));

  return (
    <Shell title="گزارش تراز اسناد شش‌سطحی" sub="ماندهٔ ابتدا، گردش دوره و ماندهٔ پایان در سطح انتخابی — فقط اسناد قطعی">
      {err && <div className="msg err">{err}</div>}
      <div className="print-head"><h2>گزارش تراز اسناد شش‌سطحی — سطح {LEVELS.find((l) => l[0] === level)?.[1]}</h2>
        <div className="meta"><span>{from || to ? `بازهٔ ${from || "ابتدای سال"} تا ${to || "پایان سال"}` : "کل سال مالی"}{fromVch || toVch ? ` · اسناد ${fromVch || "؟"} تا ${toVch || "؟"}` : ""}</span><span>YFG ACC-WEB</span></div></div>
      <div className="form-grid no-print" style={{ gridTemplateColumns: "150px 130px 130px 110px 110px 200px auto" }}>
        <div className="field"><label>سطح گزارش</label>
          <select value={level} onChange={(e) => setLevel(e.target.value)}>
            {LEVELS.map(([v, t]) => <option key={v} value={v}>{t}</option>)}
          </select>
        </div>
        <div className="field"><label>از تاریخ</label><input value={from} onChange={(e) => setFrom(e.target.value)} placeholder="1405/01/01" style={{ direction: "ltr" }} /></div>
        <div className="field"><label>تا تاریخ</label><input value={to} onChange={(e) => setTo(e.target.value)} placeholder="1405/12/29" style={{ direction: "ltr" }} /></div>
        <div className="field"><label>از شماره سند</label><input value={fromVch} onChange={(e) => setFromVch(e.target.value)} style={{ direction: "ltr" }} /></div>
        <div className="field"><label>تا شماره سند</label><input value={toVch} onChange={(e) => setToVch(e.target.value)} style={{ direction: "ltr" }} /></div>
        <div className="field"><label>حساب کل / معین</label>
          <span style={{ display: "flex", gap: 6 }}>
            <select value={kol} onChange={(e) => { setKol(e.target.value); setMoein(""); }} style={{ flex: 1 }}>
              <option value="">همه کل‌ها</option>
              {kols.map((k) => <option key={k.Code} value={k.Code}>{k.Code} — {k.Title}</option>)}
            </select>
            {level !== "kol" && (
              <select value={moein} onChange={(e) => setMoein(e.target.value)} style={{ flex: 1 }}>
                <option value="">همه معین‌ها</option>
                {moeins.filter((m) => !kol || m.KolCode === kol).map((m) => <option key={m.Code} value={m.Code}>{m.Code} — {m.Title}</option>)}
              </select>
            )}
          </span>
        </div>
        <div className="field"><label>&nbsp;</label>
          <span style={{ display: "flex", gap: 10, alignItems: "center", flexWrap: "wrap" }}>
            <label style={{ whiteSpace: "nowrap" }}><input type="checkbox" checked={withOpening} onChange={(e) => setWithOpening(e.target.checked)} /> با ماندهٔ ابتدای دوره</label>
            <label style={{ whiteSpace: "nowrap" }}><input type="checkbox" checked={onlyBal} onChange={(e) => setOnlyBal(e.target.checked)} /> فقط با مانده/گردش</label>
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
              <th rowSpan={2}>کد کل</th>{level !== "kol" && <th rowSpan={2}>کد معین</th>}
              <th rowSpan={2}>عنوان حساب</th>
              <th colSpan={2}>ماندهٔ ابتدای دوره</th>
              <th colSpan={2}>گردش دوره</th>
              <th colSpan={2}>ماندهٔ پایان</th>
            </tr>
            <tr>
              <th className="num">بدهکار</th><th className="num">بستانکار</th>
              <th className="num">بدهکار</th><th className="num">بستانکار</th>
              <th className="num">بدهکار</th><th className="num">بستانکار</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((r) => (
              <tr key={r.Key}>
                <td className="num">{r.KolCode}</td>
                {level !== "kol" && <td className="num">{r.MoeinCode || ""}</td>}
                <td>{r.Title}</td>
                <td className="num">{r.InitDbt ? fa(r.InitDbt) : "—"}</td>
                <td className="num">{r.InitCrt ? fa(r.InitCrt) : "—"}</td>
                <td className="num">{fa(r.Dbt)}</td>
                <td className="num">{fa(r.Crt)}</td>
                <td className="num"><b>{r.EndDbt ? fa(r.EndDbt) : "—"}</b></td>
                <td className="num"><b>{r.EndCrt ? fa(r.EndCrt) : "—"}</b></td>
              </tr>
            ))}
            {!rows.length && <tr><td colSpan={level !== "kol" ? 9 : 8} className="muted" style={{ textAlign: "center", padding: 18 }}>
              {loaded ? "گردشی نیست" : "…"}</td></tr>}
          </tbody>
          {totals && rows.length > 0 && (
            <tfoot><tr style={{ background: "#eef2f5", fontWeight: "bold" }}>
              <td colSpan={level !== "kol" ? 3 : 2}>جمع کل</td>
              <td className="num">{fa(totals.InitDbt)}</td><td className="num">{fa(totals.InitCrt)}</td>
              <td className="num">{fa(totals.Dbt)}</td><td className="num">{fa(totals.Crt)}</td>
              <td className="num">{fa(totals.EndDbt)}</td><td className="num">{fa(totals.EndCrt)}</td>
            </tr></tfoot>
          )}
        </table>
      </div>
    </Shell>
  );
}
