"use client";

import { useEffect, useState } from "react";
import Shell from "@/components/Shell";
import CrudWindow, { Col } from "@/components/CrudWindow";
import { api } from "@/lib/ui";

/* [فرم اصلی: معرفي حسابهاي معين — حساب كل، كد، ارتباط معين با سطوح تفصيلي چهارم/پنجم/ششم،
   ماهيت حساب، ويژگيها (پيگيري/تعدادي/ارزي/تسعيرپذير)، وضعيت حساب] */
export default function Page() {
  const [kols, setKols] = useState<any[]>([]);
  const [dltypes, setDltypes] = useState<any[]>([]);
  const [mode, setMode] = useState(2);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    Promise.all([api("/api/acc/kol"), api("/api/acc/dltypes")])
      .then(([a, b]) => { setKols(a.rows || []); setMode(a.mode || 2); setDltypes(b.rows || []); setReady(true); })
      .catch(() => setReady(true));
  }, []);

  const cols: Col[] = [
    { key: "Code", label: "کد معین", code: 6, required: true, width: 95 },
    { key: "KolCode", label: "حساب کل", type: "select", required: true, width: 200,
      options: kols.map((k) => ({ v: k.Code, t: `${k.Code} — ${k.Title}` })) },
    { key: "Title", label: "عنوان معین", required: true },
    { key: "AccNature", label: "ماهیت", type: "select", required: true, width: 95, default: "3",
      options: [{ v: 1, t: "بدهکار" }, { v: 2, t: "بستانکار" }, { v: 3, t: "دوطرفه" }] },
    { key: "Dl1TypeId", label: "تفصیلی سطح ۴ (الزامی)", type: "select", width: 140,
      options: dltypes.map((t) => ({ v: t.DlTypeId, t: t.Title })) },
    { key: "Dl2TypeId", label: "تفصیلی سطح ۵", type: "select", width: 130,
      options: dltypes.map((t) => ({ v: t.DlTypeId, t: t.Title })) },
    { key: "Dl3TypeId", label: "تفصیلی سطح ۶", type: "select", width: 130,
      options: dltypes.map((t) => ({ v: t.DlTypeId, t: t.Title })) },
    { key: "Trackable", label: "پیگیری", type: "bool", width: 70, default: "0", options: [{ v: 1, t: "بله" }, { v: 0, t: "خیر" }] },
    { key: "Countable", label: "تعدادی", type: "bool", width: 65, default: "0", options: [{ v: 1, t: "بله" }, { v: 0, t: "خیر" }] },
    { key: "IsFx", label: "ارزی", type: "bool", width: 60, default: "0", options: [{ v: 1, t: "بله" }, { v: 0, t: "خیر" }] },
    { key: "FxConvertible", label: "تسعیرپذیر", type: "bool", width: 85, default: "0", options: [{ v: 1, t: "بله" }, { v: 0, t: "خیر" }] },
    { key: "IsActive", label: "فعال", type: "bool", width: 60, default: "1", options: [{ v: 1, t: "فعال" }, { v: 0, t: "غیرفعال" }] },
  ];

  return (
    <Shell title="معرفی حساب‌های معین" sub="کد معین شش‌رقم — چهار رقم اول = کد کل (حالت accdef)">
      {!ready ? <p className="muted">…</p>
        : kols.length
          ? <CrudWindow entity="moein" title="حساب معین" cols={cols}
              note="سطوح تفصیلی باید متمایز باشند. ردیف سند برای معینِ دارای سطح تفصیلی، الزاماً تفصیلی همان نوع را می‌پذیرد." />
          : <p className="muted">ابتدا حساب کل تعریف کنید.</p>}
    </Shell>
  );
}
