"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import Shell from "@/components/Shell";
import { api, fa } from "@/lib/ui";

/* [فرم اصلی: معرفي حسابهاي تفصيل — کد، عنوان، نوع تفصيل، عنوان لاتين، وضعيت]
   v2.4.2 — انتخاب نوع‌محور: بر اساس «فهرست مبدأ» نوع تفصیل (AccTafsiliType.CodeListType)
   به‌جای عنوان آزاد، همان فهرست نمایش داده می‌شود:
     PARTY  → فهرست اشخاص و شرکت‌ها (pob.Party) + تعریف شخص جدید درجا
     BANK   → فهرست بانک‌ها (pob.CodeList → Type=BANK) + تعریف بانک جدید درجا
     BRANCH → فهرست شعبه‌ها (ACC.AccBranch) + تعریف شعبه جدید درجا
     خالی   → عنوان آزاد (مانند نوع «سایر»)
   تفصیلیِ نوعِ اشخاصی به pob.Party پیوند می‌خورد (AccTafsili.PartyRef). */

const CLS_FA: Record<string, string> = { PARTY: "اشخاص و شرکت‌ها", BANK: "بانک‌ها", BRANCH: "شعبه‌ها" };

const partyLabel = (p: any) =>
  p?.Title || [p?.FName, p?.LName].filter(Boolean).join(" ") || `شخص #${p?.Serial ?? ""}`;

