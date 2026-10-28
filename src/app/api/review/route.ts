import { NextRequest, NextResponse } from "next/server";
import { q, one } from "@/lib/db";
import { getSession } from "@/lib/auth";
import { ctxOf, openingDone } from "../books/common";

/* ============================================================================
   مرور حساب‌ها — بازنویسی کامل مطابق AcVwDef.BPL (v2.1.0)
   [فرم اصلی: مرور حسابها — TFrRemRep + TAccViewLG_Itm + TAccViewLGBalance +
    TAccAnalysForm + TAccCurFlow + مانده در خط]

   mode=tree     درخت گروه/کل/معین با گردش و ماندهٔ هر سطح
                 (فيلتردرختواره + حسابهای بامانده)
   mode=card     گردش حساب (دفتر کل/معین/تفصیلی):
                 display=full|sumIn|sumNo  ← كامل / خلاصه با احتساب مانده ابتدا / بدون
                 dir=dc|d|c               ← بدهكار و بستانكار / بدهكار / بستانكار
                 runBal=1|0               ← مانده در خط (با احتساب مانده قبل از دوره)
                 + محدوده اسناد: از/تا تاریخ، سال از/تا، ماه از/تا، شماره از/تا،
                   نوع سند، افتتاحیه/اختتامیه/عادی، شعبه
   mode=balance  تراز حساب: گردش تا این دوره / گردش دوره / گردش تا پایان دوره / مانده
   mode=analys   آناليز حسابها (گروه‌بندی تفصیلی سطح ۴/۵/۶ + آناليزشده/نشده)
   mode=fx       گردش ارز (به تفکیک ارز، سندبه‌سند)
   mode=fxbal    مانده ارزی (به تفکیک ارز + معادل ریالی)
   ============================================================================ */

type Level = "kol" | "moein" | "dl";

const YM = "CAST(LEFT(h.VchDate,4) AS int)*100 + CASE WHEN LEN(h.VchDate)>=7 THEN CAST(SUBSTRING(h.VchDate,6,2) AS int) ELSE 0 END";
const YR = "CAST(LEFT(h.VchDate,4) AS int)";
const MO = "CAST(SUBSTRING(h.VchDate,6,2) AS int)";

function num(sp: URLSearchParams, k: string): number {
  const v = Number(sp.get(k) || 0);
  return Number.isFinite(v) ? v : 0;
}

/* شرط حساب انتخاب‌شده بر اساس سطح — level: kol | moein | dl */
function accountCond(level: Level, dlLevel: number): { sql: string; code: string } {
  if (level === "kol") return { sql: "i.KolCode = @acc", code: "acc" };
  if (level === "moein") return { sql: "i.MoeinCode = @acc", code: "acc" };
  const col = dlLevel === 2 ? "Taf2Id" : dlLevel === 3 ? "Taf3Id" : "Taf1Id";
  return { sql: `i.${col} = @acc`, code: "acc" };
}

/* شرط نوع سند — افتتاحیه/اختتامیه با LatinTitle نوع شناسایی می‌شوند (اصل سند افتتاحیه AC0540) */
function kindCond(kind: string): string {
  if (kind === "opening") return "ISNULL(t.LatinTitle,'') = 'Opening'";
  if (kind === "closing") return "ISNULL(t.LatinTitle,'') = 'Closing'";
  if (kind === "normal") return "ISNULL(t.LatinTitle,'') NOT IN ('Opening','Closing')";
  return "";
}

