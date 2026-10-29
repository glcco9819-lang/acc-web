"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import Shell from "@/components/Shell";
import { api, fa } from "@/lib/ui";
import { useSync } from "@/components/App";

/* [فرم اصلی: معرفي حسابهاي تفصيل — کد، عنوان، نوع تفصيل، عنوان لاتين، وضعيت]
   v2.4.3 — تکمیل انواع استاندارد بر اساس فایل اولیه (YFG/SG) و سند ۹۰:
   برای «همهٔ» انواع تفصیل، فهرست مبدأ همان نوع نمایش داده می‌شود و تعریف رکورد
   جدیدِ همان نوع از همین پنجره ممکن است:
     PARTY      → اشخاص/شرکت‌ها (pob.Party) + تعریف شخص جدید درجا → PartyRef
     BRANCH     → شعبه‌ها (ACC.AccBranch) + تعریف شعبه درجا → BranchRef
     BANK/CASH/COSTCENTER/PROJECT/EMPLOYEE/GOODS/CHECK/LC
                → فهرست کد (pob.CodeList با همان Type) + تعریف درجا → ListRef
     خالی       → عنوان آزاد (مثل «سایر») */

const CLS_FA: Record<string, string> = {
  PARTY: "اشخاص و شرکت‌ها", BANK: "بانک‌ها", BRANCH: "شعبه‌ها", PROJECT: "پروژه‌ها",
  CASH: "صندوق‌ها", COSTCENTER: "مراکز هزینه", EMPLOYEE: "کارمندها",
  GOODS: "کالاها", CHECK: "چک‌ها", LC: "اعتبارات اسنادی",
};
/* انواع متصل به pob.CodeList — مکانیزم عمومی فهرست + تعریف درجا */
const LIST_TYPES = ["BANK", "CASH", "COSTCENTER", "PROJECT", "EMPLOYEE", "GOODS", "CHECK", "LC"];

const partyLabel = (p: any) =>
  p?.Title || [p?.FName, p?.LName].filter(Boolean).join(" ") || `شخص #${p?.Serial ?? ""}`;

/* شکل مفرد برچسب نوع (برای «تعریف … جدید» و پیام‌ها) — «صندوق‌ها» ← «صندوق» */
const ONE_FIX: Record<string, string> = { "مراکز هزینه": "مرکز هزینه", "اعتبارات اسنادی": "اعتبار اسنادی" };
const oneOf = (lbl: string) => ONE_FIX[lbl] || lbl.replace(/\u200c?ها$/u, "");

