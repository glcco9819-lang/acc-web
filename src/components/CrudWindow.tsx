"use client";

import { useCallback, useEffect, useState } from "react";
import { api, fa } from "@/lib/ui";

/* پنجرهٔ عمومی تعاریف (مطابق الگوی فرم‌های اصلی: نوار دکمه + گرید + فرم ثبت) */

export interface Col {
  key: string; label: string; width?: string | number;
  type?: "text" | "num" | "select" | "bool";
  options?: { v: string | number; t: string }[];
  required?: boolean; code?: number; hideInGrid?: boolean; default?: string | number;
}

export default function CrudWindow({ entity, title, sub, cols, note }: {
  entity: string; title: string; sub?: string; cols: Col[]; note?: string;
}) {
  const [rows, setRows] = useState<any[]>([]);
  const [form, setForm] = useState<Record<string, string>>({});
  const [editId, setEditId] = useState<number | null>(null);
  const [msg, setMsg] = useState<{ t: "err" | "ok"; s: string } | null>(null);
  const [mode, setMode] = useState(2);
  const [busy, setBusy] = useState(false);

  const load = useCallback(async () => {
    try {
      const j = await api(`/api/acc/${entity}`);
      setRows(j.rows || []); setMode(j.mode || 2);
    } catch (e: any) {
      if (e.code === "NO_CTX") setMsg({ t: "err", s: "ابتدا از نوار بالا شرکت و سال مالی را انتخاب کنید" });
      else setMsg({ t: "err", s: e.message });
    }
  }, [entity]);
  useEffect(() => { load(); }, [load]);

  const blank = useCallback(() => {
    const f: Record<string, string> = {};
    cols.forEach((c) => { f[c.key] = c.default !== undefined ? String(c.default) : ""; });
    setForm(f); setEditId(null);
  }, [cols]);
  useEffect(() => {
    const t = setTimeout(blank, 0);
    return () => clearTimeout(t);
  }, [blank]);

  const save = async () => {
    setBusy(true); setMsg(null);
    try {
      if (editId) await api(`/api/acc/${entity}`, { method: "PUT", body: JSON.stringify({ id: editId, ...form }) });
      else await api(`/api/acc/${entity}`, { method: "POST", body: JSON.stringify(form) });
      setMsg({ t: "ok", s: editId ? "اصلاح انجام شد" : "ثبت شد" });
      blank(); await load();
    } catch (e: any) { setMsg({ t: "err", s: e.message }); }
    setBusy(false);
  };

  const edit = (r: any) => {
    const f: Record<string, string> = {};
    cols.forEach((c) => { f[c.key] = r[c.key] === null || r[c.key] === undefined ? "" : String(r[c.key]); });
    setForm(f); setEditId(rowId(r));
  };

  const del = async (id: number | null) => {
    if (id === null) return;
    if (!confirm("این رکورد حذف شود؟")) return;
    try { await api(`/api/acc/${entity}?id=${id}`, { method: "DELETE" }); await load(); }
    catch (e: any) { setMsg({ t: "err", s: e.message }); }
  };

  const gridCols = cols.filter((c) => !c.hideInGrid);

  /* شناسهٔ سطر — API کلید اصلی را با نام id هم برمی‌گرداند؛ پیش از آن هم کلیدها را می‌شناسد */
  const rowId = (r: any): number | null =>
    r.id ?? r.GroupId ?? r.KolId ?? r.MoeinId ?? r.TafsiliId ?? r.TafsiliTypeId
      ?? r.CategoryId ?? r.NarrationId ?? r.VoucherTypeId ?? r.FxId ?? r.BranchId ?? null;

  return (
    <>
      {note && <p className="muted" style={{ marginBottom: 8 }}>{note}</p>}
      {msg && <div className={`msg ${msg.t}`}>{msg.s}</div>}
      <div className="form-grid">
        {cols.map((c) => (
          <div className="field" key={c.key}>
            <label>{c.label}{c.required ? " *" : ""}{c.code ? ` (${c.code} رقم)` : ""}</label>
            {c.type === "select" ? (
              <select value={form[c.key] ?? ""} onChange={(e) => setForm({ ...form, [c.key]: e.target.value })}>
                <option value="">—</option>
                {(c.options || []).map((o) => <option key={o.v} value={o.v}>{o.t}</option>)}
              </select>
            ) : (
              <input
                type={c.type === "num" ? "number" : "text"}
                value={form[c.key] ?? ""}
                onChange={(e) => setForm({ ...form, [c.key]: e.target.value })}
                style={c.code ? { direction: "ltr", textAlign: "left" } : undefined}
              />
            )}
          </div>
        ))}
      </div>
      <div className="btnrow">
        <button className="btn primary" onClick={save} disabled={busy}>{editId ? "اصلاح" : "ثبت"}</button>
        {editId && <button className="btn" onClick={blank}>انصراف</button>}
      </div>
      <div className="scrollbox">
        <table className="grid">
          <thead><tr>
            {gridCols.map((c) => <th key={c.key} style={{ width: c.width }}>{c.label}</th>)}
            <th style={{ width: 110 }}>عملیات</th>
          </tr></thead>
          <tbody>
            {rows.map((r, i) => (
              <tr key={rowId(r) ?? i}>
                {gridCols.map((c) => {
                  let v = r[c.key];
                  if (c.type === "select") v = (c.options || []).find((o) => String(o.v) === String(v))?.t ?? v;
                  if (c.type === "bool") v = v ? "بله" : "خیر";
                  const isNum = c.type === "num";
                  return <td key={c.key} className={isNum ? "num" : ""}>{c.type === "num" ? fa(v) : (v ?? "")}</td>;
                })}
                <td>
                  <button className="btn" onClick={() => edit(r)} style={{ padding: "1px 8px" }}>اصلاح</button>{" "}
                  <button className="btn danger" onClick={() => del(rowId(r))} style={{ padding: "1px 8px" }}>حذف</button>
                </td>
              </tr>
            ))}
            {!rows.length && <tr><td colSpan={gridCols.length + 1} className="muted" style={{ textAlign: "center", padding: 20 }}>رکوردی نیست</td></tr>}
          </tbody>
        </table>
      </div>
      <p className="muted" style={{ marginTop: 6 }}>تعداد رکوردها: {fa(rows.length)}</p>
    </>
  );
}
