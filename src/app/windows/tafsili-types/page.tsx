"use client";

import Shell from "@/components/Shell";
import CrudWindow, { Col } from "@/components/CrudWindow";

/* [فرم اصلی: انواع تفصيل — v2.4.3 فهرست استاندارد کامل بر اساس فایل اولیه و سند ۹۰]
   CodeListType مشخص می‌کند هنگام تعریف تفصیلیِ این نوع، کدام فهرست نمایش داده شود:
     PARTY      → اشخاص و شرکت‌ها (pob.Party)
     BANK       → بانک‌ها (pob.CodeList → Type=BANK)
     BRANCH     → شعبه‌ها (ACC.AccBranch)
     PROJECT    → پروژه‌ها (pob.CodeList → Type=PROJECT)
     CASH       → صندوق‌ها (pob.CodeList → Type=CASH)
     COSTCENTER → مراکز هزینه (pob.CodeList → Type=COSTCENTER)
     EMPLOYEE   → کارمندها (pob.CodeList → Type=EMPLOYEE)
     GOODS      → کالاها (pob.CodeList → Type=GOODS)
     CHECK      → چک‌ها (pob.CodeList → Type=CHECK)
     LC         → اعتبارات اسنادی (pob.CodeList → Type=LC)
     خالی       → عنوان آزاد (مثل «سایر») */

const CLS_OPTIONS = [
  { v: "", t: "— عنوان آزاد (بدون فهرست مبدأ)" },
  { v: "PARTY", t: "اشخاص و شرکت‌ها" },
  { v: "BANK", t: "بانک‌ها" },
  { v: "BRANCH", t: "شعبه‌ها" },
  { v: "PROJECT", t: "پروژه‌ها" },
  { v: "CASH", t: "صندوق‌ها" },
  { v: "COSTCENTER", t: "مراکز هزینه" },
  { v: "EMPLOYEE", t: "کارمندها" },
  { v: "GOODS", t: "کالاها" },
  { v: "CHECK", t: "چک‌ها" },
  { v: "LC", t: "اعتبارات اسنادی" },
];

const cols: Col[] = [
  { key: "Title", label: "نوع تفصیل", required: true },
  { key: "LatinTitle", label: "شرح لاتین" },
  { key: "CodeListType", label: "فهرست مبدأ", type: "select", width: 200,
    options: CLS_OPTIONS },
];

/* [فرم اصلی: انواع تفصيل — نوع تفصيل، شرح لاتين] */
export default function Page() {
  return (
    <Shell title="انواع تفصیل" sub="فهرست استاندارد کامل — هر نوع به فهرست مبدأ خود وصل است">
      <CrudWindow entity="tafsili-types" title="انواع تفصیل" cols={cols}
        note="فهرست مبدأ هر نوع، تعیین می‌کند در «معرفی حساب‌های تفصیلی» هنگام انتخاب این نوع، کدام فهرست نمایش داده شود — و تعریف رکورد جدید همان نوع از همان‌جا ممکن است (اشخاص، بانک‌ها، شعبه‌ها، پروژه‌ها، صندوق‌ها، مراکز هزینه، کارمندها، کالاها، چک‌ها، اعتبارات اسنادی). «—» یعنی عنوان آزاد — مناسب «سایر». حذف نوعی که به معین متصل است مجاز نیست." />
    </Shell>
  );
}
