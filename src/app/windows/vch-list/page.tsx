"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import Shell from "@/components/Shell";
import { CtxGate, useApp, useSync } from "@/components/App";
import { api, fa, exportCsv, STATE_FA, STATE_CLS } from "@/lib/ui";
import { isValidJalali, todayJalali } from "@/lib/jalali";
import { VoucherDetailCard, fetchVoucher, VchDetail } from "@/components/VoucherDetail";
import { VoucherEditor } from "@/components/VoucherEditor";
import { useColResize, ColGrip } from "@/lib/colresize";

/* ============================================================================
   لیست اسناد (v2.2.0) — درخواست کارفرما: «در اسناد گزینه لیست اسناد وجود ندارد»
   [فرم اصلی: ليست اسناد] فهرست کامل اسناد با فیلتر: وضعیت، بازهٔ تاریخ جلالی،
   بازهٔ شماره سند، نوع سند، جست‌وجوی شرح — مشاهده و ویرایش هر سند
   v2.3.0 — صفحه‌بندی (۵۰ سند در صفحه) + تعداد و جمع بدهکارِ کل اسناد فیلترشده
   + ستون‌های قابل تغییر اندازه با موس (اندازه‌ها به‌خاطر سپرده می‌شود)
   v2.4.5 — درخواست کارفرما:
   • کلید «سند جدید» — صدور سند در همین پنجره (ویرایشگر مشترک)
   • با انتخاب سند، کلیدهای تغییر وضعیت طبق دسترسی کاربر فعال می‌شوند:
     «بررسی» (موقت→بررسی‌شده) · «موقت» (بررسی‌شده→موقت) · «یادداشت»
   • کلید «کپی سند» برای سند(های) انتخاب‌شده با گزینه‌های:
     کپی تکی / ترکیبی + جابه‌جایی بدهکار و بستانکار («بده و بس») + تاریخ سند
   ============================================================================ */

const PAGE_SIZE = 50;

