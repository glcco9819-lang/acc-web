"use client";

import Shell from "@/components/Shell";
import CrudWindow, { Col } from "@/components/CrudWindow";

const cols: Col[] = [
  { key: "Title", label: "نوع سند", required: true },
  { key: "LatinTitle", label: "شرح لاتین" },
];

/* [فرم اصلی: تعريف انواع سند — نوع سند، شرح لاتين] */
export default function Page() {
  return (
    <Shell title="تعریف انواع سند" sub="طبقه‌بندی اسناد (افتتاحیه/فروش/خرید/دریافت/پرداخت/عمومی و…)">
      <CrudWindow entity="vchtypes" title="انواع سند" cols={cols}
        note="نوع «سند افتتاحیه» توسط سیستم برای صدور افتتاحیه استفاده می‌شود." />
    </Shell>
  );
}
