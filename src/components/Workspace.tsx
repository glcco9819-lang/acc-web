"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useApp } from "@/components/App";
import { MODULES, WinIcon, ModIcon, type MenuIcon } from "@/components/menus";

/* ============================================================================
   میزکار چندپنجره‌ای (v2.6.0) — الهام‌گرفته از سامانهٔ نمونهٔ «یسطا»
   ① «ساید بار بالا»: نوار ماژول‌ها — فقط آیکون ماژول‌ها به ترتیب اعلام‌شده؛
      حسابداری کامل و آماده، سایر ماژول‌ها فعلاً فقط آیکون (در دست ساخت)
   ② «ساید بار سمت راست»: تب‌های ماژول فعال + فیلدهای (آیتم‌های) هر تب —
      کلیک روی هر فیلد، پنجرهٔ آن را در میزکار باز می‌کند
   ③ هر آیتم یک پنجرهٔ شناور داخل همان صفحه باز می‌کند (MDI چندپنجره‌ای همزمان)؛
      بازکردن دوبارهٔ همان پنجره فقط آن را «فعال» می‌کند (بدون نسخهٔ تکراری)
   ④ پنجره‌ها: جابه‌جایی با نوار عنوان، تغییر اندازه از ۸ جهت،
      کوچک‌نمایی/بزرگ‌نمایی/بستن — پنجرهٔ فعال با z-index بالاتر همیشه رو است
   ⑤ «ساید بار پایین»: چیپ پنجره‌های باز — کلیک = فعال‌سازی/بازگردانی از حالت کمینه
   ⑥ همگام‌سازی خودکار بین پنجره‌ها: هر ثبت/اصلاح/حذف در یک پنجره (رویداد
      acc:data → postMessage به میزبان) بقیهٔ پنجره‌های باز را تازه می‌کند؛
      تغییر شرکت/سال مالی هم به همهٔ پنجره‌ها broadcast می‌شود (acc:ctx)
   ============================================================================ */

interface WinState {
  path: string; title: string; icon: MenuIcon;
  x: number; y: number; w: number; h: number;
  state: "normal" | "min" | "max";
  z: number;
  saved?: { x: number; y: number; w: number; h: number };
}

type Side = "n" | "s" | "e" | "w" | "ne" | "nw" | "se" | "sw";

const MIN_W = 520, MIN_H = 380;
const geomKey = (p: string) => `acc-win-geom2:${p}`;
const EMBED = "?embed=1";
const SIDES: Side[] = ["n", "s", "e", "w", "ne", "nw", "se", "sw"];