/* ============================ درخت حساب‌ها ============================ */
async function treeMode(companyId: number, yearId: number, sp: URLSearchParams) {
  const [groups, kols, moeins, sums, opDone] = await Promise.all([
    q(`SELECT Code GroupCode, Title GroupTitle, AccNature GroupNature FROM ACC.AccGroup WHERE CompanyId=@c ORDER BY Code`, { c: companyId }),
    q(`SELECT Code KolCode, Title KolTitle, GroupCode, AccNature KolNature FROM ACC.AccKol WHERE CompanyId=@c ORDER BY Code`, { c: companyId }),
    q(`SELECT Code MoeinCode, Title MoeinTitle, KolCode, AccNature MoeinNature, IsActive,
              Taf1TypeId, Taf2TypeId, Taf3TypeId, IsFx
       FROM ACC.AccMoein WHERE CompanyId=@c ORDER BY Code`, { c: companyId }),
    q(`SELECT i.MoeinCode, SUM(i.Dbt) D, SUM(i.Crt) C
       FROM ACC.AccVoucher h JOIN ACC.AccVoucherItm i ON i.VoucherId = h.VoucherId
       WHERE h.CompanyId=@c AND h.YearId=@y AND h.State=3
       GROUP BY i.MoeinCode`, { c: companyId, y: yearId }),
    openingDone(companyId, yearId),
  ]);
  /* ماندهٔ ابتدای دوره فقط وقتی به جمع اضافه می‌شود که سند افتتاحیهٔ قطعی موجود نباشد */
  const opMap = new Map<string, { D: number; C: number }>();
  if (!opDone) {
    const ops = await q(`SELECT MoeinCode, SUM(Dbt) D, SUM(Crt) C FROM ACC.AccOpeningBalance
                         WHERE CompanyId=@c AND YearId=@y GROUP BY MoeinCode`, { c: companyId, y: yearId });
    for (const o of ops as any[]) opMap.set(String(o.MoeinCode), { D: Number(o.D || 0), C: Number(o.C || 0) });
  }
  const mv = new Map<string, { D: number; C: number }>();
  for (const s of sums as any[]) mv.set(String(s.MoeinCode), { D: Number(s.D || 0), C: Number(s.C || 0) });

  const mRows = (moeins as any[]).map((m) => {
    const v = mv.get(String(m.MoeinCode)) || { D: 0, C: 0 };
    const o = opMap.get(String(m.MoeinCode)) || { D: 0, C: 0 };
    return { ...m, D: v.D + o.D, C: v.C + o.C };
  });
  const kRows = (kols as any[]).map((k) => {
    let D = 0, C = 0;
    for (const m of mRows) if (String(m.KolCode) === String(k.KolCode)) { D += Number(m.D); C += Number(m.C); }
    return { ...k, D, C };
  });
  const gRows = (groups as any[]).map((g) => {
    let D = 0, C = 0;
    for (const k of kRows) if (String(k.GroupCode) === String(g.GroupCode)) { D += Number(k.D); C += Number(k.C); }
    return { ...g, D, C };
  });

  const onlyBal = sp.get("onlyBal") === "1";
  const search = (sp.get("q") || "").trim();
  const hit = (t: string, code: string) => !search || String(t || "").includes(search) || String(code || "").includes(search);

  let mf = mRows.filter((m) => hit(m.MoeinTitle, m.MoeinCode));
  if (onlyBal) mf = mf.filter((m) => Number(m.D) - Number(m.C) !== 0);
  /* کل/گروه‌های بدون فرزندِ منطبق حذف می‌شوند تا درخت تمیز بماند */
  const mcodes = new Set(mf.map((m) => String(m.KolCode)));
  let kf = kRows.filter((k) => mcodes.has(String(k.KolCode)) || hit(k.KolTitle, k.KolCode));
  const kcodes = new Set(kf.map((k) => String(k.GroupCode)));
  const gf = gRows.filter((g) => kcodes.has(String(g.GroupCode)) || hit(g.GroupTitle, g.GroupCode));

  return { ok: true, openDone: opDone, groups: gf, kols: kf, moeins: mf };
}

/* ============================ گردش حساب ============================ */
interface CardParams {
  companyId: number; yearId: number;
  level: Level; code: string; dlLevel: number; dlId: number;
  from: string; to: string; yFrom: number; yTo: number; mFrom: number; mTo: number;
  noFrom: number; noTo: number; vchType: number; kind: string; dir: string; branch: number;
  display: string; runBal: boolean;
}

