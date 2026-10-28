import { NextRequest, NextResponse } from "next/server";
import { q, one } from "@/lib/db";
import { getSession } from "@/lib/auth";
import { ctxOf, openingDone } from "../common";

/* دفتر تفصیلی [تفصيلي — کارت تفصیلی از سه اسلات سطح ۴/۵/۶ سند] */
export async function GET(req: NextRequest) {
  const s = await getSession();
  if (!s) return NextResponse.json({ ok: false, error: "دسترسی رد شد" }, { status: 401 });
  const { companyId, yearId } = ctxOf(req);
  if (!companyId || !yearId) return NextResponse.json({ ok: false, error: "شرکت و سال مالی انتخاب نشده", code: "NO_CTX" }, { status: 400 });

  const sp = new URL(req.url).searchParams;
  const from = sp.get("from") || "";
  const to = sp.get("to") || "";
  const dlId = Number(sp.get("dlId") || 0);
  const moein = String(sp.get("moein") || "");
  if (!dlId) return NextResponse.json({ ok: false, error: "تفصیلی انتخاب نشده" }, { status: 400 });
  if (!moein) return NextResponse.json({ ok: false, error: "معین انتخاب نشده — کارت تفصیلی زیر یک معین است" }, { status: 400 });

  const dl = await one<any>(
    `SELECT d.DlId, d.Code, d.Title, t.Title TypeTitle FROM Acc.DL d JOIN Acc.DlType t ON t.DlTypeId=d.DlTypeId
     WHERE d.DlId=@d AND d.CompanyId=@c`, { d: dlId, c: companyId });
  if (!dl) return NextResponse.json({ ok: false, error: "تفصیلی یافت نشد" }, { status: 404 });

  const conds = ["h.CompanyId=@c", "h.YearId=@y", "h.State=3", "i.MoeinCode=@m", "(i.Dl1Id=@d OR i.Dl2Id=@d OR i.Dl3Id=@d)"];
  const inp: Record<string, unknown> = { c: companyId, y: yearId, d: dlId, m: moein };
  if (from) { conds.push("h.VchDate >= @from"); inp.from = from; }
  if (to) { conds.push("h.VchDate <= @to"); inp.to = to; }

  const rows = await q(
    `SELECT h.HdrId, h.VchNo, h.VchDate, h.Descr VchDescr, h.SourceModule, h.ReversalOf,
            i.RowNo, i.KolCode, k.Title KolTitle, i.MoeinCode, m.Title MoeinTitle, m.AccNature,
            CASE WHEN i.Dl1Id=@d THEN N'سطح چهارم' WHEN i.Dl2Id=@d THEN N'سطح پنجم' ELSE N'سطح ششم' END Slot,
            i.Descr ItmDescr, i.Dbt, i.Crt
     FROM Vch.Hdr h
     JOIN Vch.Itm i ON i.HdrId=h.HdrId
     JOIN Acc.Kol k ON k.CompanyId=h.CompanyId AND k.Code=i.KolCode
     JOIN Acc.Moein m ON m.CompanyId=h.CompanyId AND m.Code=i.MoeinCode
     WHERE ${conds.join(" AND ")}
     ORDER BY h.VchDate, h.VchNo, i.RowNo`, inp);

  const opDone = await openingDone(companyId, yearId);
  const op = opDone ? null : await one(
    `SELECT SUM(CASE WHEN m.AccNature=2 THEN ob.Crt-ob.Dbt ELSE ob.Dbt-ob.Crt END) Bal
     FROM Acc.OpeningBalance ob JOIN Acc.Moein m ON m.CompanyId=ob.CompanyId AND m.Code=ob.MoeinCode
     WHERE ob.CompanyId=@c AND ob.YearId=@y AND ob.MoeinCode=@m AND (ob.Dl1Id=@d OR ob.Dl2Id=@d OR ob.Dl3Id=@d)`, inp);

  const nat = Number((await one<any>(`SELECT AccNature FROM Acc.Moein WHERE CompanyId=@c AND Code=@m`, { c: companyId, m: moein }))?.AccNature || 1);
  let running = Number(op?.Bal || 0);
  const lines = rows.map((r) => {
    running += nat === 2 ? (Number(r.Crt) - Number(r.Dbt)) : (Number(r.Dbt) - Number(r.Crt));
    return { ...r, Balance: running };
  });

  return NextResponse.json({ ok: true, dl, rows: lines, opening: Number(op?.Bal || 0) });
}
