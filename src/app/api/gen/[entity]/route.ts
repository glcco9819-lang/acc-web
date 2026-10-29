import { NextRequest, NextResponse } from "next/server";
import { q, one } from "@/lib/db";
import { getSession, can } from "@/lib/auth";

/* اطلاعات عمومی (شمای pob — همتاسازی اطلاعات عمومی فایل‌های اصلی: HumCmp/GnrGeneral/ConfigCommon/gnCalndr)
   اشخاص و شرکت‌ها / نشانی‌ها / طبقه‌بندی / موقعیت‌های جغرافیایی /
   تنظیمات عمومی / مرجع کدها / تعطیلات
   همهٔ جدول‌ها ستون‌های ممیزی دارند: CreatedBy/CreatedAt(+J)/UpdatedBy/UpdatedAt(+J)/SourceSystem
   تاریخ شمسی ملاک است (ستون‌های J خودکار از توابع pob.GrgToJalali پر می‌شوند) */

const NUM = /^\d+$/;
const JDATE = /^\d{4}\/\d{2}\/\d{2}$/;

interface Spec {
  table: string;
  key: string;
  cols: { name: string; req?: boolean; num?: boolean; jdate?: boolean; max?: number }[];
  orderBy: string;
  scope?: string;               /* شرط واکشی (مثل parent) */
}

function spec(entity: string): Spec | null {
  switch (entity) {
    case "party": return {
      table: "pob.Party", key: "Serial", orderBy: "Serial DESC",
      cols: [
        { name: "RecType", req: true },
        { name: "PartyKind", num: true },
        { name: "Title", max: 400 }, { name: "FName", max: 200 }, { name: "LName", max: 200 },
        { name: "NickName", max: 200 },
        { name: "Title_En", max: 400 }, { name: "FName_En", max: 200 }, { name: "LName_En", max: 200 },
        { name: "CompName", max: 400 }, { name: "CompName_En", max: 400 },
        { name: "EconCode", max: 20 }, { name: "NationalCode", max: 20 },
        { name: "FatherName", max: 200 }, { name: "IDNo", max: 30 },
        { name: "IsActive", num: true },
      ],
    };
    case "address": return {
      table: "pob.PartyAddress", key: "Serial", orderBy: "Serial", scope: "PartyRef=@p",
      cols: [
        { name: "Title", max: 200 }, { name: "Address", max: 1000 }, { name: "Address_En", max: 1000 },
        { name: "ZipCode", max: 20 }, { name: "PostBox", max: 20 },
        { name: "Phone", max: 60 }, { name: "Fax", max: 60 }, { name: "EMail", max: 120 },
        { name: "Mobile", max: 60 }, { name: "GeoPlaceRef", num: true },
      ],
    };
    case "party-ctgry": return {
      table: "pob.PartyCategory", key: "CategoryId", orderBy: "CategoryId",
      cols: [{ name: "Title", req: true, max: 200 }, { name: "ParentRef", num: true }],
    };
    case "party-cat": return {
      table: "pob.PartyCategoryLink", key: "PartyRef", orderBy: "CategoryRef", scope: "PartyRef=@p",
      cols: [{ name: "CategoryRef", req: true, num: true }],
    };
    case "geo-place": return {
      table: "pob.GeoPlace", key: "GeoPlaceId", orderBy: "GeoPlaceId",
      cols: [
        { name: "Title", req: true, max: 200 },
        { name: "ParentRef", num: true },
        { name: "GeoType", req: true, num: true },
        { name: "LatinTitle", max: 200 },
      ],
    };
    case "lookup": return {
      table: "pob.CodeList", key: "CodeId", orderBy: "[Type], Code",
      cols: [
        { name: "Type", req: true, max: 40 },
        { name: "Code", req: true, num: true },
        { name: "Title", req: true, max: 200 },
        { name: "Aux", max: 100 }, { name: "SystemName", max: 10 },
      ],
    };
    case "app-setting": return {
      table: "pob.AppSetting", key: "SettingId", orderBy: "SettingId",
      cols: [
        { name: "KeyValue", req: true, max: 60 },
        { name: "DataValue", req: true, max: 400 },
        { name: "SystemName", max: 10 },
        { name: "Descr", max: 600 },
      ],
    };
    case "holidays": return {
      table: "pob.Holiday", key: "HolidayId", orderBy: "JDate DESC",
      cols: [
        { name: "JDate", req: true, jdate: true },
        { name: "HolidayTypeRef", num: true },
        { name: "Descr", max: 400 },
      ],
    };
    default: return null;
  }
}

