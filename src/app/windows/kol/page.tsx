"use client";

import { useEffect, useState } from "react";
import Shell from "@/components/Shell";
import CrudWindow, { Col } from "@/components/CrudWindow";
import { api, readCtxCookie } from "@/lib/ui";

/* [فرم اصلی: معرفي حسابهاي كل — گروه حساب، كد، عنوان، ماهيت حساب] */
export default function Page() {
  const [cols, setCols] = useState<Col[]>([]);
  const [groups, setGroups] = useState<any[]>([]);
  const [mode, setMode] = useState(2);

  useEffect(() => {
    (async () => {
      let { companyId } = readCtxCookie();
      if (!companyId) {
        /* پشتیبان: خواندن کانتکست از سرور در صورت نبود کوکی در سمت کلاینت */
        try { const j = await (await fetch("/api/context")).json(); if (j.ok && j.current?.CompanyId) companyId = j.current.CompanyId; } catch { /* - */ }
      }
      if (!companyId) return;
      api(`/api/acc/groups`).then((j) => { setGroups(j.rows || []); setMode(j.mode || 2); }).catch(() => {});
    })();
  }, []);

  useEffect(() => {
    setCols([
      { key: "Code", label: "کد کل", code: 4, required: true, width: 90 },
      ...(mode === 2 ? [{ key: "GroupCode", label: "گروه حساب", type: "select" as const, required: true, width: 130,
        options: groups.map((g) => ({ v: g.Code, t: `${g.Code} — ${g.Title}` })) }] : []),
      { key: "Title", label: "عنوان حساب کل", required: true },
      { key: "AccNature", label: "ماهیت حساب", type: "select", required: true, width: 110, default: "3",
        options: [{ v: 1, t: "بدهکار" }, { v: 2, t: "بستانکار" }, { v: 3, t: "دوطرفه" }] },
    ]);
  }, [groups, mode]);

  return (
    <Shell title="معرفی حساب‌های کل" sub="کد کل چهاررقم — دو رقم اول = کد گروه (حالت accdef)">
      {mode === 2 && !groups.length
        ? <p className="muted">ابتدا گروه حساب تعریف کنید.</p>
        : <CrudWindow entity="kol" title="حساب کل" cols={cols} note="تغییر کد کل پس از استفاده در سند مجاز نیست." />}
    </Shell>
  );
}
