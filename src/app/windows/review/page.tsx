"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import Shell from "@/components/Shell";
import { CtxGate, useApp } from "@/components/App";
import { api, fa, exportCsv } from "@/lib/ui";
import { VoucherDetailCard, VchDetail, fetchVoucher } from "@/components/VoucherDetail";

/* ============================================================================
   مرور حساب‌ها — بازنویسی کامل از صفر مطابق AcVwDef.BPL (v2.1.0)
   [فرم اصلی: مرور حسابها — TFrRemRep]
   • درخت حساب‌ها با گردش/ماندهٔ هر سطح + جست‌وجو + فقط حساب‌های بامانده + جمع مبالغ
   • محدودهٔ اسناد: سال از/تا، ماه از/تا، تاریخ از/تا، شماره سند از/تا، نوع سند،
     افتتاحیه/اختتامیه/عادی، شعبه + اعمال فيلتر
   • گردش حساب: كامل / خلاصه با احتساب مانده ابتدا / خلاصه بدون احتساب
   • جهت گردش: بدهكار / بستانكار / بدهكار و بستانكار
   • مانده در خط (با احتساب مانده قبل از دوره) — کلید روشن/خاموش
   • سند: نمایش سند از هر ردیف گردش (دکمهٔ «سند» در فرم اصلی)
   • تراز حساب: گردش تا این دوره / گردش دوره / گردش تا پایان دوره / مانده
   • آناليز حسابها: گروه‌بندی تفصیلی ۴/۵/۶ + آناليزشده/آناليزنشده + ریز آناليز
   • گردش ارز و مانده ارزی (TAccCurFlow)
   • صدور اعلاميه از اقلام انتخابی + Excel
   ============================================================================ */

interface Sel { level: "kol" | "moein" | "dl"; code: string; dlLevel: number; dlId: number; title: string }

