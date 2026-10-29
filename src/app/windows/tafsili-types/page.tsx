"use client";

import Shell from "@/components/Shell";
import CrudWindow, { Col } from "@/components/CrudWindow";

/* [فرم اصلی: انواع تفصيل — v2.4.2 فهرست مبدأ]
   CodeListType مشخص می‌کند هنگام تعریف تفصیلیِ این نوع، کدام فهرست نمایش داده شود:
   PARTY=اشخاص (pob.Party) / BANK=بانک‌ها (pob.CodeList) / BRANCH=شعبه‌ها (AccBranch)
   خالی = عنوان آزاد (مثل «سایر») */

const cols: Col[] = [
  { key: "Title", label: "نوع تفصیل", required: true },
  { key: "LatinTitle", label: "شرح لاتین" },
  { key: "CodeListType", label: "فهرست مبدأ", type: "select", width: 170,
    options: [
      { v: "PARTY", t: "اشخاص و شرکت‌ها" },
      { v: "BANK", t: "بانک‌ها" },
      { v: "BRANCH", t: "شعبه‌ها" },
    ] },
];

/* [فرم اصلی: انواع تفصيل — نوع تفصيل، شرح لاتين] */
export default function Page() {
  return (
    <Shell title="انواع تفصیل" sub="نوع تفصیلی که معین‌ها به سطوح ۴/۵/۶ به آن متصل می‌شوند">
      <CrudWindow entity="tafsili-types" title="انواع تفصیل" cols={cols}
        note="فهرست مبدأ: هنگام تعریف تفصیلی از این نوع، به‌جای عنوان آزاد، همان فهرست نمایش داده می‌شود (اشخاص/بانک‌ها/شعبه‌ها). «—» یعنی عنوان آزاد — مناسب انواعی مثل «سایر» و «پروژه». حذف نوعی که به معین متصل است مجاز نیست." />
    </Shell>
  );
}
