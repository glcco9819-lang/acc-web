"use client";

import { useCallback, useRef, useState } from "react";

/* ============================================================================
   ستون‌های قابل تغییر اندازه با موس (v2.2.0 — درخواست کارفرما:
   «در صدور سند اندازه ستون های سند با موس قابل کوچک و بزرگ شدن داشته باشند»)
   دستگیرهٔ باریک در لبهٔ چپ هر ستون (RTL) — کشیدن با موس عرض را عوض می‌کند.
   ============================================================================ */

export type ColWidths = Record<string, number>;

export function useColResize(defaults: ColWidths) {
  const [widths, setWidths] = useState<ColWidths>(defaults);
  const drag = useRef<{ key: string; startX: number; startW: number } | null>(null);

  const onDown = useCallback((key: string, w: number) => (e: React.PointerEvent) => {
    e.preventDefault();
    e.stopPropagation();
    drag.current = { key, startX: e.clientX, startW: w };
    const move = (ev: PointerEvent) => {
      if (!drag.current) return;
      /* در RTL ستون بعدی سمت چپ است؛ کشیدن به چپ = عریض‌تر */
      const delta = drag.current.startX - ev.clientX;
      const next = Math.max(36, Math.min(900, drag.current.startW + delta));
      setWidths((ws) => ({ ...ws, [drag.current!.key]: next }));
    };
    const up = () => {
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
  }, []);

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
      title="برای تغییر اندازهٔ ستون بکشید"
      style={{
        position: "absolute", left: -3, top: 0, bottom: 0, width: 7,
        cursor: "col-resize", zIndex: 6, touchAction: "none",
      }}
      onMouseEnter={(e) => { (e.target as HTMLElement).style.background = "rgba(46,74,99,.28)"; }}
      onMouseLeave={(e) => { (e.target as HTMLElement).style.background = "transparent"; }}
    />
  );
}
