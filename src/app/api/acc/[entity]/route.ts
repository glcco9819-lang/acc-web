import { NextRequest, NextResponse } from "next/server";
import { q, one, scalar } from "@/lib/db";
import { getSession, can } from "@/lib/auth";
import { ctxOf } from "@/lib/ctx";

/* پنجره‌های تعاریف حساب‌ها (مطابق acCDef) — یک مسیر عمومی برای هفت تعریف + شجره */

const NUM = /^\d+$/;

interface EntSpec {
  table: string;
  key: string;                /* کلید اصلی — در GET به صورت id به کلاینت برمی‌گردد */
  cols: { name: string; req?: boolean; num?: boolean; len?: number; max?: number; code?: number }[];
  delCheck?: { sql: string; inp: string[]; msg: string }[];
}

function spec(entity: string, mode: number): EntSpec | null {
  switch (entity) {
    case "groups": return {
      table: "ACC.AccGroup", key: "GroupId",
      cols: [
        { name: "Code", req: true, code: 2 },
        { name: "Title", req: true, max: 200 },
        { name: "AccNature", req: true, num: true },
      ],
      delCheck: [{ sql: "SELECT 1 x FROM ACC.AccKol WHERE CompanyId=@c AND GroupCode=@code", inp: ["code"], msg: "گروه دارای حساب کل است — ابتدا کل‌ها را حذف کنید" }],
    };
    case "kol": return {
      table: "ACC.AccKol", key: "KolId",
      cols: [
        { name: "Code", req: true, code: 4 },
        { name: "GroupCode", code: mode === 2 ? 2 : 0, req: mode === 2 },
        { name: "Title", req: true, max: 200 },
        { name: "AccNature", req: true, num: true },
      ],
      delCheck: [{ sql: "SELECT 1 x FROM ACC.AccMoein WHERE CompanyId=@c AND KolCode=@code", inp: ["code"], msg: "کل دارای معین است" }],
    };
    case "moein": return {
      table: "ACC.AccMoein", key: "MoeinId",
      cols: [
        { name: "Code", req: true, code: 6 },
        { name: "KolCode", req: true, code: mode === 2 ? 4 : 2 },
        { name: "Title", req: true, max: 200 },
        { name: "AccNature", req: true, num: true },
        { name: "Taf1TypeId", num: true }, { name: "Taf2TypeId", num: true }, { name: "Taf3TypeId", num: true },
        { name: "Trackable", num: true }, { name: "Countable", num: true },
        { name: "IsFx", num: true }, { name: "FxConvertible", num: true },
        { name: "IsActive", num: true },
      ],
      delCheck: [
        { sql: "SELECT 1 x FROM ACC.AccVoucherItm i JOIN ACC.AccVoucher h ON h.VoucherId=i.VoucherId WHERE h.CompanyId=@c AND i.MoeinCode=@code", inp: ["code"], msg: "معین در سند استفاده شده است" },
        { sql: "SELECT 1 x FROM ACC.AccOpeningBalance WHERE CompanyId=@c AND MoeinCode=@code", inp: ["code"], msg: "معین دارای ماندهٔ ابتدای دوره است" },
        { sql: "SELECT 1 x FROM ACC.AccStdNarration WHERE CompanyId=@c AND MoeinCode=@code", inp: ["code"], msg: "معین دارای شرح استاندارد است" },
      ],
    };
    case "tafsili": return {
      table: "ACC.AccTafsili", key: "TafsiliId",
      cols: [
        { name: "Code", req: true, code: 8 },
        { name: "TafsiliTypeId", req: true, num: true },
        { name: "Title", req: true, max: 200 },
        { name: "LatinTitle", max: 200 },
        { name: "IsActive", num: true },
      ],
      delCheck: [
        { sql: "SELECT 1 x FROM ACC.AccVoucherItm i JOIN ACC.AccVoucher h ON h.VoucherId=i.VoucherId WHERE h.CompanyId=@c AND (i.Taf1Id=@code OR i.Taf2Id=@code OR i.Taf3Id=@code)", inp: ["code", "int"], msg: "تفصیلی در سند استفاده شده است" },
        { sql: "SELECT 1 x FROM ACC.AccTafsiliCategoryLink WHERE TafsiliId=@code", inp: ["code", "int"], msg: "تفصیلی در طبقه‌بندی استفاده شده است" },
      ],
    };
    case "tafsili-types": return {
      table: "ACC.AccTafsiliType", key: "TafsiliTypeId",
      cols: [{ name: "Title", req: true, max: 100 }, { name: "LatinTitle", max: 100 }],
      delCheck: [
        { sql: "SELECT 1 x FROM ACC.AccMoein WHERE CompanyId=@c AND (Taf1TypeId=@code OR Taf2TypeId=@code OR Taf3TypeId=@code)", inp: ["code", "int"], msg: "نوع تفصیل به معین متصل است" },
        { sql: "SELECT 1 x FROM ACC.AccTafsili WHERE CompanyId=@c AND TafsiliTypeId=@code", inp: ["code", "int"], msg: "تفصیلی‌هایی از این نوع وجود دارد" },
      ],
    };
    case "tafsili-ctgries": return {
      table: "ACC.AccTafsiliCategory", key: "CategoryId",
      cols: [{ name: "Title", req: true, max: 100 }],
      delCheck: [{ sql: "SELECT 1 x FROM ACC.AccTafsiliCategoryLink WHERE CategoryId=@code", inp: ["code", "int"], msg: "طبقه دارای تفصیلی است" }],
    };
    case "std-narration": return {
      table: "ACC.AccStdNarration", key: "NarrationId",
      cols: [{ name: "MoeinCode", req: true, code: 6 }, { name: "Seq", req: true, num: true }, { name: "DescText", req: true, max: 300 }],
    };
    case "vchtypes": return {
      table: "ACC.AccVoucherType", key: "VoucherTypeId",
      cols: [{ name: "Title", req: true, max: 100 }, { name: "LatinTitle", max: 100 }],
      delCheck: [{ sql: "SELECT 1 x FROM ACC.AccVoucher WHERE CompanyId=@c AND VoucherTypeId=@code", inp: ["code"], msg: "سندهایی از این نوع ثبت شده است" }],
    };
    /* تعریف ارزها [فرم: اطلاعات ارزها — accCurrency] */
    case "fx": return {
      table: "ACC.AccFx", key: "FxId",
      cols: [
        { name: "Code", req: true, max: 10 }, { name: "Title", req: true, max: 100 },
        { name: "LatinTitle", max: 100 }, { name: "IsBase", num: true }, { name: "IsActive", num: true },
      ],
      delCheck: [{ sql: "SELECT 1 x FROM ACC.AccVoucherItm i JOIN ACC.AccVoucher h ON h.VoucherId=i.VoucherId WHERE h.CompanyId=@c AND i.FxId=@code", inp: ["code", "int"], msg: "ارز در اقلام سند استفاده شده است" }],
    };
    /* تعریف شعبه [فرم: تعریف شعبه — acVchDef] */
    case "branch": return {
      table: "ACC.AccBranch", key: "BranchId",
      cols: [
        { name: "Code", req: true, max: 10 }, { name: "Title", req: true, max: 150 },
        { name: "IsActive", num: true },
      ],
      delCheck: [{ sql: "SELECT 1 x FROM ACC.AccVoucher WHERE CompanyId=@c AND BranchId=@code", inp: ["code", "int"], msg: "شعبه در اسناد استفاده شده است" }],
    };
    default: return null;
  }
}

