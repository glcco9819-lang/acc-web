import { NextRequest, NextResponse } from "next/server";
import { q, one } from "@/lib/db";
import { getSession } from "@/lib/auth";
import { ctxOf, openingDone } from "../common";

/* دفتر کل [كل — گردش هر حساب کل با ماندهٔ ابتدای دوره/گردش/ماندهٔ پایان] */
export async function GET(req: NextRequest) {
  const s = await getSession();
  if (!s) return NextResponse.json({ ok: false, error: "دسترسی رد شد" }, { status: 401 });
  const { companyId, yearId } = ctxOf(req);
  if (!companyId || !yearId) return NextResponse.json({ ok: false, error: "شرکت و سال مالی انتخاب نشده", code: "NO_CTX" }, { status: 400 });

  const sp = new URL(req.url).searchParams;
  const from = sp.get("from") || "";
  const to = sp.get("to") || "";
  const kol = sp.get("kol") || "";
  const conds = ["h.CompanyId=@c", "h.YearId=@y", "h.State=3"];
  const inp: Record<string, unknown> = { c: companyId, y: yearId };
  if (from) { conds.push("h.VchDate >= @from"); inp.from = from; }
  if (to) { conds.push("h.VchDate <= @to"); inp.to = to; }
  if (kol) { conds.push("i.KolCode=@kol"); inp.kol = kol; }

  const opDone = await openingDone(companyId, yearId);
  const opening = opDone ? [] : await q(
    `SELECT ob.KolCode, SUM(ob.Dbt) Dbt, SUM(ob.Crt) Crt
     FROM ACC.AccOpeningBalance ob WHERE ob.CompanyId=@c AND ob.YearId=@y ${kol ? "AND ob.KolCode=@kol" : ""}
     GROUP BY ob.KolCode`, inp);

  const rows = await q(
    `SELECT i.KolCode, k.Title KolTitle, k.AccNature,
            ISNULL(SUM(i.Dbt),0) Dbt, ISNULL(SUM(i.Crt),0) Crt, COUNT(DISTINCT h.VoucherId) VchCount
     FROM ACC.AccVoucher h JOIN ACC.AccVoucherItm i ON i.VoucherId=h.VoucherId
     JOIN ACC.AccKol k ON k.CompanyId=h.CompanyId AND k.Code=i.KolCode
     WHERE ${conds.join(" AND ")}
     GROUP BY i.KolCode, k.Title, k.AccNature
     ORDER BY i.KolCode`, inp);

  const opMap = new Map(opening.map((o) => [String(o.KolCode), o]));
  const enriched = rows.map((r) => {
    const op = opMap.get(String(r.KolCode));
    const opDbt = Number(op?.Dbt || 0), opCrt = Number(op?.Crt || 0);
    const nature = Number(r.AccNature); /* 1=بدهکار 2=بستانکار 3=دوطرفه */
    const opBal = nature === 2 ? opCrt - opDbt : opDbt - opCrt;
    const bal = nature === 2 ? (opCrt + Number(r.Crt)) - (opDbt + Number(r.Dbt)) : (opDbt + Number(r.Dbt)) - (opCrt + Number(r.Crt));
    return { ...r, OpDbt: opDbt, OpCrt: opCrt, OpBal: opBal, EndBal: bal };
  });

  return NextResponse.json({ ok: true, rows: enriched });
}
