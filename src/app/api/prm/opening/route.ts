import { NextRequest, NextResponse } from "next/server";
import { q, one, scalar } from "@/lib/db";
import { getSession, can } from "@/lib/auth";

/* ماندهٔ ابتدای دوره + صدور سند افتتاحیه [فرم: صدور سند افتتاحیه — acfidf] */
export async function GET(req: NextRequest) {
  const s = await getSession();
  if (!s) return NextResponse.json({ ok: false, error: "دسترسی رد شد" }, { status: 401 });
  const raw = req.cookies.get("acc_ctx")?.value;
  let companyId = 0, yearId = 0;
  try { const j = JSON.parse(raw || "{}"); companyId = j.companyId || 0; yearId = j.yearId || 0; } catch { /* - */ }
  if (!companyId || !yearId) return NextResponse.json({ ok: false, error: "شرکت و سال مالی انتخاب نشده", code: "NO_CTX" }, { status: 400 });
  const rows = await q(
    `SELECT ob.*, m.Title MoeinTitle, m.AccNature, k.Title KolTitle,
            d1.Title Taf1Title, d2.Title Taf2Title, d3.Title Taf3Title
     FROM YfgAcc.OpeningBalance ob
     JOIN YfgAcc.Moein m ON m.CompanyId=ob.CompanyId AND m.Code=ob.MoeinCode
     JOIN YfgAcc.Kol k ON k.CompanyId=ob.CompanyId AND k.Code=ob.KolCode
     LEFT JOIN YfgAcc.Tafsili d1 ON d1.TafsiliId=ob.Taf1Id
     LEFT JOIN YfgAcc.Tafsili d2 ON d2.TafsiliId=ob.Taf2Id
     LEFT JOIN YfgAcc.Tafsili d3 ON d3.TafsiliId=ob.Taf3Id
     WHERE ob.CompanyId=@c AND ob.YearId=@y ORDER BY ob.KolCode, ob.MoeinCode`, { c: companyId, y: yearId });
  const totals = rows.reduce((a, r) => ({ D: a.D + Number(r.Dbt), C: a.C + Number(r.Crt) }), { D: 0, C: 0 });
  return NextResponse.json({ ok: true, rows, totals });
}

export async function POST(req: NextRequest) {
  const s = await getSession();
  if (!s || !can(s, "master")) return NextResponse.json({ ok: false, error: "مجوز ندارید" }, { status: 403 });
  const raw = req.cookies.get("acc_ctx")?.value;
  let companyId = 0, yearId = 0;
  try { const j = JSON.parse(raw || "{}"); companyId = j.companyId || 0; yearId = j.yearId || 0; } catch { /* - */ }
  const body = await req.json().catch(() => ({}));
  const KolCode = String(body.KolCode || "").trim();
  const MoeinCode = String(body.MoeinCode || "").trim();
  const Dbt = Math.round(Number(body.Dbt || 0));
  const Crt = Math.round(Number(body.Crt || 0));
  if (!/^\d{4}$/.test(KolCode) || !/^\d{6}$/.test(MoeinCode))
    return NextResponse.json({ ok: false, error: "کد کل/معین نامعتبر" }, { status: 400 });
  if (Dbt > 0 && Crt > 0) return NextResponse.json({ ok: false, error: "هم‌زمان بدهکار و بستانکار" }, { status: 400 });
  const m = await one<any>("SELECT Code, Taf1TypeId, Taf2TypeId, Taf3TypeId FROM YfgAcc.Moein WHERE CompanyId=@c AND Code=@m AND KolCode=@k", { c: companyId, m: MoeinCode, k: KolCode });
  if (!m) return NextResponse.json({ ok: false, error: "معین زیرمجموعهٔ این کل نیست" }, { status: 400 });
  /* تفصیلی الزامی مطابق ارتباط معین — همان قاعدهٔ صدور سند */
  const needs: [number | null, string, string][] = [
    [m.Taf1TypeId, "Taf1Id", "چهارم"], [m.Taf2TypeId, "Taf2Id", "پنجم"], [m.Taf3TypeId, "Taf3Id", "ششم"],
  ];
  for (const [needType, field] of needs) {
    if (needType && !body[field]) {
      if (field === "Taf1Id") return NextResponse.json({ ok: false, error: "تفصیلی سطح چهارم برای این معین الزامی است" }, { status: 400 });
      return NextResponse.json({ ok: false, error: `تفصیلی ${field} الزامی است` }, { status: 400 });
    }
  }
  /* ممیزی: ایجادکننده + تاریخ ایجاد + سیستم مبدأ (استاندارد همهٔ جدول‌ها) */
  const row = await one(
    `INSERT INTO YfgAcc.OpeningBalance (CompanyId, YearId, KolCode, MoeinCode, Taf1Id, Taf2Id, Taf3Id, Dbt, Crt, CreatedBy, CreatedAt, SourceSystem) OUTPUT INSERTED.*
     VALUES (@c, @y, @k, @m, @d1, @d2, @d3, @db, @cr, @u, SYSDATETIME(), 'ACCWEB')`,
    { c: companyId, y: yearId, k: KolCode, m: MoeinCode, d1: body.Taf1Id || null, d2: body.Taf2Id || null, d3: body.Taf3Id || null, db: Dbt, cr: Crt, u: s.username });
  return NextResponse.json({ ok: true, row });
}

