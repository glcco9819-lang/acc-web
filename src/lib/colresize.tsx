"use client";

import { useCallback, useEffect, useRef, useState } from "react";

/* ============================================================================
   ستون‌های قابل تغییر اندازه با موس (v2.2.0 — درخواست کارفرما:
   «در صدور سند اندازه ستون های سند با موس قابل کوچک و بزرگ شدن داشته باشند»)
   دستگیرهٔ باریک در لبهٔ چپ هر ستون (RTL) — کشیدن با موس عرض را عوض می‌کند.
   v2.3.0 — عرض ستون‌ها در localStorage ذخیره می‌شود؛ پس از بارگذاری مجدد صفحه
   همان اندازه‌ها برقرار است. دستگیره در «لیست اسناد» هم فعال شد.
   ============================================================================ */

export type ColWidths = Record<string, number>;

const MIN_W = 36, MAX_W = 900;

function loadSaved(key: string): ColWidths {
  if (!key) return {};
  try {
    const v = JSON.parse(localStorage.getItem(key) || "{}");
    const out: ColWidths = {};
    Object.entries(v || {}).forEach(([k, w]) => {
      const n = Number(w);
      if (Number.isFinite(n) && n >= MIN_W && n <= MAX_W) out[k] = n;
    });
    return out;
  } catch { return {}; }
}

export function useColResize(defaults: ColWidths, storageKey = "") {
  const [widths, setWidths] = useState<ColWidths>(() => ({ ...defaults, ...loadSaved(storageKey) }));
  const mirror = useRef<ColWidths>(widths); /* آخرین وضعیت برای ذخیره در پایان کشیدن */
  const drag = useRef<{ key: string; startX: number; startW: number } | null>(null);

  /* اگر کلید حافظه در رندر اول در دسترس نبود — خواندن یک‌بارهٔ عرض‌های ذخیره‌شده */
  useEffect(() => {
    if (!storageKey) return;
    const saved = loadSaved(storageKey);
    if (Object.keys(saved).length) {
      setWidths((ws) => { const n = { ...ws, ...saved }; mirror.current = n; return n; });
    }
  }, [storageKey]);

  const apply = useCallback((key: string, next: number) => {
    setWidths((ws) => {
      const n = { ...ws, [key]: next };
      mirror.current = n;
      return n;
    });
  }, []);

  const onDown = useCallback((key: string, w: number) => (e: React.PointerEvent) => {
    e.preventDefault();
    e.stopPropagation();
    drag.current = { key, startX: e.clientX, startW: w };
    const move = (ev: PointerEvent) => {
      if (!drag.current) return;
      /* در RTL ستون بعدی سمت چپ است؛ کشیدن به چپ = عریض‌تر */
      const delta = drag.current.startX - ev.clientX;
      apply(drag.current.key, Math.max(MIN_W, Math.min(MAX_W, drag.current.startW + delta)));
    };
    const up = () => {
      /* پایان کشیدن — ذخیرهٔ همهٔ عرض‌ها برای ماندگاری پس از بستن صفحه */
      if (drag.current && storageKey) {
        try { localStorage.setItem(storageKey, JSON.stringify(mirror.current)); } catch { /* - */ }
      }
      drag.current = null;
      window.removeEventListener("pointermove", move);
      window.removeEventListener("pointerup", up);
      document.body.style.cursor = "";
      document.body.style.userSelect = "";
    };
    document.body.style.cursor = "col-resize";
    document.body.style.userSelect = "none";
    window.addEventListener("pointermove", move);
    window.addEventListener("pointerup", up);
  }, [apply, storageKey]);

  /* سبکِ دستگیره — لبهٔ چپ سلول سرستون */
  const gripStyle: React.CSSProperties = {
    position: "absolute", left: -3, top: 0, bottom: 0, width: 7,
    cursor: "col-resize", zIndex: 6, touchAction: "none",
  };

  const thStyle = (key: string, fallback?: number): React.CSSProperties => ({
    width: widths[key] ?? fallback, minWidth: 36, position: "sticky",
  });

  return { widths, onDown, gripStyle, thStyle };
}

/* دستگیرهٔ قابل‌لمس داخل سرستون — <th> باید position:relative/sticky داشته باشد */
export function ColGrip({ onDown }: { onDown: (e: React.PointerEvent) => void }) {
  return (
    <span
      onPointerDown={onDown}
      title="برای تغییر اندازهٔ ستون بکشید — اندازه به‌خاطر سپرده می‌شود"
      style={{
        position: "absolute", left: -3, top: 0, bottom: 0, width: 7,
        cursor: "col-resize", zIndex: 6, touchAction: "none",
      }}
      onMouseEnter={(e) => { (e.target as HTMLElement).style.background = "rgba(46,74,99,.28)"; }}
      onMouseLeave={(e) => { (e.target as HTMLElement).style.background = "transparent"; }}
    />
  );
}
