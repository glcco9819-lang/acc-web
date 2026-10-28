"use client";

import Shell from "@/components/Shell";
import CrudWindow, { Col } from "@/components/CrudWindow";

const cols: Col[] = [
  { key: "Code", label: "کد شعبه", required: true, width: 110 },
  { key: "Title", label: "عنوان شعبه", required: true, width: 260 },
  { key: "IsActive", label: "فعال", type: "bool", width: 70, default: 1 },
];

/* [فرم اصلی: تعریف شعبه — acVchDef] شعبه در سرسند (صدور سند حسابداري) انتخاب می‌شود */
export default function Page() {
  return (
    <Shell title="تعریف شعبه" sub="شعب شرکت برای تفکیک اسناد — انتخاب در سرسند صدور سند">
      <CrudWindow entity="branch" title="شعبه" cols={cols} />
    </Shell>
  );
}
