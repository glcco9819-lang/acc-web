import { q, one } from "@/lib/db";

/* ===== لایهٔ مشترک گزارش‌های تراز [فرم‌های: گزارش تراز / تراز ماهانه / تراز اسناد شش‌سطحی — AcRepDef]
   هیچ تغییری در دیتابیس نمی‌دهد؛ فقط تجمیع از AccVoucherItm (اسناد قطعی) + AccOpeningBalance ===== */

export type Level = "kol" | "moein" | "taf1" | "taf2" | "taf3";

export const LEVEL_FA: Record<Level, string> = {
  kol: "حساب کل", moein: "حساب معین", taf1: "تفصیلی (سطح چهارم)",
  taf2: "تفصیلی (سطح پنجم)", taf3: "تفصیلی (سطح ششم)",
};

export interface TarazFilters {
  level: Level;
  from: string; to: string;          /* بازهٔ تاریخ جلالی YYYY/MM/DD */
  fromVch: number; toVch: number;    /* بازهٔ شماره سند */
  vchType: number;                   /* نوع سند */
  kol: string; moein: string;        /* فیلتر حساب */
  withOpening: boolean;              /* با در نظر گرفتن ماندهٔ ابتدای دوره */
  onlyBal: boolean;                  /* فقط حساب‌های با مانده/گردش */
}

export function parseFilters(sp: URLSearchParams): TarazFilters {
  const lv = (sp.get("level") || "kol") as Level;
  const num = (k: string) => { const v = Number(sp.get(k) || 0); return Number.isFinite(v) ? v : 0; };
  return {
    level: ["kol", "moein", "taf1", "taf2", "taf3"].includes(lv) ? lv : "kol",
    from: (sp.get("from") || "").trim(),
    to: (sp.get("to") || "").trim(),
    fromVch: num("fromVch"), toVch: num("toVch"), vchType: num("vchType"),
    kol: (sp.get("kol") || "").trim(), moein: (sp.get("moein") || "").trim(),
    withOpening: sp.get("withOpening") !== "0",
    onlyBal: sp.get("onlyBal") === "1",
  };
}

/* ردیف سطح خطِ سند — تجمیع در JS برای انعطاف سه گزارش */
interface MoveRow { KolCode: string; MoeinCode: string; Taf1Id: number | null; Taf2Id: number | null; Taf3Id: number | null; VchDate: string; Dbt: number; Crt: number; }

async function fetchMoves(c: number, y: number, f: TarazFilters, upToOnly = false): Promise<MoveRow[]> {
  const conds = ["h.CompanyId=@c", "h.YearId=@y", "h.State=3"];
  const inp: Record<string, unknown> = { c, y };
  if (f.to) { conds.push("h.VchDate <= @to"); inp.to = f.to; }
  if (!upToOnly && f.from) { conds.push("h.VchDate >= @from"); inp.from = f.from; }
  if (f.fromVch) { conds.push("h.VchNo >= @fv"); inp.fv = f.fromVch; }
  if (f.toVch) { conds.push("h.VchNo <= @tv"); inp.tv = f.toVch; }
  if (f.vchType) { conds.push("h.VoucherTypeId = @vt"); inp.vt = f.vchType; }
  if (f.kol) { conds.push("i.KolCode = @kol"); inp.kol = f.kol; }
  if (f.moein) { conds.push("i.MoeinCode = @moein"); inp.moein = f.moein; }
  const rows = await q(
    `SELECT i.KolCode, i.MoeinCode, i.Taf1Id, i.Taf2Id, i.Taf3Id, h.VchDate, i.Dbt, i.Crt
     FROM ACC.AccVoucher h JOIN ACC.AccVoucherItm i ON i.VoucherId = h.VoucherId
     WHERE ${conds.join(" AND ")}`, inp);
  return rows.map((r: any) => ({
    KolCode: String(r.KolCode), MoeinCode: String(r.MoeinCode),
    Taf1Id: r.Taf1Id == null ? null : Number(r.Taf1Id),
    Taf2Id: r.Taf2Id == null ? null : Number(r.Taf2Id),
    Taf3Id: r.Taf3Id == null ? null : Number(r.Taf3Id),
    VchDate: String(r.VchDate || ""), Dbt: Number(r.Dbt || 0), Crt: Number(r.Crt || 0),
  }));
}

