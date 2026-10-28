"use client";

import { useCallback, useEffect, useState } from "react";
import Shell from "@/components/Shell";
import { CtxGate, useApp } from "@/components/App";
import { api, fa, STATE_FA, STATE_CLS } from "@/lib/ui";
import { VoucherDetailCard, fetchVoucher, VchDetail } from "@/components/VoucherDetail";

/* بررسی اسناد (v2.0.0) [فرم اصلی: بررسي اسناد — TAccCtlVchForm]
   فقط اسناد موقت / فقط اسناد بررسی‌شده + بررسی شد / لغو بررسی + ریز سند با کدها */
export default function Page() {
  const app = useApp();
  const [rows, setRows] = useState<any[]>([]);
  const [state, setState] = useState("1");
  const [from, setFrom] = useState(""); const [to, setTo] = useState(""); const [qtext, setQ] = useState("");
  const [msg, setMsg] = useState<{ t: "err" | "ok"; s: string } | null>(null);
  const [detail, setDetail] = useState<VchDetail | null>(null);
  const can = app.can || ({} as any);

  const load = useCallback(async () => {
    if (app.ctxMissing) return;
    try {
      const p = new URLSearchParams();
      if (state) p.set("state", state); if (from) p.set("from", from);
      if (to) p.set("to", to); if (qtext) p.set("q", qtext);
      const j = await api(`/api/vch/list?${p}`);
      setRows(j.rows || []);
    } catch (e: any) { setMsg({ t: "err", s: e.message }); }
  }, [state, from, to, qtext, app.companyId, app.ctxMissing]);
  useEffect(() => { load(); }, [load]);

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
            <select value={state} onChange={(e) => setState(e.target.value)}>
              <option value="">همه</option>
              <option value="1">فقط موقت</option>
              <option value="2">فقط بررسی‌شده</option>
              <option value="3">قطعی</option>
            </select>
          </div>
          <div className="field"><label>از سند</label><input value={from} onChange={(e) => setFrom(e.target.value)} className="num" style={{ direction: "ltr" }} /></div>
          <div className="field"><label>تا سند</label><input value={to} onChange={(e) => setTo(e.target.value)} className="num" style={{ direction: "ltr" }} /></div>
          <div className="field"><label>جست‌وجو</label><input value={qtext} onChange={(e) => setQ(e.target.value)} /></div>
        </div>
        <div className="scrollbox">
          <table className="grid">
            <thead><tr>
              <th>عطف</th><th>شماره سند</th><th>تاریخ</th><th>نوع</th><th>شرح</th>
              <th className="num">ردیف</th><th className="num">جمع</th><th>مبدأ</th><th>وضعیت</th>
              <th>سازنده / بررسی‌کننده</th><th style={{ width: 210 }}>عملیات</th>
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
                    {r.State === 1 && can.review && <button className="btn green" onClick={() => doAct(r.VoucherId, "review")} style={{ padding: "1px 8px" }}>بررسی شد</button>}
                    {r.State === 2 && can.review && <button className="btn" onClick={() => doAct(r.VoucherId, "unreview")} style={{ padding: "1px 8px" }}>لغو بررسی</button>}
                  </td>
                </tr>
              ))}
              {!rows.length && <tr><td colSpan={11} className="muted" style={{ textAlign: "center", padding: 18 }}>سندی نیست</td></tr>}
            </tbody>
          </table>
        </div>

        {detail && <VoucherDetailCard d={detail} onClose={() => setDetail(null)} />}
      </CtxGate>
    </Shell>
  );
}
