import { NextRequest, NextResponse } from "next/server";
import { one, tx } from "@/lib/db";
import { getSession, can } from "@/lib/auth";
import { ctxOf } from "@/lib/ctx";
import { isValidJalali } from "@/lib/jalali";
import { validateVoucherItems, ItemIn } from "@/lib/vchitems";

/* صدور سند حسابداري [فرم: صدور سند حسابداري — acGenVch]
   قواعد: تراز بدهکار/بستانکار، معین متعلق به کل، تفصیلی‌های الزامی مطابق ارتباط سطوح ۴/۵/۶ معین،
   مبدأ سند = ACC (حسابداری)، وضعیت اولیه = موقت (فرایند صدور→بررسی→قطعی)
   G-C2 گپ‌آنالیز: سرسند — شعبه/ش روزانه/ش فرعي/شرح لاتین · قلم — ارز/مبلغ ارزی/نرخ + شماره و تاریخ پیگیری + لاتین
   v2.2.0 — اعتبارسنجی اقلام به ماژول مشترک lib/vchitems منتقل شد (مشترک با «ویرایش سند») */

export async function POST(req: NextRequest) {
  const s = await getSession();
  if (!s) return NextResponse.json({ ok: false, error: "دسترسی رد شد" }, { status: 401 });
  if (!can(s, "issue")) return NextResponse.json({ ok: false, error: "نقش شما مجاز به صدور سند نیست" }, { status: 403 });

  const body0 = await req.json().catch(() => ({}));
  /* کانتکست: کوکی acc_ctx + پشتیبان صریح companyId/yearId در body (رفع ریشه‌ای خطای کانتکست) */
  const { companyId, yearId } = ctxOf(req, body0);
  if (!companyId || !yearId) return NextResponse.json({ ok: false, error: "شرکت و سال مالی انتخاب نشده", code: "NO_CTX" }, { status: 400 });

  const body = body0;
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

  /* سال مالی متعلق به شرکتِ کانتکست و باز باشد */
  const yr = await one("SELECT IsClosed FROM pob.FiscalYear WHERE YearId=@y AND CompanyId=@c", { y: yearId, c: companyId });
  if (!yr) return NextResponse.json({ ok: false, error: "سال مالی یافت نشد" }, { status: 400 });
  if (yr.IsClosed) return NextResponse.json({ ok: false, error: "سال مالی بسته است" }, { status: 400 });

  const v = await validateVoucherItems(items, companyId);
  if ("error" in v) return v.error;
  const { items: cleaned } = v;

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
