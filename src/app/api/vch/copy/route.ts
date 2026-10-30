import { NextRequest, NextResponse } from "next/server";
import { one, q, tx } from "@/lib/db";
import { getSession, can } from "@/lib/auth";
import { ctxOf } from "@/lib/ctx";
import { isValidJalali } from "@/lib/jalali";
import { validateVoucherItems, ItemIn, OutItem } from "@/lib/vchitems";

/* ============================================================================
   کپی سند / سندهای انتخاب‌شده (v2.4.5) — درخواست کارفرما:
   «کلید کپی سند یا سند های انتخاب شده با گزینه های (کپی تکی - ترکیبی -
    جابه جایی بده و بس - تاریخ سند)»
   mode=single  کپی تکی — هر سند انتخاب‌شده یک سند جدید مستقل می‌شود
   mode=merged  ترکیبی — همهٔ ردیف‌های سندهای انتخاب‌شده در «یک» سند جدید ادغام می‌شوند
   swap=1       جابه‌جایی بدهکار/بستانکار («بده و بس») در همهٔ ردیف‌های کپی
   vchDate      تاریخ سند جدید (جلالی) — پیش‌فرض امروز
   قواعد:
   • خروجی همیشه سند «موقت» است؛ از هر وضعیتی (حتی قطعی) قابل کپی است
   • سند برگشتی هم مثل سند عادی کپی می‌شود (محتوایش همان ردیف‌هاست)
   • شمارهٔ عطف/سند/روزانهٔ جدید خودکار صادر می‌شود (مطابق صدور سند)
   • اقلام از اعتبارسنجی مشترک می‌گذرند (معین زیرمجموعهٔ کل + تفصیلی‌های الزامی + تراز)
   ============================================================================ */