function ctxFromBody(body: unknown) {
  const b = (body && typeof body === "object" ? body : {}) as Record<string, unknown>;
  return { companyId: Number(b.companyId || 0), yearId: Number(b.yearId || 0) };
}

export async function GET(req: NextRequest, { params }: { params: Promise<{ entity: string }> }) {
  const s = await getSession();
  if (!s) return NextResponse.json({ ok: false, error: "دسترسی رد شد" }, { status: 401 });
  const { entity } = await params;
  const { companyId } = ctxOf(req);
  if (!companyId) return NextResponse.json({ ok: false, error: "ابتدا از نوار بالا شرکت را انتخاب کنید", code: "NO_CTX" }, { status: 400 });

  if (entity === "chart") {
    const rows = await q(
      `SELECT g.Code GroupCode, g.Title GroupTitle, g.AccNature,
              k.Code KolCode, k.Title KolTitle,
              m.Code MoeinCode, m.Title MoeinTitle, m.IsActive MoeinActive,
              m.Taf1TypeId, m.Taf2TypeId, m.Taf3TypeId,
              t1.Title Taf1Title, t2.Title Taf2Title, t3.Title Taf3Title
       FROM ACC.AccGroup g
       LEFT JOIN ACC.AccKol k ON k.CompanyId=g.CompanyId AND k.GroupCode=g.Code
       LEFT JOIN ACC.AccMoein m ON m.CompanyId=k.CompanyId AND m.KolCode=k.Code
       LEFT JOIN ACC.AccTafsiliType t1 ON t1.TafsiliTypeId=m.Taf1TypeId
       LEFT JOIN ACC.AccTafsiliType t2 ON t2.TafsiliTypeId=m.Taf2TypeId
       LEFT JOIN ACC.AccTafsiliType t3 ON t3.TafsiliTypeId=m.Taf3TypeId
       WHERE g.CompanyId=@c
       ORDER BY g.Code, k.Code, m.Code`, { c: companyId });
    return NextResponse.json({ ok: true, rows });
  }

  const mode = Number(await scalar("SELECT CodingMode FROM pob.Companies WHERE CompanyId=@c", { c: companyId }) || 2);
  const sp = spec(entity, mode);
  if (!sp) return NextResponse.json({ ok: false, error: "تعریف ناشناخته" }, { status: 404 });
  /* شناسهٔ یکنواخت id برای کلاینت (CrudWindow) + کل سطر */
  const rows = await q(`SELECT *, CAST(${sp.key} AS int) AS id FROM ${sp.table} WHERE CompanyId=@c ORDER BY 1`, { c: companyId });
  return NextResponse.json({ ok: true, rows, mode });
}