function cardConds(p: CardParams, withType = true) {
  const conds = ["h.CompanyId=@c", "h.YearId=@y", "h.State=3", accountCond(p.level, p.dlLevel).sql];
  const inp: Record<string, unknown> = { c: p.companyId, y: p.yearId, acc: p.level === "dl" ? p.dlId : p.code };
  if (p.from) { conds.push("h.VchDate >= @from"); inp.from = p.from; }
  if (p.to) { conds.push("h.VchDate <= @to"); inp.to = p.to; }
  if (p.yFrom) { conds.push(`${YR} >= @yf`); inp.yf = p.yFrom; }
  if (p.yTo) { conds.push(`${YR} <= @yt`); inp.yt = p.yTo; }
  if (p.mFrom) { conds.push(`${MO} >= @mf`); inp.mf = p.mFrom; }
  if (p.mTo) { conds.push(`${MO} <= @mt`); inp.mt = p.mTo; }
  if (p.noFrom) { conds.push("h.VchNo >= @nf"); inp.nf = p.noFrom; }
  if (p.noTo) { conds.push("h.VchNo <= @nt"); inp.nt = p.noTo; }
  if (p.vchType) { conds.push("h.VoucherTypeId = @vt"); inp.vt = p.vchType; }
  if (p.branch) { conds.push("h.BranchId = @br"); inp.br = p.branch; }
  const kc = kindCond(p.kind);
  if (kc && withType) { conds.push(kc); }
  if (p.dir === "d") conds.push("i.Dbt > 0");
  if (p.dir === "c") conds.push("i.Crt > 0");
  return { conds, inp };
}

async function cardHead(p: CardParams) {
  if (p.level === "kol") {
    return one<any>(
      `SELECT k.Code Code, k.Title Title, k.AccNature, g.Title GroupTitle
       FROM ACC.AccKol k LEFT JOIN ACC.AccGroup g ON g.CompanyId=k.CompanyId AND g.Code=k.GroupCode
       WHERE k.CompanyId=@c AND k.Code=@code`, { c: p.companyId, code: p.code });
  }
  if (p.level === "moein") {
    return one<any>(
      `SELECT m.Code Code, m.Title Title, m.AccNature, m.Taf1TypeId, m.Taf2TypeId, m.Taf3TypeId,
              m.IsFx, k.Code KolCode, k.Title KolTitle, g.Title GroupTitle,
              t1.Title Taf1TypeTitle, t2.Title Taf2TypeTitle, t3.Title Taf3TypeTitle
       FROM ACC.AccMoein m JOIN ACC.AccKol k ON k.CompanyId=m.CompanyId AND k.Code=m.KolCode
       LEFT JOIN ACC.AccGroup g ON g.CompanyId=k.CompanyId AND g.Code=k.GroupCode
       LEFT JOIN ACC.AccTafsiliType t1 ON t1.TafsiliTypeId=m.Taf1TypeId
       LEFT JOIN ACC.AccTafsiliType t2 ON t2.TafsiliTypeId=m.Taf2TypeId
       LEFT JOIN ACC.AccTafsiliType t3 ON t3.TafsiliTypeId=m.Taf3TypeId
       WHERE m.CompanyId=@c AND m.Code=@code`, { c: p.companyId, code: p.code });
  }
  return one<any>(
    `SELECT d.TafsiliId Id, d.Code Code, d.Title Title, t.Title TypeTitle
     FROM ACC.AccTafsili d JOIN ACC.AccTafsiliType t ON t.TafsiliTypeId=d.TafsiliTypeId
     WHERE d.CompanyId=@c AND d.TafsiliId=@code`, { c: p.companyId, code: p.dlId });
}

