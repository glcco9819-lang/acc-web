import { NextResponse } from "next/server";
import { one } from "@/lib/db";
import { isValidJalali } from "@/lib/jalali";

/* ============================================================================
   اعتبارسنجی اقلام سند — مشترک میان «صدور سند» و «ویرایش سند» (v2.2.0)
   قواعد فرم اصلی: کد کل ۴ رقمی، معین ۶ رقمی زیرمجموعهٔ همان کل،
   تفصیلی‌های الزامی مطابق سطوح ۴/۵/۶ معین، ارز سه‌تایی کامل،
   پیگیری شماره+تاریخ، تراز بدهکار/بستانکار
   ============================================================================ */

export interface ItemIn {
  KolCode: string; MoeinCode: string;
  Taf1Id?: number | null; Taf2Id?: number | null; Taf3Id?: number | null;
  Descr?: string; Dbt?: number | string; Crt?: number | string;
  FxId?: number | null; FxAmount?: number | string | null; FxRate?: number | string | null;
  TrackNo?: string; TrackDate?: string; LatinDescr?: string;
}

export interface OutItem {
  KolCode: string; MoeinCode: string;
  Taf1Id: number | null; Taf2Id: number | null; Taf3Id: number | null;
  Descr: string | null; Dbt: number; Crt: number;
  FxId: number | null; FxAmount: number | null; FxRate: number | null;
  TrackNo: string | null; TrackDate: string | null; LatinDescr: string | null;
}