export default function Workspace() {
  const app = useApp();
  const router = useRouter();
  const [wins, setWins] = useState<WinState[]>([]);
  const [focused, setFocused] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);            /* درگ/ری‌سایز → iframe بی‌اثر */
  const [modId, setModId] = useState<string>("acc");  /* ماژول فعال در ساید بار راست */
  const [openTab, setOpenTab] = useState<number>(0);  /* تب بازِ ساید بار راست */
  const winsRef = useRef<WinState[]>([]);
  const zTop = useRef(20);
  const deskRef = useRef<HTMLDivElement>(null);

  const setAll = useCallback((next: WinState[]) => { winsRef.current = next; setWins(next); }, []);

  const deskSize = useCallback(() => {
    const r = deskRef.current?.getBoundingClientRect();
    return { dw: Math.round(r?.width || 1200), dh: Math.round(r?.height || 600) };
  }, []);

  const persistGeom = (path: string, g: { x: number; y: number; w: number; h: number }) => {
    try { localStorage.setItem(geomKey(path), JSON.stringify(g)); } catch { /* - */ }
  };

  const clamp = useCallback((g: { x: number; y: number; w: number; h: number }) => {
    const { dw, dh } = deskSize();
    const w = Math.max(Math.min(g.w, dw), Math.min(MIN_W, dw));
    const h = Math.max(Math.min(g.h, dh), Math.min(MIN_H, dh));
    /* x: ۱۴۰px از نوار عنوان همیشه داخل میزکار؛ y: پنجره کامل داخل میزکار */
    const x = Math.min(Math.max(g.x, -w + 140), Math.max(dw - 140, 0));
    const y = Math.min(Math.max(g.y, 0), Math.max(dh - h, 0));
    return { x, y, w, h };
  }, [deskSize]);

  const focusWin = useCallback((path: string) => {
    const w = winsRef.current.find((v) => v.path === path);
    if (!w) return;
    zTop.current += 1;
    setAll(winsRef.current.map((v) => (v.path === path ? { ...v, z: zTop.current, state: v.state === "min" ? "normal" as const : v.state } : v)));
    setFocused(path);
  }, [setAll]);

  const openWin = useCallback((path: string, title: string, icon: MenuIcon) => {
    const ex = winsRef.current.find((w) => w.path === path);
    if (ex) { focusWin(path); return; }
    const { dw, dh } = deskSize();
    let g = { x: 8, y: 8, w: Math.max(MIN_W, dw - 16), h: Math.max(MIN_H, dh - 16) };
    try {
      const s = localStorage.getItem(geomKey(path));
      if (s) { const o = JSON.parse(s); g = { x: o.x ?? g.x, y: o.y ?? g.y, w: o.w ?? g.w, h: o.h ?? g.h }; }
    } catch { /* - */ }
    const gc = clamp(g);
    zTop.current += 1;
    setAll([...winsRef.current, { path, title, icon, ...gc, state: "normal", z: zTop.current }]);
    setFocused(path);
  }, [clamp, deskSize, focusWin, setAll]);

  const closeWin = useCallback((path: string) => {
    const rest = winsRef.current.filter((w) => w.path !== path);
    setAll(rest);
    if (focused === path) {
      const top = [...rest].filter((w) => w.state !== "min").sort((a, b) => b.z - a.z)[0];
      setFocused(top ? top.path : null);
    }
    /* eslint-disable-next-line react-hooks/exhaustive-deps */
  }, [focused, setAll]);

  const minimizeWin = useCallback((path: string) => {
    setAll(winsRef.current.map((w) => (w.path === path ? { ...w, state: "min" as const } : w)));
    if (focused === path) {
      const top = [...winsRef.current].filter((w) => w.path !== path && w.state !== "min").sort((a, b) => b.z - a.z)[0];
      setFocused(top ? top.path : null);
    }
    /* eslint-disable-next-line react-hooks/exhaustive-deps */
  }, [focused, setAll]);

  const toggleMax = useCallback((path: string) => {
    const { dw, dh } = deskSize();
    zTop.current += 1; const z = zTop.current;
    setAll(winsRef.current.map((w) => {
      if (w.path !== path) return w;
      if (w.state === "max") {
        const s = w.saved || { x: 8, y: 8, w: Math.max(MIN_W, dw - 16), h: Math.max(MIN_H, dh - 16) };
        return { ...w, ...s, state: "normal" as const, z, saved: undefined };
      }
      return { ...w, saved: { x: w.x, y: w.y, w: w.w, h: w.h }, x: 0, y: 0, w: dw, h: dh, state: "max" as const, z };
    }));
    setFocused(path);
  }, [deskSize, setAll]);

  /* ---------- درگ نوار عنوان ---------- */
  const startDrag = (path: string) => (e: React.PointerEvent) => {
    if ((e.target as HTMLElement).closest("button")) return; /* دکمه‌ها درگ نکنند */
    const w = winsRef.current.find((v) => v.path === path);
    if (!w || w.state === "max") return; /* پنجرهٔ بیشینه ثابت است */
    e.preventDefault();
    focusWin(path);
    const { dw, dh } = deskSize();
    const sx = e.clientX, sy = e.clientY, ox = w.x, oy = w.y, ow = w.w, oh = w.h;
    let last = { x: ox, y: oy };
    setBusy(true);
    const move = (ev: PointerEvent) => {
      /* x: بخشی از پنجره می‌تواند بیرون بماند (۱۴۰px از نوار عنوان همیشه دیده شود)؛
         y: پنجره کامل داخل میزکار بماند تا دستگیره‌های تغییر اندازه همیشه در دسترس باشند */
      const x = Math.min(Math.max(ox + (ev.clientX - sx), -(ow) + 140), Math.max(dw - 140, 0));
      const y = Math.min(Math.max(oy + (ev.clientY - sy), 0), Math.max(dh - oh, 0));
      last = { x, y };
      setAll(winsRef.current.map((v) => (v.path === path ? { ...v, x, y } : v)));
    };
    const up = () => {
      window.removeEventListener("pointermove", move);
      window.removeEventListener("pointerup", up);
      setBusy(false);
      persistGeom(path, { ...last, w: ow, h: w.h });
    };
    window.addEventListener("pointermove", move);
    window.addEventListener("pointerup", up);
  };

  /* ---------- تغییر اندازه از ۸ جهت ---------- */
  const startResize = (path: string, side: Side) => (e: React.PointerEvent) => {
    e.preventDefault();
    const w0 = winsRef.current.find((v) => v.path === path);
    if (!w0 || w0.state === "max") return;
    focusWin(path);
    const { dw, dh } = deskSize();
    const sx = e.clientX, sy = e.clientY;
    const o = { x: w0.x, y: w0.y, w: w0.w, h: w0.h };
    let last = { ...o };
    setBusy(true);
    const move = (ev: PointerEvent) => {
      const dx = ev.clientX - sx, dy = ev.clientY - sy;
      let { x, y, w, h } = o;
      if (side.includes("e")) w = o.w + dx;
      if (side.includes("s")) h = o.h + dy;
      if (side.includes("w")) { w = o.w - dx; x = o.x + dx; }
      if (side.includes("n")) { h = o.h - dy; y = o.y + dy; }
      /* کف و سقف — با اصلاح x/y تا لبهٔ مقابل ثابت بماند */
      if (w < MIN_W) { if (side.includes("w")) x = o.x + (o.w - MIN_W); w = MIN_W; }
      if (h < MIN_H) { if (side.includes("n")) y = o.y + (o.h - MIN_H); h = MIN_H; }
      if (w > dw) { if (side.includes("w")) x = o.x + (o.w - dw); w = dw; }
      if (h > dh) { if (side.includes("n")) y = o.y + (o.h - dh); h = dh; }
      if (x > o.x + o.w - 140) x = o.x + o.w - 140;
      if (y > o.y + o.h - 52) y = o.y + o.h - 52;
      last = { x: Math.round(x), y: Math.round(y), w: Math.round(w), h: Math.round(h) };
      setAll(winsRef.current.map((v) => (v.path === path ? { ...v, ...last } : v)));
    };
    const up = () => {
      window.removeEventListener("pointermove", move);
      window.removeEventListener("pointerup", up);
      setBusy(false);
      persistGeom(path, last);
    };
    window.addEventListener("pointermove", move);
    window.addEventListener("pointerup", up);
  };

  /* تغییر اندازهٔ مرورگر → همگام‌سازی خودکار هندسهٔ پنجره‌ها */
  useEffect(() => {
    const h = () => {
      const { dw, dh } = deskSize();
      setAll(winsRef.current.map((w) => {
        if (w.state === "max") return { ...w, x: 0, y: 0, w: dw, h: dh };
        return { ...w, ...clamp({ x: w.x, y: w.y, w: w.w, h: w.h }) };
      }));
    };
    window.addEventListener("resize", h);
    return () => window.removeEventListener("resize", h);
  }, [clamp, deskSize, setAll]);

  /* ---------- پل همگام‌سازی: پیام از پنجره‌های فرزند (iframe) ---------- */
  useEffect(() => {
    const onMsg = (e: MessageEvent) => {
      try {
        if (e.origin !== window.location.origin) return;
        const d = e.data as { source?: string; type?: string };
        if (!d || d.source !== "acc-win") return;
        if (d.type === "acc:data") {
          deskRef.current?.querySelectorAll("iframe").forEach((f) => {
            if (f.contentWindow && f.contentWindow !== e.source)
              f.contentWindow.postMessage({ source: "acc-host", type: "acc:data" }, window.location.origin);
          });
        }
      } catch { /* - */ }
    };
    window.addEventListener("message", onMsg);
    return () => window.removeEventListener("message", onMsg);
  }, []);

  const broadcastCtx = useCallback(() => {
    deskRef.current?.querySelectorAll("iframe").forEach((f) => {
      try { f.contentWindow?.postMessage({ source: "acc-host", type: "acc:ctx" }, window.location.origin); } catch { /* - */ }
    });
  }, []);

  const onPickCompany = async (id: number) => { await app.pickCompany(id); broadcastCtx(); };
  const onPickYear = async (id: number) => { await app.pickYear(id); broadcastCtx(); };

  const logout = async () => {
    try { await fetch("/api/auth/login", { method: "DELETE" }); } catch { /* - */ }
    router.replace("/login");
  };

  if (!app.ready) return <div className="boot">در حال بارگذاری…</div>;

  const mod = MODULES.find((m) => m.id === modId) || MODULES[0];
  /* دسترسی لاگ سیستم — همان قاعدهٔ قبلی (app.can.logview) به تب «عملیات پایه» */
  const modTabs = mod.tabs.map((t) =>
    t.title === "عملیات پایه" && app.can?.logview
      ? { ...t, items: [...t.items, ["/windows/log", "لاگ سیستم"] as [string, string]] }
      : t
  );
  const yearsOf = app.years.filter((y) => y.CompanyId === app.companyId);
  const focusedWin = wins.find((w) => w.path === focused && w.state !== "min");

  return (
    <div className="ws">
      {/* ساید بار بالا — نوار ماژول‌ها: فقط آیکون ماژول‌ها به ترتیب اعلام‌شده */}
      <div className="modulebar">
        <Link href="/desktop" className="brand">
          <span className="brand-mark">YFG</span>
          <span>YFG ERP</span>
        </Link>
        <div className="mod-list">
          {MODULES.map((m) => (
            <button
              key={m.id}
              className={`mod-btn ${modId === m.id ? "active" : ""} ${m.ready ? "" : "soon"}`}
              onClick={() => { setModId(m.id); setOpenTab(0); }}
              title={m.ready ? m.title : `${m.title} — در دست ساخت`}
            >
              <ModIcon k={m.icon} size={19} />
              <span>{m.title}</span>
            </button>
          ))}
        </div>
        <div className="menubar-user">
          <span className="user-chip" title={app.user?.username}>
            <b>{app.user?.display}</b>
            <i>{app.user?.role === "admin" ? "مدیر سامانه" : app.user?.role === "registrar" ? "ثبت‌کننده" : "بررسی‌کننده"}</i>
          </span>
          <button className="btn ghost" onClick={logout}>خروج</button>
        </div>
      </div>

      <div className="ws-main">
        {/* ساید بار سمت راست — تب‌ها و فیلدهای ماژول فعال */}
        <aside className="side-right">
          <div className="side-head">
            <ModIcon k={mod.icon} size={16} />
            <b>{mod.title}</b>
            {!mod.ready && <span className="side-soon">در دست ساخت</span>}
          </div>
          {mod.ready ? (
            <nav className="side-tabs">
              {modTabs.map((t, i) => (
                <div key={t.title} className={`side-group ${openTab === i ? "open" : ""}`}>
                  <button className="side-tab" onClick={() => setOpenTab(openTab === i ? -1 : i)}>
                    <WinIcon k={t.icon} size={14} />
                    <span>{t.title}</span>
                    <i className="chev">▾</i>
                  </button>
                  {openTab === i && (
                    <div className="side-items">
                      {t.items.map(([href, label]) => (
                        <button key={href}
                          className={`side-item ${focused === href ? "active" : ""}`}
                          onClick={() => openWin(href, label, t.icon)}
                          title={label}>
                          <span>{label}</span>
                          {wins.some((w) => w.path === href) && <i className="dot" title="باز است" />}
                        </button>
                      ))}
                    </div>
                  )}
                </div>
              ))}
            </nav>
          ) : (
            <div className="side-empty">
              <ModIcon k={mod.icon} size={36} />
              <b>{mod.title}</b>
              <p>این ماژول در دست ساخت است؛ تب‌ها و پنجره‌های آن به‌زودی همین‌جا اضافه می‌شود.</p>
            </div>
          )}
        </aside>

        {/* ستون اصلی: نوار زمینه + میزکار پنجره‌های شناور */}
        <div className="ws-content">
          {/* نوار زمینه (شرکت/سال مالی) — تغییر آن به همهٔ پنجره‌های باز broadcast می‌شود */}
          <div className="ctxbar">
            <label>شرکت</label>
            <select value={app.companyId || ""} onChange={(e) => onPickCompany(Number(e.target.value))}>
              <option value="">— انتخاب —</option>
              {app.companies.map((c) => <option key={c.CompanyId} value={c.CompanyId}>{c.CompanyCode} — {c.TitleFa}</option>)}
            </select>
            <label>سال مالی</label>
            <select value={app.yearId || ""} onChange={(e) => onPickYear(Number(e.target.value))} disabled={!app.companyId}>
              <option value="">— انتخاب —</option>
              {yearsOf.map((y) => <option key={y.YearId} value={y.YearId}>{y.Title}{y.IsClosed ? " (بسته)" : ""}</option>)}
            </select>
            {app.company && (
              <span className="ctx-badge">کدینگ: {app.company.CodingMode === 2 ? "گروه/کل/معین" : "پلکانی"}</span>
            )}
            {app.year && <span className="ctx-badge">از {app.year.Title}</span>}
            {focusedWin && <span className="ctx-badge ws-current">پنجرهٔ فعال: {focusedWin.title}</span>}
          </div>

          {/* میزکار — پنجره‌های شناور */}
          <div className={`desktop ${busy ? "busy" : ""}`} ref={deskRef}>
            {wins.filter((w) => w.state !== "min").map((w) => (
              <div
                key={w.path}
                className={`m-window ${focused === w.path ? "focused" : ""} ${w.state === "max" ? "max" : ""}`}
                style={{ left: w.x, top: w.y, width: w.w, height: w.h, zIndex: w.z }}
                onPointerDown={() => focusWin(w.path)}
              >
                <div className="m-title" onPointerDown={startDrag(w.path)} onDoubleClick={() => toggleMax(w.path)}>
                  <span className="m-title-txt"><WinIcon k={w.icon} />{w.title}</span>
                  <span className="m-title-btns">
                    <button title="کوچک‌نمایی (حالت کمینه — از نوار پایین بازگردانی می‌شود)"
                      aria-label="کوچک‌نمایی" onClick={() => minimizeWin(w.path)}>−</button>
                    <button title={w.state === "max" ? "بازگردانی اندازه" : "بزرگ‌نمایی (تمام میزکار)"}
                      aria-label={w.state === "max" ? "بازگردانی اندازه" : "بزرگ‌نمایی"} onClick={() => toggleMax(w.path)}>❐</button>
                    <button title="بستن پنجره" aria-label="بستن (ضربدر)" onClick={() => closeWin(w.path)}>✕</button>
                  </span>
                </div>
                <div className="m-body">
                  <iframe src={`${w.path}${EMBED}`} title={w.title} />
                </div>
                {SIDES.map((s) => (
                  <div key={s} className={`mw-rz mw-rz-${s}`} onPointerDown={startResize(w.path, s)}
                    title="تغییر اندازهٔ پنجره" />
                ))}
              </div>
            ))}
            {wins.length === 0 && (
              <div className="desktop-empty">
                <div>
                  <b>میزکار چندپنجره‌ای YFG</b>
                  <p>برای شروع، از ساید بار سمت راست پنجرهٔ موردنظر را باز کنید.<br />چند پنجره می‌توانند همزمان باز باشند؛ فهرست پنجره‌های باز در نوار پایین می‌آید.</p>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* ساید بار پایین — فهرست پنجره‌های باز (مطابق سامانهٔ نمونه) */}
      <div className="taskbar">
        <span className="tb-label">
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><rect width="7" height="7" x="3" y="3" rx="1" /><rect width="7" height="7" x="14" y="3" rx="1" /><rect width="7" height="7" x="14" y="14" rx="1" /><rect width="7" height="7" x="3" y="14" rx="1" /></svg>
          پنجره‌های باز:
        </span>
        {wins.length === 0 && <span className="tb-none">— هیچ پنجره‌ای باز نیست —</span>}
        {wins.map((w) => (
          <button
            key={w.path}
            className={`tb-chip ${focused === w.path && w.state !== "min" ? "active" : ""} ${w.state === "min" ? "min" : ""}`}
            onClick={() => focusWin(w.path)}
            title={w.state === "min" ? `${w.title} (کمینه — کلیک = بازگردانی)` : w.title}
          >
            <WinIcon k={w.icon} size={13} />
            <span className="tb-txt">{w.title}</span>
            {w.state === "min" && <i className="tb-min">کمینه</i>}
          </button>
        ))}
      </div>
    </div>
  );
}
