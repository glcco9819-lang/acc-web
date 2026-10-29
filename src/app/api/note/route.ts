import { NextRequest, NextResponse } from "next/server";
import { q, one, tx } from "@/lib/db";
import { getSession, can } from "@/lib/auth";
import { ctxOf } from "@/lib/ctx";
import { faDateTime } from "@/lib/jalali";

/* ============================================================================
   اعلاميه‌ها — مطابق AcVwDef.BPL (v2.1.0)
   [فرم اصلی: صدور اعلاميه / نمايش اعلاميه ها / جزئيات اعلاميه / انتخاب اقلام اعلاميه]
   اعلاميه = عکس فوری از اقلام انتخابی گردش یک حساب؛ پس از صدور، مستقل از سند می‌ماند.
   GET        فهرست اعلاميه‌های شرکت/سال جاری
   GET ?id=   جزئيات یک اعلاميه (اقلام + جمع)
   POST       صدور اعلاميه { noteDate, title, moeinCode, items:[{voucherId,lineId}] }
   DELETE ?id حذف اعلاميه (همان سازنده یا مدیر)
   ============================================================================ */

export async function GET(req: NextRequest) {
  const s = await getSession();
  if (!s) return NextResponse.json({ ok: false, error: "دسترسی رد شد" }, { status: 401 });
  const { companyId, yearId } = ctxOf(req);
  if (!companyId || !yearId)
    return NextResponse.json({ ok: false, error: "شرکت و سال مالی انتخاب نشده", code: "NO_CTX" }, { status: 400 });

  const id = Number(new URL(req.url).searchParams.get("id") || 0);
  if (id) {
    const hdr = await one<any>(
      `SELECT n.NoteId, n.NoteNo, n.NoteDate, n.Title, n.MoeinCode, m.Title MoeinTitle,
              n.CreatedBy, n.CreatedAt
       FROM ACC.AccNoteHdr n LEFT JOIN ACC.AccMoein m ON m.CompanyId = n.CompanyId AND m.Code = n.MoeinCode
       WHERE n.NoteId = @id AND n.CompanyId = @c AND n.YearId = @y`, { id, c: companyId, y: yearId });
    if (!hdr) return NextResponse.json({ ok: false, error: "اعلاميه یافت نشد" }, { status: 404 });
    const items = await q(
      `SELECT x.NoteLineNo, x.VoucherId, x.LineId, x.VchNo, x.VchDate, x.KolCode, k.Title KolTitle,
              x.MoeinCode, x.Descr,
              d1.Code Taf1Code, d1.Title Taf1Title, d2.Code Taf2Code, d2.Title Taf2Title, d3.Code Taf3Code, d3.Title Taf3Title,
              x.Dbt, x.Crt
       FROM ACC.AccNoteItm x
       JOIN ACC.AccKol k ON k.CompanyId = @c AND k.Code = x.KolCode
       LEFT JOIN ACC.AccTafsili d1 ON d1.TafsiliId = x.Taf1Id
       LEFT JOIN ACC.AccTafsili d2 ON d2.TafsiliId = x.Taf2Id
       LEFT JOIN ACC.AccTafsili d3 ON d3.TafsiliId = x.Taf3Id
       WHERE x.NoteId = @id
       ORDER BY x.NoteLineNo`, { id, c: companyId });
    /* زمان‌های سیستم شمسی — [رفع «تاریخ‌ها شمسی نیستند»] */
    const hdrFa = { ...hdr, CreatedAtJ: faDateTime(hdr.CreatedAt) };
    return NextResponse.json({ ok: true, hdr: hdrFa, items });
  }

  const rows = await q(
    `SELECT n.NoteId, n.NoteNo, n.NoteDate, n.Title, n.MoeinCode, m.Title MoeinTitle,
            n.CreatedBy, n.CreatedAt,
            (SELECT COUNT(*) FROM ACC.AccNoteItm x WHERE x.NoteId = n.NoteId) ItemCount,
            (SELECT ISNULL(SUM(x.Dbt),0) FROM ACC.AccNoteItm x WHERE x.NoteId = n.NoteId) D,
            (SELECT ISNULL(SUM(x.Crt),0) FROM ACC.AccNoteItm x WHERE x.NoteId = n.NoteId) C
     FROM ACC.AccNoteHdr n
     LEFT JOIN ACC.AccMoein m ON m.CompanyId = n.CompanyId AND m.Code = n.MoeinCode
     WHERE n.CompanyId = @c AND n.YearId = @y
     ORDER BY n.NoteNo DESC`, { c: companyId, y: yearId });
  /* زمان‌های سیستم شمسی */
  const rowsFa = (rows as any[]).map((r) => ({ ...r, CreatedAtJ: faDateTime(r.CreatedAt) }));
  return NextResponse.json({ ok: true, rows: rowsFa });
}

