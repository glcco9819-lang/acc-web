"use client";

import Shell from "@/components/Shell";
import GenWindow, { GCol } from "@/components/GenWindow";

/* تنظیمات عمومی — YfgGen.AppSetting (ConfigCommon.bpl اصل: KeyValue/DataValue/SystemName)
   تقویم پیش‌فرض = شمسی (ملاک سامانه — دستور کارفرما) */

const cols: GCol[] = [
  { key: "KeyValue", label: "کلید", required: true, width: 170 },
  { key: "DataValue", label: "مقدار", required: true, width: 220 },
  { key: "SystemName", label: "سامانه", width: 100 },
  { key: "Descr", label: "شرح", width: 380 },
];

export default function Page() {
  return (
    <Shell title="تنظیمات عمومی سامانه" sub="اطلاعات عمومی — الگوی YfgGen.AppSetting اصل؛ شمسی بودن تقویم و بله/خیر بودن نمایش منطقی اینجا ملاک است">
      <GenWindow entity="app-setting" cols={cols} />
    </Shell>
  );
}
