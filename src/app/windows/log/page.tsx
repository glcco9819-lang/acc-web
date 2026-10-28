"use client";

import { useCallback, useEffect, useState } from "react";
import Shell from "@/components/Shell";
import { api, fa } from "@/lib/ui";

/* لاگ سیستم — فقط مدیر سامانه
   فیلتر: نام کاربری / تاریخ از–تا شمسی / سیستم / نوع فعالیت
   حذف بازه‌ای لاگ با تأیید */

const ACT_FA = ["", "ایجاد", "ویرایش", "حذف", "ورود", "خروج"];
const ACT_CLS = ["", "s3", "s2", "s1", "s3", "s2"];

export default function Page() {
  const [rows, setRows] = useState<any[]>([]);
  const [users, setUsers] = useState<string[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [can, setCan] = useState<{ logview: boolean; logdelete: boolean }>({ logview: false, logdelete: false });
  const [f, setF] = useState({ user: "", from: "", to: "", sys: "", act: "" });
  const [delOpen, setDelOpen] = useState(false);
  const [delRange, setDelRange] = useState({ from: "", to: "" });
  const [msg, setMsg] = useState<{ t: string; s: string } | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api("/api/context").then((j) => {
      setCan({ logview: !!j.can?.logview, logdelete: !!j.can?.logdelete });
      if (!j.can?.logview) setMsg({ t: "err", s: "لاگ سیستم فقط برای مدیر سامانه در دسترس است" });
    }).catch((e) => setMsg({ t: "err", s: e.message }));
  }, []);

  const load = useCallback(async (p: number) => {
    setLoading(true);
    try {
      const q = new URLSearchParams({ page: String(p), user: f.user, from: f.from, to: f.to, sys: f.sys, act: f.act });
      const j = await api(`/api/log?${q.toString()}`);
      setRows(j.rows || []); setUsers(j.users || []); setTotal(j.total || 0); setPage(j.page || 1);
      setMsg(null);
    } catch (e: any) {
      setRows([]); setTotal(0); setMsg({ t: "err", s: e.message });
    }
    setLoading(false);
  }, [f]);

  useEffect(() => { load(1); }, []); /* بار نخست */

  const pages = Math.max(1, Math.ceil(total / 50));
  const delLogs = async () => {
    if (!delRange.from && !delRange.to) { setMsg({ t: "err", s: "بازهٔ تاریخ را مشخص کنید" }); return; }
    if (!confirm(`حذف لاگ از «${delRange.from || "ابتدا"}» تا «${delRange.to || "انتها"}» — مطمئن هستید؟`)) return;
    try {
      const j = await api("/api/log", { method: "DELETE", body: JSON.stringify(delRange) });
      setMsg({ t: "ok", s: `${fa(j.deleted)} سطر لاگ حذف شد` });
      setDelOpen(false); setDelRange({ from: "", to: "" });
      load(1);
    } catch (e: any) { setMsg({ t: "err", s: e.message }); }
  };

  return (
    <Shell title="لاگ سیستم" sub="فعالیت کاربران — ثبت در پیش‌زمینهٔ دیتابیس (تریگر)">
      {msg && <div className={`msg ${msg.t}`}>{msg.s}</div>}
      {can.logview && (
        <>
          <div className="form-grid" style={{ gridTemplateColumns: "170px 130px 130px 110px 130px auto" }}>
            <div className="field"><label>نام کاربری</label>
              <select value={f.user} onChange={(e) => setF({ ...f, user: e.target.value })}>
                <option value="">همه</option>
                {users.map((u) => <option key={u} value={u}>{u}</option>)}
              </select>
            </div>
            <div className="field"><label>از تاریخ</label>
              <input value={f.from} onChange={(e) => setF({ ...f, from: e.target.value })} placeholder="1405/01/01" className="num" style={{ direction: "ltr" }} /></div>
            <div className="field"><label>تا تاریخ</label>
              <input value={f.to} onChange={(e) => setF({ ...f, to: e.target.value })} placeholder="1405/12/29" className="num" style={{ direction: "ltr" }} /></div>
            <div className="field"><label>سیستم</label>
              <select value={f.sys} onChange={(e) => setF({ ...f, sys: e.target.value })}>
                <option value="">همه</option><option value="ACC">حسابداری</option><option value="pob">مشترک</option>
              </select>
            </div>
            <div className="field"><label>نوع فعالیت</label>
              <select value={f.act} onChange={(e) => setF({ ...f, act: e.target.value })}>
                <option value="">همه</option>
                <option value="1">ایجاد</option><option value="2">ویرایش</option><option value="3">حذف</option>
                <option value="4">ورود</option><option value="5">خروج</option>
              </select>
            </div>
            <div className="field"><label>&nbsp;</label>
              <div className="btnrow">
                <button className="btn primary" onClick={() => load(1)}>نمایش</button>
                {can.logdelete && <button className="btn danger" onClick={() => setDelOpen(!delOpen)}>حذف لاگ</button>}
              </div>
            </div>
          </div>

          {delOpen && (
            <div className="form-grid" style={{ gridTemplateColumns: "130px 130px auto", border: "1px solid #e4b6b6", padding: "8px 10px", marginBottom: 8, background: "#fdf5f5" }}>
              <div className="field"><label>حذف از تاریخ</label>
                <input value={delRange.from} onChange={(e) => setDelRange({ ...delRange, from: e.target.value })} placeholder="1405/01/01" className="num" style={{ direction: "ltr" }} /></div>
              <div className="field"><label>تا تاریخ</label>
                <input value={delRange.to} onChange={(e) => setDelRange({ ...delRange, to: e.target.value })} placeholder="1405/12/29" className="num" style={{ direction: "ltr" }} /></div>
              <div className="field"><label>&nbsp;</label><button className="btn danger" onClick={delLogs}>حذف بازه</button></div>
            </div>
          )}

          <div className="scrollbox">
            <table className="grid">
              <thead><tr>
                <th>تاریخ</th><th>ساعت</th><th>کاربر</th><th>کامپیوتر</th><th className="num">IP</th>
                <th>فعالیت</th><th>سیستم</th><th>سند / رکورد</th><th>فیلد</th>
                <th>مقدار قبلی</th><th>مقدار جدید</th>
              </tr></thead>
              <tbody>
                {rows.length === 0 && (
                  <tr><td colSpan={11} style={{ textAlign: "center", color: "#888", padding: 18 }}>
                    {loading ? "در حال بارگذاری…" : "سطری با این فیلترها یافت نشد"}</td></tr>
                )}
                {rows.map((r) => (
                  <tr key={r.UserLogId}>
                    <td className="num">{r.LogDate}</td>
                    <td className="num">{r.LogTime}</td>
                    <td><b>{r.UserName}</b></td>
                    <td>{r.ComputerName || "—"}</td>
                    <td className="num">{r.IpAddress || "—"}</td>
                    <td><span className={`badge ${ACT_CLS[r.ActivityType]}`}>{ACT_FA[r.ActivityType] || r.ActivityType}</span></td>
                    <td>{r.SubSystem === "ACC" ? <span className="badge s2">حسابداری</span> : <span className="badge src">مشترک</span>}</td>
                    <td>
                      {r.DocInfo || r.TableName}
                      {r.TableName === "Session" ? "" : <span className="muted" style={{ marginInlineStart: 4 }}>({r.TableName})</span>}
                    </td>
                    <td>{r.FieldName || "—"}</td>
                    <td style={{ maxWidth: 160, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap", direction: "ltr", textAlign: "right" }} title={r.OldValue || ""}>{r.OldValue ?? "—"}</td>
                    <td style={{ maxWidth: 160, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap", direction: "ltr", textAlign: "right" }} title={r.NewValue || ""}>{r.NewValue ?? "—"}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginTop: 6 }}>
            <span className="muted">مجموع {fa(total)} سطر — صفحهٔ {fa(page)} از {fa(pages)}</span>
            <div className="btnrow">
              <button className="btn" disabled={page <= 1} onClick={() => load(page - 1)}>قبلی</button>
              <button className="btn" disabled={page >= pages} onClick={() => load(page + 1)}>بعدی</button>
            </div>
          </div>
        </>
      )}
    </Shell>
  );
}
