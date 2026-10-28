import { NextRequest, NextResponse } from "next/server";
import { q } from "@/lib/db";
import { getSession } from "@/lib/auth";
import { ctxOf, openingDone } from "../common";

/* دفتر معین [معين — کارت هر معین با مانده در خط] */
export async function GET(req: NextRequest) {
  const s = await getSession();
  if (!s) return NextResponse.json({ ok: false, error: "دسترسی رد شد" }, { status: 401 });
  const { companyId, yearId } = ctxOf(req);
  if (!companyId || !yearId) return NextResponse.json({ ok: false, error: "شرکت و سال مالی انتخاب نشده", code: "NO_CTX" }, { status: 400 });

  const sp = new URL(req.url).searchParams;
  const from = sp.get("from") || "";
  const to = sp.get("to") || "";
  const kol = sp.get("kol") || "";
  const moein = sp.get("moein") || "";
  const conds = ["h.CompanyId=@c", "h.YearId=@y", "h.State=3"];
  const inp: Record<string, unknown> = { c: companyId, y: yearId };
  if (from) { conds.push("h.VchDate >= @from"); inp.from = from; }
  if (to) { conds.push("h.VchDate <= @to"); inp.to = to; }
  if (kol) { conds.push("i.KolCode=@kol"); inp.kol = kol; }
  if (moein) { conds.push("i.MoeinCode=@moein"); inp.moein = moein; }

  const rows = await q(
    `SELECT h.VoucherId, h.VchNo, h.VchDate, h.Descr VchDescr, h.SourceModule, h.ReversalOf,
            i.RowNo, i.KolCode, k.Title KolTitle, i.MoeinCode, m.Title MoeinTitle, m.AccNature,
            d1.Code Taf1Code, d1.Title Taf1Title,
            d2.Code Taf2Code, d2.Title Taf2Title,
            d3.Code Taf3Code, d3.Title Taf3Title,
            i.Descr ItmDescr, i.Dbt, i.Crt
     FROM ACC.AccVoucher h
     JOIN ACC.AccVoucherItm i ON i.VoucherId=h.VoucherId
     JOIN ACC.AccKol k ON k.CompanyId=h.CompanyId AND k.Code=i.KolCode
     JOIN ACC.AccMoein m ON m.CompanyId=h.CompanyId AND m.Code=i.MoeinCode
     LEFT JOIN ACC.AccTafsili d1 ON d1.TafsiliId=i.Taf1Id
     LEFT JOIN ACC.AccTafsili d2 ON d2.TafsiliId=i.Taf2Id
     LEFT JOIN ACC.AccTafsili d3 ON d3.TafsiliId=i.Taf3Id
     WHERE ${conds.join(" AND ")}
     ORDER BY i.MoeinCode, h.VchDate, h.VchNo, i.RowNo`, inp);

  const opDone = await openingDone(companyId, yearId);
  const opening = opDone ? [] : await q(
    `SELECT ob.KolCode, ob.MoeinCode, SUM(ob.Dbt) Dbt, SUM(ob.Crt) Crt
     FROM ACC.AccOpeningBalance ob WHERE ob.CompanyId=@c AND ob.YearId=@y ${moein ? "AND ob.MoeinCode=@moein" : ""}
     GROUP BY ob.KolCode, ob.MoeinCode`, inp);

  /* ماندهٔ در خط: بر اساس ماهیت معین */
  const opMap = new Map(opening.map((o) => [String(o.MoeinCode), o]));
  let running: Record<string, number> = {};
  let out = rows.map((r) => {
    const key = String(r.MoeinCode);
    if (!(key in running)) {
      const op = opMap.get(key);
      const opDbt = Number(op?.Dbt || 0), opCrt = Number(op?.Crt || 0);
      const nat = Number(r.AccNature);
      running[key] = nat === 2 ? opCrt - opDbt : opDbt - opCrt;
    }
    const nat = Number(r.AccNature);
    running[key] += nat === 2 ? (Number(r.Crt) - Number(r.Dbt)) : (Number(r.Dbt) - Number(r.Crt));
    return { ...r, Balance: running[key] };
  });

  /* ماندهٔ ابتدای دوره برای معین‌هایی که در بازه گردش ندارند ولی مانده دارند */
  if (moein && !out.length) {
    const op = opMap.get(String(moein));
    if (op) out = [{ MoeinCode: moein, Balance: Number(op.Dbt) - Number(op.Crt), KolCode: op.KolCode, MoeinTitle: "", AccNature: 1 }];
  }

  return NextResponse.json({ ok: true, rows: out });
}
