"use client";

import { useEffect, useState, useRef } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { api } from "@/lib/ui";

export default function Shell({ children, title, sub }: { children: React.ReactNode; title: string; sub?: string }) {
  const [ctx, setCtx] = useState<any>(null);
  const [open, setOpen] = useState<string | null>(null);
  const path = usePathname();
  const router = useRouter();
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    fetch("/api/context").then((r) => r.json()).then((j) => {
      if (!j.ok) { router.replace("/login"); return; }
      const cur = j.current || null;
      setCtx({
        companyId: cur?.CompanyId || 0,
        company: cur || undefined,
        user: j.user, can: j.can,
      });
    }).catch(() => router.replace("/login"));
    const h = (e: MouseEvent) => { if (ref.current && !ref.current.contains(e.target as Node)) setOpen(null); };
    document.addEventListener("click", h);
    return () => document.removeEventListener("click", h);
  }, []);

  const setCompany = async (v: string) => {
    const companyId = Number(v || 0);
    await api("/api/context", { method: "POST", body: JSON.stringify({ companyId, yearId: 0 }) });
    location.reload();
  };
  const setYear = async (v: string) => {
    const yearId = Number(v || 0);
    await api("/api/context", { method: "POST", body: JSON.stringify({ companyId: ctx.companyId, yearId }) });
    location.reload();
  };
  const logout = async () => { await api("/api/auth/login", { method: "DELETE" }); router.replace("/login"); };

  if (!ctx) return <div style={{ padding: 40, textAlign: "center", color: "#666" }}>در حال بارگذاری…</div>;

  return (
    <>
      <div className="menubar" ref={ref}>
        <span className="brand">YFG ACC-WEB · ماژول حسابداری</span>
        {MENUS.map((g) => (
          <div key={g.title} className={`menu-group ${open === g.title ? "open" : ""}`}>
            <button onClick={() => setOpen(open === g.title ? null : g.title)}>{g.title}</button>
            <div className="menu-drop">
              {g.items.map(([href, label]) => (
                <Link key={href} href={href} onClick={() => setOpen(null)}
                  style={path === href ? { background: "#e8eef4", fontWeight: "bold" } : undefined}>{label}</Link>
              ))}
            </div>
          </div>
        ))}
      </div>
      <div className="ctxbar">
        <span>شرکت:</span>
        <CompanySelect value={ctx.company?.CompanyId || 0} onChange={setCompany} />
        <span>سال مالی:</span>
        <YearSelect companyId={ctx.companyId} value={ctx.company?.YearId || 0} onChange={setYear} />
        {ctx.company && <span className="badge src">کدینگ: {ctx.company.CodingMode === 2 ? "مطابق accdef (گروه/کل/معین)" : "پلکانی"}</span>}
        <span className="user">کاربر: <b>{ctx.user?.display}</b> ({ctx.user?.role === "admin" ? "مدیر" : ctx.user?.role === "registrar" ? "ثبت‌کننده" : "بررسی‌کننده"})</span>
        <button className="btn" onClick={logout} style={{ padding: "2px 10px" }}>خروج</button>
      </div>
      <div className="main">
        <div className="window">
          <div className="window-title"><span>{title}</span>{sub && <span className="sub">{sub}</span>}</div>
          <div className="window-body">{children}</div>
        </div>
      </div>
    </>
  );
}

function CompanySelect({ value, onChange }: { value: number; onChange: (v: string) => void }) {
  const [rows, setRows] = useState<any[]>([]);
  useEffect(() => { fetch("/api/prm/company").then((r) => r.json()).then((j) => j.ok && setRows(j.rows)).catch(() => {}); }, []);
  return (
    <select value={value || ""} onChange={(e) => onChange(e.target.value)}>
      <option value="">— انتخاب شرکت —</option>
      {rows.map((r) => <option key={r.CompanyId} value={r.CompanyId}>{r.CompanyCode} — {r.TitleFa}</option>)}
    </select>
  );
}

function YearSelect({ companyId, value, onChange }: { companyId: number; value: number; onChange: (v: string) => void }) {
  const [rows, setRows] = useState<any[]>([]);
  useEffect(() => {
    if (!companyId) return;
    fetch(`/api/prm/year?companyId=${companyId}`).then((r) => r.json()).then((j) => j.ok && setRows(j.rows)).catch(() => {});
  }, [companyId]);
  return (
    <select value={value || ""} onChange={(e) => onChange(e.target.value)}>
      <option value="">— انتخاب سال —</option>
      {rows.map((r) => <option key={r.YearId} value={r.YearId}>{r.Title}{r.IsClosed ? " (بسته)" : ""}</option>)}
    </select>
  );
}

const MENUS: { title: string; items: [string, string][] }[] = [
  {
    title: "حساب‌ها",
    items: [
      ["/windows/groups", "معرفی گروه حساب‌ها"],
      ["/windows/kol", "معرفی حساب‌های کل"],
      ["/windows/moein", "معرفی حساب‌های معین"],
      ["/windows/dl-types", "انواع تفصیل"],
      ["/windows/dl", "معرفی حساب‌های تفصیلی"],
      ["/windows/dl-categories", "طبقه‌بندی تفصیلی"],
      ["/windows/std-desc", "شرح‌های استاندارد"],
      ["/windows/chart", "گزارش مجموعه حساب‌ها (شجره)"],
    ],
  },
  {
    title: "اسناد حسابداری",
    items: [
      ["/windows/vch-types", "تعریف انواع سند"],
      ["/windows/vch-issue", "صدور سند حسابداری"],
      ["/windows/vch-review", "بررسی اسناد"],
      ["/windows/vch-finalize", "قطعی کردن اسناد"],
      ["/windows/vch-reverse", "برگشت اسناد قطعی"],
    ],
  },
  {
    title: "مرور و دفاتر",
    items: [
      ["/windows/browse", "مرور حساب‌ها"],
      ["/windows/book-journal", "دفتر روزنامه"],
      ["/windows/book-kol", "دفتر کل"],
      ["/windows/book-moein", "دفتر معین"],
      ["/windows/book-tafsili", "دفتر تفصیلی"],
    ],
  },
  {
    title: "عملیات پایه",
    items: [
      ["/windows/companies", "معرفی شرکت‌ها"],
      ["/windows/fiscal-year", "سال مالی"],
      ["/windows/opening", "ماندهٔ ابتدای دوره و سند افتتاحیه"],
      ["/windows/update", "آپدیت آنلاین"],
    ],
  },
];
