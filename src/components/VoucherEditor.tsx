"use client";

import { Fragment, useEffect, useMemo, useState } from "react";
import { api, fa } from "@/lib/ui";
import { fetchVoucher, VchDetail } from "@/components/VoucherDetail";
import { useColResize, ColGrip } from "@/lib/colresize";

/* ============================================================================
   ویرایشگر سند (v2.2.0) — درخواست کارفرما:
   «مشاهده سند در مرور حسابها بتوان سند را در همان پنجره ویرایش کرد»
   همان ساختار فرم «صدور سند»: سرسند + ردیف‌ها + ارز/پیگیری/لاتین + جمع و تراز
   ذخیره → POST /api/vch/update (فقط موقت/بررسی‌شده — قطعی و برگشتی مجاز نیست)
   ستون‌ها با موس قابل بزرگ/کوچک شدن‌اند (مطابق صدور سند)
   ============================================================================ */

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

const COLS: [string, number, string, "l" | "n" | ""][] = [
  ["no", 34, "#", ""],
  ["kolCode", 92, "کد کل", "l"],
  ["kol", 168, "حساب کل", ""],
  ["moeinCode", 92, "کد معین", "l"],
  ["moein", 200, "حساب معین", ""],
  ["taf1", 130, "تفصیلی ۴", ""],
  ["taf2", 130, "تفصیلی ۵", ""],
  ["taf3", 130, "تفصیلی ۶", ""],
  ["descr", 170, "شرح ردیف", ""],
  ["dbt", 118, "بدهکار", "n"],
  ["crt", 118, "بستانکار", "n"],
  ["ops", 62, "", ""],
];