/* ماندهٔ قبل از بازه — با هر مرز پایینی که تنظیم شده باشد */
async function cardOpening(p: CardParams, openDone: boolean) {
  let ob = { D: 0, C: 0 };
  if (!openDone) {
    /* ماندهٔ جدول OpeningBalance (وقتی سند افتتاحیه قطعی نشده) */
    const cs = ["CompanyId=@c", "YearId=@y", accountCond(p.level, p.dlLevel).sql.replace("i.", "ob.")];
    const ip: Record<string, unknown> = { c: p.companyId, y: p.yearId, acc: p.level === "dl" ? p.dlId : p.code };
    const r = await one<any>(`SELECT ISNULL(SUM(Dbt),0) D, ISNULL(SUM(Crt),0) C FROM ACC.AccOpeningBalance ob WHERE ${cs.join(" AND ")}`, ip);
    ob = { D: Number(r?.D || 0), C: Number(r?.C || 0) };
  }
  /* گردش قبل از ابتدای بازه — مرزها: تاریخ / سال / ماه (شرط‌های «قبل» با هم OR می‌شوند
     چون محدودهٔ خودِ بازه با AND اعمال شده است) */
  const before: string[] = [];
  const inp: Record<string, unknown> = { c: p.companyId, y: p.yearId, acc: p.level === "dl" ? p.dlId : p.code };
  const { conds, inp: inp2 } = cardConds({ ...p, from: "", to: "", yFrom: 0, yTo: 0, mFrom: 0, mTo: 0, noFrom: 0, noTo: 0, dir: "dc" });
  Object.assign(inp, inp2);
  if (p.from) { before.push("h.VchDate < @from"); inp.from = p.from; }
  if (p.yFrom) { before.push(`${YR} < @yf`); inp.yf = p.yFrom; }
  if (p.mFrom && !p.yFrom) { before.push(`${MO} < @mf`); inp.mf = p.mFrom; }
  /* اگر هیچ مرز پایینی تنظیم نشده، «قبل از بازه» یعنی صفر — کل گردش داخل بازه است */
  if (!before.length) return { D: ob.D, C: ob.C };
  const typeJoin = `LEFT JOIN ACC.AccVoucherType t ON t.VoucherTypeId = h.VoucherTypeId`;
  const kc = kindCond(p.kind);
  const r2 = await one<any>(
    `SELECT ISNULL(SUM(i.Dbt),0) D, ISNULL(SUM(i.Crt),0) C
     FROM ACC.AccVoucher h ${typeJoin} JOIN ACC.AccVoucherItm i ON i.VoucherId = h.VoucherId
     WHERE ${[...conds.filter((c) => !["i.Dbt > 0", "i.Crt > 0"].includes(c)), ...(before.length ? ["(" + before.join(" OR ") + ")"] : []), ...(kc ? [kc] : [])].join(" AND ")}`,
    inp);
  return { D: ob.D + Number(r2?.D || 0), C: ob.C + Number(r2?.C || 0) };
}

async function cardMode(p: CardParams, sp: URLSearchParams) {
  if (p.level === "dl" && !p.dlId) return { ok: false, error: "تفصیلی انتخاب نشده" };
  if (p.level !== "dl" && !p.code) return { ok: false, error: "حساب انتخاب نشده" };
  const [head, openDone] = await Promise.all([cardHead(p), openingDone(p.companyId, p.yearId)]);
  if (!head) return { ok: false, error: "حساب یافت نشد" };

  const opening = await cardOpening(p, openDone);
  const nature = Number(head.AccNature || 3);
  const { conds, inp } = cardConds(p);
  const natSign = (d: number, c: number) => (nature === 2 ? c - d : d - c);

  if (p.display === "full") {
    const rows = await q(
      `SELECT h.VoucherId, h.FolioNo, h.VchNo, h.SubNo, h.VchDate, h.Descr VchDescr, h.BranchId, h.ReversalOf,
              t.Title TypeTitle, i.LineId, i.RowNo, i.KolCode, k.Title KolTitle,
              i.MoeinCode, m.Title MoeinTitle,
              d1.Code Taf1Code, d1.Title Taf1Title, d2.Code Taf2Code, d2.Title Taf2Title, d3.Code Taf3Code, d3.Title Taf3Title,
              i.Descr ItmDescr, i.Dbt, i.Crt, i.FxId, i.FxAmount, i.FxRate, f.Code FxCode, f.Title FxTitle
       FROM ACC.AccVoucher h
       LEFT JOIN ACC.AccVoucherType t ON t.VoucherTypeId = h.VoucherTypeId
       JOIN ACC.AccVoucherItm i ON i.VoucherId = h.VoucherId
       JOIN ACC.AccKol k ON k.CompanyId = h.CompanyId AND k.Code = i.KolCode
       JOIN ACC.AccMoein m ON m.CompanyId = h.CompanyId AND m.Code = i.MoeinCode
       LEFT JOIN ACC.AccTafsili d1 ON d1.TafsiliId = i.Taf1Id
       LEFT JOIN ACC.AccTafsili d2 ON d2.TafsiliId = i.Taf2Id
       LEFT JOIN ACC.AccTafsili d3 ON d3.TafsiliId = i.Taf3Id
       LEFT JOIN ACC.AccFx f ON f.FxId = i.FxId
       WHERE ${conds.join(" AND ")}
       ORDER BY h.VchDate, h.VchNo, h.SubNo, i.RowNo`, inp);
    let run = p.runBal ? natSign(opening.D, opening.C) : 0;
    const lines = (rows as any[]).map((r) => {
      run += natSign(Number(r.Dbt), Number(r.Crt));
      return { ...r, Balance: run };
    });
    const D = lines.reduce((s, r) => s + Number(r.Dbt), 0);
    const C = lines.reduce((s, r) => s + Number(r.Crt), 0);
    return { ok: true, head, opening, rows: lines, totals: { D, C }, display: "full" };
  }

  /* خلاصه — یک سطر برای هر سند [فرم: خلاصه با/بدون احتساب مانده ابتدای دوره] */
  const vr = await q(
    `SELECT h.VoucherId, h.VchNo, h.SubNo, h.VchDate, h.Descr VchDescr, h.ReversalOf,
            t.Title TypeTitle, SUM(i.Dbt) D, SUM(i.Crt) C
     FROM ACC.AccVoucher h
     LEFT JOIN ACC.AccVoucherType t ON t.VoucherTypeId = h.VoucherTypeId
     JOIN ACC.AccVoucherItm i ON i.VoucherId = h.VoucherId
     WHERE ${conds.join(" AND ")}
     GROUP BY h.VoucherId, h.VchNo, h.SubNo, h.VchDate, h.Descr, h.ReversalOf, t.Title
     ORDER BY h.VchDate, h.VchNo, h.SubNo`, inp);
  let run = p.display === "sumIn" ? natSign(opening.D, opening.C) : 0;
  const rows = (vr as any[]).map((r) => {
    run += natSign(Number(r.D), Number(r.C));
    return { ...r, Balance: run };
  });
  const D = rows.reduce((s, r) => s + Number(r.D), 0);
  const C = rows.reduce((s, r) => s + Number(r.C), 0);
  return { ok: true, head, opening, rows, totals: { D, C }, display: p.display };
}

