"use client";

import { useCallback, useEffect, useState } from "react";
import Shell from "@/components/Shell";
import { api, fa } from "@/lib/ui";

/* برگشت اسناد قطعی — ردیف‌ها معکوس + اسلات‌های تفصیلی حفظ می‌شوند */
export default function Page() {
  const [rows, setRows] = useState<any[]>([]);
  const [msg, setMsg] = useState<{ t: "err" | "ok"; s: string } | null>(null);
  const [can, setCan] = useState<any>({});

  const load = useCallback(async () => {
    try { const j = await api("/api/vch/list?state=3"); setRows(j.rows || []); }
    catch (e: any) { setMsg({ t: "err", s: e.message }); }
  }, []);
  useEffect(() => { load(); }, [load]);
  useEffect(() => { api("/api/auth/login").then((j) => setCan(j.can || {})).catch(() => {}); }, []);

  const reverse = async (id: number) => {
    setMsg(null);
    try {
      const j = await api("/api/vch/reverse", { method: "POST", body: JSON.stringify({ id }) });
      setMsg({ t: "ok", s: `سند برگشتی شماره ${fa(j.reversal.VchNo)} به‌صورت «موقت» صادر شد — باید مثل سند عادی بررسی و قطعی شود` });
      await load();
    } catch (e: any) { setMsg({ t: "err", s: e.message }); }
  };

  return (
    <Shell title="برگشت اسناد قطعی" sub="سند قطعی اصلاح‌ناپذیر است — اصلاح فقط با صدور سند برگشتی">
      {msg && <div className={`msg ${msg.t}`}>{msg.s}</div>}
      <div className="scrollbox">
        <table className="grid">
          <thead><tr>
            <th>عطف</th><th>شماره سند</th><th>تاریخ</th><th>نوع</th><th>شرح</th>
            <th className="num">جمع</th><th>برگشتی؟</th><th>قطعی توسط</th><th style={{ width: 130 }}>عملیات</th>
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
                  {!r.ReversalOf && can.reverse
                    ? <button className="btn danger" onClick={() => reverse(r.VoucherId)} style={{ padding: "1px 10px" }}>صدور برگشتی</button>
                    : null}
                </td>
              </tr>
            ))}
            {!rows.length && <tr><td colSpan={9} className="muted" style={{ textAlign: "center", padding: 18 }}>سند قطعی وجود ندارد</td></tr>}
          </tbody>
        </table>
      </div>
    </Shell>
  );
}
