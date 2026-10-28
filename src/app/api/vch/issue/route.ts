import { NextRequest, NextResponse } from "next/server";
import { one, q, tx } from "@/lib/db";
import { getSession, can } from "@/lib/auth";
import { isValidJalali } from "@/lib/jalali";

/* صدور سند حسابداري [فرم: صدور سند حسابداري — acGenVch]
   قواعد: تراز بدهکار/بستانکار، معین متعلق به کل، تفصیلی‌های الزامی مطابق ارتباط سطوح ۴/۵/۶ معین،
   مبدأ سند = ACC (حسابداری)، وضعیت اولیه = موقت (فرایند صدور→بررسی→قطعی)
   G-C2 گپ‌آنالیز: سرسند — شعبه/ش روزانه/ش فرعي/شرح لاتین · قلم — ارز/مبلغ ارزی/نرخ + شماره و تاریخ پیگیری + لاتین */

interface ItemIn {
  KolCode: string; MoeinCode: string;
  Taf1Id?: number | null; Taf2Id?: number | null; Taf3Id?: number | null;
  Descr?: string; Dbt?: number | string; Crt?: number | string;
  FxId?: number | null; FxAmount?: number | string | null; FxRate?: number | string | null;
  TrackNo?: string; TrackDate?: string; LatinDescr?: string;
}

interface OutItem {
  KolCode: string; MoeinCode: string;
  Taf1Id: number | null; Taf2Id: number | null; Taf3Id: number | null;
  Descr: string | null; Dbt: number; Crt: number;
  FxId: number | null; FxAmount: number | null; FxRate: number | null;
  TrackNo: string | null; TrackDate: string | null; LatinDescr: string | null;
}