/* ============================ تراز حساب [TAccViewLGBalance] ============================ */
async function balanceMode(companyId: number, yearId: number, sp: URLSearchParams) {
  const level = (["kol", "moein", "dl"].includes(sp.get("level") || "") ? sp.get("level") : "moein") as Level;
  const code = (sp.get("code") || "").trim();
  const dlLevel = num(sp, "dlLevel") || 1;
  const dlId = num(sp, "dlId");
  const from = (sp.get("from") || "").trim();
  const to = (sp.get("to") || "").trim();
  const vchType = num(sp, "vchType");
  const branch = num(sp, "branch");
  const kind = sp.get("kind") || "";

  const acc = accountCond(level, dlLevel);
  const inp: Record<string, unknown> = { c: companyId, y: yearId, acc: level === "dl" ? dlId : code };
  const base = ["h.CompanyId=@c", "h.YearId=@y", "h.State=3", acc.sql];
  if (vchType) { base.push("h.VoucherTypeId = @vt"); inp.vt = vchType; }
  if (branch) { base.push("h.BranchId = @br"); inp.br = branch; }
  const kc = kindCond(kind);
  if (kc) base.push(kc);
  const typeJoin = `LEFT JOIN ACC.AccVoucherType t ON t.VoucherTypeId = h.VoucherTypeId`;
  const sum = async (extra: string[]) => {
    const r = await one<any>(
      `SELECT ISNULL(SUM(i.Dbt),0) D, ISNULL(SUM(i.Crt),0) C
       FROM ACC.AccVoucher h ${typeJoin} JOIN ACC.AccVoucherItm i ON i.VoucherId = h.VoucherId
       WHERE ${[...base, ...extra].join(" AND ")}`, inp);
    return { D: Number(r?.D || 0), C: Number(r?.C || 0) };
  };
  const [opDone, head] = await Promise.all([openingDone(companyId, yearId), cardHead({ companyId, yearId, level, code, dlLevel, dlId, from: "", to: "", yFrom: 0, yTo: 0, mFrom: 0, mTo: 0, noFrom: 0, noTo: 0, vchType: 0, kind: "", dir: "dc", branch: 0, display: "full", runBal: false })]);
  if (!head) return { ok: false, error: "حساب یافت نشد" };

  let till = { D: 0, C: 0 };
  if (from) { inp.from = from; till = await sum(["h.VchDate < @from"]); }
  const during = await sum([
    ...(from ? ["h.VchDate >= @from"] : []),
    ...(to ? ["h.VchDate <= @to"] : []),
  ]);
  let after = { D: 0, C: 0 };
  if (to) { inp.to = to; after = await sum(["h.VchDate > @to"]); }
  let ob = { D: 0, C: 0 };
  if (!opDone) {
    const obCols = level === "kol" ? "ob.KolCode" : level === "moein" ? "ob.MoeinCode" : dlLevel === 2 ? "ob.Taf2Id" : dlLevel === 3 ? "ob.Taf3Id" : "ob.Taf1Id";
    const r = await one<any>(
      `SELECT ISNULL(SUM(Dbt),0) D, ISNULL(SUM(Crt),0) C FROM ACC.AccOpeningBalance ob WHERE CompanyId=@c AND YearId=@y AND ${obCols}=@acc`, inp);
    ob = { D: Number(r?.D || 0), C: Number(r?.C || 0) };
  }
  const total = { D: ob.D + till.D + during.D + after.D, C: ob.C + till.C + during.C + after.C };
  const net = total.D - total.C;
  const balD = Math.max(net, 0);
  const balC = net < 0 ? -net : 0;
  return { ok: true, head, opening: ob, till, during, after, total, balD, balC };
}

