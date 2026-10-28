"use client";

import { useCallback, useEffect, useState } from "react";
import Shell from "@/components/Shell";
import { CtxGate, useApp } from "@/components/App";
import { api, fa, exportCsv } from "@/lib/ui";

/* ============================================================================
   نمايش اعلاميه ها — مطابق AcVwDef.BPL (v2.1.0)
   [فرم اصلی: نمايش اعلاميه ها + جزئيات اعلاميه — TAccDispNoteForm / TAccDtlNoteForm]
   فهرست اعلاميه‌ها + جزئيات اقلام + چاپ + Excel + حذف (فقط سازنده یا مدیر)
   ============================================================================ */

export default function Page() {
  const app = useApp();
  const [rows, setRows] = useState<any[]>([]);
  const [sel, setSel] = useState<any | null>(null);
  const [items, setItems] = useState<any[]>([]);
  const [err, setErr] = useState("");

  const load = useCallback(async () => {
    try {
      const j = await api("/api/note");
      setRows(j.rows || []); setErr("");
    } catch (e: any) { setErr(e.message); }
  }, []);

  useEffect(() => { if (!app.ctxMissing) load(); }, [app.companyId, app.yearId, load]); /* eslint-disable-line react-hooks/exhaustive-deps */

  const open = async (r: any) => {
    try {
      const j = await api(`/api/note?id=${r.NoteId}`);
      setSel(j.hdr); setItems(j.items || []); setErr("");
    } catch (e: any) { setErr(e.message); }
  };

  const del = async (r: any) => {
    if (!confirm(`اعلاميه شمارهٔ ${fa(r.NoteNo)} حذف شود؟`)) return;
    try {
      await api(`/api/note?id=${r.NoteId}`, { method: "DELETE" });
      if (sel?.NoteId === r.NoteId) { setSel(null); setItems([]); }
      load();
    } catch (e: any) { setErr(e.message); }
  };

  const excel = () => {
    if (!items.length) return;
    exportCsv(`اعلاميه-${sel.NoteNo}.csv`,
      ["ردیف", "تاریخ سند", "شماره سند", "کد کل", "شرح کل", "کد معین", "شرح ردیف", "تفصیلی ۴", "تفصیلی ۵", "تفصیلی ۶", "بدهکار", "بستانکار"],
      items.map((x) => [x.NoteLineNo, x.VchDate, x.VchNo, x.KolCode, x.KolTitle, x.MoeinCode, x.Descr || "",
        x.Taf1Title || "", x.Taf2Title || "", x.Taf3Title || "", Number(x.Dbt), Number(x.Crt)]));
  };

  const d = (n: number) => Math.abs(n).toLocaleString("fa-IR", { maximumFractionDigits: 0 });

  return (
    <Shell title="نمایش اعلامیه‌ها" sub="[فرم اصلی: نمايش اعلاميه ها — AcVwDef] فهرست + جزئيات + چاپ">
      <CtxGate>
        {err && <div className="msg err">{err}</div>}

        <div style={{ display: "grid", gridTemplateColumns: sel ? "1.2fr 1.6fr" : "1fr", gap: 12, alignItems: "start" }}>
          <div>
            <div className="scrollbox">
              <table className="grid">
                <thead><tr>
                  <th>ش اعلاميه</th><th>تاریخ</th><th>شرح</th><th>حساب معین</th>
                  <th className="num">اقلام</th><th className="num">بدهکار</th><th className="num">بستانکار</th>
                  <th>صادرکننده</th><th></th>
                </tr></thead>
                <tbody>
                  {rows.map((r) => (
                    <tr key={r.NoteId} style={{ background: sel?.NoteId === r.NoteId ? "#e3eef9" : undefined }}>
                      <td className="num"><b>{fa(r.NoteNo)}</b></td>
                      <td className="num">{r.NoteDate}</td>
                      <td>{r.Title || "—"}</td>
                      <td className="ltr">{r.MoeinCode ? `${r.MoeinCode} ${r.MoeinTitle || ""}` : "—"}</td>
                      <td className="num">{fa(r.ItemCount)}</td>
                      <td className="num">{fa(r.D)}</td>
                      <td className="num">{fa(r.C)}</td>
                      <td>{r.CreatedBy}</td>
                      <td style={{ whiteSpace: "nowrap" }}>
                        <button className="btn ghost" style={{ padding: "0 8px", fontSize: 11 }} onClick={() => open(r)}>جزئيات</button>{" "}
                        <button className="btn ghost danger" style={{ padding: "0 8px", fontSize: 11 }} onClick={() => del(r)}>حذف</button>
                      </td>
                    </tr>
                  ))}
                  {!rows.length && <tr><td colSpan={9} className="muted" style={{ textAlign: "center", padding: 16 }}>اعلامیه‌ای صادر نشده — از پنجرهٔ «مرور حساب‌ها» اقلام را انتخاب و اعلاميه صادر کنید</td></tr>}
                </tbody>
              </table>
            </div>
          </div>

          {sel && (
            <div>
              <div className="window-title" style={{ borderRadius: 8, marginBottom: 8 }}>
                <span>جزئيات اعلاميه شمارهٔ {fa(sel.NoteNo)} — {sel.NoteDate}</span>
                <div style={{ display: "flex", gap: 6 }}>
                  <button className="btn ghost" style={{ padding: "0 10px" }} onClick={() => window.print()}>چاپ</button>
                  <button className="btn ghost" style={{ padding: "0 10px" }} onClick={excel}>Excel</button>
                  <button className="btn ghost" style={{ padding: "0 10px" }} onClick={() => { setSel(null); setItems([]); }}>بستن</button>
                </div>
              </div>
              <p style={{ margin: "4px 0 8px", fontSize: 12.5 }}>
                شرح: {sel.Title || "—"} · حساب: <b className="ltr">{sel.MoeinCode || "—"}</b> {sel.MoeinTitle || ""} · صادرکننده: {sel.CreatedBy}
              </p>
              <div className="scrollbox">
                <table className="grid">
                  <thead><tr>
                    <th>#</th><th>تاریخ سند</th><th>سند</th>
                    <th>کد کل</th><th>کد معین</th><th>تفصیلی</th><th>شرح</th>
                    <th className="num">بدهکار</th><th className="num">بستانکار</th>
                  </tr></thead>
                  <tbody>
                    {items.map((x) => (
                      <tr key={x.NoteLineNo}>
                        <td>{x.NoteLineNo}</td>
                        <td className="num">{x.VchDate}</td>
                        <td className="num"><b>{fa(x.VchNo)}</b></td>
                        <td className="ltr"><b>{x.KolCode}</b> {x.KolTitle}</td>
                        <td className="ltr"><b>{x.MoeinCode}</b></td>
                        <td>{[x.Taf1Title && `(${x.Taf1Code}) ${x.Taf1Title}`, x.Taf2Title && `(${x.Taf2Code}) ${x.Taf2Title}`, x.Taf3Title && `(${x.Taf3Code}) ${x.Taf3Title}`].filter(Boolean).join(" / ") || "—"}</td>
                        <td>{x.Descr || "—"}</td>
                        <td className="num">{Number(x.Dbt) ? fa(x.Dbt) : ""}</td>
                        <td className="num">{Number(x.Crt) ? fa(x.Crt) : ""}</td>
                      </tr>
                    ))}
                    {!items.length && <tr><td colSpan={9} className="muted" style={{ textAlign: "center", padding: 14 }}>قلمی نیست</td></tr>}
                  </tbody>
                </table>
              </div>
              <div className="totalbar">
                <span>جمع: بد <b>{fa(items.reduce((s, x) => s + Number(x.Dbt || 0), 0))}</b> · بس <b>{fa(items.reduce((s, x) => s + Number(x.Crt || 0), 0))}</b> · اختلاف <b>{d(items.reduce((s, x) => s + Number(x.Dbt || 0), 0) - items.reduce((s, x) => s + Number(x.Crt || 0), 0))}</b></span>
              </div>
            </div>
          )}
        </div>
      </CtxGate>
    </Shell>
  );
}
