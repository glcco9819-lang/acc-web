"use client";

import { useCallback, useState } from "react";
import Shell from "@/components/Shell";
import { CtxGate, useApp, useSync } from "@/components/App";
import { api, fa, STATE_FA, STATE_CLS } from "@/lib/ui";
import { VoucherDetailCard, fetchVoucher, VchDetail } from "@/components/VoucherDetail";
import { VoucherEditor } from "@/components/VoucherEditor";
import { useColResize, ColGrip } from "@/lib/colresize";

/* بررسی اسناد (v2.0.0) [فرم اصلی: بررسي اسناد — TAccCtlVchForm]
   فقط اسناد موقت / فقط اسناد بررسی‌شده + بررسی شد / لغو بررسی + ریز سند با کدها
   v2.3.0 — صفحه‌بندی + ستون‌های قابل تغییر اندازه */
export default function Page() {
  const app = useApp();
  const [rows, setRows] = useState<any[]>([]);
  const [state, setState] = useState("1");
  const [from, setFrom] = useState(""); const [to, setTo] = useState(""); const [qtext, setQ] = useState("");
  const [msg, setMsg] = useState<{ t: "err" | "ok"; s: string } | null>(null);
  const [detail, setDetail] = useState<VchDetail | null>(null);
  const [editing, setEditing] = useState<number | null>(null);
  const [page, setPage] = useState(1);
  const [pages, setPages] = useState(1);
  const [total, setTotal] = useState(0);
  const can = app.can || ({} as any);
  const rs = useColResize({}, "acc-cols-vchreview");

  /* ویرایش سند در همین پنجره (v2.2.0) — پس از ذخیره، فهرست به‌روز می‌شود */
  const onEdited = async (v: any) => {
    setEditing(null);
    setMsg({ t: "ok", s: `سند ${fa(v.VchNo)} ویرایش شد` });
    await load();
  };

  const load = useCallback(async () => {
    if (app.ctxMissing) return;
    try {
      const p = new URLSearchParams();
      if (state) p.set("state", state); if (from) p.set("from", from);
      if (to) p.set("to", to); if (qtext) p.set("q", qtext);
      p.set("page", String(page)); p.set("pageSize", "50");
      const j = await api(`/api/vch/list?${p}`);
      setRows(j.rows || []);
      setPages(Math.max(1, Number(j.pages) || 1));
      setTotal(Number(j.total) || 0);
    } catch (e: any) { setMsg({ t: "err", s: e.message }); }
  }, [state, from, to, qtext, page, app.companyId, app.ctxMissing]);
  useSync(load);

  const doAct = async (id: number, action: string) => {
    setMsg(null);
    try {
      await api("/api/vch/transition", { method: "POST", body: JSON.stringify({ id, action, companyId: app.companyId }) });
      setMsg({ t: "ok", s: action === "review" ? "سند بررسی شد" : "لغو بررسی انجام شد" });
      setDetail(null); await load();
    } catch (e: any) { setMsg({ t: "err", s: e.message }); }
  };

  const openDetail = async (id: number) => {
    try { setDetail(await fetchVoucher(id)); } catch (e: any) { setMsg({ t: "err", s: e.message }); }
  };

  return (
    <Shell title="بررسی اسناد" sub="بررسی سند موقت → بررسی‌شده (بررسی‌کننده باید غیر از سازنده باشد)">
      <CtxGate>
        {msg && <div className={`msg ${msg.t}`}>{msg.s}</div>}
        <div className="form-grid" style={{ gridTemplateColumns: "150px 110px 110px 1fr" }}>
          <div className="field"><label>وضعیت</label>
            <select value={state} onChange={(e) => { setState(e.target.value); setPage(1); }}>
              <option value="">همه</option>
              <option value="1">فقط موقت</option>
              <option value="2">فقط بررسی‌شده</option>
              <option value="3">قطعی</option>
            </select>
          </div>
          <div className="field"><label>از سند</label><input value={from} onChange={(e) => { setFrom(e.target.value); setPage(1); }} className="num" style={{ direction: "ltr" }} /></div>
          <div className="field"><label>تا سند</label><input value={to} onChange={(e) => { setTo(e.target.value); setPage(1); }} className="num" style={{ direction: "ltr" }} /></div>
          <div className="field"><label>جست‌وجو</label><input value={qtext} onChange={(e) => setQ(e.target.value)} onKeyDown={(e) => { if (e.key === "Enter") setPage(1); }} /></div>
        </div>
        <div className="scrollbox">
          <table className="grid">
            <thead><tr>
              <th style={rs.thStyle("folio", 90)}><ColGrip onDown={rs.onDown("folio", rs.widths.folio ?? 90)} />عطف</th>
              <th style={rs.thStyle("no", 100)}><ColGrip onDown={rs.onDown("no", rs.widths.no ?? 100)} />شماره سند</th>
              <th style={rs.thStyle("date", 100)}><ColGrip onDown={rs.onDown("date", rs.widths.date ?? 100)} />تاریخ</th>
              <th style={rs.thStyle("type", 120)}><ColGrip onDown={rs.onDown("type", rs.widths.type ?? 120)} />نوع</th>
              <th style={rs.thStyle("descr", 160)}><ColGrip onDown={rs.onDown("descr", rs.widths.descr ?? 160)} />شرح</th>
              <th style={rs.thStyle("items", 60)} className="num"><ColGrip onDown={rs.onDown("items", rs.widths.items ?? 60)} />ردیف</th>
              <th style={rs.thStyle("dbt", 110)} className="num"><ColGrip onDown={rs.onDown("dbt", rs.widths.dbt ?? 110)} />جمع</th>
              <th style={rs.thStyle("src", 90)}><ColGrip onDown={rs.onDown("src", rs.widths.src ?? 90)} />مبدأ</th>
              <th style={rs.thStyle("state", 100)}><ColGrip onDown={rs.onDown("state", rs.widths.state ?? 100)} />وضعیت</th>
              <th style={rs.thStyle("users", 140)}><ColGrip onDown={rs.onDown("users", rs.widths.users ?? 140)} />سازنده / بررسی‌کننده</th>
              <th style={rs.thStyle("ops", 210)}><ColGrip onDown={rs.onDown("ops", rs.widths.ops ?? 210)} />عملیات</th>
            </tr></thead>
            <tbody>
              {rows.map((r) => (
                <tr key={r.VoucherId}>
                  <td className="num">{fa(r.FolioNo)}</td>
                  <td className="num"><b>{fa(r.VchNo)}</b>{r.ReversalOf ? <span className="badge src" style={{ marginInlineStart: 4 }}>برگشتی</span> : null}</td>
                  <td className="num">{r.VchDate}</td>
                  <td>{r.TypeTitle}</td>
                  <td>{r.Descr}</td>
                  <td className="num">{fa(r.ItemCount)}</td>
                  <td className="num">{fa(r.TotalDbt)}</td>
                  <td>{r.SourceModule === "ACC" ? <span className="badge s2">حسابداری</span> : <span className="badge src">{r.SourceModule}</span>}</td>
                  <td><span className={`badge ${STATE_CLS[r.State]}`}>{STATE_FA[r.State]}</span></td>
                  <td>{r.CreatedBy} / {r.CheckedBy || "—"}</td>
                  <td>
                    <button className="btn" onClick={() => openDetail(r.VoucherId)} style={{ padding: "1px 8px" }}>مشاهده</button>{" "}
                    {r.State !== 3 && !r.ReversalOf && String(r.SourceModule || "ACC") === "ACC" && can.issue && (
                      <button className="btn" onClick={() => { setDetail(null); setEditing(r.VoucherId); }} style={{ padding: "1px 8px" }}
                        title="ویرایش سند در همین پنجره">ویرایش</button>
                    )}{" "}
                    {r.State === 1 && can.review && <button className="btn green" onClick={() => doAct(r.VoucherId, "review")} style={{ padding: "1px 8px" }}>بررسی شد</button>}
                    {r.State === 2 && can.review && <button className="btn" onClick={() => doAct(r.VoucherId, "unreview")} style={{ padding: "1px 8px" }}>لغو بررسی</button>}
                  </td>
                </tr>
              ))}
              {!rows.length && <tr><td colSpan={11} className="muted" style={{ textAlign: "center", padding: 18 }}>سندی نیست</td></tr>}
            </tbody>
          </table>
        </div>

        {pages > 1 && (
          <div className="btnrow" style={{ justifyContent: "center", margin: "10px 0 0" }}>
            <button className="btn" disabled={page <= 1} onClick={() => setPage(1)}>ابتدا</button>
            <button className="btn" disabled={page <= 1} onClick={() => setPage(page - 1)}>قبلی</button>
            <span style={{ padding: "0 8px" }}>صفحهٔ <b>{fa(page)}</b> از <b>{fa(pages)}</b> — مجموع <b>{fa(total)}</b> سند</span>
            <button className="btn" disabled={page >= pages} onClick={() => setPage(page + 1)}>بعدی</button>
            <button className="btn" disabled={page >= pages} onClick={() => setPage(pages)}>انتها</button>
          </div>
        )}

        {detail && <VoucherDetailCard d={detail} canEdit={!!can.issue} onClose={() => setDetail(null)}
          onEdit={() => { const id = detail.hdr.VoucherId; setDetail(null); setEditing(id); }} />}

        {editing !== null && (
          <VoucherEditor id={editing} onClose={() => setEditing(null)} onSaved={onEdited} />
        )}
      </CtxGate>
    </Shell>
  );
}
