"use client";

import { Fragment, useEffect, useMemo, useState } from "react";
import Shell from "@/components/Shell";
import { api, fa, readCtxCookie } from "@/lib/ui";
import { todayJalali } from "@/lib/jalali";

/* [فرم اصلی: صدور سند حسابداري — acGenVch]
   سرسند: تاریخ/شرح/نوع + شعبه/ش روزانه/ش فرعي/لاتين (G-C2)
   ردیف: کل/معین/تفصیلی ۴-۶/شرح/بدهکار/بستانکار + ردیف بازشوندهٔ ارز و پیگیری و لاتین
   تراز زنده + شماره‌گذاری روزانهٔ خودکار */

interface Row {
  KolCode: string; MoeinCode: string; Taf1Id: string; Taf2Id: string; Taf3Id: string;
  Descr: string; Dbt: string; Crt: string;
  FxId: string; FxAmount: string; FxRate: string;
  TrackNo: string; TrackDate: string; LatinDescr: string;
}
const emptyRow = (): Row => ({
  KolCode: "", MoeinCode: "", Taf1Id: "", Taf2Id: "", Taf3Id: "", Descr: "", Dbt: "", Crt: "",
  FxId: "", FxAmount: "", FxRate: "", TrackNo: "", TrackDate: "", LatinDescr: "",
});

