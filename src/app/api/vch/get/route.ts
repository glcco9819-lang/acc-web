import { NextRequest, NextResponse } from "next/server";
import { one, q } from "@/lib/db";
import { getSession } from "@/lib/auth";

/* مشاهدهٔ کامل یک سند: سرسند + ردیف‌ها با عناوین + ردپای عملیات */
export async function GET(req: NextRequest) {
  const s = await getSession();
  if (!s) return NextResponse.json({ ok: false, error: "دسترسی رد شد" }, { status: 401 });
  const id = Number(new URL(req.url).searchParams.get("id") || 0);
  if (!id) return NextResponse.json({ ok: false, error: "شناسه لازم است" }, { status: 400 });

  const hdr = await one<any>(
    `SELECT h.*, t.Title TypeTitle, y.Title YearTitle
     FROM YfgVch.Voucher h JOIN YfgVch.VoucherType t ON t.VoucherTypeId=h.VoucherTypeId JOIN YfgPrm.FiscalYear y ON y.YearId=h.YearId
     WHERE h.VoucherId=@id`, { id });
  if (!hdr) return NextResponse.json({ ok: false, error: "سند یافت نشد" }, { status: 404 });

  const items = await q(
    `SELECT i.*, k.Title KolTitle, m.Title MoeinTitle, m.Taf1TypeId, m.Taf2TypeId, m.Taf3TypeId,
            d1.Title Taf1Title, d2.Title Taf2Title, d3.Title Taf3Title
     FROM YfgVch.VoucherLine i
     JOIN YfgAcc.Kol k ON k.CompanyId = (SELECT CompanyId FROM YfgVch.Voucher WHERE VoucherId=i.VoucherId) AND k.Code=i.KolCode
     JOIN YfgAcc.Moein m ON m.CompanyId = k.CompanyId AND m.Code=i.MoeinCode
     LEFT JOIN YfgAcc.Tafsili d1 ON d1.TafsiliId=i.Taf1Id
     LEFT JOIN YfgAcc.Tafsili d2 ON d2.TafsiliId=i.Taf2Id
     LEFT JOIN YfgAcc.Tafsili d3 ON d3.TafsiliId=i.Taf3Id
     WHERE i.VoucherId=@id ORDER BY i.RowNo`, { id });

  const log = await q(
    `SELECT Action, ByUser, CONVERT(varchar(16), At, 120) AtFa, Note FROM YfgVch.VoucherFlow WHERE VoucherId=@id ORDER BY LogId`, { id });

  const rev = hdr.ReversalOf
    ? await one(`SELECT VoucherId, VchNo, VchDate FROM YfgVch.Voucher WHERE VoucherId=@r`, { r: hdr.ReversalOf })
    : null;

  return NextResponse.json({ ok: true, hdr, items, log, reversalOf: rev });
}