export default function Page() {
  const app = useApp();
  const [tab, setTab] = useState<"card" | "balance" | "analys" | "fx">("card");
  const [err, setErr] = useState("");

  /* ---- درخت ---- */
  const [tree, setTree] = useState<any>({ groups: [], kols: [], moeins: [] });
  const [q, setQ] = useState("");
  const [onlyBal, setOnlyBal] = useState(false);
  const [expanded, setExpanded] = useState<Set<string>>(new Set());
  const [sums, setSums] = useState({ D: 0, C: 0 });

  /* ---- انتخاب ---- */
  const [sel, setSel] = useState<Sel | null>(null);
  const [dlLevel, setDlLevel] = useState(0);
  const [dlId, setDlId] = useState(0);
  const [tafsilis, setTafsilis] = useState<any[]>([]);

  /* ---- محدوده اسناد ---- */
  const [from, setFrom] = useState(""); const [to, setTo] = useState("");
  const [yFrom, setYFrom] = useState(""); const [yTo, setYTo] = useState("");
  const [mFrom, setMFrom] = useState(""); const [mTo, setMTo] = useState("");
  const [noFrom, setNoFrom] = useState(""); const [noTo, setNoTo] = useState("");
  const [vchType, setVchType] = useState(""); const [kind, setKind] = useState("");
  const [branch, setBranch] = useState("");
  const [dir, setDir] = useState("dc");
  const [display, setDisplay] = useState("full");
  const [runBal, setRunBal] = useState(true);
  const [vchTypes, setVchTypes] = useState<any[]>([]);
  const [branches, setBranches] = useState<any[]>([]);

  /* ---- داده‌ها ---- */
  const [card, setCard] = useState<any | null>(null);
  const [bal, setBal] = useState<any | null>(null);
  const [analys, setAnalys] = useState<any | null>(null);
  const [aGroup, setAGroup] = useState(1);
  const [aAnalysed, setAAnalysed] = useState("all");
  const [fx, setFx] = useState<any | null>(null);
  const [fxBal, setFxBal] = useState(false);
  const [busy, setBusy] = useState(false);

  /* ---- انتخاب اقلام برای اعلاميه ---- */
  const [picked, setPicked] = useState<Set<number>>(new Set());
  const [noteDlg, setNoteDlg] = useState(false);
  const [noteDate, setNoteDate] = useState("");
  const [noteTitle, setNoteTitle] = useState("");
  const [noteMsg, setNoteMsg] = useState("");

  /* ---- سند ---- */
  const [vch, setVch] = useState<VchDetail | null>(null);

  const todayFa = () => new Intl.DateTimeFormat("fa-IR-u-nu-latn", { calendar: "persian" })
    .format(new Date()).replace(/\//g, "/");

  const loadTree = useCallback(async (search = q, only = onlyBal) => {
    try {
      const p = new URLSearchParams(); if (search) p.set("q", search); if (only) p.set("onlyBal", "1");
      const j = await api(`/api/review?mode=tree&${p}`);
      setTree({ groups: j.groups || [], kols: j.kols || [], moeins: j.moeins || [] });
      let D = 0, C = 0;
      for (const g of j.groups || []) { D += Number(g.D); C += Number(g.C); }
      setSums({ D, C });
      setErr("");
    } catch (e: any) { setErr(e.message); }
  }, [q, onlyBal]);

  useEffect(() => {
    if (app.ctxMissing) return;
    loadTree();
    api("/api/acc/tafsili").then((j) => setTafsilis(j.rows || [])).catch(() => {});
    api("/api/acc/vchtypes").then((j) => setVchTypes(j.rows || [])).catch(() => {});
    api("/api/acc/branch").then((j) => setBranches(j.rows || [])).catch(() => {});
  }, [app.companyId, app.yearId]); /* eslint-disable-line react-hooks/exhaustive-deps */

  /* سال مالی پیش‌فرض برای فیلتر سال */
  useEffect(() => {
    if (app.year?.JalaliYear && !yFrom && !yTo) {
      setYFrom(String(app.year.JalaliYear));
      setYTo(String(app.year.JalaliYear));
    }
  }, [app.year?.JalaliYear]); /* eslint-disable-line react-hooks/exhaustive-deps */

  const rangeParams = useCallback(() => {
    const p = new URLSearchParams();
    if (from) p.set("from", from); if (to) p.set("to", to);
    if (yFrom) p.set("yFrom", yFrom); if (yTo) p.set("yTo", yTo);
    if (mFrom) p.set("mFrom", mFrom); if (mTo) p.set("mTo", mTo);
    if (noFrom) p.set("noFrom", noFrom); if (noTo) p.set("noTo", noTo);
    if (vchType) p.set("vchType", vchType); if (kind) p.set("kind", kind);
    if (branch) p.set("branch", branch);
    p.set("dir", dir); p.set("display", display); p.set("runBal", runBal ? "1" : "0");
    return p;
  }, [from, to, yFrom, yTo, mFrom, mTo, noFrom, noTo, vchType, kind, branch, dir, display, runBal]);

  const accParams = useCallback((s: Sel) => {
    const p = new URLSearchParams();
    p.set("level", s.level);
    if (s.level === "dl") { p.set("dlLevel", String(s.dlLevel)); p.set("dlId", String(s.dlId)); }
    else p.set("code", s.code);
    return p;
  }, []);

  const loadCard = useCallback(async (s: Sel) => {
    if (!s) return;
    setBusy(true);
    try {
      const p = rangeParams(); for (const [k, v] of accParams(s)) p.set(k, v);
      const j = await api(`/api/review?mode=card&${p}`);
      setCard(j); setErr("");
    } catch (e: any) { setErr(e.message); setCard(null); }
    setBusy(false);
  }, [rangeParams, accParams]);

  const loadBalance = useCallback(async (s: Sel) => {
    if (!s) return;
    try {
      const p = new URLSearchParams();
      if (from) p.set("from", from); if (to) p.set("to", to);
      if (vchType) p.set("vchType", vchType); if (kind) p.set("kind", kind); if (branch) p.set("branch", branch);
      for (const [k, v] of accParams(s)) p.set(k, v);
      setBal(await api(`/api/review?mode=balance&${p}`));
    } catch (e: any) { setErr(e.message); setBal(null); }
  }, [from, to, vchType, kind, branch, accParams]);

  const loadAnalys = useCallback(async (s: Sel, grp = aGroup, ana = aAnalysed) => {
    if (!s || s.level === "dl") return;
    try {
      const p = new URLSearchParams();
      p.set("level", s.level); p.set("code", s.code); p.set("group", String(grp)); p.set("analysed", ana);
      if (from) p.set("from", from); if (to) p.set("to", to);
      setAnalys(await api(`/api/review?mode=analys&${p}`));
    } catch (e: any) { setErr(e.message); setAnalys(null); }
  }, [aGroup, aAnalysed, from, to]);

  const loadFx = useCallback(async (s: Sel, balance: boolean) => {
    if (!s || s.level !== "moein") return;
    try {
      const p = new URLSearchParams();
      p.set("mode", balance ? "fxbal" : "fx"); p.set("code", s.code);
      if (from) p.set("from", from); if (to) p.set("to", to);
      setFx(await api(`/api/review?${p}`));
    } catch (e: any) { setErr(e.message); setFx(null); }
  }, [from, to]);

  const pick = useCallback((s: Sel) => {
    setSel(s); setPicked(new Set()); setCard(null); setBal(null); setAnalys(null); setFx(null);
    if (s.level === "moein") {
      const m = tree.moeins.find((x: any) => String(x.MoeinCode) === s.code);
      const t3 = m?.Taf3TypeId, t2 = m?.Taf2TypeId, t1 = m?.Taf1TypeId;
      const lv = t1 ? 1 : 0; /* سطح ۴ پیش‌فرض */
      setDlLevel(t1 ? 1 : t2 ? 2 : t3 ? 3 : 0);
      void lv;
    } else setDlLevel(0);
    if (tab === "balance") loadBalance(s);
    else if (tab === "analys") loadAnalys(s);
    else if (tab === "fx") loadFx(s, fxBal);
    else loadCard(s);
  }, [tab, tree.moeins, fxBal, loadCard, loadBalance, loadAnalys, loadFx]);

  const applyFilter = useCallback(() => {
    if (!sel) return;
    if (tab === "balance") loadBalance(sel);
    else if (tab === "analys") loadAnalys(sel);
    else if (tab === "fx") loadFx(sel, fxBal);
    else loadCard(sel);
  }, [sel, tab, fxBal, loadCard, loadBalance, loadAnalys, loadFx]);

  /* تغییر برگه — دادهٔ همان برگه بارگذاری شود */
  const switchTab = (t: typeof tab) => {
    setTab(t);
    if (!sel) return;
    if (t === "balance") loadBalance(sel);
    else if (t === "analys") { if (sel.level !== "dl") loadAnalys(sel); }
    else if (t === "fx") { if (sel.level === "moein") loadFx(sel, fxBal); }
    else loadCard(sel);
  };

  const openVoucher = async (id: number) => {
    try { setVch(await fetchVoucher(id)); } catch (e: any) { setErr(e.message); }
  };

  /* نگاشت lineId → voucherId برای صدور اعلاميه */
  const pickedVoucher = useMemo(() => {
    const m = new Map<number, number>();
    (card?.rows || []).forEach((r: any) => { if (r.LineId) m.set(Number(r.LineId), Number(r.VoucherId)); });
    return m;
  }, [card]);

  const togglePick = (lineId: number) => {
    const s = new Set(picked);
    if (s.has(lineId)) s.delete(lineId); else s.add(lineId);
    setPicked(s);
  };

  const excel = () => {
    if (!card || !card.rows?.length) return;
    const isSum = card.display !== "full";
    const headers = isSum
      ? ["تاریخ", "شماره سند", "نوع سند", "شرح", "بدهکار", "بستانکار", "مانده"]
      : ["تاریخ", "شماره سند", "نوع سند", "کد کل", "شرح کل", "کد معین", "شرح معین",
         "تفصیلی ۴", "تفصیلی ۵", "تفصیلی ۶", "شرح ردیف", "بدهکار", "بستانکار", "مانده"];
    const rows = card.rows.map((r: any) => isSum
      ? [r.VchDate, r.VchNo, r.TypeTitle || "", r.VchDescr || "", Number(r.D), Number(r.C), Number(r.Balance)]
      : [r.VchDate, r.VchNo, r.TypeTitle || "", r.KolCode, r.KolTitle, r.MoeinCode, r.MoeinTitle,
         r.Taf1Title || "", r.Taf2Title || "", r.Taf3Title || "", r.ItmDescr || r.VchDescr || "",
         Number(r.Dbt), Number(r.Crt), Number(r.Balance)]);
    const name = sel ? `گردش-${sel.level === "dl" ? `تفصیلی${dlId}` : sel.code}` : "گردش";
    exportCsv(`${name}.csv`, headers, rows);
  };

  const issueNote = async () => {
    setNoteMsg("");
    try {
      const items = [...picked].map((lineId) => ({ voucherId: pickedVoucher.get(lineId) || 0, lineId }));
      const j = await api("/api/note", {
        method: "POST",
        body: JSON.stringify({ noteDate: noteDate || todayFa(), title: noteTitle, moeinCode: sel?.level === "moein" ? sel.code : "", items }),
      });
      setNoteDlg(false); setPicked(new Set()); setNoteMsg("");
      alert(`اعلاميه شمارهٔ ${fa(j.noteNo)} صادر شد — در «نمایش اعلامیه‌ها» قابل مشاهده است.`);
    } catch (e: any) { setNoteMsg(e.message); }
  };

  /* ---------------- درخت ---------------- */
  const groupsOf = useMemo(() => {
    const kolsByG = new Map<string, any[]>();
    tree.kols.forEach((k: any) => {
      const key = String(k.GroupCode ?? "");
      if (!kolsByG.has(key)) kolsByG.set(key, []);
      kolsByG.get(key)!.push(k);
    });
    return tree.groups.map((g: any) => ({ g, kols: kolsByG.get(String(g.GroupCode)) || [] }));
  }, [tree]);

  const moeinsOf = useMemo(() => {
    const m = new Map<string, any[]>();
    tree.moeins.forEach((x: any) => {
      const key = String(x.KolCode);
      if (!m.has(key)) m.set(key, []);
      m.get(key)!.push(x);
    });
    return m;
  }, [tree]);

  return (
    <Shell title="مرور حساب‌ها" sub="مطابق فایل اصلی AcVwDef — درخت شش‌سطحی، گردش، تراز، آناليز، ارز، اعلاميه">
      <CtxGate>
        <div className="tabs">
          <button className={`tab ${tab === "card" ? "active" : ""}`} onClick={() => switchTab("card")}>مرور حسابها</button>
          <button className={`tab ${tab === "balance" ? "active" : ""}`} onClick={() => switchTab("balance")}>تراز حساب</button>
          <button className={`tab ${tab === "analys" ? "active" : ""}`} onClick={() => switchTab("analys")}>آناليز حسابها</button>
          <button className={`tab ${tab === "fx" ? "active" : ""}`} onClick={() => switchTab("fx")}>گردش و مانده ارز</button>
        </div>

        {err && <div className="msg err">{err}</div>}
        {!sel && !err && (
          <div className="msg ok">یک حساب را از درخت انتخاب کنید — روی معین کلیک کنید؛ «گردش کل» برای کارت کل؛ دوبار کلیک روی کل هم کارت کل را باز می‌کند.</div>
        )}

        <div style={{ display: "grid", gridTemplateColumns: "1.15fr 2fr", gap: 12, alignItems: "start" }}>
          {/* ================= ستون راست: درخت حساب‌ها ================= */}
          <div>
            <div className="filterbar">
              <input className="search" placeholder="جست‌وجوی کد/عنوان حساب…" value={q}
                onChange={(e) => setQ(e.target.value)}
                onKeyDown={(e) => { if (e.key === "Enter") loadTree(q, onlyBal); }} />
              <button className="btn" onClick={() => loadTree(q, onlyBal)}>جست‌وجو</button>
              <button className={`btn ghost ${onlyBal ? "active" : ""}`}
                onClick={() => { const v = !onlyBal; setOnlyBal(v); loadTree(q, v); }}
                title="فقط حساب‌های با مانده [فرم: حسابهاي بامانده]">فقط بامانده</button>
            </div>
            <div className="scrollbox" style={{ maxHeight: "58vh" }}>
              <div className="tree" style={{ padding: 8 }}>
                {groupsOf.map(({ g, kols }: { g: any; kols: any[] }) => {
                  const gKey = `g${g.GroupCode}`;
                  const gOpen = expanded.has(gKey);
                  return (
                    <div key={gKey}>
                      <div className="lv1" style={{ cursor: "pointer", display: "flex", justifyContent: "space-between" }}
                        onClick={() => { const s = new Set(expanded); if (gOpen) s.delete(gKey); else s.add(gKey); setExpanded(s); }}>
                        <span>{gOpen ? "▾" : "▸"} گروه {g.GroupCode} — {g.GroupTitle}</span>
                        <span style={{ fontSize: 11 }}>
                          بد {fa(g.D)} / بس {fa(g.C)}
                        </span>
                      </div>
                      {gOpen && kols.map((k: any) => {
                        const kKey = `k${k.KolCode}`;
                        const kOpen = expanded.has(kKey);
                        const ms = moeinsOf.get(String(k.KolCode)) || [];
                        return (
                          <div key={kKey}>
                            <div className="lv2" style={{ cursor: "pointer", display: "flex", justifyContent: "space-between" }}
                              onClick={() => { const s = new Set(expanded); if (kOpen) s.delete(kKey); else s.add(kKey); setExpanded(s); }}
                              onDoubleClick={() => pick({ level: "kol", code: String(k.KolCode), dlLevel: 0, dlId: 0, title: `کل ${k.KolCode} — ${k.KolTitle}` })}>
                              <span>
                                <b className="ltr">{k.KolCode}</b> {k.KolTitle}
                                <button className="btn ghost" style={{ marginInlineStart: 8, padding: "0 8px", fontSize: 11 }}
                                  onClick={(e) => { e.stopPropagation(); pick({ level: "kol", code: String(k.KolCode), dlLevel: 0, dlId: 0, title: `کل ${k.KolCode} — ${k.KolTitle}` }); }}>
                                  گردش کل
                                </button>
                              </span>
                              <span style={{ fontSize: 11 }}>
                                بد {fa(k.D)} / بس {fa(k.C)}
                              </span>
                            </div>
                            {kOpen && ms.map((m: any) => {
                              const mSel = sel?.level === "moein" && sel.code === String(m.MoeinCode);
                              const net = Number(m.D) - Number(m.C);
                              return (
                                <div key={m.MoeinCode} className="lv3"
                                  style={{ cursor: "pointer", display: "flex", justifyContent: "space-between",
                                           background: mSel ? "#e3eef9" : undefined }}
                                  onClick={() => pick({ level: "moein", code: String(m.MoeinCode), dlLevel: 0, dlId: 0, title: `معین ${m.MoeinCode} — ${m.MoeinTitle}` })}>
                                  <span>
                                    <b className="ltr">{m.MoeinCode}</b> {m.MoeinTitle}
                                    {m.IsFx ? <span className="badge s2" style={{ marginInlineStart: 4, fontSize: 9.5 }}>ارزی</span> : null}
                                    {!m.IsActive ? <span className="badge src" style={{ marginInlineStart: 4, fontSize: 9.5 }}>غیرفعال</span> : null}
                                  </span>
                                  <span style={{ fontSize: 11 }}>
                                    مانده: <b>{fa(Math.abs(net))}</b> {net >= 0 ? "بد" : "بس"}
                                  </span>
                                </div>
                              );
                            })}
                          </div>
                        );
                      })}
                    </div>
                  );
                })}
                {!groupsOf.length && <div className="muted" style={{ padding: 12, textAlign: "center" }}>حسابی برای نمایش نیست</div>}
              </div>
            </div>
            <div className="totalbar">
              <span>جمع مبالغ: بد <b>{fa(sums.D)}</b> · بس <b>{fa(sums.C)}</b> · اختلاف <b>{fa(sums.D - sums.C)}</b></span>
            </div>
          </div>

          {/* ================= ستون چپ: محدوده اسناد + نتیجه ================= */}
          <div>
            <div className="card" style={{ marginBottom: 10 }}>
              <div className="card-title">محدوده اسناد [فرم اصلی: TFrRemRep] {sel ? `— ${sel.title}` : ""}</div>
              <div className="form-grid" style={{ gridTemplateColumns: "repeat(4, minmax(110px, 1fr))" }}>
                <div className="field"><label>سال از</label><input value={yFrom} onChange={(e) => setYFrom(e.target.value)} style={{ direction: "ltr" }} placeholder="۱۴۰۴" /></div>
                <div className="field"><label>تا</label><input value={yTo} onChange={(e) => setYTo(e.target.value)} style={{ direction: "ltr" }} /></div>
                <div className="field"><label>ماه از</label><input value={mFrom} onChange={(e) => setMFrom(e.target.value)} style={{ direction: "ltr" }} placeholder="۱..۱۲" /></div>
                <div className="field"><label>تا</label><input value={mTo} onChange={(e) => setMTo(e.target.value)} style={{ direction: "ltr" }} /></div>
                <div className="field"><label>تاریخ از</label><input value={from} onChange={(e) => setFrom(e.target.value)} style={{ direction: "ltr" }} placeholder="۱۴۰۴/۰۱/۰۱" /></div>
                <div className="field"><label>تا</label><input value={to} onChange={(e) => setTo(e.target.value)} style={{ direction: "ltr" }} /></div>
                <div className="field"><label>شماره سند از</label><input value={noFrom} onChange={(e) => setNoFrom(e.target.value)} style={{ direction: "ltr" }} /></div>
                <div className="field"><label>تا</label><input value={noTo} onChange={(e) => setNoTo(e.target.value)} style={{ direction: "ltr" }} /></div>
                <div className="field"><label>نوع سند</label>
                  <select value={vchType} onChange={(e) => setVchType(e.target.value)}>
                    <option value="">همه</option>
                    {vchTypes.map((t: any) => <option key={t.VoucherTypeId} value={t.VoucherTypeId}>{t.Title}</option>)}
                  </select>
                </div>
                <div className="field"><label>گونهٔ سند</label>
                  <select value={kind} onChange={(e) => setKind(e.target.value)}>
                    <option value="">همه</option>
                    <option value="normal">عادی</option>
                    <option value="opening">افتتاحيه</option>
                    <option value="closing">اختتاميه</option>
                  </select>
                </div>
                <div className="field"><label>شعبه</label>
                  <select value={branch} onChange={(e) => setBranch(e.target.value)}>
                    <option value="">همه</option>
                    {branches.map((b: any) => <option key={b.BranchId} value={b.BranchId}>{b.Code} — {b.Title}</option>)}
                  </select>
                </div>
                <div className="field"><label>جهت گردش</label>
                  <select value={dir} onChange={(e) => setDir(e.target.value)}>
                    <option value="dc">بدهكار و بستانكار</option>
                    <option value="d">فقط بدهكار</option>
                    <option value="c">فقط بستانكار</option>
                  </select>
                </div>
                {tab === "card" && (
                  <div className="field"><label>نمایش</label>
                    <select value={display} onChange={(e) => setDisplay(e.target.value)}>
                      <option value="full">كامل</option>
                      <option value="sumIn">خلاصه — با احتساب مانده ابتداي دوره</option>
                      <option value="sumNo">خلاصه — بدون احتساب مانده ابتداي دوره</option>
                    </select>
                  </div>
                )}
                {tab === "analys" && (
                  <>
                    <div className="field"><label>گروه‌بندی تفصیلی</label>
                      <select value={aGroup} onChange={(e) => { const v = Number(e.target.value); setAGroup(v); if (sel) loadAnalys(sel, v, aAnalysed); }}>
                        <option value={1}>تفصیلی سطح ۴</option>
                        <option value={2}>تفصیلی سطح ۵</option>
                        <option value={3}>تفصیلی سطح ۶</option>
                      </select>
                    </div>
                    <div className="field"><label>وضعیت آناليز</label>
                      <select value={aAnalysed} onChange={(e) => { const v = e.target.value; setAAnalysed(v); if (sel) loadAnalys(sel, aGroup, v); }}>
                        <option value="all">همه آرتيكلها</option>
                        <option value="yes">فقط آناليز شده‌ها</option>
                        <option value="no">فقط آناليز نشده‌ها</option>
                      </select>
                    </div>
                  </>
                )}
                <div className="field">
                  <label>&nbsp;</label>
                  <label style={{ display: "flex", alignItems: "center", gap: 6, fontWeight: 600 }}>
                    <input type="checkbox" checked={runBal} onChange={(e) => setRunBal(e.target.checked)} /> مانده در خط
                  </label>
                </div>
                <div className="field"><label>&nbsp;</label>
                  <button className="btn primary" onClick={applyFilter} disabled={!sel || busy}>اعمال فيلتر</button>
                </div>
              </div>
            </div>

            {/* فیلتر تفصیلی برای معین‌های تفصیل‌دار */}
            {sel?.level === "moein" && (() => {
              const m = tree.moeins.find((x: any) => String(x.MoeinCode) === sel.code);
              const tIds = [m?.Taf1TypeId, m?.Taf2TypeId, m?.Taf3TypeId].filter(Boolean).map(Number);
              if (!tIds.length) return null;
              const lv = dlLevel || 1;
              const typeId = tIds[lv - 1];
              const typeTitle = lv === 1 ? m?.Taf1TypeTitle : lv === 2 ? m?.Taf2TypeTitle : m?.Taf3TypeTitle;
              const opts = tafsilis.filter((t: any) => Number(t.TafsiliTypeId) === typeId);
              return (
                <div className="card edit-card" style={{ marginBottom: 10 }}>
                  <div className="card-title">دفتر تفصیلی {typeTitle ? `— ${typeTitle}` : ""} [فریم TFrameAcDlFour/Five/Six]</div>
                  <div className="filterbar">
                    <select style={{ minWidth: 260 }} value={dlLevel || 1} onChange={(e) => setDlLevel(Number(e.target.value))}>
                      {tIds.map((tid, idx) => (
                        <option key={tid} value={idx + 1}>سطح {idx + 4} — {idx === 0 ? m?.Taf1TypeTitle : idx === 1 ? m?.Taf2TypeTitle : m?.Taf3TypeTitle}</option>
                      ))}
                    </select>
                    <select style={{ minWidth: 300 }} value={dlId || ""} onChange={(e) => {
                      const v = Number(e.target.value || 0); setDlId(v);
                      pick({ ...sel, level: v ? "dl" : "moein", dlLevel: lv, dlId: v });
                    }}>
                      <option value="">همه (کارِت معین)</option>
                      {opts.map((t: any) => <option key={t.TafsiliId} value={t.TafsiliId}>{t.Code} — {t.Title}</option>)}
                    </select>
                  </div>
                </div>
              );
            })()}

            {/* ---------- گردش حساب ---------- */}
            {tab === "card" && card && (
              <>
                <div className="btnrow">
                  <button className="btn" onClick={excel} disabled={!card.rows?.length}>Excel</button>
                  {display === "full" && (
                    <button className="btn green" disabled={!picked.size} onClick={() => { setNoteDlg(true); setNoteMsg(""); }}
                      title="انتخاب اقلام اعلاميه — اقلام تیک‌خورده را به اعلاميه منتقل کن">
                      صدور اعلاميه {picked.size ? `(${picked.size} قلم)` : ""}
                    </button>
                  )}
                  {dir !== "dc" && <span className="muted">فیلتر جهت فعال است — مانده‌ها فقط از ردیف‌های نمایش‌داده‌شده محاسبه می‌شوند.</span>}
                </div>
                <div className="scrollbox">
                  <table className="grid">
                    <thead><tr>
                      {display === "full" && <th></th>}
                      <th>تاریخ</th><th>سند</th><th>نوع</th>
                      {display === "full" && <><th>کد کل</th><th>کد معین</th><th>تفصیلی (۴ / ۵ / ۶)</th></>}
                      <th>شرح</th>
                      <th className="num">بدهکار</th><th className="num">بستانکار</th>
                      {runBal && <th className="num">مانده</th>}
                      <th></th>
                    </tr></thead>
                    <tbody>
                      {card.rows.map((r: any, i: number) => {
                        const isSum = display !== "full";
                        return (
                          <tr key={`${r.VoucherId || i}-${r.LineId || i}-${i}`}>
                            {display === "full" && (
                              <td><input type="checkbox" checked={picked.has(Number(r.LineId))}
                                onChange={() => togglePick(Number(r.LineId))} /></td>
                            )}
                            <td className="num">{r.VchDate}</td>
                            <td className="num"><b>{fa(r.VchNo)}</b>{Number(r.SubNo) ? `-${fa(r.SubNo)}` : ""}</td>
                            <td>{r.TypeTitle || "—"}{r.ReversalOf ? <span className="badge src" style={{ marginInlineStart: 3 }}>برگشتی</span> : null}</td>
                            {display === "full" && (
                              <>
                                <td className="ltr"><b>{r.KolCode}</b> {r.KolTitle}</td>
                                <td className="ltr"><b>{r.MoeinCode}</b>{sel?.level === "kol" || sel?.level === "dl" ? ` ${r.MoeinTitle}` : ""}</td>
                                <td>{[r.Taf1Title && `(${r.Taf1Code}) ${r.Taf1Title}`, r.Taf2Title && `(${r.Taf2Code}) ${r.Taf2Title}`, r.Taf3Title && `(${r.Taf3Code}) ${r.Taf3Title}`].filter(Boolean).join(" / ") || "—"}</td>
                              </>
                            )}
                            <td>{r.ItmDescr || r.VchDescr || "—"}</td>
                            <td className="num">{Number(isSum ? r.D : r.Dbt) ? fa(isSum ? r.D : r.Dbt) : ""}</td>
                            <td className="num">{Number(isSum ? r.C : r.Crt) ? fa(isSum ? r.C : r.Crt) : ""}</td>
                            {runBal && <td className="num"><b>{fa(r.Balance)}</b></td>}
                            <td><button className="btn ghost" style={{ padding: "0 8px", fontSize: 11 }} onClick={() => openVoucher(r.VoucherId)}>سند</button></td>
                          </tr>
                        );
                      })}
                      {!card.rows?.length && (
                        <tr><td colSpan={11} className="muted" style={{ textAlign: "center", padding: 16 }}>گردشی در این بازه نیست</td></tr>
                      )}
                    </tbody>
                  </table>
                </div>
                <div className="totalbar">
                  <span>مانده ابتدا: <b>{fa(card.opening?.D || 0)}</b> بد / <b>{fa(card.opening?.C || 0)}</b> بس</span>
                  <span>گردش دوره: بد <b>{fa(card.totals?.D || 0)}</b> · بس <b>{fa(card.totals?.C || 0)}</b></span>
                  {runBal && <span>مانده پایان: <b>{fa(card.rows?.length ? card.rows[card.rows.length - 1].Balance : 0)}</b></span>}
                </div>
              </>
            )}

            {/* ---------- تراز حساب [TAccViewLGBalance] ---------- */}
            {tab === "balance" && bal && bal.head && (
              <>
                <div className="scrollbox">
                  <table className="grid">
                    <thead><tr>
                      <th>گزارش تراز حساب — {bal.head.Title}</th>
                      <th className="num">گردش بدهكار</th><th className="num">گردش بستانكار</th>
                    </tr></thead>
                    <tbody>
                      <tr><td>گردش تا اين دوره (قبل از «تاریخ از»)</td><td className="num">{fa(bal.till.D)}</td><td className="num">{fa(bal.till.C)}</td></tr>
                      <tr><td>گردش دوره</td><td className="num">{fa(bal.during.D)}</td><td className="num">{fa(bal.during.C)}</td></tr>
                      <tr><td>گردش تا پايان دوره (بعد از «تا»)</td><td className="num">{fa(bal.after.D)}</td><td className="num">{fa(bal.after.C)}</td></tr>
                      <tr><td>مانده ابتدای دوره (جدول افتتاحیه — تا قبل از قطعی سند افتتاحیه)</td>
                        <td className="num">{fa(bal.opening.D)}</td><td className="num">{fa(bal.opening.C)}</td></tr>
                      <tr style={{ background: "#f2f6fa" }}>
                        <td><b>مانده</b></td>
                        <td className="num"><b>{fa(bal.balD)}</b> بدهكار</td>
                        <td className="num"><b>{fa(bal.balC)}</b> بستانكار</td>
                      </tr>
                    </tbody>
                  </table>
                </div>
                <div className="totalbar"><span>جمع گردش: بد <b>{fa(bal.total.D)}</b> · بس <b>{fa(bal.total.C)}</b></span></div>
              </>
            )}

            {/* ---------- آناليز حسابها [TAccAnalysForm] ---------- */}
            {tab === "analys" && analys && (
              <>
                <div className="scrollbox">
                  <table className="grid">
                    <thead><tr>
                      <th>معین</th><th>کد تفصیلی</th><th>عنوان تفصیلی</th>
                      <th className="num">بدهکار</th><th className="num">بستانکار</th><th className="num">مانده</th><th></th>
                    </tr></thead>
                    <tbody>
                      {analys.rows.map((r: any, i: number) => (
                        <tr key={i}>
                          <td className="ltr">{r.MoeinCode} {r.MoeinTitle}</td>
                          <td className="ltr">{r.TafCode || "—"}</td>
                          <td>{r.TafTitle || <span className="muted">(آناليز نشده)</span>}</td>
                          <td className="num">{Number(r.D) ? fa(r.D) : ""}</td>
                          <td className="num">{Number(r.C) ? fa(r.C) : ""}</td>
                          <td className="num"><b>{fa(Math.abs(Number(r.D) - Number(r.C)))}</b> {Number(r.D) - Number(r.C) >= 0 ? "بد" : "بس"}</td>
                          <td>
                            {sel && r.TafCode && (
                              <button className="btn ghost" style={{ padding: "0 8px", fontSize: 11 }}
                                title="ريز آناليز — کارت گردش همان تفصیلی"
                                onClick={() => {
                                  const t = tafsilis.find((x: any) => x.Code === String(r.TafCode) && (x.TafsiliTypeId === Number([tree.moeins.find((mm: any) => String(mm.MoeinCode) === r.MoeinCode)?.Taf1TypeId, tree.moeins.find((mm: any) => String(mm.MoeinCode) === r.MoeinCode)?.Taf2TypeId, tree.moeins.find((mm: any) => String(mm.MoeinCode) === r.MoeinCode)?.Taf3TypeId][aGroup - 1])));
                                  if (t) { setDlLevel(aGroup); pick({ ...sel, level: "dl", dlLevel: aGroup, dlId: t.TafsiliId, title: `تفصیلی ${t.Code} — ${t.Title}` }); setTab("card"); }
                                }}>ريز آناليز</button>
                            )}
                          </td>
                        </tr>
                      ))}
                      {!analys.rows?.length && <tr><td colSpan={7} className="muted" style={{ textAlign: "center", padding: 16 }}>گردشی برای آناليز نیست</td></tr>}
                    </tbody>
                  </table>
                </div>
                <div className="totalbar">
                  <span>جمع: بد <b>{fa((analys.rows || []).reduce((s: number, r: any) => s + Number(r.D || 0), 0))}</b> · بس <b>{fa((analys.rows || []).reduce((s: number, r: any) => s + Number(r.C || 0), 0))}</b></span>
                </div>
              </>
            )}

            {/* ---------- گردش ارز / مانده ارزی [TAccCurFlow] ---------- */}
            {tab === "fx" && (
              <>
                {sel?.level !== "moein" && (
                  <div className="msg err">برای گردش ارز، یک حساب معین (ترجیحاً ارزی) از درخت انتخاب کنید.</div>
                )}
                {sel?.level === "moein" && (
                  <div className="btnrow">
                    <button className={`btn ghost ${!fxBal ? "active" : ""}`} onClick={() => { setFxBal(false); loadFx(sel, false); }}>گردش ارز</button>
                    <button className={`btn ghost ${fxBal ? "active" : ""}`} onClick={() => { setFxBal(true); loadFx(sel, true); }}>مانده ارزي</button>
                  </div>
                )}
                {fx?.rows && (
                  <div className="scrollbox">
                    <table className="grid">
                      <thead><tr>
                        <th>ارز</th>{!fxBal && <th>تاریخ</th>}{!fxBal && <th>سند</th>}{!fxBal && <th>شرح</th>}
                        <th className="num">مبلغ ارزی بدهکار</th><th className="num">مبلغ ارزی بستانکار</th>
                        <th className="num">{fxBal ? "مانده ارزی" : "مانده در خط"}</th>
                        {!fxBal && <th className="num">نرخ</th>}
                        <th className="num">بد (ریال)</th><th className="num">بس (ریال)</th>
                      </tr></thead>
                      <tbody>
                        {fx.rows.map((r: any, i: number) => (
                          <tr key={i}>
                            <td><b className="ltr">{r.FxCode}</b> {r.FxTitle}</td>
                            {!fxBal && <td className="num">{r.VchDate || "—"}</td>}
                            {!fxBal && <td className="num">{r.VchNo ? fa(r.VchNo) : "—"}</td>}
                            {!fxBal && <td>{r.VchDescr || "—"}</td>}
                            <td className="num">{Number(r.FxD) ? fa(r.FxD) : ""}</td>
                            <td className="num">{Number(r.FxC) ? fa(r.FxC) : ""}</td>
                            <td className="num"><b>{fa(r.FxBalance ?? (Number(r.FxD) - Number(r.FxC)))}</b></td>
                            {!fxBal && <td className="num">{r.FxRate ? fa(r.FxRate) : "—"}</td>}
                            <td className="num">{Number(r.D) ? fa(r.D) : ""}</td>
                            <td className="num">{Number(r.C) ? fa(r.C) : ""}</td>
                          </tr>
                        ))}
                        {!fx.rows.length && <tr><td colSpan={10} className="muted" style={{ textAlign: "center", padding: 16 }}>گردش ارزی در این بازه نیست</td></tr>}
                      </tbody>
                    </table>
                  </div>
                )}
              </>
            )}
          </div>
        </div>

        {/* ---------- دیالوگ صدور اعلاميه ---------- */}
        {noteDlg && (
          <div className="card edit-card" style={{ marginTop: 10 }}>
            <div className="card-title">صدور اعلاميه — {picked.size} قلم انتخاب شده [فرم: صدور اعلاميه]</div>
            <div className="form-grid" style={{ gridTemplateColumns: "160px 1fr auto" }}>
              <div className="field"><label>تاريخ اعلاميه</label>
                <input value={noteDate} onChange={(e) => setNoteDate(e.target.value)} style={{ direction: "ltr" }} placeholder={todayFa()} />
              </div>
              <div className="field"><label>شرح اعلاميه</label>
                <input value={noteTitle} onChange={(e) => setNoteTitle(e.target.value)} placeholder="مثلاً: اعلاميهٔ بدهی دی‌ماه" />
              </div>
              <div className="field"><label>&nbsp;</label>
                <div className="btnrow" style={{ margin: 0 }}>
                  <button className="btn primary" onClick={issueNote} disabled={!picked.size}>تائيد</button>
                  <button className="btn" onClick={() => setNoteDlg(false)}>انصراف</button>
                </div>
              </div>
            </div>
            {noteMsg && <div className="msg err">{noteMsg}</div>}
          </div>
        )}

        {/* ---------- نمایش سند ---------- */}
        {vch && (
          <div style={{ position: "fixed", inset: 0, background: "rgba(15,35,55,.45)", zIndex: 50, display: "flex", alignItems: "center", justifyContent: "center", padding: 20 }}
            onClick={() => setVch(null)}>
            <div style={{ background: "#fff", borderRadius: 10, maxHeight: "88vh", overflow: "auto", padding: 14, minWidth: 720 }} onClick={(e) => e.stopPropagation()}>
              <VoucherDetailCard d={vch} onClose={() => setVch(null)} />
            </div>
          </div>
        )}
      </CtxGate>
    </Shell>
  );
}
