import { NextRequest, NextResponse } from "next/server";
import { q, one } from "@/lib/db";
import { getSession, can } from "@/lib/auth";

/* واژه‌نامهٔ داده — سه جدول YFG.TableName / YFG.FieldName / YFG.LinkField (درخواست کارفرما)
   GET  : مرور با جست‌وجو و فیلتر شما — برای همهٔ کاربران
   PUT  : ویرایش نام فارسی/نقش — فقط مدیر سامانه (تغییرها در pob.UserLog ثبت می‌شود) */

export async function GET(req: NextRequest) {
  const s = await getSession();
  if (!s) return NextResponse.json({ ok: false, error: "دسترسی رد شد" }, { status: 401 });
  const url = new URL(req.url);
  const view = url.searchParams.get("view") || "tables";
  const search = (url.searchParams.get("q") || "").trim();
  const schema = (url.searchParams.get("schema") || "").trim();
  const like = `%${search}%`;

  if (view === "tables") {
    const rows = await q(
      `SELECT TableId id, TableSchema, TableName, TableFa, Module, IsLookup, IsActive, CreatedBy, CreatedAtJ, UpdatedBy, UpdatedAtJ, SourceSystem
       FROM YFG.TableName
       WHERE (@q = N'' OR TableName LIKE @like OR TableFa LIKE @like OR Module LIKE @like)
         AND (@s = '' OR TableSchema = @s)
       ORDER BY TableSchema, TableName`, { q: search, like, s: schema });
    return NextResponse.json({ ok: true, rows });
  }
  if (view === "fields") {
    const rows = await q(
      `SELECT f.FieldId id, f.TableSchema, f.TableName, t.TableFa, f.FieldName, f.FieldFa, f.Module, f.DataType, f.IsActive,
              f.CreatedBy, f.CreatedAtJ, f.UpdatedBy, f.UpdatedAtJ, f.SourceSystem
       FROM YFG.FieldName f
       LEFT JOIN YFG.TableName t ON t.TableSchema=f.TableSchema AND t.TableName=f.TableName
       WHERE (@q = N'' OR f.FieldName LIKE @like OR f.FieldFa LIKE @like OR f.TableName LIKE @like OR t.TableFa LIKE @like)
         AND (@s = '' OR f.TableSchema = @s)
       ORDER BY f.TableSchema, f.TableName, f.FieldName`, { q: search, like, s: schema });
    return NextResponse.json({ ok: true, rows });
  }
  if (view === "links") {
    const rows = await q(
      `SELECT LinkId id, TableSchema, TableName, FieldName, FieldFa,
              LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole, IsActive,
              CreatedBy, CreatedAtJ, UpdatedBy, UpdatedAtJ, SourceSystem
       FROM YFG.LinkField
       WHERE (@q = N'' OR TableName LIKE @like OR FieldName LIKE @like OR FieldFa LIKE @like
                OR LinkTableName LIKE @like OR LinkFieldName LIKE @like OR LinkRole LIKE @like)
         AND (@s = '' OR TableSchema = @s)
       ORDER BY TableSchema, TableName, FieldName`, { q: search, like, s: schema });
    return NextResponse.json({ ok: true, rows });
  }
  return NextResponse.json({ ok: false, error: "نمای ناشناخته" }, { status: 404 });
}

export async function PUT(req: NextRequest) {
  const s = await getSession();
  if (!s || !can(s, "master")) return NextResponse.json({ ok: false, error: "فقط مدیر سامانه مجاز به ویرایش واژه‌نامه است" }, { status: 403 });
  const body = await req.json().catch(() => ({}));
  const view = String(body.view || "");
  const id = Number(body.id || 0);
  if (!id) return NextResponse.json({ ok: false, error: "شناسه لازم است" }, { status: 400 });

  if (view === "tables") {
    const faName = String(body.TableFa || "").trim().slice(0, 200);
    if (!faName) return NextResponse.json({ ok: false, error: "نام فارسی الزامی است" }, { status: 400 });
    await q(`UPDATE YFG.TableName SET TableFa=@v, Module=ISNULL(@m, Module), UpdatedBy=@u, UpdatedAt=SYSDATETIME() WHERE TableId=@id`,
      { v: faName, m: String(body.Module || "").trim().slice(0, 50) || null, u: s.username, id });
    return NextResponse.json({ ok: true });
  }
  if (view === "fields") {
    const faName = String(body.FieldFa || "").trim().slice(0, 200);
    if (!faName) return NextResponse.json({ ok: false, error: "نام فارسی الزامی است" }, { status: 400 });
    await q(`UPDATE YFG.FieldName SET FieldFa=@v, Module=ISNULL(@m, Module), UpdatedBy=@u, UpdatedAt=SYSDATETIME() WHERE FieldId=@id`,
      { v: faName, m: String(body.Module || "").trim().slice(0, 50) || null, u: s.username, id });
    return NextResponse.json({ ok: true });
  }
  if (view === "links") {
    const role = String(body.LinkRole || "").trim().slice(0, 200) || null;
    await q(`UPDATE YFG.LinkField SET LinkRole=@v, UpdatedBy=@u, UpdatedAt=SYSDATETIME() WHERE LinkId=@id`,
      { v: role, u: s.username, id });
    return NextResponse.json({ ok: true });
  }
  return NextResponse.json({ ok: false, error: "نمای ناشناخته" }, { status: 404 });
}

/* شمار آماری واژه‌نامه برای سربرگ پنجره */
export async function HEAD() {
  const r = await one<{ T: number; F: number; L: number }>(
    `SELECT (SELECT COUNT(*) FROM YFG.TableName) T, (SELECT COUNT(*) FROM YFG.FieldName) F, (SELECT COUNT(*) FROM YFG.LinkField) L`);
  const h = new Headers({ "X-Meta-Tables": String(r?.T ?? 0), "X-Meta-Fields": String(r?.F ?? 0), "X-Meta-Links": String(r?.L ?? 0) });
  return new Response(null, { status: 200, headers: h });
}
