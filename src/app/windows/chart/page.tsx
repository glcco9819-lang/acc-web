"use client";

import { useCallback, useEffect, useState } from "react";
import Shell from "@/components/Shell";
import { api, fa, NATURE_FA } from "@/lib/ui";

/* [فرم اصلی: گزارش مجموعه حسابها — گروه/كل/معين/تفصيلي + ارتباط سطوح] */
export default function Page() {
  const [rows, setRows] = useState<any[]>([]);
  const [err, setErr] = useState("");

  const fetchChart = useCallback(() => { api("/api/acc/chart").then((j) => setRows(j.rows || [])).catch((e) => setErr(e.message)); }, []);
  useEffect(() => { fetchChart(); }, [fetchChart]);
  /* v2.4.4 — همگام‌سازی خودکار: با هر تغییر حساب/سند در پنجره‌های دیگر، شجره تازه می‌شود */
  useEffect(() => {
    const h = () => fetchChart();
    window.addEventListener("acc:data", h);
    return () => window.removeEventListener("acc:data", h);
  }, [fetchChart]);

  /* گروه‌بندی درختی */
  const groups = new Map<string, any[]>();
  rows.forEach((r) => {
    const gk = `${r.GroupCode}|${r.GroupTitle}|${r.AccNature}`;
    if (!groups.has(gk)) groups.set(gk, []);
    groups.get(gk)!.push(r);
  });

  return (
    <Shell title="گزارش مجموعه حساب‌ها (شجره)" sub="بر اساس ارتباط حساب‌ها — گروه، کل، معین و سطوح تفصیلی">
      {err && <div className="msg err">{err}</div>}
      {!rows.length && !err && <p className="muted">کدینگی ثبت نشده است.</p>}
      <div className="tree">
        {[...groups.entries()].map(([gk, items]) => {
          const [gc, gt, gn] = gk.split("|");
          const kols = new Map<string, any[]>();
          items.forEach((r) => { if (r.KolCode) { const k = `${r.KolCode}|${r.KolTitle}`; if (!kols.has(k)) kols.set(k, []); kols.get(k)!.push(r); } });
          return (
            <div key={gk}>
              <div className="lv1">گروه {gc} — {gt} <span className="muted">({NATURE_FA[Number(gn)]})</span></div>
              {[...kols.entries()].map(([kk, ms]) => {
                const [kc, kt] = kk.split("|");
                return (
                  <div className="lv2" key={kk}>
                    کل {kc} — {kt}
                    {ms.map((m) => m.MoeinCode && (
                      <div className="lv3" key={m.MoeinCode}>
                        معین {m.MoeinCode} — {m.MoeinTitle}
                        {m.IsActive ? "" : <span className="badge s1" style={{ marginInlineStart: 6 }}>غیرفعال</span>}
                        {" "}
                        <span className="tafsili">
                          {m.Taf1TypeId ? `سطح ۴: ${m.Taf1Title}` : "بدون تفصیلی"}
                          {m.Taf2TypeId ? ` · سطح ۵: ${m.Taf2Title}` : ""}
                          {m.Taf3TypeId ? ` · سطح ۶: ${m.Taf3Title}` : ""}
                        </span>
                      </div>
                    ))}
                  </div>
                );
              })}
            </div>
          );
        })}
      </div>
      <p className="muted" style={{ marginTop: 10 }}>تعداد معین‌ها: {fa(rows.filter((r) => r.MoeinCode).length)}</p>
    </Shell>
  );
}
