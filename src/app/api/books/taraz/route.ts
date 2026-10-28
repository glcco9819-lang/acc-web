import { NextRequest, NextResponse } from "next/server";
import { getSession } from "@/lib/auth";
import { ctxOf } from "../common";
import { buildTaraz, parseFilters, LEVEL_FA } from "../taraz-common";

/* گزارش تراز [فرم: گزارش تراز — AcRepDef]
   گردش بدهکار/بستانکار + ماندهٔ بدهکار/بستانکار در سطح کل/معین/تفصیلی */
export async function GET(req: NextRequest) {
  const s = await getSession();
  if (!s) return NextResponse.json({ ok: false, error: "دسترسی رد شد" }, { status: 401 });
  const { companyId, yearId } = ctxOf(req);
  if (!companyId || !yearId) return NextResponse.json({ ok: false, error: "شرکت و سال مالی انتخاب نشده", code: "NO_CTX" }, { status: 400 });

  const f = parseFilters(new URL(req.url).searchParams);
  const rows = await buildTaraz(companyId, yearId, f);

  /* گردش: بدون «از تاریخ» → افتتاحیه داخل گردش می‌آید (مطابق گزینهٔ «با در نظر گرفتن سند افتتاحیه»)
     با «از تاریخ» → گردش طی بازه؛ مانده = ابتدا + قبل از بازه + طی بازه */
  const includeOpInMove = f.withOpening && !f.from;
  const enriched = rows.map((r) => {
    const mDbt = (includeOpInMove ? r.OpDbt : 0) + r.PreDbt + r.Dbt;
    const mCrt = (includeOpInMove ? r.OpCrt : 0) + r.PreCrt + r.Crt;
    const bal = mDbt - mCrt;
    return { ...r, MDbt: mDbt, MCrt: mCrt, BalDbt: Math.max(bal, 0), BalCrt: Math.max(-bal, 0) };
  });
  const totals = enriched.reduce((a, r) => ({
    MDbt: a.MDbt + r.MDbt, MCrt: a.MCrt + r.MCrt, BalDbt: a.BalDbt + r.BalDbt, BalCrt: a.BalCrt + r.BalCrt,
  }), { MDbt: 0, MCrt: 0, BalDbt: 0, BalCrt: 0 });

  return NextResponse.json({ ok: true, level: f.level, levelFa: LEVEL_FA[f.level], rows: enriched, totals });
}