/* خروجی: یا items پاک‌سازی‌شده، یا پاسخ خطای آمادهٔ ارسال */
export async function validateVoucherItems(
  items: ItemIn[], companyId: number,
): Promise<{ items: OutItem[]; totalDbt: number; totalCrt: number } | { error: NextResponse }> {
  let totalDbt = 0, totalCrt = 0;
  const cleaned: OutItem[] = [];

  for (let i = 0; i < items.length; i++) {
    const it = items[i];
    const kol = String(it.KolCode || "").trim();
    const moein = String(it.MoeinCode || "").trim();
    const dbt = Math.round(Number(it.Dbt || 0));
    const crt = Math.round(Number(it.Crt || 0));
    if (!/^\d{4}$/.test(kol)) return { error: NextResponse.json({ ok: false, error: `ردیف ${i + 1}: کد کل باید ۴ رقم باشد` }, { status: 400 }) };
    if (!/^\d{6}$/.test(moein)) return { error: NextResponse.json({ ok: false, error: `ردیف ${i + 1}: کد معین باید ۶ رقم باشد` }, { status: 400 }) };
    if (dbt > 0 && crt > 0) return { error: NextResponse.json({ ok: false, error: `ردیف ${i + 1}: هم‌زمان بدهکار و بستانکار` }, { status: 400 }) };
    if (dbt === 0 && crt === 0) return { error: NextResponse.json({ ok: false, error: `ردیف ${i + 1}: مبلغ صفر` }, { status: 400 }) };

    const m = await one<any>("SELECT Code, KolCode, Title, Taf1TypeId, Taf2TypeId, Taf3TypeId FROM ACC.AccMoein WHERE CompanyId=@c AND Code=@m AND KolCode=@k",
      { c: companyId, m: moein, k: kol });
    if (!m) return { error: NextResponse.json({ ok: false, error: `ردیف ${i + 1}: معین ${moein} زیرمجموعهٔ کل ${kol} نیست` }, { status: 400 }) };

    /* اعتبار تفصیلی‌ها مطابق ارتباط معین با سطوح چهارم/پنجم/ششم */
    const slots: [number | null, "Taf1Id" | "Taf2Id" | "Taf3Id", string][] = [
      [m.Taf1TypeId, "Taf1Id", "چهارم"], [m.Taf2TypeId, "Taf2Id", "پنجم"], [m.Taf3TypeId, "Taf3Id", "ششم"],
    ];
    const out: Record<string, number | null> = {};
    for (const [needType, field, label] of slots) {
      const given = (it as any)[field];
      if (needType) {
        if (!given) return { error: NextResponse.json({ ok: false, error: `ردیف ${i + 1}: تفصیلی سطح ${label} برای معین ${moein} الزامی است` }, { status: 400 }) };
        const d = await one<{ TafsiliId: number }>("SELECT TafsiliId FROM ACC.AccTafsili WHERE TafsiliId=@d AND CompanyId=@c AND TafsiliTypeId=@t AND IsActive=1", { d: given, c: companyId, t: needType });
        if (!d) return { error: NextResponse.json({ ok: false, error: `ردیف ${i + 1}: تفصیلی انتخابی سطح ${label} با نوع معین ${moein} هم‌خوان نیست` }, { status: 400 }) };
        out[field] = given;
      } else {
        if (given) return { error: NextResponse.json({ ok: false, error: `ردیف ${i + 1}: معین ${moein} سطح تفصیلی ${label} ندارد` }, { status: 400 }) };
        out[field] = null;
      }
    }

    totalDbt += dbt; totalCrt += crt;

    /* ارز قلم — سه‌تایی نوع/مبلغ/نرخ همیشه کامل یا هیچ [accCurrency + CK_Line_Fx] */
    const fxId = it.FxId ? Number(it.FxId) : null;
    const fxAmount = it.FxAmount === undefined || it.FxAmount === null || it.FxAmount === "" ? null : Number(it.FxAmount);
    const fxRate = it.FxRate === undefined || it.FxRate === null || it.FxRate === "" ? null : Number(it.FxRate);
    if (fxId === null && (fxAmount !== null || fxRate !== null))
      return { error: NextResponse.json({ ok: false, error: `ردیف ${i + 1}: برای ثبت ارز، نوع ارز الزامی است` }, { status: 400 }) };
    if (fxId !== null && (fxAmount === null || fxRate === null))
      return { error: NextResponse.json({ ok: false, error: `ردیف ${i + 1}: مبلغ ارزی و نرخ ارز با هم کامل وارد شوند` }, { status: 400 }) };
    if (fxId !== null) {
      if (!(fxAmount! > 0)) return { error: NextResponse.json({ ok: false, error: `ردیف ${i + 1}: مبلغ ارزی باید بزرگ‌تر از صفر باشد` }, { status: 400 }) };
      if (!(fxRate! > 0)) return { error: NextResponse.json({ ok: false, error: `ردیف ${i + 1}: نرخ ارز باید بزرگ‌تر از صفر باشد` }, { status: 400 }) };
      const f = await one("SELECT FxId FROM ACC.AccFx WHERE FxId=@f AND CompanyId=@c AND IsActive=1", { f: fxId, c: companyId });
      if (!f) return { error: NextResponse.json({ ok: false, error: `ردیف ${i + 1}: ارز انتخابی نامعتبر است` }, { status: 400 }) };
    }
    /* پیگیری — شماره + تاریخ [فرم: تغيير شماره و تاريخ پيگيري] */
    const trackNo = String(it.TrackNo || "").trim().slice(0, 50) || null;
    const trackDate = String(it.TrackDate || "").trim() || null;
    if (trackDate && !isValidJalali(trackDate))
      return { error: NextResponse.json({ ok: false, error: `ردیف ${i + 1}: تاریخ پیگیری نامعتبر است (جلالی YYYY/MM/DD)` }, { status: 400 }) };
    if (!trackNo && trackDate)
      return { error: NextResponse.json({ ok: false, error: `ردیف ${i + 1}: تاریخ پیگیری بدون شمارهٔ پیگیری مجاز نیست` }, { status: 400 }) };

    cleaned.push({
      KolCode: kol, MoeinCode: moein,
      Taf1Id: out.Taf1Id, Taf2Id: out.Taf2Id, Taf3Id: out.Taf3Id,
      Descr: String(it.Descr || "").trim().slice(0, 500) || null,
      Dbt: dbt, Crt: crt,
      FxId: fxId, FxAmount: fxAmount, FxRate: fxRate,
      TrackNo: trackNo, TrackDate: trackDate,
      LatinDescr: String(it.LatinDescr || "").trim().slice(0, 500) || null,
    });
  }

  if (totalDbt !== totalCrt)
    return { error: NextResponse.json({ ok: false, error: `سند تراز نیست — بدهکار ${totalDbt.toLocaleString("fa-IR")} ≠ بستانکار ${totalCrt.toLocaleString("fa-IR")}` }, { status: 400 }) };

  return { items: cleaned, totalDbt, totalCrt };
}