export async function POST(req: NextRequest) {
  const s = await getSession();
  if (!s) return NextResponse.json({ ok: false, error: "دسترسی رد شد" }, { status: 401 });
  const body = await req.json().catch(() => null);
  const { companyId, yearId } = ctxOf(req, body);
  if (!companyId || !yearId)
    return NextResponse.json({ ok: false, error: "شرکت و سال مالی انتخاب نشده", code: "NO_CTX" }, { status: 400 });
  if (!can(s, "issue")) return NextResponse.json({ ok: false, error: "دسترسی صدور ندارید" }, { status: 403 });

  const noteDate = String(body?.noteDate || "").trim();
  const title = String(body?.title || "").slice(0, 300);
  const moeinCode = String(body?.moeinCode || "").trim() || null;
  const items: { voucherId: number; lineId: number }[] = Array.isArray(body?.items) ? body.items : [];
  if (!/^\d{4}\/\d{2}\/\d{2}$/.test(noteDate)) return NextResponse.json({ ok: false, error: "تاریخ اعلاميه نامعتبر است" }, { status: 400 });
  if (!items.length) return NextResponse.json({ ok: false, error: "هیچ قلمی انتخاب نشده" }, { status: 400 });

  /* اقلام فقط از اسناد قطعیِ همین سال — عکس فوری ذخیره می‌شود */
  const lines = await q(
    `SELECT i.LineId, i.VoucherId, h.VchNo, h.VchDate, i.KolCode, i.MoeinCode,
            i.Taf1Id, i.Taf2Id, i.Taf3Id, i.Descr, i.Dbt, i.Crt
     FROM ACC.AccVoucherItm i JOIN ACC.AccVoucher h ON h.VoucherId = i.VoucherId
     WHERE h.CompanyId = @c AND h.YearId = @y AND h.State = 3
       AND i.LineId IN (${items.map((_, i) => `@l${i}`).join(",")})`,
    { c: companyId, y: yearId, ...Object.fromEntries(items.map((it, i) => [`l${i}`, it.lineId])) });
  if (!lines.length) return NextResponse.json({ ok: false, error: "اقلام انتخابی معتبر نیستند" }, { status: 400 });

  const nextNo = await one<any>(
    `SELECT ISNULL(MAX(NoteNo),0)+1 N FROM ACC.AccNoteHdr WHERE CompanyId=@c AND YearId=@y`, { c: companyId, y: yearId });
  const noteNo = Number(nextNo?.N || 1);

  let noteId = 0;
  await tx(async (run) => {
    const h = await run(
      `INSERT INTO ACC.AccNoteHdr (CompanyId, YearId, NoteNo, NoteDate, Title, MoeinCode, CreatedBy)
       VALUES (@c, @y, @no, @d, @t, @m, @u);
       SELECT NoteId FROM ACC.AccNoteHdr WHERE NoteId = CAST(SCOPE_IDENTITY() AS int)`,
      { c: companyId, y: yearId, no: noteNo, d: noteDate, t: title, m: moeinCode, u: s.username });
    noteId = Number(h[0].NoteId);
    /* یک INSERT برای همهٔ اقلام — سازگار با تریگرهای OUTPUT */
    const vals: string[] = [];
    const p: Record<string, unknown> = { nid: noteId };
    (lines as any[]).forEach((l, i) => {
      vals.push(`(@nid, @s${i}, @v${i}, @l${i}, @vn${i}, @vd${i}, @k${i}, @m${i}, @t1_${i}, @t2_${i}, @t3_${i}, @ds${i}, @db${i}, @cr${i})`);
      p[`s${i}`] = i + 1;
      p[`v${i}`] = Number(l.VoucherId); p[`l${i}`] = Number(l.LineId);
      p[`vn${i}`] = Number(l.VchNo); p[`vd${i}`] = String(l.VchDate);
      p[`k${i}`] = String(l.KolCode); p[`m${i}`] = String(l.MoeinCode);
      p[`t1_${i}`] = l.Taf1Id ?? null; p[`t2_${i}`] = l.Taf2Id ?? null; p[`t3_${i}`] = l.Taf3Id ?? null;
      p[`ds${i}`] = l.Descr ?? null; p[`db${i}`] = Number(l.Dbt); p[`cr${i}`] = Number(l.Crt);
    });
    await run(
      `INSERT INTO ACC.AccNoteItm (NoteId, NoteLineNo, VoucherId, LineId, VchNo, VchDate, KolCode, MoeinCode, Taf1Id, Taf2Id, Taf3Id, Descr, Dbt, Crt)
       VALUES ${vals.join(",")}`, p);
  });

  return NextResponse.json({ ok: true, noteId, noteNo });
}

export async function DELETE(req: NextRequest) {
  const s = await getSession();
  if (!s) return NextResponse.json({ ok: false, error: "دسترسی رد شد" }, { status: 401 });
  const { companyId, yearId } = ctxOf(req);
  const id = Number(new URL(req.url).searchParams.get("id") || 0);
  if (!id) return NextResponse.json({ ok: false, error: "شناسه اعلاميه نامعتبر" }, { status: 400 });
  const hdr = await one<any>(
    `SELECT NoteId, CreatedBy FROM ACC.AccNoteHdr WHERE NoteId=@id AND CompanyId=@c AND YearId=@y`,
    { id, c: companyId, y: yearId });
  if (!hdr) return NextResponse.json({ ok: false, error: "اعلاميه یافت نشد" }, { status: 404 });
  if (hdr.CreatedBy !== s.username && !can(s, "master"))
    return NextResponse.json({ ok: false, error: "فقط سازندهٔ اعلاميه یا مدیر می‌تواند حذف کند" }, { status: 403 });
  await one(`DELETE FROM ACC.AccNoteItm WHERE NoteId=@id`, { id });
  await one(`DELETE FROM ACC.AccNoteHdr WHERE NoteId=@id`, { id });
  return NextResponse.json({ ok: true });
}
