"use client";

import { useCallback, useEffect, useState } from "react";
import Shell from "@/components/Shell";
import { api, fa } from "@/lib/ui";

/* [ماندهٔ ابتدای دوره + صدور سند افتتاحیه — acfidf] */
export default function Page() {
  const [rows, setRows] = useState<any[]>([]);
  const [totals, setTotals] = useState<any>({ D: 0, C: 0 });
  const [moeins, setMoeins] = useState<any[]>([]);
  const [dls, setDls] = useState<any[]>([]);
  const [form, setForm] = useState({ KolCode: "", MoeinCode: "", Dl1Id: "", Dbt: "", Crt: "" });
  const [msg, setMsg] = useState<{ t: "err" | "ok"; s: string } | null>(null);
  const [can, setCan] = useState<any>({});

  const load = useCallback(async () => {
    try {
      const j = await api("/api/prm/opening");
      setRows(j.rows || []); setTotals(j.totals || { D: 0, C: 0 });
    } catch (e: any) { setMsg({ t: "err", s: e.message }); }
  }, []);
  useEffect(() => {
    load();
    api("/api/acc/moein").then((j) => setMoeins(j.rows || [])).catch(() => {});
    api("/api/acc/dl").then((j) => setDls(j.rows || [])).catch(() => {});
    api("/api/auth/login").then((j) => setCan(j.can || {})).catch(() => {});
  }, [load]);

  const save = async () => {
    setMsg(null);
    try {
      await api("/api/prm/opening", { method: "POST", body: JSON.stringify(form) });
      setForm({ KolCode: "", MoeinCode: "", Dl1Id: "", Dbt: "", Crt: "" });
      await load();
    } catch (e: any) { setMsg({ t: "err", s: e.message }); }
  };
  const del = async (id: number) => {
    try { await api(`/api/prm/opening?id=${id}`, { method: "DELETE" }); await load(); }
    catch (e: any) { setMsg({ t: "err", s: e.message }); }
  };
  const issueOpening = async () => {
    setMsg(null);
    try {
      const j = await api("/api/prm/opening", { method: "PUT", body: "{}" });
      setMsg({ t: "ok", s: `سند افتتاحیه شماره ${fa(j.voucher.VchNo)} به‌صورت «موقت» صادر شد — بررسی و قطعی در پنجره‌های اسناد` });
    } catch (e: any) { setMsg({ t: "err", s: e.message }); }
  };

  const selM = moeins.find((m) => m.Code === form.MoeinCode);
  const balanced = Number(totals.D) === Number(totals.C) && Number(totals.D) > 0;

  return (
    <Shell title="ماندهٔ ابتدای دوره و سند افتتاحیه" sub="مانده‌ها → سند افتتاحیه (موقت → بررسی → قطعی طبق روال)">
      {msg && <div className={`msg ${msg.t}`}>{msg.s}</div>}
      <div className="form-grid" style={{ gridTemplateColumns: "220px 130px 130px 130px" }}>
        <div className="field"><label>حساب معین *</label>
          <select value={form.MoeinCode} onChange={(e) => setForm({ ...form, MoeinCode: e.target.value, KolCode: moeins.find((m) => m.Code === e.target.value)?.KolCode || "", Dl1Id: "" })}>
            <option value="">—</option>
            {moeins.map((m) => <option key={m.Code} value={m.Code}>{m.Code} — {m.Title}</option>)}
          </select>
        </div>
        <div className="field"><label>تفصیلی{selM?.Dl1TypeId ? ` (${moeins.find((t) => t.Dl1TypeId === selM.Dl1TypeId) ? "الزامی" : ""})` : ""}</label>
          <select value={form.Dl1Id} disabled={!selM?.Dl1TypeId} onChange={(e) => setForm({ ...form, Dl1Id: e.target.value })}>
            <option value="">{selM?.Dl1TypeId ? "— الزامی —" : "—"}</option>
            {dls.filter((d) => d.DlTypeId === selM?.Dl1TypeId).map((d) => <option key={d.DlId} value={d.DlId}>{d.Code} — {d.Title}</option>)}
          </select>
        </div>
        <div className="field"><label>بدهکار</label><input value={form.Dbt} onChange={(e) => setForm({ ...form, Dbt: e.target.value, Crt: e.target.value ? "" : form.Crt })} className="num" style={{ direction: "ltr" }} /></div>
        <div className="field"><label>بستانکار</label><input value={form.Crt} onChange={(e) => setForm({ ...form, Crt: e.target.value, Dbt: e.target.value ? "" : form.Dbt })} className="num" style={{ direction: "ltr" }} /></div>
      </div>
      <div className="btnrow">
        <button className="btn primary" onClick={save} disabled={!form.MoeinCode}>ثبت مانده</button>
        <button className="btn green" onClick={issueOpening} disabled={!balanced || !can.issue}>صدور سند افتتاحیه</button>
        <span className="muted">جمع بدهکار: {fa(totals.D)} — جمع بستانکار: {fa(totals.C)} {balanced ? "(تراز ✓)" : "(تراز نیست)"}</span>
      </div>
      <div className="scrollbox">
        <table className="grid">
          <thead><tr><th>کل</th><th>معین</th><th>تفصیلی</th><th className="num">بدهکار</th><th className="num">بستانکار</th><th style={{ width: 70 }}></th></tr></thead>
          <tbody>
            {rows.map((r) => (
              <tr key={r.ObId}>
                <td>{r.KolCode} — {r.KolTitle}</td>
                <td>{r.MoeinCode} — {r.MoeinTitle}</td>
                <td>{r.Dl1Title || "—"}</td>
                <td className="num">{Number(r.Dbt) ? fa(r.Dbt) : ""}</td>
                <td className="num">{Number(r.Crt) ? fa(r.Crt) : ""}</td>
                <td><button className="btn danger" onClick={() => del(r.ObId)} style={{ padding: "1px 8px" }}>حذف</button></td>
              </tr>
            ))}
            {!rows.length && <tr><td colSpan={6} className="muted" style={{ textAlign: "center", padding: 16 }}>مانده‌ای ثبت نشده</td></tr>}
          </tbody>
        </table>
      </div>
    </Shell>
  );
}
