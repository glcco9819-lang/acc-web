import { NextRequest, NextResponse } from "next/server";
import { getSession } from "@/lib/auth";
import { ctxOf } from "../common";
import { buildTarazMonthly, parseFilters, LEVEL_FA, MonthlyRow } from "../taraz-common";

/* تراز ماهانه [فرم: گزارش تحلیلی تراز ماهانه — AcRepDef]
   ستون اول = ماندهٔ ابتدای دوره (افتتاحیه)، سپس گردش بد/بس هر ماه شمسی، ستون پایان = مانده تا پایان بازه */
export async function GET(req: NextRequest) {
  const s = await getSession();
  if (!s) return NextResponse.json({ ok: false, error: "دسترسی رد شد" }, { status: 401 });
  const { companyId, yearId } = ctxOf(req);
  if (!companyId || !yearId) return NextResponse.json({ ok: false, error: "شرکت و سال مالی انتخاب نشده", code: "NO_CTX" }, { status: 400 });

  const sp = new URL(req.url).searchParams;
  const f = parseFilters(sp);
  const mFrom = Math.min(Math.max(Number(sp.get("mFrom") || 1), 1), 12);
  const mTo = Math.min(Math.max(Number(sp.get("mTo") || 12), mFrom), 12);

  const rows = await buildTarazMonthly(companyId, yearId, f);
  const months: string[] = [];
  for (let m = mFrom; m <= mTo; m++) months.push(String(m).padStart(2, "0"));

  const enriched = rows.map((r: MonthlyRow) => {
    const cells: Record<string, { Dbt: number; Crt: number }> = {};
    for (const mo of months) cells[mo] = r.Months[mo] || { Dbt: 0, Crt: 0 };
    /* ماندهٔ پایان بازه = ابتدا + ماه‌های ۱ تا پایان بازهٔ انتخابی (انباشته) */
    let EndDbt = r.OpDbt, EndCrt = r.OpCrt;
    for (let m = 1; m <= mTo; m++) { const b = r.Months[String(m).padStart(2, "0")]; if (b) { EndDbt += b.Dbt; EndCrt += b.Crt; } }
    const bal = EndDbt - EndCrt;
    return { ...r, Cells: cells, EndDbt, EndCrt, EndBalDbt: Math.max(bal, 0), EndBalCrt: Math.max(-bal, 0) };
  });

  const totals: Record<string, number> = { OpDbt: 0, OpCrt: 0, EndDbt: 0, EndCrt: 0 };
  for (const mo of months) { totals[`M${mo}D`] = 0; totals[`M${mo}C`] = 0; }
  for (const r of enriched) {
    totals.OpDbt += r.OpDbt; totals.OpCrt += r.OpCrt; totals.EndDbt += r.EndDbt; totals.EndCrt += r.EndCrt;
    for (const mo of months) { totals[`M${mo}D`] += r.Cells[mo].Dbt; totals[`M${mo}C`] += r.Cells[mo].Crt; }
  }

  return NextResponse.json({ ok: true, level: f.level, levelFa: LEVEL_FA[f.level], months, rows: enriched, totals });
}