export async function POST(req: NextRequest, { params }: { params: Promise<{ entity: string }> }) {
  const s = await getSession();
  if (!s || !can(s, "master")) return NextResponse.json({ ok: false, error: "مجوز تعریف ندارید" }, { status: 403 });
  const { entity } = await params;
  const body = await req.json().catch(() => ({}));
  const { companyId } = { ...ctxOf(req), ...ctxFromBody(body) };
  if (!companyId) return NextResponse.json({ ok: false, error: "شرکت انتخاب نشده" }, { status: 400 });
  const mode = Number(await scalar("SELECT CodingMode FROM pob.Companies WHERE CompanyId=@c", { c: companyId }) || 2);
  const sp = spec(entity, mode);
  if (!sp) return NextResponse.json({ ok: false, error: "تعریف ناشناخته" }, { status: 404 });

  const vals: Record<string, unknown> = {};
  for (const col of sp.cols) {
    let v = body[col.name];
    if (v === "" || v === undefined || v === null) {
      if (col.req) return NextResponse.json({ ok: false, error: `${col.name} الزامی است` }, { status: 400 });
      vals[col.name] = null; continue;
    }
    v = String(v).trim();
    if (col.code) {
      if (!NUM.test(v) || v.length !== col.code)
        return NextResponse.json({ ok: false, error: `کد باید ${col.code} رقم باشد` }, { status: 400 });
    }
    if (col.num) { const n = Number(v); if (Number.isNaN(n)) return NextResponse.json({ ok: false, error: `${col.name} عددی نیست` }, { status: 400 }); vals[col.name] = n; }
    else vals[col.name] = col.max ? v.slice(0, col.max) : v;
  }

  /* قواعد ویژهٔ معین: سطوح تفصیلی متمایز + تعلق نوع‌ها به شرکت */
  if (entity === "moein") {
    const ts = [vals.Taf1TypeId, vals.Taf2TypeId, vals.Taf3TypeId].filter(Boolean);
    if (new Set(ts).size !== ts.length)
      return NextResponse.json({ ok: false, error: "سطوح تفصیلی باید متمایز باشند" }, { status: 400 });
  }
  if (entity === "kol" && mode === 1) vals.GroupCode = null;

  /* ارز پایه — تنها یک ارز پایه برای هر شرکت (بله/خیر) */
  if (entity === "fx" && vals.IsBase === 1)
    await q("UPDATE ACC.AccFx SET IsBase=0 WHERE CompanyId=@c", { c: companyId });

  const cols = Object.keys(vals);
  const names = cols.map((c) => `@${c}`);
  const inp: Record<string, unknown> = { ...vals, c: companyId, u: s.username };
  /* کلید اصلی هر تعریف — برای بازیابی سطر ایجادشده بدون OUTPUT (جدول‌های دارای تریگر لاگ) */
  const keyCol = sp.key;
  const keyType = keyCol === "MoeinId" || keyCol === "NarrationId" || keyCol === "TafsiliId" ? "int" : "smallint";
  try {
    /* ستون‌های ممیزی — ایجادکننده/تاریخ ایجاد/سیستم مبدأ (دستور کارفرما) */
    const r = await one<{ id: number }>(
      `INSERT INTO ${sp.table} (CompanyId, CreatedBy, CreatedAt, SourceSystem, ${cols.join(",")}) VALUES (@c, @u, SYSDATETIME(), 'ACCWEB', ${names.join(",")});
       SELECT * FROM ${sp.table} WHERE ${keyCol} = CAST(SCOPE_IDENTITY() AS ${keyType})`, inp);
    return NextResponse.json({ ok: true, row: r });
  } catch (e: any) {
    const msg = String(e.message || e);
    return NextResponse.json({ ok: false, error: msg.includes("UNIQUE") ? "کد تکراری است" : msg.slice(0, 200) }, { status: 400 });
  }
}

