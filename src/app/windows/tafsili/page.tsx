"use client";

import { useEffect, useState } from "react";
import Shell from "@/components/Shell";
import CrudWindow, { Col } from "@/components/CrudWindow";
import { api } from "@/lib/ui";

/* [فرم اصلی: معرفي حسابهاي تفصيل — كد، عنوان، نوع تفصيل، عنوان لاتين، وضعيت حساب فعال/غيرفعال] */
export default function Page() {
  const [types, setTypes] = useState<any[]>([]);
  const [ctgries, setCtgries] = useState<any[]>([]);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    Promise.all([api("/api/acc/tafsili-types"), api("/api/acc/tafsili-ctgries")])
      .then(([a, b]) => { setTypes(a.rows || []); setCtgries(b.rows || []); setReady(true); })
      .catch(() => setReady(true));
  }, []);

  const cols: Col[] = [
    { key: "Code", label: "کد تفصیلی", code: 8, required: true, width: 105 },
    { key: "TafsiliTypeId", label: "نوع تفصیل", type: "select", required: true, width: 130,
      options: types.map((t) => ({ v: t.TafsiliTypeId, t: t.Title })) },
    { key: "Title", label: "عنوان تفصیلی", required: true },
    { key: "LatinTitle", label: "عنوان لاتین" },
    { key: "IsActive", label: "وضعیت", type: "bool", width: 80, default: "1", options: [{ v: 1, t: "فعال" }, { v: 0, t: "غیرفعال" }] },
  ];

  return (
    <Shell title="معرفی حساب‌های تفصیلی" sub="کد تفصیلی هشترقمی — تفصیلی والد ندارد">
      {!ready ? <p className="muted">…</p>
        : types.length
          ? <CrudWindow entity="tafsili" title="حساب تفصیلی" cols={cols}
              note="تفصیلی به معین وصل نیست؛ نوع تفصیل آن باید با یکی از سطوح ۴/۵/۶ معین هم‌خوان باشد تا در سند پذیرفته شود." />
          : <p className="muted">ابتدا نوع تفصیل تعریف کنید.</p>}
    </Shell>
  );
}
