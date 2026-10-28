"use client";

import { useCallback, useEffect, useState } from "react";
import { api, fa } from "@/lib/ui";

/* پنجرهٔ عمومی اطلاعات عمومی (شمای YfgGen) — با ستون‌های ممیزی و تاریخ شمسی
   ممیزی: ایجادکننده/تاریخ ایجاد(شمسی)/ویرایش‌کننده/تاریخ ویرایش(شمسی)/سیستم مبدأ
   مقادیر منطقی: بله/خیر (دستور کارفرما) */

export interface GCol {
  key: string; label: string; width?: string | number;
  type?: "text" | "num" | "select" | "bool" | "jdate" | "ltext";
  options?: { v: string | number; t: string }[];
  required?: boolean; hideInGrid?: boolean; default?: string | number;
  placeholder?: string;
}

export default function GenWindow({ entity, title, sub, cols, note, parent }: {
  entity: string; title?: string; sub?: string; cols: GCol[]; note?: string;
  parent?: { key: string; label: string; load: () => Promise<{ v: number; t: string }[]>; };
}) {
  const [rows, setRows] = useState<any[]>([]);
  const [form, setForm] = useState<Record<string, string>>({});
  const [editId, setEditId] = useState<number | null>(null);
  const [msg, setMsg] = useState<{ t: "err" | "ok"; s: string } | null>(null);
  const [busy, setBusy] = useState(false);
  const [pval, setPval] = useState("");
  const [popts, setPopts] = useState<{ v: number; t: string }[]>([]);
  const [expanded, setExpanded] = useState<number | null>(null);

  const qs = parent && pval ? `?p=${pval}` : "";
  const url = `/api/gen/${entity}${qs}`;

  const load = useCallback(async () => {
    if (parent && !pval) { setRows([]); return; }
    try { const j = await api(url); setRows(j.rows || []); setMsg(null); }
    catch (e: any) { setMsg({ t: "err", s: e.message }); }
  }, [url, entity, parent, pval]);
  useEffect(() => { load(); }, [load]);

  useEffect(() => {
    if (parent) parent.load().then(setPopts).catch(() => {});
  }, [parent]);

  const blank = useCallback(() => {
    const f: Record<string, string> = {};
    cols.forEach((c) => { f[c.key] = c.default !== undefined ? String(c.default) : ""; });
    setForm(f); setEditId(null);
  }, [cols]);
  useEffect(() => { const t = setTimeout(blank, 0); return () => clearTimeout(t); }, [blank]);

  const save = async () => {
    setBusy(true); setMsg(null);
    try {
      if (editId) await api(url, { method: "PUT", body: JSON.stringify({ id: editId, ...form }) });
      else await api(url, { method: "POST", body: JSON.stringify(form) });
      setMsg({ t: "ok", s: editId ? "اصلاح انجام شد" : "ثبت شد" });
      blank(); await load();
    } catch (e: any) { setMsg({ t: "err", s: e.message }); }
    setBusy(false);
  };

  const edit = (r: any) => {
    const f: Record<string, string> = {};
    cols.forEach((c) => { f[c.key] = r[c.key] === null || r[c.key] === undefined ? "" : String(r[c.key]); });
    setForm(f);
    setEditId(r.id ?? r.Serial ?? r.CategoryId ?? r.GeoPlaceId ?? r.CodeId ?? r.SettingId ?? r.HolidayId ?? r.PartyRef);
    /* اطلاع به صفحهٔ میزبان برای پنل‌های وابسته (نشانی/طبقه‌بندی) */
    try { window.dispatchEvent(new CustomEvent("gen-row-edit", { detail: { entity, row: r } })); } catch { /* noop */ }
  };

  const del = async (id: number) => {
    if (!confirm("این رکورد حذف شود؟")) return;
    try { await api(`/api/gen/${entity}?id=${id}`, { method: "DELETE" }); await load(); }
    catch (e: any) { setMsg({ t: "err", s: e.message }); }
  };

  const gridCols = cols.filter((c) => !c.hideInGrid);
  const showAudit = !["party-cat"].includes(entity);

  return (
    <>
      {note && <p className="muted" style={{ marginBottom: 8 }}>{note}</p>}
      {msg && <div className={`msg ${msg.t}`}>{msg.s}</div>}
      {parent && (
        <div className="field" style={{ maxWidth: 380, marginBottom: 10 }}>
          <label>{parent.label}</label>
          <select value={pval} onChange={(e) => { setPval(e.target.value); setExpanded(null); }}>
            <option value="">— انتخاب کنید —</option>
            {popts.map((o) => <option key={o.v} value={o.v}>{o.t}</option>)}
          </select>
        </div>
      )}
      {(!parent || pval) && (
        <>
          <div className="form-grid">
            {cols.map((c) => (
              <div className="field" key={c.key}>
                <label>{c.label}{c.required ? " *" : ""}</label>
                {c.type === "select" ? (
                  <select value={form[c.key] ?? ""} onChange={(e) => setForm({ ...form, [c.key]: e.target.value })}>
                    <option value="">—</option>
                    {(c.options || []).map((o) => <option key={o.v} value={o.v}>{o.t}</option>)}
                  </select>
                ) : c.type === "bool" ? (
                  <select value={form[c.key] ?? "1"} onChange={(e) => setForm({ ...form, [c.key]: e.target.value })}>
                    <option value="1">بله</option>
                    <option value="0">خیر</option>
                  </select>
                ) : (
                  <input
                    type={c.type === "num" ? "number" : "text"}
                    value={form[c.key] ?? ""}
                    placeholder={c.type === "jdate" ? "1405/01/01" : c.placeholder}
                    onChange={(e) => setForm({ ...form, [c.key]: e.target.value })}
                    style={c.type === "num" || c.type === "jdate" ? { direction: "ltr", textAlign: "left" } : undefined}
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
                {showAudit && <th style={{ width: 130 }}>ایجادکننده</th>}
                {showAudit && <th style={{ width: 110 }}>تاریخ ایجاد</th>}
                {showAudit && <th style={{ width: 130 }}>ویرایش‌کننده</th>}
                {showAudit && <th style={{ width: 110 }}>تاریخ ویرایش</th>}
                {showAudit && <th style={{ width: 90 }}>سیستم مبدأ</th>}
                <th style={{ width: 110 }}>عملیات</th>
              </tr></thead>
              <tbody>
                {rows.map((r, i) => {
                  const rid = r.id ?? r.Serial ?? r.CategoryId ?? r.GeoPlaceId ?? r.CodeId ?? r.SettingId ?? r.HolidayId ?? r.PartyRef;
                  return (
                    <tr key={rid ?? i}>
                      {gridCols.map((c) => {
                        let v = r[c.key];
                        if (c.type === "select") v = (c.options || []).find((o) => String(o.v) === String(v))?.t ?? v;
                        if (c.type === "bool") v = v ? "بله" : "خیر";
                        const isNum = c.type === "num";
                        return <td key={c.key} className={isNum ? "num" : ""}>{c.type === "num" ? fa(v) : (v ?? "")}</td>;
                      })}
                      {showAudit && <td>{r.CreatedBy}</td>}
                      {showAudit && <td className="num">{r.CreatedAtJ ?? ""}</td>}
                      {showAudit && <td>{r.UpdatedBy ?? "—"}</td>}
                      {showAudit && <td className="num">{r.UpdatedAtJ ?? "—"}</td>}
                      {showAudit && <td className="num">{r.SourceSystem ?? ""}</td>}
                      <td>
                        <button className="btn" onClick={() => edit(r)} style={{ padding: "1px 8px" }}>اصلاح</button>{" "}
                        <button className="btn danger" onClick={() => del(rid)} style={{ padding: "1px 8px" }}>حذف</button>
                      </td>
                    </tr>
                  );
                })}
                {!rows.length && <tr><td colSpan={gridCols.length + (showAudit ? 6 : 1)} className="muted" style={{ textAlign: "center", padding: 14 }}>ردیفی ثبت نشده است</td></tr>}
              </tbody>
            </table>
          </div>
        </>
      )}
    </>
  );
}