export async function GET(req: NextRequest, { params }: { params: Promise<{ entity: string }> }) {
  const s = await getSession();
  if (!s) return NextResponse.json({ ok: false, error: "دسترسی رد شد" }, { status: 401 });
  const { entity } = await params;
  const sp = spec(entity);
  if (!sp) return NextResponse.json({ ok: false, error: "تعریف ناشناخته" }, { status: 404 });
  const url = new URL(req.url);
  const p = url.searchParams.get("p");
  /* v2.4.2 — lookup پشتیبانی فیلتر نوع: ?t=BANK برای فهرست بانک‌ها */
  const t = url.searchParams.get("t");
  let where = sp.scope && p ? `WHERE ${sp.scope}` : "";
  const inp: Record<string, unknown> = sp.scope && p ? { p } : {};
  if (entity === "lookup" && t) {
    where = where ? `${where} AND [Type]=@t` : "WHERE [Type]=@t";
    inp.t = t;
  }
  const rows = await q(
    `SELECT * FROM ${sp.table} ${where} ORDER BY ${sp.orderBy}`, inp);
  /* انواع تعطیلی برای دراپ‌داون پنجرهٔ تعطیلات */
  if (entity === "holidays") {
    const types = await q(`SELECT HolidayTypeId v, Title t FROM pob.HolidayType WHERE IsActive=1 ORDER BY HolidayTypeId`);
    return NextResponse.json({ ok: true, rows, types });
  }
  return NextResponse.json({ ok: true, rows });
}

export async function POST(req: NextRequest, { params }: { params: Promise<{ entity: string }> }) {
  const s = await getSession();
  if (!s || !can(s, "master")) return NextResponse.json({ ok: false, error: "مجوز ثبت ندارید" }, { status: 403 });
  const { entity } = await params;
  const sp = spec(entity);
  if (!sp) return NextResponse.json({ ok: false, error: "تعریف ناشناخته" }, { status: 404 });
  const body = await req.json().catch(() => ({}));

  /* قاعده: عنوان برای شرکت لازم است؛ نام برای شخص */
  if (entity === "party") {
    const rt = String(body.RecType || "").trim();
    if (rt === "CMP" && !String(body.Title || "").trim() && !String(body.CompName || "").trim())
      return NextResponse.json({ ok: false, error: "عنوان شرکت الزامی است" }, { status: 400 });
    if (rt === "MAN" && !String(body.FName || "").trim() && !String(body.Title || "").trim())
      return NextResponse.json({ ok: false, error: "نام شخص الزامی است" }, { status: 400 });
  }

  const vals: Record<string, unknown> = {};
  for (const col of sp.cols) {
    let v = body[col.name];
    if (v === "" || v === undefined || v === null) {
      if (col.req) return NextResponse.json({ ok: false, error: `${col.name} الزامی است` }, { status: 400 });
      vals[col.name] = null; continue;
    }
    v = String(v).trim();
    if (col.jdate && !JDATE.test(v))
      return NextResponse.json({ ok: false, error: "تاریخ باید شمسی و به قالب 1405/01/01 باشد" }, { status: 400 });
    if (col.num) { const n = Number(v); if (Number.isNaN(n)) return NextResponse.json({ ok: false, error: `${col.name} عددی نیست` }, { status: 400 }); vals[col.name] = n; }
    else vals[col.name] = col.max ? v.slice(0, col.max) : v;
  }
  /* کلید والد از پارامتر نشستِ فرم */
  const url = new URL(req.url);
  const p = url.searchParams.get("p");
  if (sp.scope && p) vals["PartyRef"] = Number(p);

  const cols = Object.keys(vals);
  if (!cols.length) return NextResponse.json({ ok: false, error: "داده‌ای ارسال نشده" }, { status: 400 });
  const names = cols.map((c) => `@${c}`);
  const inp: Record<string, unknown> = { ...vals, u: s.username };
  try {
    /* ممیزی: ایجادکننده + تاریخ ایجاد + سیستم مبدأ (J شمسی خودکار)
       بازیابی سطر با SCOPE_IDENTITY — جدول‌های دارای تریگر لاگ از OUTPUT بدون INTO پشتیبانی نمی‌کنند
       جدول بدون ستون IDENTITY (لینک طبقه/تفصیلی): بازیابی با کلید مرکب */
    const sel = sp.table === "pob.PartyCategoryLink"
      ? `SELECT * FROM ${sp.table} WHERE PartyRef = @PartyRef AND CategoryRef = @CategoryRef`
      : `SELECT * FROM ${sp.table} WHERE ${sp.key} = CAST(SCOPE_IDENTITY() AS int)`;
    const r = await one(
      `INSERT INTO ${sp.table} (CreatedBy, CreatedAt, SourceSystem, ${cols.join(",")}) VALUES (@u, SYSDATETIME(), 'ACCWEB', ${names.join(",")});
       ${sel}`, inp);
    return NextResponse.json({ ok: true, row: r });
  } catch (e: any) {
    const msg = String(e.message || e);
    return NextResponse.json({ ok: false, error: msg.includes("UNIQUE") ? "مقدار تکراری است" : msg.slice(0, 200) }, { status: 400 });
  }
}

