import { NextRequest, NextResponse } from "next/server";
import { one, q, tx } from "@/lib/db";
import { getSession, can } from "@/lib/auth";
import { isValidJalali } from "@/lib/jalali";

/* صدور سند حسابداري [فرم: صدور سند حسابداري — acGenVch]
   قواعد: تراز بدهکار/بستانکار، معین متعلق به کل، تفصیلی‌های الزامی مطابق ارتباط سطوح ۴/۵/۶ معین،
   مبدأ سند = ACC (حسابداری)، وضعیت اولیه = موقت (فرایند صدور→بررسی→قطعی) */

interface ItemIn {
  KolCode: string; MoeinCode: string;
  Taf1Id?: number | null; Taf2Id?: number | null; Taf3Id?: number | null;
  Descr?: string; Dbt?: number | string; Crt?: number | string;
}

interface OutItem {
  KolCode: string; MoeinCode: string;
  Taf1Id: number | null; Taf2Id: number | null; Taf3Id: number | null;
  Descr: string | null; Dbt: number; Crt: number;
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

  if (!isValidJalali(vchDate)) return NextResponse.json({ ok: false, error: "تاریخ سند نامعتبر است (جلالی YYYY/MM/DD)" }, { status: 400 });
  const t = await one("SELECT Title FROM ACC.AccVoucherType WHERE VoucherTypeId=@t AND CompanyId=@c", { t: typeId, c: companyId });
  if (!t) return NextResponse.json({ ok: false, error: "نوع سند نامعتبر" }, { status: 400 });
  if (!items.length) return NextResponse.json({ ok: false, error: "سند بدون ردیف نیست" }, { status: 400 });

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
    cleaned.push({
      KolCode: kol, MoeinCode: moein,
      Taf1Id: out.Taf1Id, Taf2Id: out.Taf2Id, Taf3Id: out.Taf3Id,
      Descr: String(it.Descr || "").trim().slice(0, 500) || null,
      Dbt: dbt, Crt: crt,
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
      const h = await run(
        `INSERT INTO ACC.AccVoucher (CompanyId, YearId, FolioNo, VchNo, VoucherTypeId, VchDate, Descr, State, SourceModule, CreatedBy)
         OUTPUT INSERTED.* VALUES (@c, @y, @f, @n, @t, @d, @ds, 1, 'ACC', @u)`,
        { c: companyId, y: yearId, f: folio, n: vchNo, t: typeId, d: vchDate, ds: descr, u: s.username });
      hdr = h[0];
      for (let i = 0; i < cleaned.length; i++) {
        const it = cleaned[i];
        await run(
          `INSERT INTO ACC.AccVoucherItm (VoucherId, RowNo, KolCode, MoeinCode, Taf1Id, Taf2Id, Taf3Id, Descr, Dbt, Crt)
           VALUES (@h, @r, @k, @m, @d1, @d2, @d3, @ds, @db, @cr)`,
          { h: hdr.VoucherId, r: i + 1, k: it.KolCode, m: it.MoeinCode, d1: it.Taf1Id, d2: it.Taf2Id, d3: it.Taf3Id, ds: it.Descr, db: it.Dbt, cr: it.Crt });
      }
      await run(`INSERT INTO ACC.AccVoucherFlow (VoucherId, Action, ByUser, Note) VALUES (@h, 1, @u, N'صدور سند')`, { h: hdr.VoucherId, u: s.username });
    });
    return NextResponse.json({ ok: true, voucher: hdr });
  } catch (e: any) {
    return NextResponse.json({ ok: false, error: String(e.message || e).slice(0, 300) }, { status: 400 });
  }
}
