"use client";

import { useCallback, useEffect, useState } from "react";
import Shell from "@/components/Shell";
import { api, exportCsv, fa } from "@/lib/ui";

/* واژه‌نامهٔ داده — سه جدول مرجع YFG (درخواست کارفرما):
   ۱) TableName : نام جدول انگلیسی + شما + نام فارسی بر اساس نقش
   ۲) FieldName : نام فیلد + نام تیبل + شما + نام فارسی بر اساس نقش + ماژول
   ۳) LinkField : فیلد + تیبل + شما + نام فارسی + فیلد لینک + تیبل لینک + شما لینک + نام فارسی + نقش
   ویرایش نام فارسی: فقط مدیر سامانه */

type Tab = "tables" | "fields" | "links";
const TABS: { k: Tab; label: string }[] = [
  { k: "tables", label: "جدول‌ها (TableName)" },
  { k: "fields", label: "فیلدها (FieldName)" },
  { k: "links", label: "پیوندها (LinkField)" },
];

export default function Page() {
  const [tab, setTab] = useState<Tab>("tables");
  const [search, setSearch] = useState("");
  const [schema, setSchema] = useState("");
  const [rows, setRows] = useState<any[]>([]);
  const [stats, setStats] = useState<{ T: number; F: number; L: number } | null>(null);
  const [msg, setMsg] = useState<{ t: "err" | "ok"; s: string } | null>(null);
  const [canEdit, setCanEdit] = useState(false);
  const [edit, setEdit] = useState<{ id: number; fa: string; module: string; role: string } | null>(null);
  const [busy, setBusy] = useState(false);

  const load = useCallback(async () => {
    try {
      const j = await api(`/api/meta?view=${tab}&q=${encodeURIComponent(search)}&schema=${encodeURIComponent(schema)}`);
      setRows(j.rows || []); setMsg(null);
    } catch (e: any) { setMsg({ t: "err", s: e.message }); }
  }, [tab, search, schema]);

  useEffect(() => { load(); }, [load]);
  useEffect(() => {
    api("/api/context").then((j) => setCanEdit(!!j.ok && j.user?.role === "admin")).catch(() => {});
    fetch("/api/meta", { method: "HEAD" }).then((r) => {
      const T = Number(r.headers.get("X-Meta-Tables") || 0);
      const F = Number(r.headers.get("X-Meta-Fields") || 0);
      const L = Number(r.headers.get("X-Meta-Links") || 0);
      setStats({ T, F, L });
    }).catch(() => {});
  }, []);

  const startEdit = (r: any) => {
    setEdit({
      id: r.id,
      fa: tab === "tables" ? r.TableFa : tab === "fields" ? r.FieldFa : (r.FieldFa || ""),
      module: r.Module || "",
      role: r.LinkRole || "",
    });
  };

  const saveEdit = async () => {
    if (!edit) return;
    setBusy(true); setMsg(null);
    try {
      await api("/api/meta", { method: "PUT", body: JSON.stringify({ view: tab, id: edit.id, TableFa: edit.fa, FieldFa: edit.fa, Module: edit.module, LinkRole: edit.role }) });
      setMsg({ t: "ok", s: "واژه‌نامه به‌روزرسانی شد" });
      setEdit(null); await load();
    } catch (e: any) { setMsg({ t: "err", s: e.message }); }
    setBusy(false);
  };

  const doExport = () => {
    if (tab === "tables") exportCsv("YFG-TableName.csv",
      ["شما", "نام جدول", "نام فارسی بر اساس نقش", "ماژول", "جدول مرجع"],
      rows.map((r) => [r.TableSchema, r.TableName, r.TableFa, r.Module, r.IsLookup ? "بله" : "خیر"]));
    else if (tab === "fields") exportCsv("YFG-FieldName.csv",
      ["شما", "نام تیبل", "نام فیلد", "نام فارسی بر اساس نقش", "ماژول", "نوع داده"],
      rows.map((r) => [r.TableSchema, r.TableName, r.FieldName, r.FieldFa, r.Module, r.DataType || ""]));
    else exportCsv("YFG-LinkField.csv",
      ["شما", "نام تیبل", "نام فیلد", "نام فارسی", "شمای لینک", "تیبل لینک", "فیلد لینک", "نام فارسی لینک", "نقش"],
      rows.map((r) => [r.TableSchema, r.TableName, r.FieldName, r.FieldFa, r.LinkTableSchema, r.LinkTableName, r.LinkFieldName, r.LinkFieldFa, r.LinkRole || ""]));
  };

  return (
    <Shell title="واژه‌نامهٔ داده" sub="مستندسازی زندهٔ دیتابیس: جدول‌ها، فیلدها و پیوندها — نام فارسی بر اساس نقش">
      <div className="tabs">
        {TABS.map((t) => (
          <button key={t.k} className={`tab ${tab === t.k ? "active" : ""}`} onClick={() => { setTab(t.k); setEdit(null); }}>
            {t.label}
            {stats && t.k === "tables" ? ` (${fa(stats.T)})` : stats && t.k === "fields" ? ` (${fa(stats.F)})` : stats && t.k === "links" ? ` (${fa(stats.L)})` : ""}
          </button>
        ))}
      </div>

      {msg && <div className={`msg ${msg.t}`}>{msg.s}</div>}

      <div className="filterbar">
        <input className="search" placeholder="جست‌وجو در نام‌ها…" value={search}
          onChange={(e) => setSearch(e.target.value)} />
        <select value={schema} onChange={(e) => setSchema(e.target.value)}>
          <option value="">همهٔ شماها</option>
          <option value="ACC">ACC — حسابداری</option>
          <option value="pob">pob — عمومی (بستر)</option>
          <option value="YFG">YFG — واژه‌نامه</option>
        </select>
        <button className="btn" onClick={doExport}>Excel</button>
        {canEdit && edit && <span className="muted">در حال ویرایش ردیف #{fa(edit.id)}</span>}
      </div>

      {canEdit && edit && (
        <div className="card edit-card">
          <div className="card-title">ویرایش نام فارسی بر اساس نقش</div>
          <div className="form-grid" style={{ gridTemplateColumns: "1fr 220px 1fr auto" }}>
            {tab !== "links" && (
              <div className="field">
                <label>نام فارسی {tab === "tables" ? "جدول" : "فیلد"} *</label>
                <input value={edit.fa} onChange={(e) => setEdit({ ...edit, fa: e.target.value })} />
              </div>
            )}
            {tab === "links" && (
              <div className="field">
                <label>نام فارسی فیلد</label>
                <input value={edit.fa} onChange={(e) => setEdit({ ...edit, fa: e.target.value })} />
              </div>
            )}
            {tab !== "links" && (
              <div className="field">
                <label>ماژول</label>
                <input value={edit.module} onChange={(e) => setEdit({ ...edit, module: e.target.value })} />
              </div>
            )}
            {tab === "links" && (
              <div className="field" style={{ gridColumn: "span 3" }}>
                <label>نقش فیلد در پیوند</label>
                <input value={edit.role} onChange={(e) => setEdit({ ...edit, role: e.target.value })} />
              </div>
            )}
            <div className="field">
              <label>&nbsp;</label>
              <div className="btnrow" style={{ margin: 0 }}>
                <button className="btn primary" onClick={saveEdit} disabled={busy}>ثبت</button>
                <button className="btn" onClick={() => setEdit(null)}>انصراف</button>
              </div>
            </div>
          </div>
        </div>
      )}

      <div className="scrollbox">
        <table className="grid">
          {tab === "tables" && (
            <>
              <thead><tr>
                <th style={{ width: 70 }}>شما</th><th style={{ width: 190 }}>نام جدول</th>
                <th>نام فارسی بر اساس نقش</th><th style={{ width: 110 }}>ماژول</th>
                <th style={{ width: 80 }}>مرجع</th><th style={{ width: 120 }}>ایجادکننده</th><th style={{ width: 100 }}>تاریخ ایجاد</th>
                {canEdit && <th style={{ width: 70 }}>عملیات</th>}
              </tr></thead>
              <tbody>
                {rows.map((r) => (
                  <tr key={r.id}>
                    <td className="ltr">{r.TableSchema}</td><td className="ltr">{r.TableName}</td>
                    <td>{r.TableFa}</td><td>{r.Module}</td>
                    <td>{r.IsLookup ? "بله" : "خیر"}</td><td>{r.CreatedBy}</td><td className="num">{r.CreatedAtJ ?? ""}</td>
                    {canEdit && <td><button className="btn" onClick={() => startEdit(r)} style={{ padding: "1px 8px" }}>اصلاح</button></td>}
                  </tr>
                ))}
              </tbody>
            </>
          )}
          {tab === "fields" && (
            <>
              <thead><tr>
                <th style={{ width: 70 }}>شما</th><th style={{ width: 180 }}>نام تیبل</th><th style={{ width: 180 }}>نام فیلد</th>
                <th>نام فارسی بر اساس نقش</th><th style={{ width: 100 }}>ماژول</th><th style={{ width: 90 }}>نوع داده</th>
                {canEdit && <th style={{ width: 70 }}>عملیات</th>}
              </tr></thead>
              <tbody>
                {rows.map((r) => (
                  <tr key={r.id}>
                    <td className="ltr">{r.TableSchema}</td>
                    <td className="ltr" title={r.TableFa || ""}>{r.TableName}</td>
                    <td className="ltr">{r.FieldName}</td>
                    <td>{r.FieldFa}</td><td>{r.Module}</td><td className="ltr">{r.DataType || ""}</td>
                    {canEdit && <td><button className="btn" onClick={() => startEdit(r)} style={{ padding: "1px 8px" }}>اصلاح</button></td>}
                  </tr>
                ))}
              </tbody>
            </>
          )}
          {tab === "links" && (
            <>
              <thead><tr>
                <th style={{ width: 60 }}>شما</th><th style={{ width: 150 }}>نام تیبل</th><th style={{ width: 130 }}>نام فیلد</th>
                <th>نام فارسی بر اساس نقش</th>
                <th style={{ width: 60 }}>شما لینک</th><th style={{ width: 150 }}>تیبل لینک</th><th style={{ width: 130 }}>فیلد لینک</th>
                <th>نام فارسی لینک</th><th>نقش فیلد در پیوند</th>
                {canEdit && <th style={{ width: 70 }}>عملیات</th>}
              </tr></thead>
              <tbody>
                {rows.map((r) => (
                  <tr key={r.id}>
                    <td className="ltr">{r.TableSchema}</td><td className="ltr">{r.TableName}</td><td className="ltr">{r.FieldName}</td>
                    <td>{r.FieldFa}</td>
                    <td className="ltr">{r.LinkTableSchema}</td><td className="ltr">{r.LinkTableName}</td><td className="ltr">{r.LinkFieldName}</td>
                    <td>{r.LinkFieldFa}</td><td>{r.LinkRole || "—"}</td>
                    {canEdit && <td><button className="btn" onClick={() => startEdit(r)} style={{ padding: "1px 8px" }}>اصلاح</button></td>}
                  </tr>
                ))}
              </tbody>
            </>
          )}
          {!rows.length && (
            <tbody><tr><td colSpan={9} className="muted" style={{ textAlign: "center", padding: 20 }}>موردی یافت نشد</td></tr></tbody>
          )}
        </table>
      </div>
      <p className="muted" style={{ marginTop: 6 }}>
        تعداد ردیف‌ها: {fa(rows.length)}
        {stats && <> — کل واژه‌نامه: {fa(stats.T)} جدول، {fa(stats.F)} فیلد، {fa(stats.L)} پیوند</>}
      </p>
    </Shell>
  );
}