/* ============================ آناليز حسابها [TAccAnalysForm] ============================ */
async function analysMode(companyId: number, yearId: number, sp: URLSearchParams) {
  const level = (sp.get("level") || "moein") as "kol" | "moein";
  const code = (sp.get("code") || "").trim();
  const grp = num(sp, "group") || 1;
  const analysed = sp.get("analysed") || "all";
  const from = (sp.get("from") || "").trim();
  const to = (sp.get("to") || "").trim();
  if (!code) return { ok: false, error: "حساب انتخاب نشده" };
  const col = grp === 2 ? "Taf2Id" : grp === 3 ? "Taf3Id" : "Taf1Id";
  const conds = ["h.CompanyId=@c", "h.YearId=@y", "h.State=3",
    level === "kol" ? "i.KolCode = @acc" : "i.MoeinCode = @acc"];
  const inp: Record<string, unknown> = { c: companyId, y: yearId, acc: code };
  if (from) { conds.push("h.VchDate >= @from"); inp.from = from; }
  if (to) { conds.push("h.VchDate <= @to"); inp.to = to; }
  if (analysed === "yes") conds.push(`i.${col} IS NOT NULL`);
  if (analysed === "no") conds.push(`i.${col} IS NULL`);
  const rows = await q(
    `SELECT i.MoeinCode, m.Title MoeinTitle, d.Code TafCode, d.Title TafTitle,
            SUM(i.Dbt) D, SUM(i.Crt) C
     FROM ACC.AccVoucher h JOIN ACC.AccVoucherItm i ON i.VoucherId = h.VoucherId
     JOIN ACC.AccMoein m ON m.CompanyId = h.CompanyId AND m.Code = i.MoeinCode
     LEFT JOIN ACC.AccTafsili d ON d.TafsiliId = i.${col}
     WHERE ${conds.join(" AND ")}
     GROUP BY i.MoeinCode, m.Title, d.Code, d.Title
     ORDER BY i.MoeinCode, d.Code`, inp);
  return { ok: true, rows, group: grp, analysed };
}