export async function PUT(req: NextRequest, { params }: { params: Promise<{ entity: string }> }) {
  const s = await getSession();
  if (!s || !can(s, "master")) return NextResponse.json({ ok: false, error: "مجوز ندارید" }, { status: 403 });
  const { entity } = await params;
  const body = await req.json().catch(() => ({}));
  const { companyId } = { ...ctxOf(req), ...ctxFromBody(body) };
  const mode = Number(await scalar("SELECT CodingMode FROM pob.Companies WHERE CompanyId=@c", { c: companyId }) || 2);
  const sp = spec(entity, mode);
  if (!sp) return NextResponse.json({ ok: false, error: "تعریف ناشناخته" }, { status: 404 });
  const key = Number(body.id || 0);
  if (!key) return NextResponse.json({ ok: false, error: "شناسه لازم است" }, { status: 400 });
  const keyCol = sp.key;

  /* تغییر کد در صورت استفاده ممنوع (ارجاع سند/زیرمجموعه) */
  if (["groups", "kol", "moein", "tafsili"].includes(entity) && body.Code) {
    const old = await one<{ Code: string }>(`SELECT Code FROM ${sp.table} WHERE ${keyCol}=@id AND CompanyId=@c`, { id: key, c: companyId });
    if (old && String(old.Code) !== String(body.Code).trim()) {
      const used = await scalar(
        entity === "groups" ? "SELECT COUNT(*) FROM ACC.AccKol WHERE CompanyId=@c AND GroupCode=@oc"
          : entity === "kol" ? "SELECT COUNT(*) FROM ACC.AccMoein WHERE CompanyId=@c AND KolCode=@oc"
            : entity === "moein" ? "SELECT COUNT(*) FROM ACC.AccVoucherItm i JOIN ACC.AccVoucher h ON h.VoucherId=i.VoucherId WHERE h.CompanyId=@c AND i.MoeinCode=@oc"
              : "SELECT COUNT(*) FROM ACC.AccVoucherItm i JOIN ACC.AccVoucher h ON h.VoucherId=i.VoucherId WHERE h.CompanyId=@c AND (i.Taf1Id=@oc OR i.Taf2Id=@oc OR i.Taf3Id=@oc)",
        { c: companyId, oc: old.Code });
      if (Number(used) > 0) return NextResponse.json({ ok: false, error: "کد در اسناد/زیرمجموعه استفاده شده — تغییر کد ممنوع" }, { status: 400 });
    }
  }

  const sets: string[] = [];
  const inp: Record<string, unknown> = { id: key, c: companyId };
  for (const col of sp.cols) {
    if (!(col.name in body)) continue;
    let v = body[col.name];
    if (v === "" || v === null || v === undefined) {
      if (col.req) continue;
      sets.push(`${col.name}=@f_${col.name}`); inp[`f_${col.name}`] = null; continue;
    }
    v = String(v).trim();
    if (col.code && (!NUM.test(v) || v.length !== col.code))
      return NextResponse.json({ ok: false, error: `کد باید ${col.code} رقم باشد` }, { status: 400 });
    if (col.num) { const n = Number(v); if (Number.isNaN(n)) return NextResponse.json({ ok: false, error: `${col.name} عددی نیست` }, { status: 400 }); sets.push(`${col.name}=@f_${col.name}`); inp[`f_${col.name}`] = n; }
    else { sets.push(`${col.name}=@f_${col.name}`); inp[`f_${col.name}`] = col.max ? v.slice(0, col.max) : v; }
  }
  if (!sets.length) return NextResponse.json({ ok: false, error: "چیزی برای تغییر نیست" }, { status: 400 });
  /* ارز پایه — تنها یک ارز پایه برای هر شرکت (بله/خیر) */
  if (entity === "fx" && (body.IsBase === 1 || body.IsBase === "1"))
    await q("UPDATE ACC.AccFx SET IsBase=0 WHERE CompanyId=@c AND FxId<>@id", { c: companyId, id: key });
  /* ستون‌های ممیزی ویرایش — ویرایش‌کننده/تاریخ ویرایش */
  sets.push("UpdatedBy=@u"); inp.u = s.username;
  sets.push("UpdatedAt=SYSDATETIME()");
  try {
    await q(`UPDATE ${sp.table} SET ${sets.join(",")} WHERE ${keyCol}=@id AND CompanyId=@c`, inp);
    return NextResponse.json({ ok: true });
  } catch (e: any) {
    return NextResponse.json({ ok: false, error: String(e.message || e).slice(0, 200) }, { status: 400 });
  }
}