/* کلید سطح برای تجمیع */
function keyOf(r: { KolCode: string; MoeinCode: string; Taf1Id: number | null; Taf2Id: number | null; Taf3Id: number | null }, level: Level): string {
  switch (level) {
    case "kol": return r.KolCode;
    case "moein": return `${r.KolCode}|${r.MoeinCode}`;
    case "taf1": return `${r.KolCode}|${r.MoeinCode}|${r.Taf1Id ?? 0}`;
    case "taf2": return `${r.KolCode}|${r.MoeinCode}|${r.Taf1Id ?? 0}|${r.Taf2Id ?? 0}`;
    default: return `${r.KolCode}|${r.MoeinCode}|${r.Taf1Id ?? 0}|${r.Taf2Id ?? 0}|${r.Taf3Id ?? 0}`;
  }
}

export interface TarazRow {
  Key: string; KolCode: string; MoeinCode: string;
  Taf1Id: number | null; Taf2Id: number | null; Taf3Id: number | null;
  Title: string; Nature: number;
  /* سه سطل: افتتاحیه (ماندهٔ ابتدای دوره) / قبل از بازه / طی بازه — هر گزارش از ترکیبش ستون می‌سازد */
  OpDbt: number; OpCrt: number;
  PreDbt: number; PreCrt: number;
  Dbt: number; Crt: number;
}

/* عناوین حساب‌ها — یک پرس‌وجو برای هر سه جدول */
async function fetchTitles(c: number) {
  const [kols, moeins, tafs] = await Promise.all([
    q(`SELECT Code, Title, AccNature FROM ACC.AccKol WHERE CompanyId=@c`, { c }),
    q(`SELECT Code, Title, KolCode FROM ACC.AccMoein WHERE CompanyId=@c`, { c }),
    q(`SELECT TafsiliId, Title, Code FROM ACC.AccTafsili WHERE CompanyId=@c`, { c }),
  ]);
  return {
    kol: new Map((kols as any[]).map((k) => [String(k.Code), { title: String(k.Title), nature: Number(k.AccNature || 3) }])),
    moein: new Map((moeins as any[]).map((m) => [String(m.Code), String(m.Title)])),
    taf: new Map((tafs as any[]).map((t) => [Number(t.TafsiliId), String(t.Title)])),
  };
}

function titleFor(keys: string[], level: Level, T: Awaited<ReturnType<typeof fetchTitles>>): { title: string; nature: number } {
  const [kol, moein, t1, t2, t3] = keys;
  const k = T.kol.get(kol);
  const nature = k?.nature ?? 3;
  const kolT = k ? `${kol} ${k.title}` : kol;
  switch (level) {
    case "kol": return { title: kolT, nature };
    case "moein": {
      const m = T.moein.get(moein);
      return { title: `${kolT} › ${moein} ${m ?? ""}`.trim(), nature };
    }
    default: {
      const m = T.moein.get(moein);
      const base = `${kolT} › ${moein} ${m ?? ""}`.trim();
      const parts: string[] = [];
      const push = (id: string, map: Map<number, string>) => { const n = Number(id); if (n) parts.push(map.get(n) || `تفصیلی ${n}`); };
      push(t1, T.taf); if (level === "taf2" || level === "taf3") push(t2, T.taf); if (level === "taf3") push(t3, T.taf);
      return { title: `${base} › ${parts.join(" › ")}`.trim(), nature };
    }
  }
}