export default function Page() {
  const [types, setTypes] = useState<any[]>([]);
  const [rows, setRows] = useState<any[]>([]);
  const [parties, setParties] = useState<any[]>([]);
  const [branches, setBranches] = useState<any[]>([]);
  const [lists, setLists] = useState<Record<string, any[]>>({});   /* فهرست کد به‌ازای هر CodeListType */
  const [ready, setReady] = useState(false);

  const [form, setForm] = useState<Record<string, string>>({
    Code: "", TafsiliTypeId: "", Title: "", LatinTitle: "", IsActive: "1",
    PartyRef: "", BranchRef: "", ListRef: "",
  });
  const [editId, setEditId] = useState<number | null>(null);
  const [msg, setMsg] = useState<{ t: "err" | "ok"; s: string } | null>(null);
  const [busy, setBusy] = useState(false);

  /* جستجو در فهرست مبدأ فعال */
  const [filter, setFilter] = useState("");

  /* تعریف شخص جدید درجا */
  const [npOpen, setNpOpen] = useState(false);
  const [np, setNp] = useState<Record<string, string>>({
    RecType: "MAN", FName: "", LName: "", Title: "", NationalCode: "", EconCode: "",
  });
  const [npBusy, setNpBusy] = useState(false);

  /* تعریف رکورد جدید درجا (شعبه/فهرست کد) */
  const [nbOpen, setNbOpen] = useState(false);
  const [nbTitle, setNbTitle] = useState("");
  const [nbBusy, setNbBusy] = useState(false);

  const load = useCallback(async () => {
    try {
      const t = await api("/api/acc/tafsili-types");
      const r = await api("/api/acc/tafsili");
      setTypes(t.rows || []);
      setRows(r.rows || []);
      return r.rows || [];
    } catch (e: any) {
      if (e.code === "NO_CTX") setMsg({ t: "err", s: "ابتدا از نوار بالا شرکت و سال مالی را انتخاب کنید" });
      else setMsg({ t: "err", s: e.message });
      return [];
    }
  }, []);

  const loadAux = useCallback(async () => {
    api("/api/gen/party").then((j) => setParties(j.rows || [])).catch(() => {});
    api("/api/acc/branch").then((j) => setBranches(j.rows || [])).catch(() => {});
  }, []);

  /* واکشی فهرست کدِ یک نوع (یک‌بار) */
  const getList = useCallback(async (cls: string): Promise<any[]> => {
    if (lists[cls]) return lists[cls];
    try {
      const j = await api(`/api/gen/lookup?t=${encodeURIComponent(cls)}`);
      const l = j.rows || [];
      setLists((m) => ({ ...m, [cls]: l }));
      return l;
    } catch { return []; }
  }, [lists]);

  /* کد پیشنهادی — ماکزیمم کد فعلی شرکت + ۱ (یکتایی کد در سطح شرکت است) */
  const suggestCode = useCallback((list: any[]) =>
    String(list.reduce((m, r) => Math.max(m, Number(r.Code) || 0), 0) + 1).padStart(8, "0"), []);

  const blank = useCallback((list?: any[]) => {
    const src = list ?? rows;
    setForm({ Code: suggestCode(src), TafsiliTypeId: "", Title: "", LatinTitle: "", IsActive: "1", PartyRef: "", BranchRef: "", ListRef: "" });
    setEditId(null); setFilter(""); setNpOpen(false); setNbOpen(false); setNbTitle("");
  }, [rows, suggestCode]);

  useSync(load); /* v2.4.4 — فهرست تفصیل‌ها با هر ثبت/اصلاح/حذف (در هر پنجره‌ای) خودکار تازه می‌شود */
  useEffect(() => {
    (async () => {
      const rws = await load();
      await loadAux();
      setForm({ Code: suggestCode(rws), TafsiliTypeId: "", Title: "", LatinTitle: "", IsActive: "1", PartyRef: "", BranchRef: "", ListRef: "" });
      setReady(true);
    })();
    /* واکشی پیش‌دستانهٔ فهرست انواع کد برای نمایش سریع */
    LIST_TYPES.forEach((c) => getList(c));
  }, [load, loadAux, suggestCode]);   /* eslint-disable-line react-hooks/exhaustive-deps */

  /* نوع انتخاب‌شده و مبدأ آن */
  const selType = types.find((t) => String(t.TafsiliTypeId) === String(form.TafsiliTypeId || ""));
  const src = String(selType?.CodeListType || "").trim().toUpperCase();
  const isParty = src === "PARTY";
  const isBranch = src === "BRANCH";
  const isList = LIST_TYPES.includes(src);
  const isFree = !isParty && !isBranch && !isList;   /* مثل «سایر» */
  const srcLabel = CLS_FA[src] || "";

  /* فهرست فعال برای انواع متصل به pob.CodeList */
  const listRows = isList ? (lists[src] || []) : [];

  /* گزینه‌های فهرست فعال با فیلتر جستجو */
  const options = useMemo(() => {
    const s = filter.trim().toLowerCase();
    let base: { v: string; t: string }[] = [];
    if (isParty) {
      base = parties.map((p) => ({ v: String(p.Serial), t: partyLabel(p) }));
      if (s) base = base.filter((o) => {
        const p = parties.find((x) => String(x.Serial) === o.v) || {};
        return partyLabel(p).toLowerCase().includes(s) || String(p.NationalCode || "").includes(s) || String(p.EconCode || "").includes(s);
      });
    } else if (isBranch) {
      base = branches.map((b) => ({ v: String(b.BranchId), t: b.Code ? `${b.Code} — ${b.Title}` : b.Title }));
      if (s) base = base.filter((o) => o.t.toLowerCase().includes(s));
    } else if (isList) {
      base = listRows.map((b) => ({ v: String(b.CodeId), t: b.Title }));
      if (s) base = base.filter((o) => o.t.toLowerCase().includes(s));
    }
    return base.slice(0, 500);
  }, [isParty, isBranch, isList, parties, branches, listRows, filter]);

  const pickType = (v: string) => {
    setForm((f) => ({ ...f, TafsiliTypeId: v, PartyRef: "", BranchRef: "", ListRef: "" }));
    setNpOpen(false); setNbOpen(false); setFilter("");
    const t = types.find((x) => String(x.TafsiliTypeId) === v);
    const c = String(t?.CodeListType || "").trim().toUpperCase();
    if (LIST_TYPES.includes(c)) getList(c);
  };

  /* انتخاب رکورد از فهرست مبدأ فعال — عنوان تفصیلی خودکار درج می‌شود */
  const pickFromList = (v: string) => {
    if (isParty) {
      if (!v) { setForm((f) => ({ ...f, PartyRef: "" })); return; }
      const p = parties.find((x) => String(x.Serial) === v);
      setForm((f) => ({ ...f, PartyRef: v, BranchRef: "", ListRef: "", Title: p ? partyLabel(p) : f.Title }));
    } else if (isBranch) {
      const b = branches.find((x) => String(x.BranchId) === v);
      setForm((f) => ({ ...f, BranchRef: v, PartyRef: "", ListRef: "", Title: b ? b.Title : f.Title }));
    } else if (isList) {
      const b = listRows.find((x) => String(x.CodeId) === v);
      setForm((f) => ({ ...f, ListRef: v, PartyRef: "", BranchRef: "", Title: b ? b.Title : f.Title }));
    }
  };

  /* ثبت شخص جدید از همین پنجره — سپس انتساب به تفصیلی */
  const submitParty = async () => {
    const body: any = { RecType: np.RecType, IsActive: 1 };
    if (np.RecType === "CMP") {
      if (!np.Title.trim()) { setMsg({ t: "err", s: "عنوان شرکت الزامی است" }); return; }
      body.Title = np.Title.trim(); body.PartyKind = 2;
    } else {
      if (!np.FName.trim() && !np.LName.trim()) { setMsg({ t: "err", s: "نام یا نام خانوادگی الزامی است" }); return; }
      body.FName = np.FName.trim(); body.LName = np.LName.trim(); body.PartyKind = 1;
      if (np.Title.trim()) body.Title = np.Title.trim();
    }
    if (np.NationalCode.trim()) body.NationalCode = np.NationalCode.trim();
    if (np.EconCode.trim()) body.EconCode = np.EconCode.trim();
    setNpBusy(true); setMsg(null);
    try {
      const j = await api("/api/gen/party", { method: "POST", body: JSON.stringify(body) });
      const p = j.row;
      setParties((ps) => [p, ...ps]);
      setForm((f) => ({ ...f, PartyRef: String(p.Serial), BranchRef: "", ListRef: "", Title: partyLabel(p) }));
      setNp({ RecType: np.RecType, FName: "", LName: "", Title: "", NationalCode: "", EconCode: "" });
      setNpOpen(false);
      setMsg({ t: "ok", s: "شخص جدید ثبت شد و به این تفصیلی منتسب گردید" });
    } catch (e: any) { setMsg({ t: "err", s: e.message }); }
    setNpBusy(false);
  };

  /* ثبت رکورد جدید در فهرست مبدأ (شعبه یا هر نوع متصل به فهرست کد) از همین پنجره */
  const submitNb = async () => {
    if (!nbTitle.trim()) { setMsg({ t: "err", s: "عنوان الزامی است" }); return; }
    setNbBusy(true); setMsg(null);
    try {
      if (isBranch) {
        const next = branches.reduce((m, b) => Math.max(m, Number(b.Code) || 0), 0) + 1;
        const j = await api("/api/acc/branch", { method: "POST", body: JSON.stringify({ Code: String(next).slice(0, 10), Title: nbTitle.trim(), IsActive: 1 }) });
        const row = j.row;
        setBranches((bs) => [...bs, row]);
        setForm((f) => ({ ...f, BranchRef: String(row.BranchId), PartyRef: "", ListRef: "", Title: nbTitle.trim() }));
        setMsg({ t: "ok", s: "شعبه جدید ثبت شد و به این تفصیلی منتسب گردید" });
      } else if (isList) {
        const cur = lists[src] || [];
        const next = cur.reduce((m, b) => Math.max(m, Number(b.Code) || 0), 0) + 1;
        const j = await api("/api/gen/lookup", { method: "POST", body: JSON.stringify({ Type: src, Code: next, Title: nbTitle.trim() }) });
        const row = j.row;
        setLists((m) => ({ ...m, [src]: [...cur, row] }));
        setForm((f) => ({ ...f, ListRef: String(row.CodeId), PartyRef: "", BranchRef: "", Title: nbTitle.trim() }));
        setMsg({ t: "ok", s: `${oneOf(srcLabel)} جدید ثبت شد و به این تفصیلی منتسب گردید` });
      }
      setNbTitle(""); setNbOpen(false);
    } catch (e: any) { setMsg({ t: "err", s: e.message }); }
    setNbBusy(false);
  };

  const save = async () => {
    if (!form.TafsiliTypeId) { setMsg({ t: "err", s: "نوع تفصیل را انتخاب کنید" }); return; }
    if (!String(form.Title).trim()) { setMsg({ t: "err", s: "عنوان تفصیلی الزامی است" }); return; }
    setBusy(true); setMsg(null);
    try {
      const body = {
        Code: String(form.Code).trim(), TafsiliTypeId: form.TafsiliTypeId,
        Title: String(form.Title).trim(), LatinTitle: String(form.LatinTitle || "").trim(),
        IsActive: form.IsActive,
        PartyRef: isParty && form.PartyRef ? form.PartyRef : "",
        BranchRef: isBranch && form.BranchRef ? form.BranchRef : "",
        ListRef: isList && form.ListRef ? form.ListRef : "",
      };
      if (editId) await api("/api/acc/tafsili", { method: "PUT", body: JSON.stringify({ id: editId, ...body }) });
      else await api("/api/acc/tafsili", { method: "POST", body: JSON.stringify(body) });
      setMsg({ t: "ok", s: editId ? "اصلاح انجام شد" : "ثبت شد" });
      const rws = await load();
      blank(rws);
    } catch (e: any) { setMsg({ t: "err", s: e.message }); }
    setBusy(false);
  };

  const edit = (r: any) => {
    setForm({
      Code: String(r.Code ?? ""), TafsiliTypeId: String(r.TafsiliTypeId ?? ""),
      Title: String(r.Title ?? ""), LatinTitle: String(r.LatinTitle ?? ""),
      IsActive: r.IsActive ? "1" : "0",
      PartyRef: r.PartyRef ? String(r.PartyRef) : "",
      BranchRef: r.BranchRef ? String(r.BranchRef) : "",
      ListRef: r.ListRef ? String(r.ListRef) : "",
    });
    setEditId(r.id ?? r.TafsiliId);
    setNpOpen(false); setNbOpen(false); setFilter("");
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  const del = async (r: any) => {
    const id = r.id ?? r.TafsiliId;
    if (!id) return;
    if (!confirm("این تفصیلی حذف شود؟")) return;
    try { await api(`/api/acc/tafsili?id=${id}`, { method: "DELETE" }); await load(); if (!editId) blank(); }
    catch (e: any) { setMsg({ t: "err", s: e.message }); }
  };

  const typeTitle = (id: any) => types.find((t) => String(t.TafsiliTypeId) === String(id))?.Title ?? id;
  const srcOf = (r: any) =>
    r.PartyTitle || [r.PartyFName, r.PartyLName].filter(Boolean).join(" ") || r.BranchTitle || r.ListTitle || "";

  const hasList = isParty || isBranch || isList;

  return (
    <Shell title="معرفی حساب‌های تفصیلی" sub="بر اساس نوع تفصیل، فهرست مبدأ همان نوع — با تعریف رکورد جدید از همین‌جا">
      {!ready ? <p className="muted">…</p>
        : !types.length ? <p className="muted">ابتدا در «انواع تفصیل» نوع تعریف کنید.</p>
        : <>
      {msg && <div className={`msg ${msg.t}`}>{msg.s}</div>}

      <div className="form-grid">
        <div className="field">
          <label>کد تفصیلی (۸ رقم) *</label>
          <input value={form.Code} onChange={(e) => setForm({ ...form, Code: e.target.value })}
            style={{ direction: "ltr", textAlign: "left" }} />
        </div>
        <div className="field">
          <label>نوع تفصیل *</label>
          <select value={form.TafsiliTypeId} onChange={(e) => pickType(e.target.value)}>
            <option value="">—</option>
            {types.map((t) => <option key={t.TafsiliTypeId} value={t.TafsiliTypeId}>{t.Title}</option>)}
          </select>
        </div>

        {/* فهرست مبدأ بر اساس نوع — برای همهٔ انواعِ متصل */}
        {hasList && (
          <div className="field" style={{ gridColumn: "span 2" }}>
            <label>انتخاب از فهرست {srcLabel}{isParty && form.PartyRef ? " ✓" : (isBranch && form.BranchRef) || (isList && form.ListRef) ? " ✓" : ""}</label>
            <div style={{ display: "flex", gap: 6 }}>
              <select value={isParty ? form.PartyRef : isBranch ? form.BranchRef : form.ListRef}
                onChange={(e) => pickFromList(e.target.value)} style={{ flex: 1 }}>
                <option value="">— انتخاب از فهرست {srcLabel} ({fa(options.length)}) —</option>
                {options.map((o) => <option key={o.v} value={o.v}>{o.t}</option>)}
              </select>
              <button type="button" className="btn" onClick={() => { setNpOpen(isParty ? !npOpen : false); setNbOpen(!isParty ? !nbOpen : false); }}>
                + تعریف {isParty ? "شخص" : oneOf(srcLabel)} جدید
              </button>
            </div>
            {options.length > 8 && (
              <input placeholder={`جستجو در ${srcLabel}…`}
                value={filter} onChange={(e) => setFilter(e.target.value)} />
            )}
          </div>
        )}
        {isFree && (
          <div className="field" style={{ gridColumn: "span 2" }}>
            <p className="muted" style={{ margin: 0 }}>این نوع فهرست مبدأ ندارد — عنوان تفصیلی را آزاد وارد کنید.</p>
          </div>
        )}

        <div className="field">
          <label>عنوان تفصیلی *{hasList && (form.PartyRef || form.BranchRef || form.ListRef) ? " (از مبدأ انتخابی)" : ""}</label>
          <input value={form.Title} onChange={(e) => setForm({ ...form, Title: e.target.value })} />
        </div>
        <div className="field">
          <label>عنوان لاتین</label>
          <input value={form.LatinTitle} onChange={(e) => setForm({ ...form, LatinTitle: e.target.value })}
            style={{ direction: "ltr", textAlign: "left" }} />
        </div>
        <div className="field">
          <label>وضعیت</label>
          <select value={form.IsActive} onChange={(e) => setForm({ ...form, IsActive: e.target.value })}>
            <option value="1">فعال</option>
            <option value="0">غیرفعال</option>
          </select>
        </div>
      </div>

      {/* پنل تعریف شخص جدید درجا */}
      {isParty && npOpen && (
        <div className="edit-card" style={{ marginBottom: 10 }}>
          <div className="card-title">تعریف شخص/شرکت جدید — پس از ثبت، به همین تفصیلی منتسب می‌شود</div>
          <div className="form-grid">
            <div className="field">
              <label>نوع</label>
              <select value={np.RecType} onChange={(e) => setNp({ ...np, RecType: e.target.value })}>
                <option value="MAN">شخص حقیقی</option>
                <option value="CMP">شرکت / شخص حقوقی</option>
              </select>
            </div>
            {np.RecType === "MAN" ? (
              <>
                <div className="field"><label>نام *</label>
                  <input value={np.FName} onChange={(e) => setNp({ ...np, FName: e.target.value })} /></div>
                <div className="field"><label>نام خانوادگی *</label>
                  <input value={np.LName} onChange={(e) => setNp({ ...np, LName: e.target.value })} /></div>
              </>
            ) : (
              <div className="field"><label>عنوان شرکت *</label>
                <input value={np.Title} onChange={(e) => setNp({ ...np, Title: e.target.value })} /></div>
            )}
            <div className="field"><label>کد/شناسه ملی</label>
              <input value={np.NationalCode} onChange={(e) => setNp({ ...np, NationalCode: e.target.value })} /></div>
            <div className="field"><label>کد اقتصادی</label>
              <input value={np.EconCode} onChange={(e) => setNp({ ...np, EconCode: e.target.value })} /></div>
          </div>
          <div className="btnrow">
            <button className="btn primary" onClick={submitParty} disabled={npBusy}>{npBusy ? "…" : "ثبت شخص"}</button>
            <button className="btn" onClick={() => setNpOpen(false)}>انصراف</button>
          </div>
        </div>
      )}

      {/* پنل تعریف رکورد جدید در فهرست مبدأ (شعبه/فهرست کد) */}
      {(isBranch || isList) && nbOpen && (
        <div className="edit-card" style={{ marginBottom: 10 }}>
          <div className="card-title">تعریف {isParty ? "شخص/شرکت" : oneOf(srcLabel)} جدید — پس از ثبت، به همین تفصیلی منتسب می‌شود</div>
          <div className="form-grid">
            <div className="field"><label>عنوان {oneOf(srcLabel)} *</label>
              <input value={nbTitle} onChange={(e) => setNbTitle(e.target.value)} /></div>
          </div>
          <div className="btnrow">
            <button className="btn primary" onClick={submitNb} disabled={nbBusy}>{nbBusy ? "…" : "ثبت"}</button>
            <button className="btn" onClick={() => setNbOpen(false)}>انصراف</button>
          </div>
        </div>
      )}

      <div className="btnrow">
        <button className="btn primary" onClick={save} disabled={busy}>{editId ? "اصلاح" : "ثبت"}</button>
        {editId ? <button className="btn" onClick={() => blank()}>انصراف</button>
          : <button className="btn" onClick={() => blank()}>جدید</button>}
      </div>

      <div className="scrollbox">
        <table className="grid">
          <thead><tr>
            <th style={{ width: 105 }}>کد تفصیلی</th>
            <th style={{ width: 130 }}>نوع تفصیل</th>
            <th>عنوان تفصیلی</th>
            <th style={{ width: 190 }}>مبدأ مرتبط</th>
            <th style={{ width: 150 }}>عنوان لاتین</th>
            <th style={{ width: 80 }}>وضعیت</th>
            <th style={{ width: 110 }}>عملیات</th>
          </tr></thead>
          <tbody>
            {rows.map((r, i) => (
              <tr key={r.id ?? r.TafsiliId ?? i}>
                <td className="num" style={{ direction: "ltr" }}>{r.Code}</td>
                <td>{typeTitle(r.TafsiliTypeId)}</td>
                <td>{r.Title}</td>
                <td>{srcOf(r) || <span className="muted">—</span>}</td>
                <td style={{ direction: "ltr" }}>{r.LatinTitle ?? ""}</td>
                <td>{r.IsActive ? "بله" : "خیر"}</td>
                <td>
                  <button className="btn" onClick={() => edit(r)} style={{ padding: "1px 8px" }}>اصلاح</button>{" "}
                  <button className="btn danger" onClick={() => del(r)} style={{ padding: "1px 8px" }}>حذف</button>
                </td>
              </tr>
            ))}
            {!rows.length && <tr><td colSpan={7} className="muted" style={{ textAlign: "center", padding: 20 }}>رکوردی نیست</td></tr>}
          </tbody>
        </table>
      </div>
      <p className="muted" style={{ marginTop: 6 }}>تعداد رکوردها: {fa(rows.length)}</p>
      <p className="muted" style={{ marginTop: 2 }}>
        بر اساس نوع تفصیل، فهرست مبدأ همان نوع نمایش داده می‌شود و تعریف رکورد جدید همان نوع از همین پنجره ممکن است —
        اشخاص، بانک‌ها، شعبه‌ها، پروژه‌ها، صندوق‌ها، مراکز هزینه، کارمندها، کالاها، چک‌ها و اعتبارات اسنادی؛
        انواع بدون مبدأ (مانند «سایر») عنوان آزاد دارند.
        تنظیم فهرست مبدأ هر نوع در پنجرهٔ «انواع تفصیل».
      </p>
        </>}
    </Shell>
  );
}
