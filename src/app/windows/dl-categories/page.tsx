"use client";

import Shell from "@/components/Shell";
import CrudWindow, { Col } from "@/components/CrudWindow";

const cols: Col[] = [{ key: "Title", label: "عنوان طبقه", required: true }];

/* [فرم اصلی: طبقه بندي تفصيلي] */
export default function Page() {
  return (
    <Shell title="طبقه‌بندی تفصیلی" sub="گروه‌بندی تفصیلی‌ها در طبقات گزارش‌گیری">
      <CrudWindow entity="dlctgries" title="طبقه‌بندی تفصیلی" cols={cols}
        note="تفصیلی‌های هر طبقه از پنجرهٔ معرفی حساب‌های تفصیلی به طبقه متصل می‌شوند." />
    </Shell>
  );
}
