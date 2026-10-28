import { NextRequest, NextResponse } from "next/server";
import { getSession } from "@/lib/auth";
import { ctxOf } from "../common";
import { buildTaraz, parseFilters, LEVEL_FA } from "../taraz-common";

/* تراز اسناد شش‌سطحی [فرم: گزارش تراز اسناد شش سطحي — AcRepDef]
   شش ستون: ماندهٔ ابتدا (بد/بس) + گردش دوره (بد/بس) + ماندهٔ پایان (بد/بس) در سطح انتخابی */
export async function GET(req: NextRequest) {
  const s = await getSession();
  if (!s) return NextResponse.json({ ok: false, error: "دسترسی رد شد" }, { status: 401 });
  const { companyId, yearId } = ctxOf(req);
  if (!companyId || !yearId) return NextResponse.json({ ok: false, error: "شرکت و سال مالی انتخاب نشده", code: "NO_CTX" }, { status: 400 });

  const f = parseFilters(new URL(req.url).searchParams);
  const rows = await buildTaraz(companyId, yearId, f);

  const enriched = rows.map((r) => {
    /* ماندهٔ ابتدا = افتتاحیه (در صورت تیک) + حرکات قبل از «از تاریخ»؛ گردش = طی بازه */
    const iDbt = (f.withOpening ? r.OpDbt : 0) + r.PreDbt;
    const iCrt = (f.withOpening ? r.OpCrt : 0) + r.PreCrt;
    const eBal = (iDbt + r.Dbt) - (iCrt + r.Crt);
    return { ...r, InitDbt: iDbt, InitCrt: iCrt, EndDbt: Math.max(eBal, 0), EndCrt: Math.max(-eBal, 0) };
  });
  const totals = enriched.reduce((a, r) => ({
    InitDbt: a.InitDbt + r.InitDbt, InitCrt: a.InitCrt + r.InitCrt,
    Dbt: a.Dbt + r.Dbt, Crt: a.Crt + r.Crt,
    EndDbt: a.EndDbt + r.EndDbt, EndCrt: a.EndCrt + r.EndCrt,
  }), { InitDbt: 0, InitCrt: 0, Dbt: 0, Crt: 0, EndDbt: 0, EndCrt: 0 });

  return NextResponse.json({ ok: true, level: f.level, levelFa: LEVEL_FA[f.level], rows: enriched, totals });
}