/* ============================ گردش ارز [TAccCurFlow] / مانده ارزی ============================ */
async function fxMode(companyId: number, yearId: number, sp: URLSearchParams, bal: boolean) {
  const moein = (sp.get("code") || "").trim();
  if (!moein) return { ok: false, error: "حساب معین انتخاب نشده" };
  const from = (sp.get("from") || "").trim();
  const to = (sp.get("to") || "").trim();
  const conds = ["h.CompanyId=@c", "h.YearId=@y", "h.State=3", "i.MoeinCode = @acc", "i.FxId IS NOT NULL"];
  const inp: Record<string, unknown> = { c: companyId, y: yearId, acc: moein };
  if (from) { conds.push("h.VchDate >= @from"); inp.from = from; }
  if (to) { conds.push("h.VchDate <= @to"); inp.to = to; }
  if (bal) {
    const rows = await q(
      `SELECT f.Code FxCode, f.Title FxTitle,
              SUM(CASE WHEN i.Dbt > 0 THEN i.FxAmount ELSE 0 END) FxD,
              SUM(CASE WHEN i.Crt > 0 THEN i.FxAmount ELSE 0 END) FxC,
              SUM(i.Dbt) D, SUM(i.Crt) C
       FROM ACC.AccVoucher h JOIN ACC.AccVoucherItm i ON i.VoucherId = h.VoucherId
       JOIN ACC.AccFx f ON f.FxId = i.FxId
       WHERE ${conds.join(" AND ")}
       GROUP BY f.Code, f.Title ORDER BY f.Code`, inp);
    return { ok: true, rows };
  }
  const rows = await q(
    `SELECT h.VoucherId, h.VchNo, h.SubNo, h.VchDate, h.Descr VchDescr,
            f.FxId, f.Code FxCode, f.Title FxTitle, i.FxRate,
            SUM(CASE WHEN i.Dbt > 0 THEN i.FxAmount ELSE 0 END) FxD,
            SUM(CASE WHEN i.Crt > 0 THEN i.FxAmount ELSE 0 END) FxC,
            SUM(i.Dbt) D, SUM(i.Crt) C
     FROM ACC.AccVoucher h JOIN ACC.AccVoucherItm i ON i.VoucherId = h.VoucherId
     JOIN ACC.AccFx f ON f.FxId = i.FxId
     WHERE ${conds.join(" AND ")}
     GROUP BY h.VoucherId, h.VchNo, h.SubNo, h.VchDate, h.Descr, f.FxId, f.Code, f.Title, i.FxRate
     ORDER BY h.VchDate, h.VchNo, f.Code`, inp);
  /* مانده در خط به تفکیک ارز */
  const run = new Map<string, number>();
  const lines = (rows as any[]).map((r) => {
    const k = String(r.FxCode);
    const b = (run.get(k) || 0) + Number(r.FxD) - Number(r.FxC);
    run.set(k, b);
    return { ...r, FxBalance: b };
  });
  return { ok: true, rows: lines };
}

/* ============================ مسیر اصلی ============================ */
export async function GET(req: NextRequest) {
  const s = await getSession();
  if (!s) return NextResponse.json({ ok: false, error: "دسترسی رد شد" }, { status: 401 });
  const { companyId, yearId } = ctxOf(req);
  if (!companyId || !yearId)
    return NextResponse.json({ ok: false, error: "شرکت و سال مالی انتخاب نشده", code: "NO_CTX" }, { status: 400 });

  const sp = new URL(req.url).searchParams;
  const mode = sp.get("mode") || "tree";
  try {
    switch (mode) {
      case "tree":
        return NextResponse.json(await treeMode(companyId, yearId, sp));
      case "card": {
        const p: CardParams = {
          companyId, yearId,
          level: (["kol", "moein", "dl"].includes(sp.get("level") || "") ? sp.get("level") : "moein") as Level,
          code: (sp.get("code") || "").trim(),
          dlLevel: num(sp, "dlLevel") || 1,
          dlId: num(sp, "dlId"),
          from: (sp.get("from") || "").trim(), to: (sp.get("to") || "").trim(),
          yFrom: num(sp, "yFrom"), yTo: num(sp, "yTo"), mFrom: num(sp, "mFrom"), mTo: num(sp, "mTo"),
          noFrom: num(sp, "noFrom"), noTo: num(sp, "noTo"),
          vchType: num(sp, "vchType"), kind: sp.get("kind") || "", dir: sp.get("dir") || "dc",
          branch: num(sp, "branch"),
          display: ["full", "sumIn", "sumNo"].includes(sp.get("display") || "") ? sp.get("display")! : "full",
          runBal: sp.get("runBal") !== "0",
        };
        const r = await cardMode(p, sp);
        return NextResponse.json(r, { status: r.ok === false ? 400 : 200 });
      }
      case "balance":
        return NextResponse.json(await balanceMode(companyId, yearId, sp));
      case "analys":
        return NextResponse.json(await analysMode(companyId, yearId, sp));
      case "fx":
        return NextResponse.json(await fxMode(companyId, yearId, sp, false));
      case "fxbal":
        return NextResponse.json(await fxMode(companyId, yearId, sp, true));
      default:
        return NextResponse.json({ ok: false, error: "mode نامعتبر" }, { status: 400 });
    }
  } catch (e: any) {
    return NextResponse.json({ ok: false, error: e?.message || "خطای دیتابیس" }, { status: 500 });
  }
}
