"use client";

import { useCallback, useEffect, useState } from "react";
import Shell from "@/components/Shell";
import { api, fa, exportCsv } from "@/lib/ui";

/* [فرم: گزارش تراز — AcRepDef] گردش و مانده در سطح کل/معین/تفصیلی با بازهٔ تاریخ */
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
  const [kol, setKol] = useState(""); const [moein, setMoein] = useState("");
  const [withOpening, setWithOpening] = useState(true); const [onlyBal, setOnlyBal] = useState(true);
  const [loaded, setLoaded] = useState(false);

  const load = useCallback(async () => {
    try {
      const p = new URLSearchParams({ level, withOpening: withOpening ? "1" : "0", onlyBal: onlyBal ? "1" : "0" });
      if (from) p.set("from", from); if (to) p.set("to", to);
      if (kol) p.set("kol", kol); if (moein) p.set("moein", moein);
      const j = await api(`/api/books/taraz?${p}`);
      setRows(j.rows || []); setTotals(j.totals || null); setErr(""); setLoaded(true);
    } catch (e: any) { setErr(e.message); }
  }, [level, from, to, kol, moein, withOpening, onlyBal]);
  useEffect(() => { load(); }, [load]);
  useEffect(() => {
    api("/api/acc/kol").then((j) => setKols(j.rows || [])).catch(() => {});
  }, []);
  useEffect(() => {
    if (level === "kol") { setMoeins([]); return; }
    api("/api/acc/moein").then((j) => setMoeins(j.rows || [])).catch(() => setMoeins([]));
  }, [level]);

  const doCsv = () => exportCsv("taraz.csv",
    ["کد کل", "کد معین", "عنوان", "گردش بدهکار", "گردش بستانکار", "ماندهٔ بدهکار", "ماندهٔ بستانکار"],
    rows.map((r) => [r.KolCode, r.MoeinCode || "", r.Title, r.MDbt, r.MCrt, r.BalDbt, r.BalCrt]));

  return (
    <Shell title="گزارش تراز" sub="گردش بدهکار/بستانکار و مانده در سطح کل، معین یا تفصیلی — فقط اسناد قطعی">
      {err && <div className="msg err">{err}</div>}
      <div className="print-head"><h2>گزارش تراز — سطح {LEVELS.find((l) => l[0] === level)?.[1]}</h2>
        <div className="meta"><span>{from || to ? `بازهٔ ${from || "ابتدای سال"} تا ${to || "پایان سال"}` : "کل سال مالی"}</span><span>YFG ACC-WEB</span></div></div>
      <div className="form-grid no-print" style={{ gridTemplateColumns: "150px 130px 130px 200px 200px auto" }}>
        <div className="field"><label>سطح گزارش</label>
          <select value={level} onChange={(e) => setLevel(e.target.value)}>
            {LEVELS.map(([v, t]) => <option key={v} value={v}>{t}</option>)}
          </select>
        </div>
        <div className="field"><label>از تاریخ</label><input value={from} onChange={(e) => setFrom(e.target.value)} placeholder="1405/01/01" style={{ direction: "ltr" }} /></div>
        <div className="field"><label>تا تاریخ</label><input value={to} onChange={(e) => setTo(e.target.value)} placeholder="1405/12/29" style={{ direction: "ltr" }} /></div>
        <div className="field"><label>حساب کل</label>
          <select value={kol} onChange={(e) => { setKol(e.target.value); setMoein(""); }}>
            <option value="">همه کل‌ها</option>
            {kols.map((k) => <option key={k.Code} value={k.Code}>{k.Code} — {k.Title}</option>)}
          </select>
        </div>
        <div className="field"><label>حساب معین</label>
          <select value={moein} onChange={(e) => setMoein(e.target.value)}>
            <option value="">همه معین‌ها</option>
            {moeins.filter((m) => !kol || m.KolCode === kol).map((m) => <option key={m.Code} value={m.Code}>{m.Code} — {m.Title}</option>)}
          </select>
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
          <thead><tr>
            <th>کد کل</th>{level !== "kol" && <th>کد معین</th>}
            <th>عنوان حساب</th>
            <th className="num">گردش بدهکار</th><th className="num">گردش بستانکار</th>
            <th className="num">ماندهٔ بدهکار</th><th className="num">ماندهٔ بستانکار</th>
          </tr></thead>
          <tbody>
            {rows.map((r) => (
              <tr key={r.Key}>
                <td className="num">{r.KolCode}</td>
                {level !== "kol" && <td className="num">{r.MoeinCode || ""}</td>}
                <td>{r.Title}</td>
                <td className="num">{fa(r.MDbt)}</td>
                <td className="num">{fa(r.MCrt)}</td>
                <td className="num">{r.BalDbt ? fa(r.BalDbt) : "—"}</td>
                <td className="num">{r.BalCrt ? fa(r.BalCrt) : "—"}</td>
              </tr>
            ))}
            {!rows.length && <tr><td colSpan={level !== "kol" ? 7 : 6} className="muted" style={{ textAlign: "center", padding: 18 }}>
              {loaded ? "گردشی نیست" : "…"}</td></tr>}
          </tbody>
          {totals && rows.length > 0 && (
            <tfoot><tr style={{ background: "#eef2f5", fontWeight: "bold" }}>
              <td colSpan={level !== "kol" ? 3 : 2}>جمع کل</td>
              <td className="num">{fa(totals.MDbt)}</td><td className="num">{fa(totals.MCrt)}</td>
              <td className="num">{fa(totals.BalDbt)}</td><td className="num">{fa(totals.BalCrt)}</td>
            </tr></tfoot>
          )}
        </table>
      </div>
    </Shell>
  );
}