/* تجمیع حرکات + ماندهٔ ابتدای دوره در سطح انتخابی — سه سطل Op/Pre/In
   توجه: حرکات بدون شرط «از تاریخ» واکشی می‌شوند و در JS تفکیک می‌شوند تا سطل Pre پر شود */
export async function buildTaraz(c: number, y: number, f: TarazFilters): Promise<TarazRow[]> {
  const [moves, T, opDone] = await Promise.all([
    fetchMoves(c, y, f, true),
    fetchTitles(c),
    one(`SELECT COUNT(*) N FROM ACC.AccVoucher h JOIN ACC.AccVoucherType t ON t.VoucherTypeId = h.VoucherTypeId
         WHERE h.CompanyId=@c AND h.YearId=@y AND h.State=3 AND t.LatinTitle='Opening'`, { c, y }),
  ]);

  /* ماندهٔ ابتدای دوره: اگر سند افتتاحیهٔ قطعی موجود باشد، جدول OpeningBalance دوبار شمرده نمی‌شود */
  const useOp = f.withOpening && !Number(opDone?.N || 0);
  const opRows = useOp
    ? await q(`SELECT KolCode, MoeinCode, Taf1Id, Taf2Id, Taf3Id, Dbt, Crt
               FROM ACC.AccOpeningBalance WHERE CompanyId=@c AND YearId=@y
               ${f.kol ? "AND KolCode=@kol" : ""} ${f.moein ? "AND MoeinCode=@moein" : ""}`,
              { c, y, ...(f.kol ? { kol: f.kol } : {}), ...(f.moein ? { moein: f.moein } : {}) })
    : [];

  const map = new Map<string, TarazRow>();
  const ensure = (key: string, src: any): TarazRow => {
    let r = map.get(key);
    if (!r) {
      r = { Key: key, KolCode: src.KolCode, MoeinCode: src.MoeinCode, Taf1Id: src.Taf1Id ?? null, Taf2Id: src.Taf2Id ?? null, Taf3Id: src.Taf3Id ?? null,
            Title: "", Nature: 3, OpDbt: 0, OpCrt: 0, PreDbt: 0, PreCrt: 0, Dbt: 0, Crt: 0 };
      map.set(key, r);
    }
    return r;
  };

  /* ماندهٔ ابتدای دوره → سطل Op */
  for (const o of opRows as any[]) {
    const src = { KolCode: String(o.KolCode), MoeinCode: String(o.MoeinCode), Taf1Id: o.Taf1Id, Taf2Id: o.Taf2Id, Taf3Id: o.Taf3Id };
    const r = ensure(keyOf(src, f.level), src);
    r.OpDbt += Number(o.Dbt || 0); r.OpCrt += Number(o.Crt || 0);
  }
  /* حرکات: قبل از بازه → Pre؛ داخل بازه → In (تا تاریخ همیشه اعمال شده؛ از تاریخ فقط برای In) */
  const from = f.from; /* 'YYYY/MM/DD' مقایسهٔ رشته‌ای درست است */
  for (const m of moves) {
    const r = ensure(keyOf(m, f.level), m);
    if (from && m.VchDate && m.VchDate < from) { r.PreDbt += m.Dbt; r.PreCrt += m.Crt; }
    else { r.Dbt += m.Dbt; r.Crt += m.Crt; }
  }

  const rows = [...map.values()];
  for (const r of rows) {
    const [kol, moein, t1, t2, t3] = r.Key.split("|");
    const t = titleFor([kol, moein, t1, t2, t3], f.level, T);
    r.Title = t.title; r.Nature = t.nature;
  }
  rows.sort((a, b) => a.Key.localeCompare(b.Key, "en"));
  return f.onlyBal ? rows.filter((r) => (r.OpDbt + r.OpCrt + r.PreDbt + r.PreCrt + r.Dbt + r.Crt) !== 0) : rows;
}

