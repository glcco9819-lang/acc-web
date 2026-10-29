"use client";

import { useCallback, useEffect, useState } from "react";
import Shell from "@/components/Shell";
import { CtxGate, useApp, useSync } from "@/components/App";
import { api, fa, exportCsv, STATE_FA, STATE_CLS } from "@/lib/ui";
import { VoucherDetailCard, fetchVoucher, VchDetail } from "@/components/VoucherDetail";
import { VoucherEditor } from "@/components/VoucherEditor";
import { useColResize, ColGrip } from "@/lib/colresize";

/* ============================================================================
   لیست اسناد (v2.2.0) — درخواست کارفرما: «در اسناد گزینه لیست اسناد وجود ندارد»
   [فرم اصلی: ليست اسناد] فهرست کامل اسناد با فیلتر: وضعیت، بازهٔ تاریخ جلالی،
   بازهٔ شماره سند، نوع سند، جست‌وجوی شرح — مشاهده و ویرایش هر سند
   v2.3.0 — صفحه‌بندی (۵۰ سند در صفحه) + تعداد و جمع بدهکارِ کل اسناد فیلترشده
   + ستون‌های قابل تغییر اندازه با موس (اندازه‌ها به‌خاطر سپرده می‌شود)
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
    setMsg({ t: "ok", s: `سند ${fa(v.VchNo)} ویرایش شد` });
    await load();
    if (detail && detail.hdr.VoucherId === v.VoucherId) {
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

  return (
    <Shell title="لیست اسناد" sub="فهرست کامل اسناد با فیلتر تاریخ/شماره/نوع — مشاهده و ویرایش هر سند">
      <CtxGate>
        {msg && <div className={`msg ${msg.t}`}>{msg.s}</div>}

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
              {!rows.length && <tr><td colSpan={10} className="muted" style={{ textAlign: "center", padding: 18 }}>سندی با این فیلترها نیست</td></tr>}
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
      </CtxGate>
    </Shell>
  );
}
