"use client";

import { useCallback, useEffect, useState } from "react";
import Shell from "@/components/Shell";
import { api, fa, STATE_FA, STATE_CLS } from "@/lib/ui";

/* [فرم اصلی: بررسي اسناد — فقط اسناد موقت/بررسی‌شده، بررسی شد / لغو بررسی] */
export default function Page() {
  const [rows, setRows] = useState<any[]>([]);
  const [state, setState] = useState("1");
  const [from, setFrom] = useState(""); const [to, setTo] = useState(""); const [qtext, setQ] = useState("");
  const [msg, setMsg] = useState<{ t: "err" | "ok"; s: string } | null>(null);
  const [detail, setDetail] = useState<any | null>(null);
  const [can, setCan] = useState<any>({});

  const load = useCallback(async () => {
    try {
      const p = new URLSearchParams(); if (state) p.set("state", state); if (from) p.set("from", from); if (to) p.set("to", to); if (qtext) p.set("q", qtext);
      const j = await api(`/api/vch/list?${p}`);
      setRows(j.rows || []);
    } catch (e: any) { setMsg({ t: "err", s: e.message }); }
  }, [state, from, to, qtext]);
  useEffect(() => { load(); }, [load]);
  useEffect(() => { api("/api/auth/login").then((j) => setCan(j.can || {})).catch(() => {}); }, []);

  const doAct = async (id: number, action: string) => {
    setMsg(null);
    try {
      await api("/api/vch/transition", { method: "POST", body: JSON.stringify({ id, action }) });
      setMsg({ t: "ok", s: action === "review" ? "سند بررسی شد" : "لغو بررسی انجام شد" });
      setDetail(null); await load();
    } catch (e: any) { setMsg({ t: "err", s: e.message }); }
  };

  const openDetail = async (id: number) => {
    try { setDetail(await api(`/api/vch/get?id=${id}`)); } catch (e: any) { setMsg({ t: "err", s: e.message }); }
  };

  return (
    <Shell title="بررسی اسناد" sub="بررسی سند موقت → بررسی‌شده (بررسی‌کننده باید غیر از سازنده باشد)">
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
              <tr key={r.HdrId}>
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
                  <button className="btn" onClick={() => openDetail(r.HdrId)} style={{ padding: "1px 8px" }}>مشاهده</button>{" "}
                  {r.State === 1 && can.review && <button className="btn green" onClick={() => doAct(r.HdrId, "review")} style={{ padding: "1px 8px" }}>بررسی شد</button>}
                  {r.State === 2 && can.review && <button className="btn" onClick={() => doAct(r.HdrId, "unreview")} style={{ padding: "1px 8px" }}>لغو بررسی</button>}
                </td>
              </tr>
            ))}
            {!rows.length && <tr><td colSpan={11} className="muted" style={{ textAlign: "center", padding: 18 }}>سندی نیست</td></tr>}
          </tbody>
        </table>
      </div>

      {detail && (
        <div className="window" style={{ marginTop: 12 }}>
          <div className="window-title"><span>سند {fa(detail.hdr.VchNo)} — {detail.hdr.TypeTitle}</span>
            <button className="btn" onClick={() => setDetail(null)} style={{ padding: "1px 10px" }}>بستن</button></div>
          <div className="window-body">
            <p style={{ marginBottom: 8 }}>
              تاریخ: {detail.hdr.VchDate} · شرح: {detail.hdr.Descr || "—"} · وضعیت: <b>{STATE_FA[detail.hdr.State]}</b>
              {" "}· سازنده: {detail.hdr.CreatedBy} · بررسی: {detail.hdr.CheckedBy || "—"} · قطعی: {detail.hdr.FinalizedBy || "—"}
            </p>
            <table className="grid">
              <thead><tr><th>#</th><th>کل</th><th>معین</th><th>تفصیلی ۴</th><th>تفصیلی ۵</th><th>تفصیلی ۶</th><th>شرح</th><th className="num">بدهکار</th><th className="num">بستانکار</th></tr></thead>
              <tbody>
                {detail.items.map((it: any) => (
                  <tr key={it.ItmId}>
                    <td>{it.RowNo}</td>
                    <td>{it.KolCode} — {it.KolTitle}</td>
                    <td>{it.MoeinCode} — {it.MoeinTitle}</td>
                    <td>{it.Dl1Title || "—"}</td><td>{it.Dl2Title || "—"}</td><td>{it.Dl3Title || "—"}</td>
                    <td>{it.Descr || "—"}</td>
                    <td className="num">{fa(it.Dbt)}</td><td className="num">{fa(it.Crt)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
            <p className="muted" style={{ marginTop: 8 }}>ردپای عملیات: {detail.log.map((l: any) => `${["", "صدور", "بررسی", "لغو بررسی", "قطعی", "لغو قطعی", "برگشت"][l.Action]} (${l.ByUser} — ${l.AtFa})`).join(" ← ")}</p>
          </div>
        </div>
      )}
    </Shell>
  );
}