export default function Page() {
  const [types, setTypes] = useState<any[]>([]);
  const [branches, setBranches] = useState<any[]>([]);
  const [fxList, setFxList] = useState<any[]>([]);
  const [vchDate, setVchDate] = useState(todayJalali());
  const [descr, setDescr] = useState("");
  const [typeId, setTypeId] = useState("");
  const [branchId, setBranchId] = useState("");
  const [dayNo, setDayNo] = useState("");
  const [subNo, setSubNo] = useState("0");
  const [latin, setLatin] = useState("");
  const [rows, setRows] = useState<Row[]>([emptyRow(), emptyRow()]);
  const [openRows, setOpenRows] = useState<Set<number>>(new Set());
  const [msg, setMsg] = useState<{ t: "err" | "ok"; s: string } | null>(null);
  const [busy, setBusy] = useState(false);
  const [lastNo, setLastNo] = useState<number | null>(null);
  const [moeins, setMoeins] = useState<any[]>([]);
  const [dls, setDls] = useState<any[]>([]);

  useEffect(() => {
    (async () => {
      let { companyId } = readCtxCookie();
      if (!companyId) {
        /* پشتیبان: خواندن کانتکست از سرور در صورت نبود کوکی در سمت کلاینت */
        try { const j = await (await fetch("/api/context")).json(); if (j.ok && j.current?.CompanyId) companyId = j.current.CompanyId; } catch { /* - */ }
      }
      if (!companyId) { setMsg({ t: "err", s: "ابتدا شرکت و سال مالی را از نوار بالا انتخاب کنید" }); return; }
      try {
        const j = await api("/api/vch/types");
        setTypes(j.rows || []); if (j.rows?.length) setTypeId(String(j.rows[0].VoucherTypeId));
        setBranches(j.branches || []); setFxList(j.fx || []);
      } catch (e: any) { setMsg({ t: "err", s: e.message }); }
      api("/api/acc/moein").then((j) => setMoeins(j.rows || [])).catch(() => {});
      api("/api/acc/tafsili").then((j) => setDls(j.rows || [])).catch(() => {});
    })();
  }, []);

  const moeinMap = useMemo(() => new Map(moeins.map((m) => [m.Code, m])), [moeins]);
  const kolTitles = useMemo(() => {
    const m = new Map<string, string>();
    moeins.forEach((x: any) => { if (x.KolCode && x.KolTitle && !m.has(x.KolCode)) m.set(x.KolCode, x.KolTitle); });
    return m;
  }, [moeins]);
  const kolOptions = useMemo(() => [...new Set(moeins.map((m) => m.KolCode))].sort(), [moeins]);
  const moeinsOf = (kol: string) => moeins.filter((m) => m.KolCode === kol);
  const dlsOfType = (typeId: number) => dls.filter((d) => d.TafsiliTypeId === typeId);

  const upd = (i: number, patch: Partial<Row>) => {
    setRows((rs) => rs.map((r, k) => (k === i ? { ...r, ...patch } : r)));
  };
  const toggleOpen = (i: number) => {
    setOpenRows((s) => { const n = new Set(s); n.has(i) ? n.delete(i) : n.add(i); return n; });
  };

  const pickMoein = (i: number, code: string) => {
    const m = moeinMap.get(code);
    upd(i, { MoeinCode: code, KolCode: m ? m.KolCode : "", Taf1Id: "", Taf2Id: "", Taf3Id: "" });
  };

  const totals = rows.reduce((a, r) => ({ D: a.D + (Number(r.Dbt) || 0), C: a.C + (Number(r.Crt) || 0) }), { D: 0, C: 0 });
  const balanced = totals.D === totals.C && totals.D > 0;

  const save = async () => {
    setBusy(true); setMsg(null);
    try {
      /* همگام‌سازی سال مالی قبل از ارسال — اگر کوکی هنوز سال ندارد، از سرور گرفته و کوکی آپدیت می‌شود */
      let ctx = readCtxCookie();
      if (!ctx.yearId || !ctx.companyId) {
        try { await (await fetch("/api/context")).json(); ctx = readCtxCookie(); } catch { /* - */ }
      }
      if (!ctx.companyId || !ctx.yearId) { setMsg({ t: "err", s: "ابتدا شرکت و سال مالی را از نوار بالا انتخاب کنید" }); setBusy(false); return; }
      const items = rows
        .filter((r) => r.KolCode || r.MoeinCode || Number(r.Dbt) || Number(r.Crt))
        .map((r) => ({
          KolCode: r.KolCode, MoeinCode: r.MoeinCode,
          Taf1Id: r.Taf1Id ? Number(r.Taf1Id) : null, Taf2Id: r.Taf2Id ? Number(r.Taf2Id) : null, Taf3Id: r.Taf3Id ? Number(r.Taf3Id) : null,
          Descr: r.Descr, Dbt: Number(r.Dbt) || 0, Crt: Number(r.Crt) || 0,
          FxId: r.FxId ? Number(r.FxId) : null, FxAmount: r.FxAmount || null, FxRate: r.FxRate || null,
          TrackNo: r.TrackNo || "", TrackDate: r.TrackDate || "", LatinDescr: r.LatinDescr || "",
        }));
      const j = await api("/api/vch/issue", { method: "POST", body: JSON.stringify({
        VchDate: vchDate, Descr: descr, VoucherTypeId: Number(typeId),
        BranchId: branchId ? Number(branchId) : null,
        DayNo: dayNo === "" ? null : Number(dayNo),
        SubNo: subNo === "" ? 0 : Number(subNo),
        LatinDescr: latin, items,
      }) });
      setLastNo(j.voucher.VchNo);
      setRows([emptyRow(), emptyRow()]); setDescr(""); setLatin(""); setDayNo(""); setOpenRows(new Set());
      setMsg({ t: "ok", s: `سند شماره ${j.voucher.VchNo} (عطف ${j.voucher.FolioNo} — ش روزانهٔ ${j.voucher.DayNo}) به‌صورت «موقت» صادر شد` });
    } catch (e: any) { setMsg({ t: "err", s: e.message }); }
    setBusy(false);
  };

  return (
    <Shell title="صدور سند حسابداری" sub="سند صادرشده «موقت» است — فرایند: صدور ← بررسی ← قطعی">
      {msg && <div className={`msg ${msg.t}`}>{msg.s}</div>}

      <div className="card">
        <div className="card-title">سرسند</div>
        <div className="form-grid" style={{ gridTemplateColumns: "repeat(auto-fit, minmax(150px, 1fr))" }}>
          <div className="field">
            <label>تاریخ سند (جلالی)</label>
            <input value={vchDate} onChange={(e) => setVchDate(e.target.value)} style={{ direction: "ltr", textAlign: "left" }} />
          </div>
          <div className="field" style={{ gridColumn: "span 2" }}>
            <label>شرح سند</label>
            <input value={descr} onChange={(e) => setDescr(e.target.value)} />
          </div>
          <div className="field">
            <label>نوع سند</label>
            <select value={typeId} onChange={(e) => setTypeId(e.target.value)}>
              {types.map((t) => <option key={t.VoucherTypeId} value={t.VoucherTypeId}>{t.Title}</option>)}
            </select>
          </div>
          <div className="field">
            <label>شعبه</label>
            <select value={branchId} onChange={(e) => setBranchId(e.target.value)}>
              <option value="">—</option>
              {branches.map((b) => <option key={b.v} value={b.v}>{b.t}</option>)}
            </select>
          </div>
          <div className="field">
            <label>ش روزانه (خالی = خودکار)</label>
            <input value={dayNo} onChange={(e) => setDayNo(e.target.value.replace(/\D/g, ""))} placeholder="خودکار"
              style={{ direction: "ltr", textAlign: "left" }} />
          </div>
          <div className="field">
            <label>ش فرعي</label>
            <input value={subNo} onChange={(e) => setSubNo(e.target.value.replace(/\D/g, ""))}
              style={{ direction: "ltr", textAlign: "left" }} />
          </div>
          <div className="field" style={{ gridColumn: "span 2" }}>
            <label>لاتين (شرح لاتین سند)</label>
            <input value={latin} onChange={(e) => setLatin(e.target.value)} dir="ltr"
              style={{ direction: "ltr", textAlign: "left", fontFamily: "inherit" }} />
          </div>
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
            <th style={{ width: 64 }}></th>
          </tr></thead>
          <tbody>
            {rows.map((r, i) => {
              const m = moeinMap.get(r.MoeinCode);
              const hasFx = !!(r.FxId || r.FxAmount || r.FxRate || r.TrackNo || r.TrackDate || r.LatinDescr);
              return (
                <Fragment key={i}>
                  <tr className={openRows.has(i) ? "row-open" : ""}>
                    <td>{i + 1}</td>
                    <td>
                      <select value={r.KolCode} onChange={(e) => upd(i, { KolCode: e.target.value, MoeinCode: "", Taf1Id: "", Taf2Id: "", Taf3Id: "" })} style={{ width: "100%" }}>
                        <option value="">—</option>
                        {kolOptions.map((k) => <option key={k} value={k}>{k} — {kolTitles.get(k) || ""}</option>)}
                      </select>
                    </td>
                    <td>
                      <select value={r.MoeinCode} onChange={(e) => pickMoein(i, e.target.value)} style={{ width: "100%" }}>
                        <option value="">—</option>
                        {moeinsOf(r.KolCode).map((m2) => <option key={m2.Code} value={m2.Code}>{m2.Code} — {m2.Title}</option>)}
                      </select>
                    </td>
                    {[["Taf1Id", m?.Taf1TypeId], ["Taf2Id", m?.Taf2TypeId], ["Taf3Id", m?.Taf3TypeId]].map(([f, t]) => (
                      <td key={String(f)}>
                        {t ? (
                          <select value={(r as any)[String(f)]} onChange={(e) => upd(i, { [String(f)]: e.target.value } as Partial<Row>)} style={{ width: "100%" }}>
                            <option value="">— الزامی —</option>
                            {dlsOfType(Number(t)).map((d) => <option key={d.TafsiliId} value={d.TafsiliId}>{d.Code} — {d.Title}</option>)}
                          </select>
                        ) : <span className="muted">—</span>}
                      </td>
                    ))}
                    <td><input value={r.Descr} onChange={(e) => upd(i, { Descr: e.target.value })} style={{ width: "95%" }} /></td>
                    <td><input value={r.Dbt} onChange={(e) => upd(i, { Dbt: e.target.value, Crt: e.target.value ? "" : r.Crt })} className="num" style={{ width: "95%", direction: "ltr", textAlign: "left" }} /></td>
                    <td><input value={r.Crt} onChange={(e) => upd(i, { Crt: e.target.value, Dbt: e.target.value ? "" : r.Dbt })} className="num" style={{ width: "95%", direction: "ltr", textAlign: "left" }} /></td>
                    <td style={{ whiteSpace: "nowrap" }}>
                      <button className={`btn ghost ${hasFx ? "active" : ""}`} title="ارز / پیگیری / لاتین"
                        onClick={() => toggleOpen(i)} style={{ padding: "1px 7px" }}>▾</button>{" "}
                      <button className="btn danger" onClick={() => setRows(rows.filter((_, k) => k !== i))} style={{ padding: "1px 7px" }}>×</button>
                    </td>
                  </tr>
                  {openRows.has(i) && (
                    <tr className="detail-row">
                      <td></td>
                      <td colSpan={9}>
                        <div className="detail-grid">
                          <div className="field">
                            <label>نوع ارز</label>
                            <select value={r.FxId} onChange={(e) => upd(i, { FxId: e.target.value })}>
                              <option value="">— ریال (بدون ارز) —</option>
                              {fxList.map((f) => <option key={f.v} value={f.v}>{f.t}{f.IsBase ? " ★" : ""}</option>)}
                            </select>
                          </div>
                          <div className="field">
                            <label>مبلغ ارزی</label>
                            <input value={r.FxAmount} onChange={(e) => upd(i, { FxAmount: e.target.value })} disabled={!r.FxId}
                              className="num" style={{ direction: "ltr", textAlign: "left" }} />
                          </div>
                          <div className="field">
                            <label>نرخ ارز</label>
                            <input value={r.FxRate} onChange={(e) => upd(i, { FxRate: e.target.value })} disabled={!r.FxId}
                              className="num" style={{ direction: "ltr", textAlign: "left" }} />
                          </div>
                          <div className="field">
                            <label>شمارهٔ پیگیری</label>
                            <input value={r.TrackNo} onChange={(e) => upd(i, { TrackNo: e.target.value })}
                              style={{ direction: "ltr", textAlign: "left" }} />
                          </div>
                          <div className="field">
                            <label>تاریخ پیگیری (جلالی)</label>
                            <input value={r.TrackDate} onChange={(e) => upd(i, { TrackDate: e.target.value })} placeholder="1405/01/01"
                              style={{ direction: "ltr", textAlign: "left" }} />
                          </div>
                          <div className="field" style={{ gridColumn: "span 2" }}>
                            <label>شرح لاتین ردیف</label>
                            <input value={r.LatinDescr} onChange={(e) => upd(i, { LatinDescr: e.target.value })} dir="ltr"
                              style={{ direction: "ltr", textAlign: "left" }} />
                          </div>
                        </div>
                        {r.FxId && r.FxAmount && r.FxRate && (
                          <p className="muted" style={{ marginTop: 4 }}>
                            معادل ریالی تقریبی: {fa(Number(r.FxAmount) * Number(r.FxRate))} — مبلغ ریالی قلم باید جداگانه در بدهکار/بستانکار ثبت شود
                          </p>
                        )}
                      </td>
                    </tr>
                  )}
                </Fragment>
              );
            })}
          </tbody>
        </table>
      </div>
      <div className="totalbar">
        <span>جمع بدهکار: {fa(totals.D)}</span>
        <span>جمع بستانکار: {fa(totals.C)}</span>
        <span style={{ color: balanced ? "var(--green)" : "var(--accent)" }}>{balanced ? "تراز ✓" : "تراز نیست"}</span>
      </div>
      <div className="btnrow">
        <button className="btn" onClick={() => setRows([...rows, emptyRow()])}>افزودن ردیف</button>
        <button className="btn primary" onClick={save} disabled={busy || !balanced}>صدور سند</button>
        {lastNo && <span className="muted">آخرین سند صادرشده: {fa(lastNo)}</span>}
      </div>
    </Shell>
  );
}
