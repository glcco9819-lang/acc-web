"use client";

import { useEffect, useMemo, useState } from "react";
import Shell from "@/components/Shell";
import { api, fa, readCtxCookie } from "@/lib/ui";
import { todayJalali } from "@/lib/jalali";

/* [فرم اصلی: صدور سند حسابداري — acGenVch]
   ردیف‌ها: کل / معین / تفصیلی ۴ / تفصیلی ۵ / تفصیلی ۶ / شرح / بدهکار / بستانکار — با تراز زنده */

interface Row {
  KolCode: string; MoeinCode: string; Dl1Id: string; Dl2Id: string; Dl3Id: string;
  Descr: string; Dbt: string; Crt: string;
}
const emptyRow = (): Row => ({ KolCode: "", MoeinCode: "", Dl1Id: "", Dl2Id: "", Dl3Id: "", Descr: "", Dbt: "", Crt: "" });

export default function Page() {
  const [types, setTypes] = useState<any[]>([]);
  const [vchDate, setVchDate] = useState(todayJalali());
  const [descr, setDescr] = useState("");
  const [typeId, setTypeId] = useState("");
  const [rows, setRows] = useState<Row[]>([emptyRow(), emptyRow()]);
  const [msg, setMsg] = useState<{ t: "err" | "ok"; s: string } | null>(null);
  const [busy, setBusy] = useState(false);
  const [lastNo, setLastNo] = useState<number | null>(null);
  const [moeins, setMoeins] = useState<any[]>([]);
  const [dls, setDls] = useState<any[]>([]);

  useEffect(() => {
    const { companyId } = readCtxCookie();
    if (!companyId) { setMsg({ t: "err", s: "ابتدا شرکت و سال مالی را از نوار بالا انتخاب کنید" }); return; }
    api("/api/vch/types").then((j) => { setTypes(j.rows || []); if (j.rows?.length) setTypeId(String(j.rows[0].TypeId)); }).catch((e) => setMsg({ t: "err", s: e.message }));
    api("/api/acc/moein").then((j) => setMoeins(j.rows || [])).catch(() => {});
    api("/api/acc/dl").then((j) => setDls(j.rows || [])).catch(() => {});
  }, []);

  const moeinMap = useMemo(() => new Map(moeins.map((m) => [m.Code, m])), [moeins]);
  const kolOptions = useMemo(() => [...new Set(moeins.map((m) => m.KolCode))].sort(), [moeins]);
  const moeinsOf = (kol: string) => moeins.filter((m) => m.KolCode === kol);
  const dlsOfType = (typeId: number) => dls.filter((d) => d.DlTypeId === typeId);

  const upd = (i: number, patch: Partial<Row>) => {
    setRows((rs) => rs.map((r, k) => (k === i ? { ...r, ...patch } : r)));
  };

  const pickMoein = (i: number, code: string) => {
    const m = moeinMap.get(code);
    upd(i, { MoeinCode: code, KolCode: m ? m.KolCode : "", Dl1Id: "", Dl2Id: "", Dl3Id: "" });
  };

  const totals = rows.reduce((a, r) => ({ D: a.D + (Number(r.Dbt) || 0), C: a.C + (Number(r.Crt) || 0) }), { D: 0, C: 0 });
  const balanced = totals.D === totals.C && totals.D > 0;

  const save = async () => {
    setBusy(true); setMsg(null);
    try {
      const items = rows
        .filter((r) => r.KolCode || r.MoeinCode || Number(r.Dbt) || Number(r.Crt))
        .map((r) => ({
          KolCode: r.KolCode, MoeinCode: r.MoeinCode,
          Dl1Id: r.Dl1Id ? Number(r.Dl1Id) : null, Dl2Id: r.Dl2Id ? Number(r.Dl2Id) : null, Dl3Id: r.Dl3Id ? Number(r.Dl3Id) : null,
          Descr: r.Descr, Dbt: Number(r.Dbt) || 0, Crt: Number(r.Crt) || 0,
        }));
      const j = await api("/api/vch/issue", { method: "POST", body: JSON.stringify({ VchDate: vchDate, Descr: descr, TypeId: Number(typeId), items }) });
      setLastNo(j.voucher.VchNo);
      setRows([emptyRow(), emptyRow()]); setDescr("");
      setMsg({ t: "ok", s: `سند شماره ${j.voucher.VchNo} (عطف ${j.voucher.FolioNo}) به‌صورت «موقت» صادر شد — در پنجرهٔ بررسی اسناد قابل بررسی است` });
    } catch (e: any) { setMsg({ t: "err", s: e.message }); }
    setBusy(false);
  };

  return (
    <Shell title="صدور سند حسابداری" sub="سند صادرشده «موقت» است — فرایند: صدور ← بررسی ← قطعی">
      {msg && <div className={`msg ${msg.t}`}>{msg.s}</div>}
      <div className="form-grid" style={{ gridTemplateColumns: "160px 1fr 260px" }}>
        <div className="field">
          <label>تاریخ سند (جلالی)</label>
          <input value={vchDate} onChange={(e) => setVchDate(e.target.value)} style={{ direction: "ltr", textAlign: "left" }} />
        </div>
        <div className="field">
          <label>شرح سند</label>
          <input value={descr} onChange={(e) => setDescr(e.target.value)} />
        </div>
        <div className="field">
          <label>نوع سند</label>
          <select value={typeId} onChange={(e) => setTypeId(e.target.value)}>
            {types.map((t) => <option key={t.TypeId} value={t.TypeId}>{t.Title}</option>)}
          </select>
        </div>
      </div>

      <div className="scrollbox" style={{ maxHeight: "none" }}>
        <table className="grid">
          <thead><tr>
            <th style={{ width: 34 }}>#</th>
            <th style={{ width: 150 }}>حساب کل</th>
            <th style={{ width: 200 }}>حساب معین</th>
            <th>تفصیلی ۴</th><th>تفصیلی ۵</th><th>تفصیلی ۶</th>
            <th>شرح ردیف</th>
            <th style={{ width: 120 }} className="num">بدهکار</th>
            <th style={{ width: 120 }} className="num">بستانکار</th>
            <th style={{ width: 30 }}></th>
          </tr></thead>
          <tbody>
            {rows.map((r, i) => {
              const m = moeinMap.get(r.MoeinCode);
              return (
                <tr key={i}>
                  <td>{i + 1}</td>
                  <td>
                    <select value={r.KolCode} onChange={(e) => upd(i, { KolCode: e.target.value, MoeinCode: "", Dl1Id: "", Dl2Id: "", Dl3Id: "" })} style={{ width: "100%" }}>
                      <option value="">—</option>
                      {kolOptions.map((k) => <option key={k} value={k}>{k} — {moeinMap.get(k) ? moeins.find((x) => x.KolCode === k)?.KolCode && (moeins.find((x) => x.KolCode === k) as any).KolTitle : ""}</option>)}
                    </select>
                  </td>
                  <td>
                    <select value={r.MoeinCode} onChange={(e) => pickMoein(i, e.target.value)} style={{ width: "100%" }}>
                      <option value="">—</option>
                      {moeinsOf(r.KolCode).map((m2) => <option key={m2.Code} value={m2.Code}>{m2.Code} — {m2.Title}</option>)}
                    </select>
                  </td>
                  {[["Dl1Id", m?.Dl1TypeId, "۴"], ["Dl2Id", m?.Dl2TypeId, "۵"], ["Dl3Id", m?.Dl3TypeId, "۶"]].map(([f, t]) => (
                    <td key={String(f)}>
                      {t ? (
                        <select value={(r as any)[String(f)]} onChange={(e) => upd(i, { [String(f)]: e.target.value } as Partial<Row>)} style={{ width: "100%" }}>
                          <option value="">— الزامی —</option>
                          {dlsOfType(Number(t)).map((d) => <option key={d.DlId} value={d.DlId}>{d.Code} — {d.Title}</option>)}
                        </select>
                      ) : <span className="muted">—</span>}
                    </td>
                  ))}
                  <td><input value={r.Descr} onChange={(e) => upd(i, { Descr: e.target.value })} style={{ width: "95%" }} /></td>
                  <td><input value={r.Dbt} onChange={(e) => upd(i, { Dbt: e.target.value, Crt: e.target.value ? "" : r.Crt })} className="num" style={{ width: "95%", direction: "ltr", textAlign: "left" }} /></td>
                  <td><input value={r.Crt} onChange={(e) => upd(i, { Crt: e.target.value, Dbt: e.target.value ? "" : r.Dbt })} className="num" style={{ width: "95%", direction: "ltr", textAlign: "left" }} /></td>
                  <td><button className="btn danger" onClick={() => setRows(rows.filter((_, k) => k !== i))} style={{ padding: "1px 7px" }}>×</button></td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
      <div className="totalbar">
        <span>جمع بدهکار: {fa(totals.D)}</span>
        <span>جمع بستانکار: {fa(totals.C)}</span>
        <span style={{ color: balanced ? "#2e6b3f" : "#8c2f39" }}>{balanced ? "تراز ✓" : "تراز نیست"}</span>
      </div>
      <div className="btnrow">
        <button className="btn" onClick={() => setRows([...rows, emptyRow()])}>افزودن ردیف</button>
        <button className="btn primary" onClick={save} disabled={busy || !balanced}>صدور سند</button>
        {lastNo && <span className="muted">آخرین سند صادرشده: {fa(lastNo)}</span>}
      </div>
    </Shell>
  );
}