export async function DELETE(req: NextRequest, { params }: { params: Promise<{ entity: string }> }) {
  const s = await getSession();
  if (!s || !can(s, "master")) return NextResponse.json({ ok: false, error: "مجوز ندارید" }, { status: 403 });
  const { entity } = await params;
  const { companyId } = ctxOf(req);
  if (!companyId) return NextResponse.json({ ok: false, error: "شرکت انتخاب نشده" }, { status: 400 });
  const url = new URL(req.url);
  const id = Number(url.searchParams.get("id") || 0);
  if (!id) return NextResponse.json({ ok: false, error: "شناسه لازم است" }, { status: 400 });
  const mode = Number(await scalar("SELECT CodingMode FROM pob.Companies WHERE CompanyId=@c", { c: companyId }) || 2);
  const sp = spec(entity, mode);
  if (!sp) return NextResponse.json({ ok: false, error: "تعریف ناشناخته" }, { status: 404 });

  const keyCol = entity === "tafsili" ? "TafsiliId" : entity === "tafsili-types" ? "TafsiliTypeId" : entity === "tafsili-ctgries" ? "CategoryId"
    : entity === "groups" ? "GroupId" : entity === "kol" ? "KolId" : entity === "moein" ? "MoeinId" : entity === "std-narration" ? "NarrationId" : entity === "vchtypes" ? "VoucherTypeId" : "id";
  const codeCol = entity === "groups" ? "Code" : entity === "kol" ? "Code" : entity === "moein" ? "Code" : entity === "tafsili" ? "TafsiliId" : entity === "tafsili-types" ? "TafsiliTypeId" : entity === "tafsili-ctgries" ? "CategoryId" : entity === "vchtypes" ? "VoucherTypeId" : "NarrationId";
  const row = await one<any>(`SELECT * FROM ${sp.table} WHERE ${keyCol}=@id AND CompanyId=@c`, { id, c: companyId });
  if (!row) return NextResponse.json({ ok: false, error: "یافت نشد" }, { status: 404 });

  if (sp.delCheck) {
    for (const chk of sp.delCheck) {
      const hit = await one(chk.sql, { c: companyId, code: row[codeCol] });
      if (hit) return NextResponse.json({ ok: false, error: chk.msg }, { status: 400 });
    }
  }
  await q(`DELETE FROM ${sp.table} WHERE ${keyCol}=@id AND CompanyId=@c`, { id, c: companyId });
  return NextResponse.json({ ok: true });
}
