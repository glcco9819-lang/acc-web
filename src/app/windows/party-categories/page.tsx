"use client";

import Shell from "@/components/Shell";
import GenWindow, { GCol } from "@/components/GenWindow";

/* تعریف طبقه‌بندی اشخاص — OF0003 (HumCmp.bpl) — pob.PartyCategory */

const cols: GCol[] = [
  { key: "Title", label: "عنوان طبقه‌بندی", required: true, width: 280 },
  { key: "ParentRef", label: "طبقهٔ والد", type: "num", width: 110, hideInGrid: false },
];

export default function Page() {
  return (
    <Shell title="تعریف طبقه‌بندی اشخاص و شرکت‌ها" sub="اطلاعات عمومی — OF0003؛ برای اختصاص طبقه به شخص: پنجرهٔ اشخاص → برگهٔ طبقه‌بندی">
      <GenWindow entity="party-ctgry" cols={cols} />
    </Shell>
  );
}
