"use client";

import Shell from "@/components/Shell";
import CrudWindow, { Col } from "@/components/CrudWindow";

const cols: Col[] = [
  { key: "Code", label: "کد گروه", code: 2, required: true, width: 90 },
  { key: "Title", label: "عنوان گروه", required: true },
  { key: "AccNature", label: "نوع حساب", type: "select", required: true, width: 110, default: "3",
    options: [{ v: 1, t: "بدهکار" }, { v: 2, t: "بستانکار" }, { v: 3, t: "دوطرفه" }] },
];

/* [فرم اصلی: معرفي گروه حساب — كد، عنوان، نوع حساب] */
export default function Page() {
  return (
    <Shell title="معرفی گروه حساب‌ها" sub="کد گروه دورقم — سطح اول کدینگ مطابق accdef">
      <CrudWindow entity="groups" title="گروه حساب" cols={cols}
        note="در کدینگ accdef، دو رقم اول حساب کل از کد گروه گرفته می‌شود. این پنجره در حالت کدینگ پلکانی استفاده نمی‌شود." />
    </Shell>
  );
}
