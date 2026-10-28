"use client";

import { useEffect, useState } from "react";
import Shell from "@/components/Shell";
import GenWindow, { GCol } from "@/components/GenWindow";
import { api } from "@/lib/ui";

/* تعطیلات و تقویم — gnCalndr.bpl اصل: YfgGen.Holiday + YfgGen.HolidayType
   تاریخ شمسی ملاک؛ معادل میلادی به‌صورت خودکار محاسبه و نمایش داده می‌شود (GDate) */

export default function Page() {
  const [types, setTypes] = useState<{ v: number; t: string }[]>([]);
  useEffect(() => {
    api("/api/gen/holidays").then((j) => setTypes(j.types || [])).catch(() => {});
  }, []);

  const cols: GCol[] = [
    { key: "JDate", label: "تاریخ (شمسی)", required: true, type: "jdate", width: 130 },
    { key: "GDate", label: "معادل میلادی", width: 130 },
    { key: "HolidayTypeRef", label: "نوع تعطیلی", type: "select", width: 140, options: types },
    { key: "Descr", label: "شرح", width: 320 },
  ];

  return (
    <Shell title="تعطیلات و تقویم" sub="اطلاعات عمومی — تاریخ شمسی ملاک است؛ معادل میلادی خودکار محاسبه می‌شود (قالب ورودی: 1405/01/01)">
      <GenWindow entity="holidays" cols={cols} />
    </Shell>
  );
}
