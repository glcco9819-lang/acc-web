"use client";

import Shell from "@/components/Shell";
import CrudWindow, { Col } from "@/components/CrudWindow";

const cols: Col[] = [
  { key: "Title", label: "نوع تفصیل", required: true },
  { key: "LatinTitle", label: "شرح لاتین" },
];

/* [فرم اصلی: انواع تفصيل — نوع تفصيل، شرح لاتين] */
export default function Page() {
  return (
    <Shell title="انواع تفصیل" sub="نوع تفصیلی که معین‌ها به سطوح ۴/۵/۶ به آن متصل می‌شوند">
      <CrudWindow entity="tafsili-types" title="انواع تفصیل" cols={cols}
        note="انواع تفصیل مثال: مشتری، تأمین‌کننده، بانک، شعبه، پروژه. حذف نوعی که به معین متصل است مجاز نیست." />
    </Shell>
  );
}