/* ===== تراز ماهانه [فرم: گزارش تحلیلی تراز ماهانه — AcRepDef]
   ستون اول = ماندهٔ ابتدای دوره (افتتاحیه)، ستون‌های ماهانه = گردش بد/بس هر ماه، پایان = ماندهٔ پایان */
export interface MonthlyRow {
  Key: string; Title: string; Nature: number;
  OpDbt: number; OpCrt: number;                       /* ماندهٔ ابتدای دوره */
  Months: Record<string, { Dbt: number; Crt: number }>; /* کلید ماه ۰۱..۱۲ */
  EndDbt: number; EndCrt: number;                     /* ماندهٔ پایان */
}

export async function buildTarazMonthly(c: number, y: number, f: TarazFilters): Promise<MonthlyRow[]> {
  const [moves, T, opDone] = await Promise.all([
    fetchMoves(c, y, { ...f, from: "", to: "" }, true),
    fetchTitles(c),
    one(`SELECT COUNT(*) N FROM ACC.AccVoucher h JOIN ACC.AccVoucherType t ON t.VoucherTypeId = h.VoucherTypeId
         WHERE h.CompanyId=@c AND h.YearId=@y AND h.State=3 AND t.LatinTitle='Opening'`, { c, y }),
  ]);

  const useOp = f.withOpening && !Number(opDone?.N || 0);
  const opRows = useOp
    ? await q(`SELECT KolCode, MoeinCode, Taf1Id, Taf2Id, Taf3Id, Dbt, Crt
               FROM ACC.AccOpeningBalance WHERE CompanyId=@c AND YearId=@y
               ${f.kol ? "AND KolCode=@kol" : ""} ${f.moein ? "AND MoeinCode=@moein" : ""}`,
              { c, y, ...(f.kol ? { kol: f.kol } : {}), ...(f.moein ? { moein: f.moein } : {}) })
    : [];

  type Acc = { src: any; OpDbt: number; OpCrt: number; Months: Record<string, { Dbt: number; Crt: number }> };
  const map = new Map<string, Acc>();
  const ensure = (key: string, src: any): Acc => {
    let r = map.get(key);
    if (!r) { r = { src, OpDbt: 0, OpCrt: 0, Months: {} }; map.set(key, r); }
    return r;
  };

  for (const o of opRows as any[]) {
    const src = { KolCode: String(o.KolCode), MoeinCode: String(o.MoeinCode), Taf1Id: o.Taf1Id, Taf2Id: o.Taf2Id, Taf3Id: o.Taf3Id };
    const r = ensure(keyOf(src, f.level), src);
    r.OpDbt += Number(o.Dbt || 0); r.OpCrt += Number(o.Crt || 0);
  }
  for (const m of moves) {
    const r = ensure(keyOf(m, f.level), m);
    const mo = (m.VchDate || "").length >= 7 ? m.VchDate.slice(5, 7) : "";
    if (!mo) continue;
    const b = r.Months[mo] || (r.Months[mo] = { Dbt: 0, Crt: 0 });
    b.Dbt += m.Dbt; b.Crt += m.Crt;
  }

  const rows: MonthlyRow[] = [];
  for (const [key, v] of map) {
    const [kol, moein, t1, t2, t3] = key.split("|");
    const t = titleFor([kol, moein, t1, t2, t3], f.level, T);
    let EndDbt = v.OpDbt, EndCrt = v.OpCrt;
    for (const b of Object.values(v.Months)) { EndDbt += b.Dbt; EndCrt += b.Crt; }
    rows.push({ Key: key, Title: t.title, Nature: t.nature, OpDbt: v.OpDbt, OpCrt: v.OpCrt, Months: v.Months, EndDbt, EndCrt });
  }
  rows.sort((a, b) => a.Key.localeCompare(b.Key, "en"));
  return f.onlyBal
    ? rows.filter((r) => r.OpDbt + r.OpCrt + r.EndDbt + r.EndCrt !== 0 || Object.values(r.Months).some((b) => b.Dbt + b.Crt !== 0))
    : rows;
}
