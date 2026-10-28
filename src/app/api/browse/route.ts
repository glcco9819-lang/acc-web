import { NextRequest, NextResponse } from "next/server";
import { q, one } from "@/lib/db";
import { getSession } from "@/lib/auth";
import { ctxOf, openingDone } from "../books/common";

/* مرور حساب‌ها [فرم: مرور حساب‌ها — acvwdf] پارامتر moein یا kol → کارت گردش با مانده در خط */
export async function GET(req: NextRequest) {
  const s = await getSession();
  if (!s) return NextResponse.json({ ok: false, error: "دسترسی رد شد" }, { status: 401 });
  const { companyId, yearId } = ctxOf(req);
  if (!companyId || !yearId) return NextResponse.json({ ok: false, error: "شرکت و سال مالی انتخاب نشده", code: "NO_CTX" }, { status: 400 });

  const sp = new URL(req.url).searchParams;
  const mode = sp.get("mode") || "tree";

  if (mode === "tree") {
    const rows = await q(
      `SELECT g.Code GroupCode, g.Title GroupTitle, g.AccNature GroupNature,
              k.Code KolCode, k.Title KolTitle,
              m.Code MoeinCode, m.Title MoeinTitle, m.AccNature, m.IsActive,
              t1.Title Taf1Title, t2.Title Taf2Title, t3.Title Taf3Title,
              ISNULL(bal.D,0) Dbt, ISNULL(bal.C,0) Crt
       FROM YfgAcc.AccGroup g
       LEFT JOIN YfgAcc.Kol k ON k.CompanyId=g.CompanyId AND k.GroupCode=g.Code
       LEFT JOIN YfgAcc.Moein m ON m.CompanyId=k.CompanyId AND m.KolCode=k.Code
       LEFT JOIN YfgAcc.TafsiliType t1 ON t1.TafsiliTypeId=m.Taf1TypeId
       LEFT JOIN YfgAcc.TafsiliType t2 ON t2.TafsiliTypeId=m.Taf2TypeId
       LEFT JOIN YfgAcc.TafsiliType t3 ON t3.TafsiliTypeId=m.Taf3TypeId
       LEFT JOIN (SELECT i.MoeinCode, SUM(i.Dbt) D, SUM(i.Crt) C
                  FROM YfgVch.Voucher h JOIN YfgVch.VoucherLine i ON i.VoucherId=h.VoucherId
                  WHERE h.CompanyId=@c AND h.YearId=@y AND h.State=3
                  GROUP BY i.MoeinCode) bal ON bal.MoeinCode=m.Code
       WHERE g.CompanyId=@c
       ORDER BY g.Code, k.Code, m.Code`, { c: companyId, y: yearId });
    return NextResponse.json({ ok: true, rows });
  }

  if (mode === "card") {
    const moein = String(sp.get("moein") || "");
    const dlId = Number(sp.get("dlId") || 0);
    const from = sp.get("from") || "";
    const to = sp.get("to") || "";
    if (!moein) return NextResponse.json({ ok: false, error: "معین انتخاب نشده" }, { status: 400 });

    const head = await one<any>(
      `SELECT m.Code, m.Title, m.AccNature, m.Taf1TypeId, m.Taf2TypeId, m.Taf3TypeId, k.Title KolTitle,
              t1.Title Dl1TypeTitle, t2.Title Dl2TypeTitle, t3.Title Dl3TypeTitle
       FROM YfgAcc.Moein m JOIN YfgAcc.Kol k ON k.CompanyId=m.CompanyId AND k.Code=m.KolCode
       LEFT JOIN YfgAcc.TafsiliType t1 ON t1.TafsiliTypeId=m.Taf1TypeId
       LEFT JOIN YfgAcc.TafsiliType t2 ON t2.TafsiliTypeId=m.Taf2TypeId
       LEFT JOIN YfgAcc.TafsiliType t3 ON t3.TafsiliTypeId=m.Taf3TypeId
       WHERE m.CompanyId=@c AND m.Code=@m`, { c: companyId, m: moein });
    if (!head) return NextResponse.json({ ok: false, error: "معین یافت نشد" }, { status: 404 });

    const conds = ["h.CompanyId=@c", "h.YearId=@y", "h.State=3", "i.MoeinCode=@m"];
    const inp: Record<string, unknown> = { c: companyId, y: yearId, m: moein };
    if (dlId) { conds.push("(i.Taf1Id=@d OR i.Taf2Id=@d OR i.Taf3Id=@d)"); inp.d = dlId; }
    if (from) { conds.push("h.VchDate >= @from"); inp.from = from; }
    if (to) { conds.push("h.VchDate <= @to"); inp.to = to; }

    const rows = await q(
      `SELECT h.VoucherId, h.VchNo, h.VchDate, h.Descr VchDescr, h.SourceModule, h.ReversalOf,
              i.RowNo, i.KolCode, k.Title KolTitle,
              d1.Title Taf1Title, d2.Title Taf2Title, d3.Title Taf3Title,
              i.Descr ItmDescr, i.Dbt, i.Crt
       FROM YfgVch.Voucher h JOIN YfgVch.VoucherLine i ON i.VoucherId=h.VoucherId
       JOIN YfgAcc.Kol k ON k.CompanyId=h.CompanyId AND k.Code=i.KolCode
       LEFT JOIN YfgAcc.Tafsili d1 ON d1.TafsiliId=i.Taf1Id
       LEFT JOIN YfgAcc.Tafsili d2 ON d2.TafsiliId=i.Taf2Id
       LEFT JOIN YfgAcc.Tafsili d3 ON d3.TafsiliId=i.Taf3Id
       WHERE ${conds.join(" AND ")}
       ORDER BY h.VchDate, h.VchNo, i.RowNo`, inp);

    const opDone = await openingDone(companyId, yearId);
    const op = opDone ? null : await one(
      `SELECT SUM(CASE WHEN m.AccNature=2 THEN ob.Crt-ob.Dbt ELSE ob.Dbt-ob.Crt END) Bal
       FROM YfgAcc.OpeningBalance ob JOIN YfgAcc.Moein m ON m.CompanyId=ob.CompanyId AND m.Code=ob.MoeinCode
       WHERE ob.CompanyId=@c AND ob.YearId=@y AND ob.MoeinCode=@m ${dlId ? "AND (ob.Taf1Id=@d OR ob.Taf2Id=@d OR ob.Taf3Id=@d)" : ""}`, inp);

    let running = Number(op?.Bal || 0);
    const lines = rows.map((r) => {
      const nat = Number(head.AccNature);
      running += nat === 2 ? (Number(r.Crt) - Number(r.Dbt)) : (Number(r.Dbt) - Number(r.Crt));
      return { ...r, Balance: running };
    });
    return NextResponse.json({ ok: true, head, rows: lines, opening: Number(op?.Bal || 0) });
  }

  return NextResponse.json({ ok: false, error: "mode نامعتبر" }, { status: 400 });
}
