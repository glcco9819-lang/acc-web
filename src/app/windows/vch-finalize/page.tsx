"use client";

import { useCallback, useEffect, useState } from "react";
import Shell from "@/components/Shell";
import { api, fa, STATE_FA } from "@/lib/ui";

/* [فرم اصلی: قطعي كردن اسناد — قطعی شود / لغو قطعی ممنوع: سند قطعی فقط با سند برگشتی اصلاح می‌شود] */
export default function Page() {
  const [rows, setRows] = useState<any[]>([]);
  const [state, setState] = useState("2");
  const [msg, setMsg] = useState<{ t: "err" | "ok"; s: string } | null>(null);
  const [can, setCan] = useState<any>({});

  const load = useCallback(async () => {
    try {
      const j = await api(`/api/vch/list?state=${state}`);
      setRows(j.rows || []);
    } catch (e: any) { setMsg({ t: "err", s: e.message }); }
  }, [state]);
  useEffect(() => { load(); }, [load]);
  useEffect(() => { api("/api/auth/login").then((j) => setCan(j.can || {})).catch(() => {}); }, []);

  const finalize = async (id: number) => {
    setMsg(null);
    try {
      await api("/api/vch/transition", { method: "POST", body: JSON.stringify({ id, action: "finalize" }) });
      setMsg({ t: "ok", s: "سند قطعی شد — از این لحظه در دفاتر قانونی منظور می‌شود و تغییرش فقط با سند برگشتی ممکن است" });
      await load();
    } catch (e: any) { setMsg({ t: "err", s: e.message }); }
  };

  return (
    <Shell title="قطعی کردن اسناد" sub="بررسی‌شده → قطعی (قطعی‌کننده باید غیر از سازنده و بررسی‌کننده باشد)">
      {msg && <div className={`msg ${msg.t}`}>{msg.s}</div>}
      <div className="form-grid" style={{ gridTemplateColumns: "200px" }}>
        <div className="field"><label>وضعیت</label>
          <select value={state} onChange={(e) => setState(e.target.value)}>
            <option value="2">آمادهٔ قطعی (بررسی‌شده)</option>
            <option value="3">قطعی‌شده</option>
          </select>
        </div>
      </div>
      <div className="scrollbox">
        <table className="grid">
          <thead><tr>
            <th>عطف</th><th>شماره سند</th><th>تاریخ</th><th>نوع</th><th>شرح</th>
            <th className="num">جمع</th><th>مبدأ</th><th>وضعیت</th>
            <th>سازنده / بررسی / قطعی</th><th style={{ width: 150 }}>عملیات</th>
          </tr></thead>
          <tbody>
            {rows.map((r) => (
              <tr key={r.VoucherId}>
                <td className="num">{fa(r.FolioNo)}</td>
                <td className="num"><b>{fa(r.VchNo)}</b>{r.ReversalOf ? <span className="badge src" style={{ marginInlineStart: 4 }}>برگشتی</span> : null}</td>
                <td className="num">{r.VchDate}</td>
                <td>{r.TypeTitle}</td>
                <td>{r.Descr}</td>
                <td className="num">{fa(r.TotalDbt)}</td>
                <td>{r.SourceModule === "ACC" ? "حسابداری" : r.SourceModule}</td>
                <td><span className="badge">{STATE_FA[r.State]}</span></td>
                <td>{r.CreatedBy} / {r.CheckedBy || "—"} / {r.FinalizedBy || "—"}</td>
                <td>
                  {r.State === 2 && can.finalize
                    ? <button className="btn green" onClick={() => finalize(r.VoucherId)} style={{ padding: "1px 10px" }}>قطعی شود</button>
                    : <span className="muted">قطعی {r.FinalizedBy ? `توسط ${r.FinalizedBy}` : ""}</span>}
                </td>
              </tr>
            ))}
            {!rows.length && <tr><td colSpan={10} className="muted" style={{ textAlign: "center", padding: 18 }}>سندی در این وضعیت نیست</td></tr>}
          </tbody>
        </table>
      </div>
    </Shell>
  );
}
