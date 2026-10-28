"use client";

import Shell from "@/components/Shell";
import CrudWindow, { Col } from "@/components/CrudWindow";

const cols: Col[] = [
  { key: "Code", label: "کد ارز", required: true, width: 110 },
  { key: "Title", label: "عنوان ارز", required: true, width: 200 },
  { key: "LatinTitle", label: "عنوان لاتین" },
  { key: "IsBase", label: "ارز پایه", type: "bool", width: 90, default: 0 },
  { key: "IsActive", label: "فعال", type: "bool", width: 70, default: 1 },
];

/* [فرم اصلی: اطلاعات ارزها — accCurrency] مبلغ ارزي/نوع ارز/نرخ ارز در اقلام سند به این تعریف متصل است */
export default function Page() {
  return (
    <Shell title="تعریف ارزها" sub="ارز پایه (ریال) و ارزهای خارجی — نرخ هر سند در قلم ثبت می‌شود">
      <CrudWindow entity="fx" title="ارز" cols={cols}
        note="تنها یک ارز می‌تواند «ارز پایه» باشد؛ انتخاب ارز پایه تازه، نشان پایه را از ارز قبلی برمی‌دارد. سه‌تایی مبلغ ارزی/نوع/نرخ در قلم سند همیشه کامل ثبت می‌شود." />
    </Shell>
  );
}