export function VoucherEditor({ id, onClose, onSaved }: {
  id: number; onClose: () => void; onSaved?: (voucher: any) => void;
}) {
  const [d, setD] = useState<VchDetail | null>(null);
  const [loadErr, setLoadErr] = useState("");
  const [types, setTypes] = useState<any[]>([]);
  const [branches, setBranches] = useState<any[]>([]);
  const [fxList, setFxList] = useState<any[]>([]);
  const [moeins, setMoeins] = useState<any[]>([]);
  const [dls, setDls] = useState<any[]>([]);
  const [vchDate, setVchDate] = useState("");
  const [descr, setDescr] = useState("");
  const [typeId, setTypeId] = useState("");
  const [branchId, setBranchId] = useState("");
  const [dayNo, setDayNo] = useState("");
  const [subNo, setSubNo] = useState("0");
  const [latin, setLatin] = useState("");
  const [rows, setRows] = useState<Row[]>([emptyRow()]);
  const [openRows, setOpenRows] = useState<Set<number>>(new Set());
  const [msg, setMsg] = useState<{ t: "err" | "ok"; s: string } | null>(null);
  const [busy, setBusy] = useState(false);
  const rs = useColResize({});

  useEffect(() => {
    (async () => {
      try {
        const v = await fetchVoucher(id);
        setD(v);
        const h = v.hdr;
        setVchDate(h.VchDate || ""); setDescr(h.Descr || ""); setTypeId(String(h.VoucherTypeId || ""));
        setBranchId(h.BranchId ? String(h.BranchId) : ""); setDayNo(h.DayNo === null || h.DayNo === undefined ? "" : String(h.DayNo));
        setSubNo(String(h.SubNo ?? 0)); setLatin(h.LatinDescr || "");
        setRows(v.items.length ? v.items.map((it: any) => ({
          KolCode: String(it.KolCode || ""), MoeinCode: String(it.MoeinCode || ""),
          Taf1Id: it.Taf1Id ? String(it.Taf1Id) : "", Taf2Id: it.Taf2Id ? String(it.Taf2Id) : "", Taf3Id: it.Taf3Id ? String(it.Taf3Id) : "",
          Descr: it.Descr || "", Dbt: Number(it.Dbt) ? String(Number(it.Dbt)) : "", Crt: Number(it.Crt) ? String(Number(it.Crt)) : "",
          FxId: it.FxId ? String(it.FxId) : "", FxAmount: it.FxAmount ? String(it.FxAmount) : "", FxRate: it.FxRate ? String(it.FxRate) : "",
          TrackNo: it.TrackNo || "", TrackDate: it.TrackDate || "", LatinDescr: it.LatinDescr || "",
        })) : [emptyRow()]);
      } catch (e: any) { setLoadErr(e.message); }
      try { const j = await api("/api/vch/types"); setTypes(j.rows || []); setBranches(j.branches || []); setFxList(j.fx || []); } catch { /* - */ }
      try { const m = await api("/api/acc/moein"); setMoeins((m.rows || []).filter((x: any) => x.IsActive !== 0)); } catch { /* - */ }
      try { const dd = await api("/api/acc/tafsili"); setDls((dd.rows || []).filter((x: any) => x.IsActive !== 0)); } catch { /* - */ }
    })();
  }, [id]);

  const moeinMap = useMemo(() => new Map(moeins.map((m) => [m.Code, m])), [moeins]);
  const kolMap = useMemo(() => {
    const m = new Map<string, { code: string; title: string }>();
    moeins.forEach((x: any) => { if (x.KolCode && !m.has(x.KolCode)) m.set(x.KolCode, { code: x.KolCode, title: x.KolTitle || "" }); });
    return m;
  }, [moeins]);
  const kolOptions = useMemo(() => [...kolMap.keys()].sort(), [kolMap]);
  const moeinsOf = (kol: string) => moeins.filter((m) => m.KolCode === kol);
  const dlsOfType = (t: number) => dls.filter((x) => x.TafsiliTypeId === t);

  const upd = (i: number, patch: Partial<Row>) => setRows((rs2) => rs2.map((r, k) => (k === i ? { ...r, ...patch } : r)));
  const toggleOpen = (i: number) => setOpenRows((s) => { const n = new Set(s); n.has(i) ? n.delete(i) : n.add(i); return n; });
  const pickKol = (i: number, kol: string) => upd(i, { KolCode: kol, MoeinCode: "", Taf1Id: "", Taf2Id: "", Taf3Id: "" });
  const pickMoein = (i: number, code: string) => {
    const m = moeinMap.get(code);
    upd(i, { MoeinCode: code, KolCode: m ? m.KolCode : "", Taf1Id: "", Taf2Id: "", Taf3Id: "" });
  };

  const totals = rows.reduce((a, r) => ({ D: a.D + (Number(r.Dbt) || 0), C: a.C + (Number(r.Crt) || 0) }), { D: 0, C: 0 });
  const balanced = totals.D === totals.C && totals.D > 0;

  /* شرایط ویرایش — هم‌راستا با سرور */
  const h = d?.hdr;
  const forbidden = h && (h.State === 3 ? "سند قطعی قابل ویرایش نیست — ابتدا سند را برگشت دهید."
    : h.ReversalOf ? "سند برگشتی قابل ویرایش نیست." : "");

  const save = async () => {
    if (!d) return;
    setBusy(true); setMsg(null);
    try {
      const items = rows
        .filter((r) => r.KolCode || r.MoeinCode || Number(r.Dbt) || Number(r.Crt))
        .map((r) => ({
          KolCode: r.KolCode, MoeinCode: r.MoeinCode,
          Taf1Id: r.Taf1Id ? Number(r.Taf1Id) : null, Taf2Id: r.Taf2Id ? Number(r.Taf2Id) : null, Taf3Id: r.Taf3Id ? Number(r.Taf3Id) : null,
          Descr: r.Descr, Dbt: Number(r.Dbt) || 0, Crt: Number(r.Crt) || 0,
          FxId: r.FxId ? Number(r.FxId) : null, FxAmount: r.FxAmount || null, FxRate: r.FxRate || null,
          TrackNo: r.TrackNo || "", TrackDate: r.TrackDate || "", LatinDescr: r.LatinDescr || "",
        }));
      const j = await api("/api/vch/update", { method: "POST", body: JSON.stringify({
        id: d.hdr.VoucherId,
        VchDate: vchDate, Descr: descr, VoucherTypeId: Number(typeId),
        BranchId: branchId ? Number(branchId) : null,
        DayNo: dayNo === "" ? null : Number(dayNo),
        SubNo: subNo === "" ? 0 : Number(subNo),
        LatinDescr: latin, items,
      }) });
      setMsg({ t: "ok", s: `سند ${fa(j.voucher.VchNo)} با موفقیت ویرایش شد` });
      onSaved?.(j.voucher);
    } catch (e: any) { setMsg({ t: "err", s: e.message }); }
    setBusy(false);
  };

  return (
    <div style={{ position: "fixed", inset: 0, background: "rgba(15,35,55,.5)", zIndex: 60, display: "flex", alignItems: "center", justifyContent: "center", padding: 18 }}
      onClick={() => { /* کلیک بیرون نمی‌بندد — از دکمه‌ها استفاده کنید */ }}>
      <div style={{ background: "#fff", borderRadius: 10, width: "min(1400px, 97vw)", maxHeight: "94vh", overflow: "auto", padding: 0 }}
        onClick={(e) => e.stopPropagation()}>
        <div className="window" style={{ marginTop: 0, border: "none" }}>
          <div className="window-title">
            <span>ویرایش سند {d ? `${fa(h!.VchNo)} — ${h!.TypeTitle}` : `#${id}`}{h?.State === 2 ? " (بررسی‌شده)" : ""}</span>
            <button className="btn" onClick={onClose} style={{ padding: "1px 10px" }}>بستن</button>
          </div>
          <div className="window-body">
            {loadErr && <div className="msg err">{loadErr}</div>}
            {forbidden && <div className="msg err">{forbidden}</div>}
            {d && !forbidden && (
              <>
                {msg && <div className={`msg ${msg.t}`}>{msg.s}</div>}
                <div className="card">
                  <div className="card-title">سرسند — ویرایش</div>
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
                      <label>ش روزانه</label>
                      <input value={dayNo} onChange={(e) => setDayNo(e.target.value.replace(/\D/g, ""))}
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
                      {COLS.map(([key, w, label, align]) => (
                        <th key={key} className={align === "n" ? "num" : align === "l" ? "" : ""}
                          style={{ width: rs.widths[key] ?? w, minWidth: 36 }}>
                          <span style={{ position: "relative", display: "inline-block", width: "100%" }}>
                            {label}
                            <ColGrip onDown={rs.onDown(key, rs.widths[key] ?? w)} />
                          </span>
                        </th>
                      ))}
                    </tr></thead>
                    <tbody>
                      {rows.map((r, i) => {
                        const m = moeinMap.get(r.MoeinCode);
                        const hasFx = !!(r.FxId || r.FxAmount || r.FxRate || r.TrackNo || r.TrackDate || r.LatinDescr);
                        return (
                          <Fragment key={i}>
                            <tr className={openRows.has(i) ? "row-open" : ""}>
                              <td>{i + 1}</td>
                              <td className="ltr">{r.KolCode ? <b>{r.KolCode}</b> : <span className="muted">—</span>}</td>
                              <td>
                                <select value={r.KolCode} onChange={(e) => pickKol(i, e.target.value)} style={{ width: "100%" }} title={kolMap.get(r.KolCode)?.title || ""}>
                                  <option value="">— انتخاب —</option>
                                  {kolOptions.map((k) => <option key={k} value={k}>{k} — {kolMap.get(k)?.title}</option>)}
                                </select>
                              </td>
                              <td className="ltr">{r.MoeinCode ? <b>{r.MoeinCode}</b> : <span className="muted">—</span>}</td>
                              <td>
                                <select value={r.MoeinCode} onChange={(e) => pickMoein(i, e.target.value)} style={{ width: "100%" }} title={m?.Title || ""}>
                                  <option value="">— انتخاب —</option>
                                  {moeinsOf(r.KolCode).map((m2) => <option key={m2.Code} value={m2.Code}>{m2.Code} — {m2.Title}</option>)}
                                </select>
                              </td>
                              {[["Taf1Id", m?.Taf1TypeId], ["Taf2Id", m?.Taf2TypeId], ["Taf3Id", m?.Taf3TypeId]].map(([f, t]) => (
                                <td key={String(f)}>
                                  {t ? (
                                    <select value={(r as any)[String(f)]} onChange={(e) => upd(i, { [String(f)]: e.target.value } as Partial<Row>)} style={{ width: "100%" }}>
                                      <option value="">— الزامی —</option>
                                      {dlsOfType(Number(t)).map((x) => <option key={x.TafsiliId} value={x.TafsiliId}>{x.Code} — {x.Title}</option>)}
                                    </select>
                                  ) : <span className="muted">—</span>}
                                </td>
                              ))}
                              <td><input value={r.Descr} onChange={(e) => upd(i, { Descr: e.target.value })} style={{ width: "96%" }} /></td>
                              <td><input value={r.Dbt} onChange={(e) => upd(i, { Dbt: e.target.value, Crt: e.target.value ? "" : r.Crt })} className="num" style={{ width: "96%", direction: "ltr", textAlign: "left" }} /></td>
                              <td><input value={r.Crt} onChange={(e) => upd(i, { Crt: e.target.value, Dbt: e.target.value ? "" : r.Dbt })} className="num" style={{ width: "96%", direction: "ltr", textAlign: "left" }} /></td>
                              <td style={{ whiteSpace: "nowrap" }}>
                                <button className={`btn ghost ${hasFx ? "active" : ""}`} title="ارز / پیگیری / لاتین"
                                  onClick={() => toggleOpen(i)} style={{ padding: "1px 7px" }}>▾</button>{" "}
                                <button className="btn danger" onClick={() => setRows(rows.filter((_, k) => k !== i))} style={{ padding: "1px 7px" }}>×</button>
                              </td>
                            </tr>
                            {openRows.has(i) && (
                              <tr className="detail-row">
                                <td></td>
                                <td colSpan={11}>
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
                  <button className="btn primary" onClick={save} disabled={busy || !balanced}>ذخیرهٔ تغییرها</button>
                  <button className="btn" onClick={onClose}>انصراف</button>
                </div>
              </>
            )}
            {!d && !loadErr && <div className="boot">در حال بارگذاری سند…</div>}
          </div>
        </div>
      </div>
    </div>
  );
}