export async function DELETE(req: NextRequest) {
  const s = await getSession();
  if (!s || !can(s, "master")) return NextResponse.json({ ok: false, error: "مجوز ندارید" }, { status: 403 });
  const id = Number(new URL(req.url).searchParams.get("id") || 0);
  await q("DELETE FROM YfgAcc.OpeningBalance WHERE ObId=@id", { id });
  return NextResponse.json({ ok: true });
}

/* صدور سند افتتاحیه از مانده‌ها — State=1 (فرایند بررسی/قطعی طبق روال) */
export async function PUT(req: NextRequest) {
  const s = await getSession();
  if (!s || !can(s, "issue")) return NextResponse.json({ ok: false, error: "نقش شما مجاز به صدور سند نیست" }, { status: 403 });
  const raw = req.cookies.get("acc_ctx")?.value;
  let companyId = 0, yearId = 0;
  try { const j = JSON.parse(raw || "{}"); companyId = j.companyId || 0; yearId = j.yearId || 0; } catch { /* - */ }
  if (!companyId || !yearId) return NextResponse.json({ ok: false, error: "شرکت و سال مالی انتخاب نشده" }, { status: 400 });

  const bal = await scalar(
    `SELECT ISNULL(SUM(Dbt),0)-ISNULL(SUM(Crt),0) FROM YfgAcc.OpeningBalance WHERE CompanyId=@c AND YearId=@y`, { c: companyId, y: yearId });
  if (Number(bal) !== 0) return NextResponse.json({ ok: false, error: `مانده‌ها تراز نیستند (اختلاف ${Number(bal).toLocaleString("fa-IR")})` }, { status: 400 });
  const exists = await scalar(
    `SELECT COUNT(*) FROM YfgVch.Voucher WHERE CompanyId=@c AND YearId=@y AND VoucherTypeId=(SELECT TOP 1 VoucherTypeId FROM YfgVch.VoucherType WHERE CompanyId=@c AND LatinTitle='Opening') AND ReversalOf IS NULL`, { c: companyId, y: yearId });
  if (Number(exists) > 0) return NextResponse.json({ ok: false, error: "سند افتتاحیه قبلاً صادر شده" }, { status: 400 });

  const rows = await q(
    `SELECT ob.KolCode, ob.MoeinCode, ob.Taf1Id, ob.Taf2Id, ob.Taf3Id, ob.Dbt, ob.Crt, m.Title MoeinTitle
     FROM YfgAcc.OpeningBalance ob JOIN YfgAcc.Moein m ON m.CompanyId=ob.CompanyId AND m.Code=ob.MoeinCode
     WHERE ob.CompanyId=@c AND ob.YearId=@y AND (ob.Dbt<>0 OR ob.Crt<>0) ORDER BY ob.KolCode, ob.MoeinCode`, { c: companyId, y: yearId });
  if (!rows.length) return NextResponse.json({ ok: false, error: "مانده‌ای ثبت نشده است" }, { status: 400 });

  const t = await one<{ VoucherTypeId: number }>(`SELECT VoucherTypeId FROM YfgVch.VoucherType WHERE CompanyId=@c AND LatinTitle='Opening'`, { c: companyId });
  if (!t) return NextResponse.json({ ok: false, error: "نوع سند «افتتاحیه» تعریف نشده است" }, { status: 400 });
  const yr = await one<{ JalaliYear: number }>("SELECT JalaliYear FROM YfgPrm.FiscalYear WHERE YearId=@y", { y: yearId });
  const openDate = `${yr!.JalaliYear}/01/01`; /* سند افتتاحیه در ابتدای سال — دفاتر هر بازه‌ای درست حساب می‌شود */
  const { tx } = await import("@/lib/db");
  let hdr: any = null;
  await tx(async (run) => {
    const noRow = await run(
      `SELECT ISNULL(MAX(FolioNo),0)+1 NF, ISNULL(MAX(VchNo),0)+1 NV FROM YfgVch.Voucher WITH (TABLOCKX) WHERE CompanyId=@c AND YearId=@y`, { c: companyId, y: yearId });
    const h = await run(
      `INSERT INTO YfgVch.Voucher (CompanyId, YearId, FolioNo, VchNo, VoucherTypeId, VchDate, Descr, State, SourceModule, CreatedBy)
       OUTPUT INSERTED.* VALUES (@c, @y, @f, @n, @t, @d, N'سند افتتاحیه', 1, 'ACC', @u)`,
      { c: companyId, y: yearId, f: Number(noRow[0].NF), n: Number(noRow[0].NV), t: t.VoucherTypeId, d: openDate, u: s.username });
    hdr = h[0];
    for (let i = 0; i < rows.length; i++) {
      const r = rows[i];
      await run(
        `INSERT INTO YfgVch.VoucherLine (VoucherId, RowNo, KolCode, MoeinCode, Taf1Id, Taf2Id, Taf3Id, Descr, Dbt, Crt)
         VALUES (@h, @r, @k, @m, @d1, @d2, @d3, N'انتقال ماندهٔ ابتدای دوره', @db, @cr)`,
        { h: hdr.VoucherId, r: i + 1, k: r.KolCode, m: r.MoeinCode, d1: r.Taf1Id, d2: r.Taf2Id, d3: r.Taf3Id, db: r.Dbt, cr: r.Crt });
    }
    await run(`INSERT INTO YfgVch.VoucherFlow (VoucherId, Action, ByUser, Note) VALUES (@h, 1, @u, N'صدور سند افتتاحیه از مانده‌ها')`, { h: hdr.VoucherId, u: s.username });
  });
  return NextResponse.json({ ok: true, voucher: hdr });
}