export async function PUT(req: NextRequest, { params }: { params: Promise<{ entity: string }> }) {
  const s = await getSession();
  if (!s || !can(s, "master")) return NextResponse.json({ ok: false, error: "مجوز ویرایش ندارید" }, { status: 403 });
  const { entity } = await params;
  const sp = spec(entity);
  if (!sp) return NextResponse.json({ ok: false, error: "تعریف ناشناخته" }, { status: 404 });
  const body = await req.json().catch(() => ({}));
  const key = Number(body.id || 0);
  if (!key) return NextResponse.json({ ok: false, error: "شناسه لازم است" }, { status: 400 });

  const sets: string[] = [];
  const inp: Record<string, unknown> = { id: key };
  for (const col of sp.cols) {
    if (!(col.name in body)) continue;
    let v = body[col.name];
    if (v === "" || v === null || v === undefined) {
      if (col.req) continue;
      sets.push(`${col.name}=@f_${col.name}`); inp[`f_${col.name}`] = null; continue;
    }
    v = String(v).trim();
    if (col.jdate && !JDATE.test(v))
      return NextResponse.json({ ok: false, error: "تاریخ باید شمسی و به قالب 1405/01/01 باشد" }, { status: 400 });
    if (col.num) { const n = Number(v); if (Number.isNaN(n)) return NextResponse.json({ ok: false, error: `${col.name} عددی نیست` }, { status: 400 }); sets.push(`${col.name}=@f_${col.name}`); inp[`f_${col.name}`] = n; }
    else { sets.push(`${col.name}=@f_${col.name}`); inp[`f_${col.name}`] = col.max ? v.slice(0, col.max) : v; }
  }
  if (!sets.length) return NextResponse.json({ ok: false, error: "چیزی برای تغییر نیست" }, { status: 400 });
  /* ممیزی ویرایش: ویرایش‌کننده + تاریخ ویرایش */
  sets.push("UpdatedBy=@u"); inp.u = s.username;
  sets.push("UpdatedAt=SYSDATETIME()");
  try {
    await q(`UPDATE ${sp.table} SET ${sets.join(",")} WHERE ${sp.key}=@id`, inp);
    return NextResponse.json({ ok: true });
  } catch (e: any) {
    return NextResponse.json({ ok: false, error: String(e.message || e).slice(0, 200) }, { status: 400 });
  }
}

export async function DELETE(req: NextRequest, { params }: { params: Promise<{ entity: string }> }) {
  const s = await getSession();
  if (!s || !can(s, "master")) return NextResponse.json({ ok: false, error: "مجوز حذف ندارید" }, { status: 403 });
  const { entity } = await params;
  const sp = spec(entity);
  if (!sp) return NextResponse.json({ ok: false, error: "تعریف ناشناخته" }, { status: 404 });
  const url = new URL(req.url);
  const id = Number(url.searchParams.get("id") || 0);
  if (!id) return NextResponse.json({ ok: false, error: "شناسه لازم است" }, { status: 400 });

  /* کنترل ارجاع قبل از حذف (الگوی اصل) */
  const refs: Record<string, { sql: string; msg: string }[]> = {
    party: [
      { sql: "SELECT 1 x FROM ACC.AccTafsili WHERE PartyRef=@id", msg: "شخص/شرکت در تفصیلی‌های حسابداری استفاده شده است" },
      { sql: "SELECT 1 x FROM pob.PartyAddress WHERE PartyRef=@id", msg: "ابتدا نشانی‌های این شخص را حذف کنید" },
    ],
    "party-ctgry": [
      { sql: "SELECT 1 x FROM pob.PartyCategoryLink WHERE CategoryRef=@id", msg: "طبقه‌بندی به اشخاص اختصاص داده شده است" },
      { sql: "SELECT 1 x FROM pob.PartyCategory WHERE ParentRef=@id", msg: "طبقه‌بندی دارای زیرمجموعه است" },
    ],
    "geo-place": [
      { sql: "SELECT 1 x FROM pob.GeoPlace WHERE ParentRef=@id", msg: "موقعیت دارای زیرمجموعه است" },
      { sql: "SELECT 1 x FROM pob.PartyAddress WHERE GeoPlaceRef=@id", msg: "موقعیت در نشانی‌ها استفاده شده است" },
    ],
    holidays: [],
    lookup: [],
    "app-setting": [],
  };
  for (const chk of (refs[entity] || [])) {
    const hit = await one(chk.sql, { id });
    if (hit) return NextResponse.json({ ok: false, error: chk.msg }, { status: 400 });
  }
  await q(`DELETE FROM ${sp.table} WHERE ${sp.key}=@id`, { id });
  return NextResponse.json({ ok: true });
}
