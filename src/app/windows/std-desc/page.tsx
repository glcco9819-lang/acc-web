"use client";

import { useEffect, useState } from "react";
import Shell from "@/components/Shell";
import CrudWindow, { Col } from "@/components/CrudWindow";
import { api } from "@/lib/ui";

/* [فرم اصلی: شرحهاي استاندارد] */
export default function Page() {
  const [moeins, setMoeins] = useState<any[]>([]);
  const [cols, setCols] = useState<Col[]>([]);

  useEffect(() => {
    api("/api/acc/moein").then((j) => setMoeins(j.rows || [])).catch(() => {});
  }, []);
  useEffect(() => {
    setCols([
      { key: "MoeinCode", label: "حساب معین", type: "select", required: true, width: 220,
        options: moeins.map((m) => ({ v: m.Code, t: `${m.Code} — ${m.Title}` })) },
      { key: "Seq", label: "ترتیب", type: "num", required: true, width: 70 },
      { key: "DescText", label: "شرح استاندارد", required: true },
    ]);
  }, [moeins]);

  return (
    <Shell title="شرح‌های استاندارد" sub="شرح‌های آماده برای انتخاب در ردیف‌های سند">
      {moeins.length
        ? <CrudWindow entity="stddesc" title="شرح استاندارد" cols={cols} />
        : <p className="muted">ابتدا معین تعریف کنید.</p>}
    </Shell>
  );
}
