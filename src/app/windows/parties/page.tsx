"use client";

import { useCallback, useEffect, useState } from "react";
import Shell from "@/components/Shell";
import GenWindow, { GCol } from "@/components/GenWindow";
import { api } from "@/lib/ui";

/* معرفی اشخاص و شرکت‌های طرف مکاتبه — OF0001/0002/0005/0006 (HumCmp.bpl)
   ساختار وفادار pob.Party + pob.PartyAddress + pob.PartyCategoryLink اصل */

const COMP_TYPES = [
  { v: 1, t: "شخص حقیقی" }, { v: 2, t: "شخص حقوقی" }, { v: 3, t: "موسسه دولتی" },
];

const cols: GCol[] = [
  { key: "RecType", label: "نوع", type: "select", required: true, width: 90, options: [{ v: "CMP", t: "شرکت" }, { v: "MAN", t: "شخص" }], default: "CMP" },
  { key: "Title", label: "عنوان", width: 220 },
  { key: "FName", label: "نام", width: 130 },
  { key: "LName", label: "نام خانوادگی", width: 150 },
  { key: "NationalCode", label: "کد/شناسه ملی", width: 130 },
  { key: "EconCode", label: "کد اقتصادی", width: 120 },
  { key: "PartyKind", label: "نوع شخص", type: "select", options: COMP_TYPES, width: 110 },
  { key: "FatherName", label: "نام پدر", width: 120, hideInGrid: true },
  { key: "IDNo", label: "شماره شناسنامه", width: 120, hideInGrid: true },
  { key: "NickName", label: "لقب", width: 120, hideInGrid: true },
  { key: "CompName", label: "نام شرکت (مکمل)", width: 160, hideInGrid: true },
  { key: "Title_En", label: "عنوان لاتین", width: 160, hideInGrid: true },
  { key: "FName_En", label: "نام لاتین", width: 140, hideInGrid: true },
  { key: "LName_En", label: "نام خانوادگی لاتین", width: 150, hideInGrid: true },
  { key: "IsActive", label: "فعال", type: "bool", width: 70, default: 1 },
];

export default function Page() {
  const [sel, setSel] = useState<any>(null);
  const [tab, setTab] = useState<"addr" | "cat">("addr");
  const [ctgries, setCtgries] = useState<{ v: number; t: string }[]>([]);

  useEffect(() => {
    api("/api/gen/party-ctgry").then((j) => setCtgries((j.rows || []).map((r: any) => ({ v: r.CategoryId, t: r.Title })))).catch(() => {});
  }, []);

  const selTitle = sel ? (sel.Title || [sel.FName, sel.LName].filter(Boolean).join(" ") || `#${sel.Serial}`) : "";
  const pickerLoader = useCallback(async () => (sel ? [{ v: sel.Serial, t: selTitle }] : []), [sel, selTitle]);

  const addrCols: GCol[] = [
    { key: "Title", label: "عنوان نشانی", width: 140 },
    { key: "Address", label: "نشانی", width: 300 },
    { key: "ZipCode", label: "کد پستی", width: 100 },
    { key: "PostBox", label: "صندوق پستی", width: 100 },
    { key: "Phone", label: "تلفن", width: 110 },
    { key: "Fax", label: "دورنگار", width: 110, hideInGrid: true },
    { key: "EMail", label: "رایانامه", width: 150 },
    { key: "Mobile", label: "تلفن همراه", width: 120 },
  ];

  return (
    <Shell title="معرفی اشخاص و شرکت‌های طرف مکاتبه" sub="اطلاعات عمومی — عیناً مطابق پنجره‌های اصل (OF0001/0002/0005/0006)">
      <div style={{ display: "grid", gridTemplateColumns: "minmax(320px,1fr) 380px", gap: 16, alignItems: "start" }}>
        <GenWindow entity="party" cols={cols} note="پس از ثبت، با دکمهٔ «اصلاح» هر ردیف، پنل نشانی/طبقه‌بندی همان شخص باز می‌شود" />
        <div className="scrollbox" style={{ position: "sticky", top: 12 }}>
          <div style={{ borderBottom: "1px solid var(--line)", display: "flex", gap: 4, padding: "8px 8px 0" }}>
            <button className={`btn ${tab === "addr" ? "primary" : ""}`} style={{ padding: "2px 10px" }} onClick={() => setTab("addr")}>نشانی‌ها</button>
            <button className={`btn ${tab === "cat" ? "primary" : ""}`} style={{ padding: "2px 10px" }} onClick={() => setTab("cat")}>طبقه‌بندی</button>
          </div>
          {!sel ? (
            <p className="muted" style={{ padding: 14 }}>یک شخص/شرکت را از جدول انتخاب کنید — دکمهٔ «اصلاح» آن ردیف را بزنید</p>
          ) : tab === "addr" ? (
            <GenWindow key={`addr-${sel.Serial}`} entity="address" cols={addrCols}
              parent={{ key: "PartyRef", label: "شخص/شرکت", load: pickerLoader }} />
          ) : (
            <GenWindow key={`cat-${sel.Serial}`} entity="party-cat" cols={[{ key: "CategoryRef", label: "طبقه‌بندی", type: "select", required: true, options: ctgries }]}
              parent={{ key: "PartyRef", label: "شخص/شرکت", load: pickerLoader }} />
          )}
        </div>
      </div>
      <SelBridge onPick={setSel} />
    </Shell>
  );
}

function SelBridge({ onPick }: { onPick: (r: any) => void }) {
  useEffect(() => {
    const h = (e: Event) => {
      const d = (e as CustomEvent).detail;
      if (d?.entity === "party") onPick(d.row);
    };
    window.addEventListener("gen-row-edit", h);
    return () => window.removeEventListener("gen-row-edit", h);
  }, [onPick]);
  return null;
}