export default function Page() {
  const app = useApp();
  const [rows, setRows] = useState<any[]>([]);
  const [types, setTypes] = useState<any[]>([]);
  const [state, setState] = useState("");
  const [dFrom, setDFrom] = useState(""); const [dTo, setDTo] = useState("");
  const [noFrom, setNoFrom] = useState(""); const [noTo, setNoTo] = useState("");
  const [typeId, setTypeId] = useState(""); const [qtext, setQ] = useState("");
  const [page, setPage] = useState(1);
  const [pages, setPages] = useState(1);
  const [total, setTotal] = useState(0);
  const [sumDbt, setSumDbt] = useState(0);
  const [msg, setMsg] = useState<{ t: "err" | "ok"; s: string } | null>(null);
  const [detail, setDetail] = useState<VchDetail | null>(null);
  const [editing, setEditing] = useState<number | null>(null);
  const [busy, setBusy] = useState(false);
  const can = app.can || ({} as any);
  const rs = useColResize({}, "acc-cols-list");

  /* v2.4.5 — انتخاب سندها + پنجره‌های کپی/یادداشت */
  const [sel, setSel] = useState<Set<number>>(new Set());
  const [copyOpen, setCopyOpen] = useState(false);
  const [copyMode, setCopyMode] = useState<"single" | "merged">("single");
  const [copySwap, setCopySwap] = useState(false);
  const [copyDate, setCopyDate] = useState(todayJalali());
  const [noteOpen, setNoteOpen] = useState(false);
  const [noteText, setNoteText] = useState("");

  useEffect(() => {
    if (app.ctxMissing) return;
    api("/api/vch/types").then((j) => setTypes(j.rows || [])).catch(() => {});
  }, [app.companyId, app.ctxMissing]); /* eslint-disable-line react-hooks/exhaustive-deps */

  const load = useCallback(async () => {
    if (app.ctxMissing) return;
    setBusy(true);
    try {
      const p = new URLSearchParams();
      if (state) p.set("state", state);
      if (dFrom) p.set("dFrom", dFrom); if (dTo) p.set("dTo", dTo);
      if (noFrom) p.set("from", noFrom); if (noTo) p.set("to", noTo);
      if (typeId) p.set("typeId", typeId);
      if (qtext) p.set("q", qtext);
      p.set("page", String(page)); p.set("pageSize", String(PAGE_SIZE));
      const j = await api(`/api/vch/list?${p}`);
      setRows(j.rows || []);
      setTotal(Number(j.total) || 0);
      setSumDbt(Number(j.sumDbt) || 0);
      setPages(Math.max(1, Number(j.pages) || 1));
    } catch (e: any) { setMsg({ t: "err", s: e.message }); }
    setBusy(false);
  }, [state, dFrom, dTo, noFrom, noTo, typeId, qtext, page, app.companyId, app.ctxMissing]);
  useSync(load);

  /* تغییر هر فیلتر = برگشت به صفحهٔ یک */
  const resetPage = () => setPage(1);

  const openDetail = async (id: number) => {
    try { setDetail(await fetchVoucher(id)); } catch (e: any) { setMsg({ t: "err", s: e.message }); }
  };

  const editable = (r: any) => r.State !== 3 && !r.ReversalOf && String(r.SourceModule || "ACC") === "ACC";

  const onEdited = async (v: any) => {
    setMsg({ t: "ok", s: v && v.VchNo ? `سند ${fa(v.VchNo)} با موفقیت ثبت شد` : "سند ثبت شد" });
    await load();
    if (detail && detail.hdr.VoucherId === v?.VoucherId) {
      try { setDetail(await fetchVoucher(v.VoucherId)); } catch { setDetail(null); }
    }
  };

  const excel = () => {
    if (!rows.length) return;
    exportCsv("لیست-اسناد.csv",
      ["عطف", "شماره سند", "ش فرعی", "تاریخ", "نوع سند", "شرح", "ردیف", "جمع بدهکار", "وضعیت", "مبدأ", "سازنده", "بررسی‌کننده", "قطعی‌کننده"],
      rows.map((r) => [r.FolioNo, r.VchNo, r.SubNo ?? 0, r.VchDate, r.TypeTitle || "", r.Descr || "",
        Number(r.ItemCount) || 0, Number(r.TotalDbt) || 0, STATE_FA[r.State] || "", r.SourceModule || "",
        r.CreatedBy || "", r.CheckedBy || "", r.FinalizedBy || ""]));
  };

  const grip = (key: string, w: number) => <ColGrip onDown={rs.onDown(key, rs.widths[key] ?? w)} />;

  /* ===================== v2.4.5 — انتخاب و عملیات دسته‌ای ===================== */
  const selRows = useMemo(() => rows.filter((r) => sel.has(Number(r.VoucherId))), [rows, sel]);
  const allPageSel = rows.length > 0 && rows.every((r) => sel.has(Number(r.VoucherId)));
  const somePageSel = selRows.length > 0 && !allPageSel;
  const allSelState1 = selRows.length > 0 && selRows.every((r) => Number(r.State) === 1);
  const allSelState2 = selRows.length > 0 && selRows.every((r) => Number(r.State) === 2);

  const toggleRow = (id: number) => setSel((s) => { const n = new Set(s); n.has(id) ? n.delete(id) : n.add(id); return n; });
  const toggleAll = () => setSel((s) => {
    const n = new Set(s);
    if (rows.every((r) => n.has(Number(r.VoucherId)))) rows.forEach((r) => n.delete(Number(r.VoucherId)));
    else rows.forEach((r) => n.add(Number(r.VoucherId)));
    return n;
  });

  /* اجرای دسته‌ای روی سندهای انتخاب‌شده — گزارش موفق/ناموفق با دلیل */
  const batch = async (ids: number[], run: (id: number) => Promise<void>, label: string) => {
    let ok = 0; const errs: string[] = [];
    for (const id of ids) {
      try { await run(id); ok++; } catch (e: any) { errs.push(e.message || String(e)); }
    }
    const failed = ids.length - ok;
    setMsg(failed === 0
      ? { t: "ok", s: `${label}: ${fa(ok)} سند با موفقیت انجام شد` }
      : { t: errs.length && ok === 0 ? "err" : "ok", s: `${label}: ${fa(ok)} موفق، ${fa(failed)} ناموفق${errs.length ? ` — ${errs[0]}${errs.length > 1 ? ` (+${fa(errs.length - 1)} مورد دیگر)` : ""}` : ""}` });
    if (ok > 0) setSel(new Set());
    await load();
  };

  const doTransition = (action: "review" | "unreview") => {
    if (!selRows.length || busy) return;
    batch(selRows.map((r) => Number(r.VoucherId)),
      async (id) => { await api("/api/vch/transition", { method: "POST", body: JSON.stringify({ id, action }) }); },
      action === "review" ? "بررسی" : "بازگشت به موقت");
  };

  const doNote = async () => {
    const note = noteText.trim();
    if (!note || !selRows.length || busy) return;
    setNoteOpen(false);
    await batch(selRows.map((r) => Number(r.VoucherId)),
      async (id) => { await api("/api/vch/transition", { method: "POST", body: JSON.stringify({ id, action: "note", note }) }); },
      "یادداشت");
    setNoteText("");
  };

  const doCopy = async () => {
    if (!selRows.length || busy) return;
    if (!isValidJalali(copyDate)) { setMsg({ t: "err", s: "تاریخ سند جدید نامعتبر است — قالب جلالی: 1405/01/01" }); return; }
    setBusy(true); setMsg(null);
    try {
      const j = await api("/api/vch/copy", { method: "POST", body: JSON.stringify({
        ids: selRows.map((r) => Number(r.VoucherId)), mode: copyMode, swap: copySwap, vchDate: copyDate,
      }) });
      const nos = (j.vouchers || []).map((v: any) => fa(v.VchNo)).join("، ");
      setMsg({ t: "ok", s: `کپی انجام شد — سند جدید: ${nos}${copySwap ? " (با جابه‌جایی بدهکار/بستانکار)" : ""}` });
      setCopyOpen(false); setSel(new Set());
      await load();
    } catch (e: any) { setMsg({ t: "err", s: e.message }); }
    setBusy(false);
  };

  return (
    <Shell title="لیست اسناد" sub="فهرست کامل اسناد با فیلتر تاریخ/شماره/نوع — صدور، انتخاب، تغییر وضعیت و کپی">
      <CtxGate>
        {msg && <div className={`msg ${msg.t}`}>{msg.s}</div>}

        {/* v2.4.5 — نوار کلیدها: سند جدید + کلیدهای وضعیت با انتخاب سند (طبق دسترسی) */}
        <div className="btnrow" style={{ margin: "0 0 10px", flexWrap: "wrap" }}>
          {can.issue && (
            <button className="btn primary" onClick={() => setEditing(0)}>سند جدید</button>
          )}
          {can.review && (
            <button className="btn" disabled={!allSelState1 || busy} title="بررسی‌شده کردن سندهای موقتِ انتخاب‌شده"
              onClick={() => doTransition("review")}>بررسی</button>
          )}
          {can.review && (
            <button className="btn" disabled={!allSelState2 || busy} title="بازگرداندن سندهای بررسی‌شده به وضعیت موقت"
              onClick={() => doTransition("unreview")}>موقت</button>
          )}
          {can.master && (
            <button className="btn" disabled={!selRows.length || busy} title="ثبت یادداشت روی سندهای انتخاب‌شده"
              onClick={() => setNoteOpen(true)}>یادداشت</button>
          )}
          {can.issue && (
            <button className="btn" disabled={!selRows.length || busy} title="کپی سند(های) انتخاب‌شده — تکی/ترکیبی، جابه‌جایی بدهکار/بستانکار، تاریخ سند"
              onClick={() => setCopyOpen(true)}>کپی سند…</button>
          )}
          {selRows.length > 0 && (
            <span className="badge src" style={{ padding: "3px 10px" }}>
              {fa(selRows.length)} سند انتخاب شده
              <button className="btn ghost" onClick={() => setSel(new Set())} style={{ padding: "0 6px", marginInlineStart: 6 }}>لغو انتخاب</button>
            </span>
          )}
        </div>

        <div className="card">
          <div className="card-title">فیلترها</div>
          <div className="form-grid" style={{ gridTemplateColumns: "repeat(auto-fit, minmax(130px, 1fr))" }}>
            <div className="field"><label>وضعیت</label>
              <select value={state} onChange={(e) => { setState(e.target.value); resetPage(); }}>
                <option value="">همه</option>
                <option value="1">موقت</option>
                <option value="2">بررسی‌شده</option>
                <option value="3">قطعی</option>
              </select>
            </div>
            <div className="field"><label>از تاریخ</label>
              <input value={dFrom} onChange={(e) => { setDFrom(e.target.value); resetPage(); }} placeholder="1405/01/01" style={{ direction: "ltr", textAlign: "left" }} />
            </div>
            <div className="field"><label>تا تاریخ</label>
              <input value={dTo} onChange={(e) => { setDTo(e.target.value); resetPage(); }} placeholder="1405/12/29" style={{ direction: "ltr", textAlign: "left" }} />
            </div>
            <div className="field"><label>از سند</label>
              <input value={noFrom} onChange={(e) => { setNoFrom(e.target.value.replace(/\D/g, "")); resetPage(); }} style={{ direction: "ltr", textAlign: "left" }} />
            </div>
            <div className="field"><label>تا سند</label>
              <input value={noTo} onChange={(e) => { setNoTo(e.target.value.replace(/\D/g, "")); resetPage(); }} style={{ direction: "ltr", textAlign: "left" }} />
            </div>
            <div className="field"><label>نوع سند</label>
              <select value={typeId} onChange={(e) => { setTypeId(e.target.value); resetPage(); }}>
                <option value="">همه</option>
                {types.map((t: any) => <option key={t.VoucherTypeId} value={t.VoucherTypeId}>{t.Title}</option>)}
              </select>
            </div>
            <div className="field" style={{ gridColumn: "span 2" }}><label>جست‌وجو (شرح / شماره)</label>
              <input value={qtext} onChange={(e) => setQ(e.target.value)}
                onKeyDown={(e) => { if (e.key === "Enter") { resetPage(); load(); } }} />
            </div>
            <div className="field"><label>&nbsp;</label>
              <div className="btnrow" style={{ margin: 0 }}>
                <button className="btn primary" onClick={() => { resetPage(); load(); }} disabled={busy}>نمایش</button>
                <button className="btn" onClick={excel} disabled={!rows.length}>Excel</button>
              </div>
            </div>
          </div>
        </div>

        <div className="scrollbox">
          <table className="grid">
            <thead><tr>
              <th style={{ width: 38, minWidth: 38 }}>
                <input type="checkbox" checked={allPageSel} ref={(el) => { if (el) el.indeterminate = somePageSel; }}
                  onChange={toggleAll} title="انتخاب/لغو انتخاب همهٔ سندهای این صفحه" />
              </th>
              <th style={rs.thStyle("folio", 90)}>{grip("folio", 90)}عطف</th>
              <th style={rs.thStyle("no", 100)}>{grip("no", 100)}شماره سند</th>
              <th style={rs.thStyle("date", 100)}>{grip("date", 100)}تاریخ</th>
              <th style={rs.thStyle("type", 130)}>{grip("type", 130)}نوع</th>
              <th style={rs.thStyle("descr", 180)}>{grip("descr", 180)}شرح</th>
              <th style={rs.thStyle("items", 70)} className="num">{grip("items", 70)}ردیف</th>
              <th style={rs.thStyle("dbt", 120)} className="num">{grip("dbt", 120)}جمع بدهکار</th>
              <th style={rs.thStyle("state", 100)}>{grip("state", 100)}وضعیت</th>
              <th style={rs.thStyle("users", 170)}>{grip("users", 170)}سازنده / بررسی‌کننده / قطعی‌کننده</th>
              <th style={rs.thStyle("ops", 170)}>{grip("ops", 170)}عملیات</th>
            </tr></thead>
            <tbody>
              {rows.map((r) => (
                <tr key={r.VoucherId} onDoubleClick={() => openDetail(r.VoucherId)} style={{ cursor: "pointer" }}
                  title="دوبار کلیک = مشاهدهٔ سند">
                  <td onClick={(e) => e.stopPropagation()} onDoubleClick={(e) => e.stopPropagation()}>
                    <input type="checkbox" checked={sel.has(Number(r.VoucherId))} onChange={() => toggleRow(Number(r.VoucherId))} />
                  </td>
                  <td className="num">{fa(r.FolioNo)}</td>
                  <td className="num"><b>{fa(r.VchNo)}</b>{Number(r.SubNo) ? `-${fa(r.SubNo)}` : ""}{r.ReversalOf ? <span className="badge src" style={{ marginInlineStart: 4 }}>برگشتی</span> : null}</td>
                  <td className="num">{r.VchDate}</td>
                  <td>{r.TypeTitle}</td>
                  <td>{r.Descr || "—"}</td>
                  <td className="num">{fa(r.ItemCount)}</td>
                  <td className="num">{fa(r.TotalDbt)}</td>
                  <td><span className={`badge ${STATE_CLS[r.State]}`}>{STATE_FA[r.State]}</span></td>
                  <td>{r.CreatedBy || "—"} / {r.CheckedBy || "—"} / {r.FinalizedBy || "—"}</td>
                  <td>
                    <button className="btn" onClick={() => openDetail(r.VoucherId)} style={{ padding: "1px 8px" }}>مشاهده</button>{" "}
                    {editable(r) && can.issue && (
                      <button className="btn" onClick={() => { setDetail(null); setEditing(r.VoucherId); }} style={{ padding: "1px 8px" }}>ویرایش</button>
                    )}
                  </td>
                </tr>
              ))}
              {!rows.length && <tr><td colSpan={11} className="muted" style={{ textAlign: "center", padding: 18 }}>سندی با این فیلترها نیست</td></tr>}
            </tbody>
          </table>
        </div>

        {pages > 1 && (
          <div className="btnrow" style={{ justifyContent: "center", margin: "10px 0 0" }}>
            <button className="btn" disabled={page <= 1 || busy} onClick={() => setPage(1)}>ابتدا</button>
            <button className="btn" disabled={page <= 1 || busy} onClick={() => setPage(page - 1)}>قبلی</button>
            <span style={{ padding: "0 8px" }}>صفحهٔ <b>{fa(page)}</b> از <b>{fa(pages)}</b></span>
            <button className="btn" disabled={page >= pages || busy} onClick={() => setPage(page + 1)}>بعدی</button>
            <button className="btn" disabled={page >= pages || busy} onClick={() => setPage(pages)}>انتها</button>
          </div>
        )}

        <div className="totalbar">
          <span>تعداد کل اسناد: <b>{fa(total)}</b></span>
          <span>جمع بدهکار همهٔ اسناد: <b>{fa(sumDbt)}</b></span>
          <span>این صفحه: <b>{fa(rows.length)}</b> سند</span>
        </div>

        {detail && (
          <div style={{ position: "fixed", inset: 0, background: "rgba(15,35,55,.45)", zIndex: 50, display: "flex", alignItems: "center", justifyContent: "center", padding: 20 }}
            onClick={() => setDetail(null)}>
            <div style={{ background: "#fff", borderRadius: 10, maxHeight: "88vh", overflow: "auto", padding: 14, minWidth: 720 }} onClick={(e) => e.stopPropagation()}>
              <VoucherDetailCard d={detail} canEdit={!!can.issue}
                onClose={() => setDetail(null)}
                onEdit={() => { const id = detail.hdr.VoucherId; setDetail(null); setEditing(id); }} />
            </div>
          </div>
        )}

        {editing !== null && (
          <VoucherEditor id={editing} onClose={() => setEditing(null)} onSaved={onEdited} />
        )}

        {/* v2.4.5 — پنجرهٔ کپی سند: تکی/ترکیبی + جابه‌جایی بده و بس + تاریخ سند */}
        {copyOpen && (
          <div style={{ position: "fixed", inset: 0, background: "rgba(15,35,55,.5)", zIndex: 70, display: "flex", alignItems: "center", justifyContent: "center", padding: 18 }}
            onClick={() => !busy && setCopyOpen(false)}>
            <div className="window" style={{ width: "min(560px, 96vw)" }} onClick={(e) => e.stopPropagation()}>
              <div className="window-title">
                <span>کپی سند — {fa(selRows.length)} سند انتخاب شده</span>
                <button className="btn" onClick={() => setCopyOpen(false)} style={{ padding: "1px 10px" }}>بستن</button>
              </div>
              <div className="window-body">
                <div className="card">
                  <div className="card-title">روش کپی</div>
                  <div style={{ display: "grid", gap: 8 }}>
                    <label style={{ display: "flex", gap: 8, alignItems: "flex-start", cursor: "pointer" }}>
                      <input type="radio" checked={copyMode === "single"} onChange={() => setCopyMode("single")} style={{ marginTop: 4 }} />
                      <span><b>کپی تکی</b> — از هر سند انتخاب‌شده یک سند جدید مستقل ساخته می‌شود (شرح، نوع، شعبه و ش فرعی همان سند حفظ می‌شود)</span>
                    </label>
                    <label style={{ display: "flex", gap: 8, alignItems: "flex-start", cursor: "pointer" }}>
                      <input type="radio" checked={copyMode === "merged"} onChange={() => setCopyMode("merged")} style={{ marginTop: 4 }} />
                      <span><b>ترکیبی</b> — ردیف‌های همهٔ سندهای انتخاب‌شده در «یک» سند جدید ادغام می‌شوند</span>
                    </label>
                    <label style={{ display: "flex", gap: 8, alignItems: "center", cursor: "pointer", borderTop: "1px dashed var(--border)", paddingTop: 8 }}>
                      <input type="checkbox" checked={copySwap} onChange={(e) => setCopySwap(e.target.checked)} />
                      <span><b>جابه‌جایی بدهکار و بستانکار</b> («بده و بس») — در ردیف‌های سند(های) کپی‌شده</span>
                    </label>
                  </div>
                </div>
                <div className="field" style={{ marginTop: 10 }}>
                  <label>تاریخ سند جدید (جلالی)</label>
                  <input value={copyDate} onChange={(e) => setCopyDate(e.target.value)} placeholder="1405/01/01"
                    style={{ direction: "ltr", textAlign: "left", width: "50%", borderColor: copyDate && !isValidJalali(copyDate) ? "var(--accent)" : undefined }} />
                  {copyDate && !isValidJalali(copyDate) && <span style={{ color: "var(--accent)", fontSize: 11 }}>قالب جلالی نیست</span>}
                </div>
                <p className="muted" style={{ fontSize: 12 }}>سند(های) جدید همیشه با وضعیت «موقت» صادر می‌شوند — شمارهٔ سند و عطف خودکار گرفته می‌شود.</p>
                <div className="btnrow">
                  <button className="btn primary" disabled={busy || !copyDate || !isValidJalali(copyDate)} onClick={doCopy}>
                    {busy ? "در حال کپی…" : "انجام کپی"}
                  </button>
                  <button className="btn" onClick={() => setCopyOpen(false)} disabled={busy}>انصراف</button>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* v2.4.5 — پنجرهٔ یادداشت سند */}
        {noteOpen && (
          <div style={{ position: "fixed", inset: 0, background: "rgba(15,35,55,.5)", zIndex: 70, display: "flex", alignItems: "center", justifyContent: "center", padding: 18 }}
            onClick={() => !busy && setNoteOpen(false)}>
            <div className="window" style={{ width: "min(520px, 96vw)" }} onClick={(e) => e.stopPropagation()}>
              <div className="window-title">
                <span>یادداشت سند — {fa(selRows.length)} سند انتخاب شده</span>
                <button className="btn" onClick={() => setNoteOpen(false)} style={{ padding: "1px 10px" }}>بستن</button>
              </div>
              <div className="window-body">
                <div className="field">
                  <label>متن یادداشت (در ردپای عملیات هر سند ثبت می‌شود)</label>
                  <textarea value={noteText} onChange={(e) => setNoteText(e.target.value)} rows={4}
                    placeholder="مثلاً: در انتظار دریافت فاکتور رسمی" style={{ width: "100%", resize: "vertical" }} />
                </div>
                <div className="btnrow">
                  <button className="btn primary" disabled={busy || !noteText.trim()} onClick={doNote}>ثبت یادداشت</button>
                  <button className="btn" onClick={() => setNoteOpen(false)}>انصراف</button>
                </div>
              </div>
            </div>
          </div>
        )}
      </CtxGate>
    </Shell>
  );
}