export default function Page() {
  const [types, setTypes] = useState<any[]>([]);
  const [rows, setRows] = useState<any[]>([]);
  const [parties, setParties] = useState<any[]>([]);
  const [banks, setBanks] = useState<any[]>([]);
  const [branches, setBranches] = useState<any[]>([]);
  const [ready, setReady] = useState(false);

  const [form, setForm] = useState<Record<string, string>>({
    Code: "", TafsiliTypeId: "", Title: "", LatinTitle: "", IsActive: "1", PartyRef: "",
  });
  const [editId, setEditId] = useState<number | null>(null);
  const [msg, setMsg] = useState<{ t: "err" | "ok"; s: string } | null>(null);
  const [busy, setBusy] = useState(false);

  /* جستجو در فهرست اشخاص */
  const [partyFilter, setPartyFilter] = useState("");

  /* تعریف شخص جدید درجا */
  const [npOpen, setNpOpen] = useState(false);
  const [np, setNp] = useState<Record<string, string>>({
    RecType: "MAN", FName: "", LName: "", Title: "", NationalCode: "", EconCode: "",
  });
  const [npBusy, setNpBusy] = useState(false);

  /* تعریف بانک/شعبه جدید درجا */
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
    api("/api/gen/lookup?t=BANK").then((j) => setBanks(j.rows || [])).catch(() => {});
    api("/api/acc/branch").then((j) => setBranches(j.rows || [])).catch(() => {});
  }, []);

  /* کد پیشنهادی — ماکزیمم کد فعلی شرکت + ۱ (یکتایی کد در سطح شرکت است) */
  const suggestCode = useCallback((list: any[]) =>
    String(list.reduce((m, r) => Math.max(m, Number(r.Code) || 0), 0) + 1).padStart(8, "0"), []);

  const blank = useCallback((list?: any[]) => {
    const src = list ?? rows;
    setForm({ Code: suggestCode(src), TafsiliTypeId: "", Title: "", LatinTitle: "", IsActive: "1", PartyRef: "" });
    setEditId(null); setPartyFilter(""); setNpOpen(false); setNbOpen(false); setNbTitle("");
  }, [rows, suggestCode]);

  useEffect(() => {
    (async () => {
      const rws = await load();
      await loadAux();
      setForm({ Code: suggestCode(rws), TafsiliTypeId: "", Title: "", LatinTitle: "", IsActive: "1", PartyRef: "" });
      setReady(true);
    })();
  }, [load, loadAux, suggestCode]);

  /* نوع انتخاب‌شده و مبدأ آن */
  const selType = types.find((t) => String(t.TafsiliTypeId) === String(form.TafsiliTypeId || ""));
  const src = String(selType?.CodeListType || "").trim().toUpperCase();
  const isParty = src === "PARTY";
  const isBank = src === "BANK";
  const isBranch = src === "BRANCH";
  const isFree = !isParty && !isBank && !isBranch;   /* مثل «سایر» و «پروژه» */

  /* گزینه‌های فهرست اشخاص با فیلتر جستجو */
  const partyOptions = useMemo(() => {
    const s = partyFilter.trim().toLowerCase();
    const list = s
      ? parties.filter((p) => partyLabel(p).toLowerCase().includes(s) || String(p.NationalCode || "").includes(s) || String(p.EconCode || "").includes(s))
      : parties;
    return list.slice(0, 500).map((p) => ({ v: String(p.Serial), t: partyLabel(p) }));
  }, [parties, partyFilter]);

  const pickType = (v: string) => {
    setForm((f) => ({ ...f, TafsiliTypeId: v, PartyRef: "" }));
    setNpOpen(false); setNbOpen(false); setPartyFilter("");
  };

  const pickParty = (v: string) => {
    if (!v) { setForm((f) => ({ ...f, PartyRef: "" })); return; }
    const p = parties.find((x) => String(x.Serial) === v);
    setForm((f) => ({ ...f, PartyRef: v, Title: p ? partyLabel(p) : f.Title }));
  };

  const pickFromList = (v: string) => {
    if (!v) return;
    if (isBank) {
      const b = banks.find((x) => String(x.CodeId) === v);
      if (b) setForm((f) => ({ ...f, Title: b.Title }));
    } else if (isBranch) {
      const b = branches.find((x) => String(x.BranchId) === v);
      if (b) setForm((f) => ({ ...f, Title: b.Title }));
    }
  };

  /* ثبت شخص جدید از همان پنجره — سپس انتساب به تفصیلی */
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
      setForm((f) => ({ ...f, PartyRef: String(p.Serial), Title: partyLabel(p) }));
      setNp({ RecType: np.RecType, FName: "", LName: "", Title: "", NationalCode: "", EconCode: "" });
      setNpOpen(false);
      setMsg({ t: "ok", s: "شخص جدید ثبت شد و به این تفصیلی منتسب گردید" });
    } catch (e: any) { setMsg({ t: "err", s: e.message }); }
    setNpBusy(false);
  };

  /* ثبت بانک/شعبه جدید از همان پنجره */
  const submitNb = async () => {
    if (!nbTitle.trim()) { setMsg({ t: "err", s: "عنوان الزامی است" }); return; }
    setNbBusy(true); setMsg(null);
    try {
      if (isBank) {
        const next = banks.reduce((m, b) => Math.max(m, Number(b.Code) || 0), 0) + 1;
        const j = await api("/api/gen/lookup", { method: "POST", body: JSON.stringify({ Type: "BANK", Code: next, Title: nbTitle.trim() }) });
        setBanks((bs) => [...bs, j.row]);
      } else if (isBranch) {
        const next = branches.reduce((m, b) => Math.max(m, Number(b.Code) || 0), 0) + 1;
        const j = await api("/api/acc/branch", { method: "POST", body: JSON.stringify({ Code: String(next).slice(0, 10), Title: nbTitle.trim(), IsActive: 1 }) });
        setBranches((bs) => [...bs, j.row]);
      }
      setForm((f) => ({ ...f, Title: nbTitle.trim() }));
      setNbTitle(""); setNbOpen(false);
      setMsg({ t: "ok", s: isBank ? "بانک جدید ثبت شد" : "شعبه جدید ثبت شد" });
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
    });
    setEditId(r.id ?? r.TafsiliId);
    setNpOpen(false); setNbOpen(false); setPartyFilter("");
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
  const partyOf = (r: any) => r.PartyTitle || [r.PartyFName, r.PartyLName].filter(Boolean).join(" ");

  return (
    <Shell title="معرفی حساب‌های تفصیلی" sub="کد تفصیلی هشترقمی — انتخاب از فهرست مبدأ بر اساس نوع تفصیل">
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

        {/* فهرست مبدأ بر اساس نوع — اشخاص */}
        {isParty && (
          <div className="field" style={{ gridColumn: "span 2" }}>
            <label>انتخاب شخص/شرکت از فهرست اشخاص</label>
            <div style={{ display: "flex", gap: 6 }}>
              <select value={form.PartyRef} onChange={(e) => pickParty(e.target.value)} style={{ flex: 1 }}>
                <option value="">— انتخاب از فهرست اشخاص ({fa(parties.length)}) —</option>
                {partyOptions.map((o) => <option key={o.v} value={o.v}>{o.t}</option>)}
              </select>
              <button type="button" className="btn" onClick={() => { setNpOpen(!npOpen); setNbOpen(false); }}>+ تعریف شخص جدید</button>
            </div>
            {parties.length > 8 && (
              <input placeholder="جستجو در اشخاص (عنوان / کد ملی / کد اقتصادی)…"
                value={partyFilter} onChange={(e) => setPartyFilter(e.target.value)} />
            )}
          </div>
        )}

        {/* فهرست مبدأ — بانک‌ها / شعبه‌ها */}
        {(isBank || isBranch) && (
          <div className="field" style={{ gridColumn: "span 2" }}>
            <label>انتخاب {isBank ? "بانک" : "شعبه"} از فهرست</label>
            <div style={{ display: "flex", gap: 6 }}>
              <select value="" onChange={(e) => pickFromList(e.target.value)} style={{ flex: 1 }}>
                <option value="">— انتخاب {isBank ? "بانک" : "شعبه"} — عنوان در فیلد بعدی درج می‌شود —</option>
                {isBank && banks.map((b) => <option key={b.CodeId} value={b.CodeId}>{b.Title}</option>)}
                {isBranch && branches.map((b) => <option key={b.BranchId} value={b.BranchId}>{b.Code ? `${b.Code} — ${b.Title}` : b.Title}</option>)}
              </select>
              <button type="button" className="btn" onClick={() => { setNbOpen(!nbOpen); setNpOpen(false); }}>+ تعریف {isBank ? "بانک" : "شعبه"} جدید</button>
            </div>
          </div>
        )}

        <div className="field">
          <label>عنوان تفصیلی *{isParty && form.PartyRef ? " (از شخص انتخابی)" : ""}</label>
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

      {/* پنل تعریف بانک/شعبه جدید درجا */}
      {(isBank || isBranch) && nbOpen && (
        <div className="edit-card" style={{ marginBottom: 10 }}>
          <div className="card-title">تعریف {isBank ? "بانک" : "شعبه"} جدید — پس از ثبت، عنوان به تفصیلی درج می‌شود</div>
          <div className="form-grid">
            <div className="field"><label>عنوان {isBank ? "بانک" : "شعبه"} *</label>
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
            <th style={{ width: 190 }}>شخص/شرکت مرتبط</th>
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
                <td>{partyOf(r) || <span className="muted">—</span>}</td>
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
        بر اساس نوع تفصیل، فهرست مبدأ نمایش داده می‌شود — اشخاص، بانک‌ها، شعبه‌ها؛ انواع بدون مبدأ (مانند «سایر» و «پروژه») عنوان آزاد دارند.
        تفصیلی به معین وصل نیست؛ نوع تفصیل آن باید با یکی از سطوح ۴/۵/۶ معین هم‌خوان باشد تا در سند پذیرفته شود.
        تنظیم فهرست مبدأ هر نوع در پنجرهٔ «انواع تفصیل».
      </p>
        </>}
    </Shell>
  );
}