export async function POST(req: NextRequest) {
  const s = await getSession();
  if (!s) return NextResponse.json({ ok: false, error: "دسترسی رد شد" }, { status: 401 });
  if (!can(s, "issue")) return NextResponse.json({ ok: false, error: "نقش شما مجاز به صدور سند نیست" }, { status: 403 });

  const body0 = await req.json().catch(() => ({}));
  const { companyId, yearId } = ctxOf(req, body0);
  if (!companyId || !yearId) return NextResponse.json({ ok: false, error: "شرکت و سال مالی انتخاب نشده", code: "NO_CTX" }, { status: 400 });

  const rawIds: any[] = Array.isArray(body0?.ids) ? body0.ids : [];
  const ids: number[] = Array.from(new Set<number>(rawIds.map((x: any): number => Number(x) || 0))).filter(Boolean);
  const mode = body0.mode === "merged" ? "merged" : "single";
  const swap = !!body0.swap;
  const vchDate = String(body0.vchDate || "").trim();

  if (!ids.length) return NextResponse.json({ ok: false, error: "هیچ سندی انتخاب نشده" }, { status: 400 });
  if (ids.length > 200) return NextResponse.json({ ok: false, error: "بیش از ۲۰۰ سند در هر بار مجاز نیست" }, { status: 400 });
  if (!isValidJalali(vchDate)) return NextResponse.json({ ok: false, error: "تاریخ سند جدید نامعتبر است (جلالی YYYY/MM/DD)" }, { status: 400 });

  const yr = await one("SELECT IsClosed FROM pob.FiscalYear WHERE YearId=@y AND CompanyId=@c", { y: yearId, c: companyId });
  if (!yr) return NextResponse.json({ ok: false, error: "سال مالی یافت نشد" }, { status: 400 });
  if (yr.IsClosed) return NextResponse.json({ ok: false, error: "سال مالی بسته است" }, { status: 400 });

  /* سرسندها — فقط از شرکت/سال جاری */
  const ph = ids.map((_, i) => `@i${i}`).join(",");
  const ip: Record<string, unknown> = { c: companyId, y: yearId };
  ids.forEach((v, i) => { ip[`i${i}`] = v; });
  const srcs = await q(
    `SELECT VoucherId, VchNo, VoucherTypeId, Descr, BranchId, SubNo, LatinDescr, ReversalOf
     FROM ACC.AccVoucher WHERE CompanyId=@c AND YearId=@y AND VoucherId IN (${ph})
     ORDER BY VchNo, SubNo`, ip);
  if (!srcs.length) return NextResponse.json({ ok: false, error: "سند(های) انتخابی در شرکت/سال جاری یافت نشد" }, { status: 404 });

  /* اقلام مبدأ — به ترتیب سند و ردیف */
  const items = await q(
    `SELECT i.VoucherId, i.KolCode, i.MoeinCode, i.Taf1Id, i.Taf2Id, i.Taf3Id, i.Descr, i.Dbt, i.Crt,
            i.FxId, i.FxAmount, i.FxRate, i.TrackNo, i.TrackDate, i.LatinDescr
     FROM ACC.AccVoucherItm i WHERE i.VoucherId IN (${ph})
     ORDER BY i.VoucherId, i.RowNo`, ip);
  const byVch = new Map<number, any[]>();
  for (const it of items as any[]) {
    const arr = byVch.get(Number(it.VoucherId)) || [];
    arr.push(it); byVch.set(Number(it.VoucherId), arr);
  }
  const missing = (srcs as any[]).filter((h) => !(byVch.get(Number(h.VoucherId)) || []).length);
  if (missing.length) return NextResponse.json({ ok: false, error: `سند ${missing[0].VchNo} ردیفی ندارد و کپی نمی‌شود` }, { status: 400 });

  /* مونتاژ اقلام خروجی — جابه‌جایی بدهکار/بستانکار در صورت درخواست */
  const mount = (rows: any[]): ItemIn[] => rows.map((r) => ({
    KolCode: String(r.KolCode), MoeinCode: String(r.MoeinCode),
    Taf1Id: r.Taf1Id ?? null, Taf2Id: r.Taf2Id ?? null, Taf3Id: r.Taf3Id ?? null,
    Descr: r.Descr || "", Dbt: swap ? Number(r.Crt || 0) : Number(r.Dbt || 0),
    Crt: swap ? Number(r.Dbt || 0) : Number(r.Crt || 0),
    FxId: r.FxId ?? null, FxAmount: r.FxAmount ?? null, FxRate: r.FxRate ?? null,
    TrackNo: r.TrackNo || "", TrackDate: r.TrackDate || "", LatinDescr: r.LatinDescr || "",
  }));

  /* سند(های) مقصد: تکی = یکی به‌ازای هر مبدأ · ترکیبی = فقط یکی */
  const dests: { items: ItemIn[]; typeId: number; descr: string | null; branchId: number | null; subNo: number; latin: string | null; from: number[] }[] = [];
  if (mode === "merged") {
    const all: any[] = [];
    const fromNos: string[] = [];
    for (const h of srcs as any[]) {
      all.push(...(byVch.get(Number(h.VoucherId)) || []));
      fromNos.push(String(h.VchNo));
    }
    const first = (srcs as any[])[0];
    dests.push({
      items: mount(all),
      typeId: Number(first.VoucherTypeId),
      descr: `کپی ترکیبی سندهای ${fromNos.join("، ")}`.slice(0, 500),
      branchId: first.BranchId ? Number(first.BranchId) : null,
      subNo: 0, latin: first.LatinDescr || null,
      from: (srcs as any[]).map((h) => Number(h.VoucherId)),
    });
  } else {
    for (const h of srcs as any[]) {
      dests.push({
        items: mount(byVch.get(Number(h.VoucherId)) || []),
        typeId: Number(h.VoucherTypeId),
        descr: String(h.Descr || "").slice(0, 500) || null,
        branchId: h.BranchId ? Number(h.BranchId) : null,
        subNo: Number(h.SubNo || 0),
        latin: h.LatinDescr || null,
        from: [Number(h.VoucherId)],
      });
    }
  }

  /* اعتبارسنجی همهٔ اسناد مقصد قبل از هر ثبت */
  const cleaned: { items: OutItem[]; d: (typeof dests)[number] }[] = [];
  for (let i = 0; i < dests.length; i++) {
    const v = await validateVoucherItems(dests[i].items, companyId);
    if ("error" in v) return v.error;
    cleaned.push({ items: v.items, d: dests[i] });
  }

  try {
    const created: { VoucherId: number; VchNo: number; VchDate: string; Items: number }[] = [];
    await tx(async (run) => {
      const noRow = await run(
        `SELECT ISNULL(MAX(FolioNo),0)+1 NF, ISNULL(MAX(VchNo),0)+1 NV FROM ACC.AccVoucher WITH (TABLOCKX) WHERE CompanyId=@c AND YearId=@y`,
        { c: companyId, y: yearId });
      let folio = Number(noRow[0].NF), vchNo = Number(noRow[0].NV);
      const dRow = await run(
        `SELECT ISNULL(MAX(DayNo),0) DN FROM ACC.AccVoucher WHERE CompanyId=@c AND YearId=@y AND VchDate=@d`,
        { c: companyId, y: yearId, d: vchDate });
      let dayNo = Number(dRow[0].DN);
      for (const { items: its, d } of cleaned) {
        const vals: string[] = [];
        const p: Record<string, unknown> = {
          c: companyId, y: yearId, f: folio, n: vchNo, t: d.typeId, d: vchDate,
          ds: d.descr, u: s.username, br: d.branchId, dn: dayNo + 1, sn: d.subNo, ld: d.latin,
        };
        its.forEach((it, i) => {
          vals.push(`(@h, @r${i}, @k${i}, @m${i}, @d1_${i}, @d2_${i}, @d3_${i}, @ds${i}, @db${i}, @cr${i}, @fx${i}, @fa${i}, @fr${i}, @tn${i}, @td${i}, @ld${i})`);
          p[`r${i}`] = i + 1; p[`k${i}`] = it.KolCode; p[`m${i}`] = it.MoeinCode;
          p[`d1_${i}`] = it.Taf1Id; p[`d2_${i}`] = it.Taf2Id; p[`d3_${i}`] = it.Taf3Id;
          p[`ds${i}`] = it.Descr; p[`db${i}`] = it.Dbt; p[`cr${i}`] = it.Crt;
          p[`fx${i}`] = it.FxId; p[`fa${i}`] = it.FxAmount; p[`fr${i}`] = it.FxRate;
          p[`tn${i}`] = it.TrackNo; p[`td${i}`] = it.TrackDate; p[`ld${i}`] = it.LatinDescr;
        });
        const h = await run(
          `INSERT INTO ACC.AccVoucher (CompanyId, YearId, FolioNo, VchNo, VoucherTypeId, VchDate, Descr, State, SourceModule, CreatedBy, BranchId, DayNo, SubNo, LatinDescr)
           VALUES (@c, @y, @f, @n, @t, @d, @ds, 1, 'ACC', @u, @br, @dn, @sn, @ld);
           SELECT VoucherId, VchNo FROM ACC.AccVoucher WHERE VoucherId = CAST(SCOPE_IDENTITY() AS int)`, p);
        const newId = Number(h[0].VoucherId);
        await run(
          `INSERT INTO ACC.AccVoucherItm (VoucherId, RowNo, KolCode, MoeinCode, Taf1Id, Taf2Id, Taf3Id, Descr, Dbt, Crt, FxId, FxAmount, FxRate, TrackNo, TrackDate, LatinDescr)
           VALUES ${vals.join(",")}`, { ...p, h: newId });
        const srcTitle = mode === "merged"
          ? `کپی ترکیبی از ${d.from.length} سند`
          : `کپی از سند ${(srcs as any[]).find((x) => Number(x.VoucherId) === d.from[0])?.VchNo || ""}`;
        await run(`INSERT INTO ACC.AccVoucherFlow (VoucherId, Action, ByUser, Note) VALUES (@h, 9, @u, @n)`,
          { h: newId, u: s.username, n: srcTitle });
        created.push({ VoucherId: newId, VchNo: Number(h[0].VchNo), VchDate: vchDate, Items: its.length });
        folio++; vchNo++; dayNo++;
      }
    });
    return NextResponse.json({ ok: true, mode, swap, vouchers: created });
  } catch (e: any) {
    return NextResponse.json({ ok: false, error: String(e.message || e).slice(0, 300) }, { status: 400 });
  }
}