export async function POST(req: NextRequest) {
  const s = await getSession();
  if (!s) return NextResponse.json({ ok: false, error: "دسترسی رد شد" }, { status: 401 });
  if (!can(s, "issue")) return NextResponse.json({ ok: false, error: "نقش شما مجاز به صدور سند نیست" }, { status: 403 });

  const raw = (await (await import("next/headers")).cookies()).get("acc_ctx")?.value;
  let companyId = 0, yearId = 0;
  try { const j = JSON.parse(raw || "{}"); companyId = j.companyId || 0; yearId = j.yearId || 0; } catch { /* - */ }
  if (!companyId || !yearId) return NextResponse.json({ ok: false, error: "شرکت و سال مالی انتخاب نشده", code: "NO_CTX" }, { status: 400 });

  const body = await req.json().catch(() => ({}));
  const vchDate = String(body.VchDate || "").trim();
  const descr = String(body.Descr || "").trim().slice(0, 500) || null;
  const typeId = Number(body.VoucherTypeId || 0);
  const items: ItemIn[] = Array.isArray(body.items) ? body.items : [];
  /* سرسند — فیلدهای فرم اصلی (G-C2) */
  const branchId = body.BranchId ? Number(body.BranchId) : null;
  const dayNoIn = body.DayNo === undefined || body.DayNo === null || body.DayNo === "" ? null : Number(body.DayNo);
  const subNo = body.SubNo === undefined || body.SubNo === null || body.SubNo === "" ? 0 : Number(body.SubNo);
  const latinDescr = String(body.LatinDescr || "").trim().slice(0, 500) || null;

  if (!isValidJalali(vchDate)) return NextResponse.json({ ok: false, error: "تاریخ سند نامعتبر است (جلالی YYYY/MM/DD)" }, { status: 400 });
  const t = await one("SELECT Title FROM ACC.AccVoucherType WHERE VoucherTypeId=@t AND CompanyId=@c", { t: typeId, c: companyId });
  if (!t) return NextResponse.json({ ok: false, error: "نوع سند نامعتبر" }, { status: 400 });
  if (!items.length) return NextResponse.json({ ok: false, error: "سند بدون ردیف نیست" }, { status: 400 });
  /* شعبه متعلق به شرکت و فعال */
  if (branchId) {
    const b = await one("SELECT BranchId FROM ACC.AccBranch WHERE BranchId=@b AND CompanyId=@c AND IsActive=1", { b: branchId, c: companyId });
    if (!b) return NextResponse.json({ ok: false, error: "شعبهٔ انتخابی نامعتبر است" }, { status: 400 });
  }
  if (subNo < 0 || subNo > 9999 || !Number.isInteger(subNo))
    return NextResponse.json({ ok: false, error: "شمارهٔ فرعی نامعتبر است" }, { status: 400 });
  if (dayNoIn !== null && (!Number.isInteger(dayNoIn) || dayNoIn < 0))
    return NextResponse.json({ ok: false, error: "شمارهٔ روزانه نامعتبر است" }, { status: 400 });

  /* سال مالی باز؟ */
  const yr = await one("SELECT IsClosed FROM pob.FiscalYear WHERE YearId=@y", { y: yearId });
  if (!yr) return NextResponse.json({ ok: false, error: "سال مالی یافت نشد" }, { status: 400 });
  if (yr.IsClosed) return NextResponse.json({ ok: false, error: "سال مالی بسته است" }, { status: 400 });

  let totalDbt = 0, totalCrt = 0;
  const cleaned: OutItem[] = [];

  for (let i = 0; i < items.length; i++) {
    const it = items[i];
    const kol = String(it.KolCode || "").trim();
    const moein = String(it.MoeinCode || "").trim();
    const dbt = Math.round(Number(it.Dbt || 0));
    const crt = Math.round(Number(it.Crt || 0));
    if (!/^\d{4}$/.test(kol)) return NextResponse.json({ ok: false, error: `ردیف ${i + 1}: کد کل باید ۴ رقم باشد` }, { status: 400 });
    if (!/^\d{6}$/.test(moein)) return NextResponse.json({ ok: false, error: `ردیف ${i + 1}: کد معین باید ۶ رقم باشد` }, { status: 400 });
    if (dbt > 0 && crt > 0) return NextResponse.json({ ok: false, error: `ردیف ${i + 1}: هم‌زمان بدهکار و بستانکار` }, { status: 400 });
    if (dbt === 0 && crt === 0) return NextResponse.json({ ok: false, error: `ردیف ${i + 1}: مبلغ صفر` }, { status: 400 });

    const m = await one<any>("SELECT Code, KolCode, Title, Taf1TypeId, Taf2TypeId, Taf3TypeId FROM ACC.AccMoein WHERE CompanyId=@c AND Code=@m AND KolCode=@k",
      { c: companyId, m: moein, k: kol });
    if (!m) return NextResponse.json({ ok: false, error: `ردیف ${i + 1}: معین ${moein} زیرمجموعهٔ کل ${kol} نیست` }, { status: 400 });

    /* اعتبار تفصیلی‌ها مطابق ارتباط معین با سطوح چهارم/پنجم/ششم */
    const slots: [number | null, "Taf1Id" | "Taf2Id" | "Taf3Id", string][] = [
      [m.Taf1TypeId, "Taf1Id", "چهارم"], [m.Taf2TypeId, "Taf2Id", "پنجم"], [m.Taf3TypeId, "Taf3Id", "ششم"],
    ];
    const out: Record<string, number | null> = {};
    for (const [needType, field, label] of slots) {
      const given = (it as any)[field];
      if (needType) {
        if (!given) return NextResponse.json({ ok: false, error: `ردیف ${i + 1}: تفصیلی سطح ${label} برای معین ${moein} الزامی است` }, { status: 400 });
        const d = await one<{ TafsiliId: number }>("SELECT TafsiliId FROM ACC.AccTafsili WHERE TafsiliId=@d AND CompanyId=@c AND TafsiliTypeId=@t AND IsActive=1", { d: given, c: companyId, t: needType });
        if (!d) return NextResponse.json({ ok: false, error: `ردیف ${i + 1}: تفصیلی انتخابی سطح ${label} با نوع معین ${moein} هم‌خوان نیست` }, { status: 400 });
        out[field] = given;
      } else {
        if (given) return NextResponse.json({ ok: false, error: `ردیف ${i + 1}: معین ${moein} سطح تفصیلی ${label} ندارد` }, { status: 400 });
        out[field] = null;
      }
    }

    totalDbt += dbt; totalCrt += crt;

    /* ارز قلم — سه‌تایی نوع/مبلغ/نرخ همیشه کامل یا هیچ [accCurrency + CK_Line_Fx] */
    const fxId = it.FxId ? Number(it.FxId) : null;
    const fxAmount = it.FxAmount === undefined || it.FxAmount === null || it.FxAmount === "" ? null : Number(it.FxAmount);
    const fxRate = it.FxRate === undefined || it.FxRate === null || it.FxRate === "" ? null : Number(it.FxRate);
    if (fxId === null && (fxAmount !== null || fxRate !== null))
      return NextResponse.json({ ok: false, error: `ردیف ${i + 1}: برای ثبت ارز، نوع ارز الزامی است` }, { status: 400 });
    if (fxId !== null && (fxAmount === null || fxRate === null))
      return NextResponse.json({ ok: false, error: `ردیف ${i + 1}: مبلغ ارزی و نرخ ارز با هم کامل وارد شوند` }, { status: 400 });
    if (fxId !== null) {
      if (!(fxAmount! > 0)) return NextResponse.json({ ok: false, error: `ردیف ${i + 1}: مبلغ ارزی باید بزرگ‌تر از صفر باشد` }, { status: 400 });
      if (!(fxRate! > 0)) return NextResponse.json({ ok: false, error: `ردیف ${i + 1}: نرخ ارز باید بزرگ‌تر از صفر باشد` }, { status: 400 });
      const f = await one("SELECT FxId FROM ACC.AccFx WHERE FxId=@f AND CompanyId=@c AND IsActive=1", { f: fxId, c: companyId });
      if (!f) return NextResponse.json({ ok: false, error: `ردیف ${i + 1}: ارز انتخابی نامعتبر است` }, { status: 400 });
    }
    /* پیگیری — شماره + تاریخ [فرم: تغيير شماره و تاريخ پيگيري] */
    const trackNo = String(it.TrackNo || "").trim().slice(0, 50) || null;
    const trackDate = String(it.TrackDate || "").trim() || null;
    if (trackDate && !isValidJalali(trackDate))
      return NextResponse.json({ ok: false, error: `ردیف ${i + 1}: تاریخ پیگیری نامعتبر است (جلالی YYYY/MM/DD)` }, { status: 400 });
    if (!trackNo && trackDate)
      return NextResponse.json({ ok: false, error: `ردیف ${i + 1}: تاریخ پیگیری بدون شمارهٔ پیگیری مجاز نیست` }, { status: 400 });

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

  if (totalDbt !== totalCrt) return NextResponse.json({ ok: false, error: `سند تراز نیست — بدهکار ${totalDbt.toLocaleString("fa-IR")} ≠ بستانکار ${totalCrt.toLocaleString("fa-IR")}` }, { status: 400 });

  try {
    let hdr: any = null;
    await tx(async (run) => {
      const noRow = await run(
        `SELECT ISNULL(MAX(FolioNo),0)+1 NF, ISNULL(MAX(VchNo),0)+1 NV FROM ACC.AccVoucher WITH (TABLOCKX) WHERE CompanyId=@c AND YearId=@y`,
        { c: companyId, y: yearId });
      const folio = Number(noRow[0].NF), vchNo = Number(noRow[0].NV);
      /* ش روزانه — اگر داده نشده باشد: بزرگ‌ترین شمارهٔ روزانهٔ همان تاریخ + ۱ [فرم: ش روزانه] */
      let dayNo = dayNoIn;
      if (dayNo === null) {
        const d = await run(`SELECT ISNULL(MAX(DayNo),0)+1 DN FROM ACC.AccVoucher WHERE CompanyId=@c AND YearId=@y AND VchDate=@d`,
          { c: companyId, y: yearId, d: vchDate });
        dayNo = Number(d[0].DN);
      }
      const h = await run(
        `INSERT INTO ACC.AccVoucher (CompanyId, YearId, FolioNo, VchNo, VoucherTypeId, VchDate, Descr, State, SourceModule, CreatedBy, BranchId, DayNo, SubNo, LatinDescr)
         VALUES (@c, @y, @f, @n, @t, @d, @ds, 1, 'ACC', @u, @br, @dn, @sn, @ld);
         SELECT * FROM ACC.AccVoucher WHERE VoucherId = CAST(SCOPE_IDENTITY() AS int)`,
        { c: companyId, y: yearId, f: folio, n: vchNo, t: typeId, d: vchDate, ds: descr, u: s.username,
          br: branchId, dn: dayNo, sn: subNo, ld: latinDescr });
      hdr = h[0];
      /* یک INSERT برای همهٔ ردیف‌ها — لاگ تجمیعی «N ردیف» برای کل سند */
      const vals: string[] = [];
      const p: Record<string, unknown> = { h: hdr.VoucherId };
      cleaned.forEach((it, i) => {
        vals.push(`(@h, @r${i}, @k${i}, @m${i}, @d1_${i}, @d2_${i}, @d3_${i}, @ds${i}, @db${i}, @cr${i}, @fx${i}, @fa${i}, @fr${i}, @tn${i}, @td${i}, @ld${i})`);
        p[`r${i}`] = i + 1; p[`k${i}`] = it.KolCode; p[`m${i}`] = it.MoeinCode;
        p[`d1_${i}`] = it.Taf1Id; p[`d2_${i}`] = it.Taf2Id; p[`d3_${i}`] = it.Taf3Id;
        p[`ds${i}`] = it.Descr; p[`db${i}`] = it.Dbt; p[`cr${i}`] = it.Crt;
        p[`fx${i}`] = it.FxId; p[`fa${i}`] = it.FxAmount; p[`fr${i}`] = it.FxRate;
        p[`tn${i}`] = it.TrackNo; p[`td${i}`] = it.TrackDate; p[`ld${i}`] = it.LatinDescr;
      });
      await run(
        `INSERT INTO ACC.AccVoucherItm (VoucherId, RowNo, KolCode, MoeinCode, Taf1Id, Taf2Id, Taf3Id, Descr, Dbt, Crt, FxId, FxAmount, FxRate, TrackNo, TrackDate, LatinDescr)
         VALUES ${vals.join(",")}`, p);
      await run(`INSERT INTO ACC.AccVoucherFlow (VoucherId, Action, ByUser, Note) VALUES (@h, 1, @u, N'صدور سند')`, { h: hdr.VoucherId, u: s.username });
    });
    return NextResponse.json({ ok: true, voucher: hdr });
  } catch (e: any) {
    return NextResponse.json({ ok: false, error: String(e.message || e).slice(0, 300) }, { status: 400 });
  }
}
