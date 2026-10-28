"use client";

import Shell from "@/components/Shell";
import GenWindow, { GCol } from "@/components/GenWindow";

/* معرفی موقعیت‌های جغرافیایی — OF0004 (TFrmGeoPos در GnrGeneral.bpl) — pob.GeoPlace
   1=کشور 2=استان 3=شهرستان 4=شهر */

const cols: GCol[] = [
  { key: "Title", label: "عنوان", required: true, width: 220 },
  { key: "GeoType", label: "نوع", type: "select", required: true, width: 110, options: [
    { v: 1, t: "کشور" }, { v: 2, t: "استان" }, { v: 3, t: "شهرستان" }, { v: 4, t: "شهر" },
  ], default: 2 },
  { key: "ParentRef", label: "والد (شناسه)", type: "num", width: 120 },
  { key: "LatinTitle", label: "عنوان لاتین", width: 160 },
];

export default function Page() {
  return (
    <Shell title="معرفی موقعیت‌های جغرافیایی" sub="اطلاعات عمومی — OF0004؛ کشور/استان/شهرستان/شهر — ایران به‌صورت پیش‌فرض ثبت شده است">
      <GenWindow entity="geo-place" cols={cols} />
    </Shell>
  );
}
