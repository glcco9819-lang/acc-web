"use client";

import { useCallback, useEffect, useState } from "react";
import Shell from "@/components/Shell";
import { CtxGate, useApp } from "@/components/App";
import { api, fa } from "@/lib/ui";
import { VoucherDetailCard, fetchVoucher, VchDetail } from "@/components/VoucherDetail";

/* برگشت اسناد قطعی (v2.0.0) — ردیف‌ها معکوس + اسلات‌های تفصیلی حفظ می‌شوند */
export default function Page() {
  const app = useApp();
  const [rows, setRows] = useState<any[]>([]);
  const [msg, setMsg] = useState<{ t: "err" | "ok"; s: string } | null>(null);
  const [detail, setDetail] = useState<VchDetail | null>(null);
  const can = app.can || ({} as any);

  const load = useCallback(async () => {
    if (app.ctxMissing) return;
    try { const j = await api(`/api/vch/list?state=3&companyId=${app.companyId}`); setRows(j.rows || []); }
    catch (e: any) { setMsg({ t: "err", s: e.message }); }
  }, [app.companyId, app.ctxMissing]);
  useEffect(() => { load(); }, [load]);

  const reverse = async (id: number) => {
    setMsg(null);
    try {
      const j = await api("/api/vch/reverse", { method: "POST", body: JSON.stringify({ id, companyId: app.companyId }) });
      setMsg({ t: "ok", s: `سند برگشتی شماره ${fa(j.reversal.VchNo)} به‌صورت «موقت» صادر شد — باید مثل سند عادی بررسی و قطعی شود` });
      await load();
    } catch (e: any) { setMsg({ t: "err", s: e.message }); }
  };

  const openDetail = async (id: number) => {
    try { setDetail(await fetchVoucher(id)); } catch (e: any) { setMsg({ t: "err", s: e.message }); }
  };

  return (
    <Shell title="برگشت اسناد قطعی" sub="سند قطعی اصلاح‌ناپذیر است — اصلاح فقط با صدور سند برگشتی">
      <CtxGate>
        {msg && <div className={`msg ${msg.t}`}>{msg.s}</div>}
        <div className="scrollbox">
          <table className="grid">
            <thead><tr>
              <th>عطف</th><th>شماره سند</th><th>تاریخ</th><th>نوع</th><th>شرح</th>
              <th className="num">جمع</th><th>برگشتی؟</th><th>قطعی توسط</th><th style={{ width: 190 }}>عملیات</th>
            </tr></thead>
            <tbody>
              {rows.map((r) => (
                <tr key={r.VoucherId}>
                  <td className="num">{fa(r.FolioNo)}</td>
                  <td className="num"><b>{fa(r.VchNo)}</b></td>
                  <td className="num">{r.VchDate}</td>
                  <td>{r.TypeTitle}</td>
                  <td>{r.Descr}</td>
                  <td className="num">{fa(r.TotalDbt)}</td>
                  <td>{r.ReversalOf ? <span className="badge src">این سند برگشتی است</span> : <span className="muted">—</span>}</td>
                  <td>{r.FinalizedBy}</td>
                  <td>
                    <button className="btn" onClick={() => openDetail(r.VoucherId)} style={{ padding: "1px 8px" }}>مشاهده</button>{" "}
                    {!r.ReversalOf && can.reverse
                      ? <button className="btn danger" onClick={() => reverse(r.VoucherId)} style={{ padding: "1px 8px" }}>صدور برگشتی</button>
                      : null}
                  </td>
                </tr>
              ))}
              {!rows.length && <tr><td colSpan={9} className="muted" style={{ textAlign: "center", padding: 18 }}>سند قطعی وجود ندارد</td></tr>}
            </tbody>
          </table>
        </div>
        {detail && <VoucherDetailCard d={detail} onClose={() => setDetail(null)} />}
      </CtxGate>
    </Shell>
  );
}
