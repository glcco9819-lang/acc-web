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
     FROM Vch.Hdr h JOIN Vch.[Type] t ON t.TypeId=h.TypeId JOIN Prm.FiscalYear y ON y.YearId=h.YearId
     WHERE h.HdrId=@id`, { id });
  if (!hdr) return NextResponse.json({ ok: false, error: "سند یافت نشد" }, { status: 404 });

  const items = await q(
    `SELECT i.*, k.Title KolTitle, m.Title MoeinTitle, m.Dl1TypeId, m.Dl2TypeId, m.Dl3TypeId,
            d1.Title Dl1Title, d2.Title Dl2Title, d3.Title Dl3Title
     FROM Vch.Itm i
     JOIN Acc.Kol k ON k.CompanyId = (SELECT CompanyId FROM Vch.Hdr WHERE HdrId=i.HdrId) AND k.Code=i.KolCode
     JOIN Acc.Moein m ON m.CompanyId = k.CompanyId AND m.Code=i.MoeinCode
     LEFT JOIN Acc.DL d1 ON d1.DlId=i.Dl1Id
     LEFT JOIN Acc.DL d2 ON d2.DlId=i.Dl2Id
     LEFT JOIN Acc.DL d3 ON d3.DlId=i.Dl3Id
     WHERE i.HdrId=@id ORDER BY i.RowNo`, { id });

  const log = await q(
    `SELECT Action, ByUser, CONVERT(varchar(16), At, 120) AtFa, Note FROM Vch.WfLog WHERE HdrId=@id ORDER BY LogId`, { id });

  const rev = hdr.ReversalOf
    ? await one(`SELECT HdrId, VchNo, VchDate FROM Vch.Hdr WHERE HdrId=@r`, { r: hdr.ReversalOf })
    : null;

  return NextResponse.json({ ok: true, hdr, items, log, reversalOf: rev });
}
