import { NextRequest, NextResponse } from "next/server";
import { one, tx } from "@/lib/db";
import { getSession, can } from "@/lib/auth";
import { ctxOf } from "@/lib/ctx";
import { isValidJalali } from "@/lib/jalali";
import { validateVoucherItems, ItemIn } from "@/lib/vchitems";

/* ============================================================================
   ویرایش سند حسابداری (v2.2.0) [فرم اصلی: اصلاح سند — درخواست کارفرما:
   «مشاهده سند در مرور حسابها بتوان سند را در همان پنجره ویرایش کرد»]
   قواعد:
   • فقط اسناد «موقت» یا «بررسی‌شده» ویرایش می‌شوند — سند «قطعی» ابتدا باید برگشت داده شود
   • اسناد برگشتی (ReversalOf) و اسناد سایر ماژول‌ها (SourceModule<>ACC) قابل ویرایش نیستند
   • شمارهٔ سند/عطف/سازنده تغییر نمی‌کند؛ همهٔ تغییرها در ردپای عملیات (Action=7 ویرایش) ثبت می‌شود
   • اقلام ردیف‌ها کامل جایگزین می‌شوند (حذف و درج مجدد داخل یک تراکنش)
   ============================================================================ */

export async function POST(req: NextRequest) {
  const s = await getSession();
  if (!s) return NextResponse.json({ ok: false, error: "دسترسی رد شد" }, { status: 401 });
  if (!can(s, "issue")) return NextResponse.json({ ok: false, error: "نقش شما مجاز به ویرایش سند نیست" }, { status: 403 });

  const body0 = await req.json().catch(() => ({}));
  const { companyId, yearId } = ctxOf(req, body0);
  if (!companyId || !yearId) return NextResponse.json({ ok: false, error: "شرکت و سال مالی انتخاب نشده", code: "NO_CTX" }, { status: 400 });

  const body = body0;
  const id = Number(body.id || 0);
  if (!id) return NextResponse.json({ ok: false, error: "شناسهٔ سند لازم است" }, { status: 400 });

  const hdr = await one<any>(
    `SELECT VoucherId, CompanyId, YearId, VchNo, State, SourceModule, ReversalOf, DayNo
     FROM ACC.AccVoucher WHERE VoucherId=@id`, { id });
  if (!hdr) return NextResponse.json({ ok: false, error: "سند یافت نشد" }, { status: 404 });
  if (hdr.CompanyId !== companyId || hdr.YearId !== yearId)
    return NextResponse.json({ ok: false, error: "سند متعلق به شرکت/سال مالی جاری نیست" }, { status: 400 });
  if (hdr.State === 3)
    return NextResponse.json({ ok: false, error: "سند قطعی قابل ویرایش نیست — ابتدا سند را برگشت دهید" }, { status: 400 });
  if (hdr.ReversalOf)
    return NextResponse.json({ ok: false, error: "سند برگشتی قابل ویرایش نیست" }, { status: 400 });
  if (String(hdr.SourceModule || "ACC") !== "ACC")
    return NextResponse.json({ ok: false, error: `سند متعلق به ماژول «${hdr.SourceModule}» است و از اینجا قابل ویرایش نیست` }, { status: 400 });

  const vchDate = String(body.VchDate || "").trim();
  const descr = String(body.Descr || "").trim().slice(0, 500) || null;
  const typeId = Number(body.VoucherTypeId || 0);
  const items: ItemIn[] = Array.isArray(body.items) ? body.items : [];
  const branchId = body.BranchId ? Number(body.BranchId) : null;
  const dayNoIn = body.DayNo === undefined || body.DayNo === null || body.DayNo === "" ? null : Number(body.DayNo);
  const subNo = body.SubNo === undefined || body.SubNo === null || body.SubNo === "" ? 0 : Number(body.SubNo);
  const latinDescr = String(body.LatinDescr || "").trim().slice(0, 500) || null;

  if (!isValidJalali(vchDate)) return NextResponse.json({ ok: false, error: "تاریخ سند نامعتبر است (جلالی YYYY/MM/DD)" }, { status: 400 });
  const t = await one("SELECT Title FROM ACC.AccVoucherType WHERE VoucherTypeId=@t AND CompanyId=@c", { t: typeId, c: companyId });
  if (!t) return NextResponse.json({ ok: false, error: "نوع سند نامعتبر" }, { status: 400 });
  if (!items.length) return NextResponse.json({ ok: false, error: "سند بدون ردیف نیست" }, { status: 400 });
  if (branchId) {
    const b = await one("SELECT BranchId FROM ACC.AccBranch WHERE BranchId=@b AND CompanyId=@c AND IsActive=1", { b: branchId, c: companyId });
    if (!b) return NextResponse.json({ ok: false, error: "شعبهٔ انتخابی نامعتبر است" }, { status: 400 });
  }
  if (subNo < 0 || subNo > 9999 || !Number.isInteger(subNo))
    return NextResponse.json({ ok: false, error: "شمارهٔ فرعی نامعتبر است" }, { status: 400 });
  if (dayNoIn !== null && (!Number.isInteger(dayNoIn) || dayNoIn < 0))
    return NextResponse.json({ ok: false, error: "شمارهٔ روزانه نامعتبر است" }, { status: 400 });

  const yr = await one("SELECT IsClosed FROM pob.FiscalYear WHERE YearId=@y AND CompanyId=@c", { y: yearId, c: companyId });
  if (!yr) return NextResponse.json({ ok: false, error: "سال مالی یافت نشد" }, { status: 400 });
  if (yr.IsClosed) return NextResponse.json({ ok: false, error: "سال مالی بسته است" }, { status: 400 });

  const v = await validateVoucherItems(items, companyId);
  if ("error" in v) return v.error;
  const { items: cleaned } = v;

  try {
    await tx(async (run) => {
      await run(
        `UPDATE ACC.AccVoucher
         SET VchDate=@d, VoucherTypeId=@t, Descr=@ds, BranchId=@br, DayNo=@dn, SubNo=@sn, LatinDescr=@ld
         WHERE VoucherId=@id`,
        { id, d: vchDate, t: typeId, ds: descr, br: branchId, dn: dayNoIn === null ? hdr.DayNo : dayNoIn, sn: subNo, ld: latinDescr });
      await run(`DELETE FROM ACC.AccVoucherItm WHERE VoucherId=@id`, { id });
      const vals: string[] = [];
      const p: Record<string, unknown> = { h: id };
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
      await run(`INSERT INTO ACC.AccVoucherFlow (VoucherId, Action, ByUser, Note) VALUES (@h, 7, @u, @n)`,
        { h: id, u: s.username, n: `ویرایش سند — ${cleaned.length} ردیف` });
    });
    /* خواندن نهایی پس از commit — خواندن سطر قفل‌شده از pool دیگر داخل tx، تراکنش را تا ابد بلاک می‌کند */
    const updated = await one("SELECT VoucherId, VchNo, FolioNo, DayNo FROM ACC.AccVoucher WHERE VoucherId=@id", { id });
    return NextResponse.json({ ok: true, voucher: updated });
  } catch (e: any) {
    return NextResponse.json({ ok: false, error: String(e.message || e).slice(0, 300) }, { status: 400 });
  }
}
