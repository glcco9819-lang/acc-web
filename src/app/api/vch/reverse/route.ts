import { NextRequest, NextResponse } from "next/server";
import { one, tx } from "@/lib/db";
import { getSession, can } from "@/lib/auth";
import { todayJalali } from "@/lib/jalali";

/* صدور سند برگشتی از سند قطعی [اصول: سند قطعی با برگشت اصلاح می‌شود]
   ردیف‌ها معکوس می‌شوند (بدهکار↔بستانکار) + اسلات‌های تفصیلی عیناً حفظ می‌شوند */
export async function POST(req: NextRequest) {
  const s = await getSession();
  if (!s) return NextResponse.json({ ok: false, error: "دسترسی رد شد" }, { status: 401 });
  if (!can(s, "reverse")) return NextResponse.json({ ok: false, error: "نقش شما مجاز به برگشت سند نیست" }, { status: 403 });

  const body = await req.json().catch(() => ({}));
  const id = Number(body.id || 0);
  const descr = String(body.Descr || "").trim().slice(0, 500) || null;
  const hdr = await one<any>("SELECT * FROM ACC.AccVoucher WHERE VoucherId=@id", { id });
  if (!hdr) return NextResponse.json({ ok: false, error: "سند یافت نشد" }, { status: 404 });
  if (hdr.State !== 3) return NextResponse.json({ ok: false, error: "فقط سند قطعی برگشت می‌خورد" }, { status: 400 });
  const already = await one("SELECT VoucherId FROM ACC.AccVoucher WHERE ReversalOf=@id", { id });
  if (already) return NextResponse.json({ ok: false, error: `این سند قبلاً برگشت خورده (سند ${already.VoucherId})` }, { status: 400 });

  const rows = await one<any>(`SELECT COUNT(*) C FROM ACC.AccVoucherItm WHERE VoucherId=@id`, { id });
  if (!rows || !rows.C) return NextResponse.json({ ok: false, error: "سند بدون ردیف" }, { status: 400 });

  try {
    let rev: any = null;
    await tx(async (run) => {
      const noRow = await run(
        `SELECT ISNULL(MAX(FolioNo),0)+1 NF, ISNULL(MAX(VchNo),0)+1 NV FROM ACC.AccVoucher WITH (TABLOCKX) WHERE CompanyId=@c AND YearId=@y`,
        { c: hdr.CompanyId, y: hdr.YearId });
      const h = await run(
        `INSERT INTO ACC.AccVoucher (CompanyId, YearId, FolioNo, VchNo, VoucherTypeId, VchDate, Descr, State, ReversalOf, SourceModule, CreatedBy, FinalizedBy, FinalizedAt)
         VALUES (@c, @y, @f, @n, @t, @d, @ds, 1, @rev, 'ACC', @u, NULL, NULL);
         SELECT * FROM ACC.AccVoucher WHERE VoucherId = CAST(SCOPE_IDENTITY() AS int)`,
        { c: hdr.CompanyId, y: hdr.YearId, f: Number(noRow[0].NF), n: Number(noRow[0].NV), t: hdr.VoucherTypeId, d: todayJalali(), ds: descr || `برگشت سند شماره ${hdr.VchNo}`, rev: id, u: s.username });
      rev = h[0];
      const src = await run(`SELECT RowNo, KolCode, MoeinCode, Taf1Id, Taf2Id, Taf3Id, Descr, Dbt, Crt FROM ACC.AccVoucherItm WHERE VoucherId=@id ORDER BY RowNo`, { id });
      /* یک INSERT برای همهٔ ردیف‌ها — لاگ تجمیعی «N ردیف» برای کل سند برگشتی */
      const vals: string[] = [];
      const p: Record<string, unknown> = { h: rev.VoucherId };
      src.forEach((it: any, i: number) => {
        vals.push(`(@h, @r${i}, @k${i}, @m${i}, @d1_${i}, @d2_${i}, @d3_${i}, @ds${i}, @db${i}, @cr${i})`);
        p[`r${i}`] = i + 1; p[`k${i}`] = it.KolCode; p[`m${i}`] = it.MoeinCode;
        p[`d1_${i}`] = it.Taf1Id; p[`d2_${i}`] = it.Taf2Id; p[`d3_${i}`] = it.Taf3Id;
        p[`ds${i}`] = it.Descr; p[`db${i}`] = it.Crt; p[`cr${i}`] = it.Dbt; /* معکوس */
      });
      await run(
        `INSERT INTO ACC.AccVoucherItm (VoucherId, RowNo, KolCode, MoeinCode, Taf1Id, Taf2Id, Taf3Id, Descr, Dbt, Crt)
         VALUES ${vals.join(",")}`, p);
      await run(`INSERT INTO ACC.AccVoucherFlow (VoucherId, Action, ByUser, Note) VALUES (@h, 6, @u, @n)`,
        { h: rev.VoucherId, u: s.username, n: `سند برگشتی برای سند ${hdr.VchNo}` });
      await run(`INSERT INTO ACC.AccVoucherFlow (VoucherId, Action, ByUser, Note) VALUES (@id, 6, @u, @n)`,
        { id, u: s.username, n: `سند برگشتی شماره ${Number(noRow[0].NV)} صادر شد` });
    });
    return NextResponse.json({ ok: true, reversal: rev });
  } catch (e: any) {
    return NextResponse.json({ ok: false, error: String(e.message || e).slice(0, 300) }, { status: 400 });
  }
}
