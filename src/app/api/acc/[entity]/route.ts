import { NextRequest, NextResponse } from "next/server";
import { q, one, scalar } from "@/lib/db";
import { getSession, can } from "@/lib/auth";

/* پنجره‌های تعاریف حساب‌ها (مطابق acCDef) — یک مسیر عمومی برای هفت تعریف + شجره */

const NUM = /^\d+$/;

interface EntSpec {
  table: string;
  cols: { name: string; req?: boolean; num?: boolean; len?: number; max?: number; code?: number }[];
  delCheck?: { sql: string; inp: string[]; msg: string }[];
}

function spec(entity: string, mode: number): EntSpec | null {
  switch (entity) {
    case "groups": return {
      table: "Acc.[Group]",
      cols: [
        { name: "Code", req: true, code: 2 },
        { name: "Title", req: true, max: 200 },
        { name: "AccNature", req: true, num: true },
      ],
      delCheck: [{ sql: "SELECT 1 x FROM Acc.Kol WHERE CompanyId=@c AND GroupCode=@code", inp: ["code"], msg: "گروه دارای حساب کل است — ابتدا کل‌ها را حذف کنید" }],
    };
    case "kol": return {
      table: "Acc.Kol",
      cols: [
        { name: "Code", req: true, code: 4 },
        { name: "GroupCode", code: mode === 2 ? 2 : 0, req: mode === 2 },
        { name: "Title", req: true, max: 200 },
        { name: "AccNature", req: true, num: true },
      ],
      delCheck: [{ sql: "SELECT 1 x FROM Acc.Moein WHERE CompanyId=@c AND KolCode=@code", inp: ["code"], msg: "کل دارای معین است" }],
    };
    case "moein": return {
      table: "Acc.Moein",
      cols: [
        { name: "Code", req: true, code: 6 },
        { name: "KolCode", req: true, code: mode === 2 ? 4 : 2 },
        { name: "Title", req: true, max: 200 },
        { name: "AccNature", req: true, num: true },
        { name: "Dl1TypeId", num: true }, { name: "Dl2TypeId", num: true }, { name: "Dl3TypeId", num: true },
        { name: "Trackable", num: true }, { name: "Countable", num: true },
        { name: "IsFx", num: true }, { name: "FxConvertible", num: true },
        { name: "IsActive", num: true },
      ],
      delCheck: [
        { sql: "SELECT 1 x FROM Vch.Itm i JOIN Vch.Hdr h ON h.HdrId=i.HdrId WHERE h.CompanyId=@c AND i.MoeinCode=@code", inp: ["code"], msg: "معین در سند استفاده شده است" },
        { sql: "SELECT 1 x FROM Acc.OpeningBalance WHERE CompanyId=@c AND MoeinCode=@code", inp: ["code"], msg: "معین دارای ماندهٔ ابتدای دوره است" },
        { sql: "SELECT 1 x FROM Acc.StdDesc WHERE CompanyId=@c AND MoeinCode=@code", inp: ["code"], msg: "معین دارای شرح استاندارد است" },
      ],
    };
    case "dl": return {
      table: "Acc.DL",
      cols: [
        { name: "Code", req: true, code: 8 },
        { name: "DlTypeId", req: true, num: true },
        { name: "Title", req: true, max: 200 },
        { name: "LatinTitle", max: 200 },
        { name: "IsActive", num: true },
      ],
      delCheck: [
        { sql: "SELECT 1 x FROM Vch.Itm i JOIN Vch.Hdr h ON h.HdrId=i.HdrId WHERE h.CompanyId=@c AND (i.Dl1Id=@code OR i.Dl2Id=@code OR i.Dl3Id=@code)", inp: ["code", "int"], msg: "تفصیلی در سند استفاده شده است" },
        { sql: "SELECT 1 x FROM Acc.DlCtgryLink WHERE DlId=@code", inp: ["code", "int"], msg: "تفصیلی در طبقه‌بندی استفاده شده است" },
      ],
    };
    case "dltypes": return {
      table: "Acc.DlType",
      cols: [{ name: "Title", req: true, max: 100 }, { name: "LatinTitle", max: 100 }],
      delCheck: [
        { sql: "SELECT 1 x FROM Acc.Moein WHERE CompanyId=@c AND (Dl1TypeId=@code OR Dl2TypeId=@code OR Dl3TypeId=@code)", inp: ["code", "int"], msg: "نوع تفصیل به معین متصل است" },
        { sql: "SELECT 1 x FROM Acc.DL WHERE CompanyId=@c AND DlTypeId=@code", inp: ["code", "int"], msg: "تفصیلی‌هایی از این نوع وجود دارد" },
      ],
    };
    case "dlctgries": return {
      table: "Acc.DlCtgry",
      cols: [{ name: "Title", req: true, max: 100 }],
      delCheck: [{ sql: "SELECT 1 x FROM Acc.DlCtgryLink WHERE CtgryId=@code", inp: ["code", "int"], msg: "طبقه دارای تفصیلی است" }],
    };
    case "stddesc": return {
      table: "Acc.StdDesc",
      cols: [{ name: "MoeinCode", req: true, code: 6 }, { name: "Seq", req: true, num: true }, { name: "DescText", req: true, max: 300 }],
    };
    case "vchtypes": return {
      table: "Vch.[Type]",
      cols: [{ name: "Title", req: true, max: 100 }, { name: "LatinTitle", max: 100 }],
      delCheck: [{ sql: "SELECT 1 x FROM Vch.Hdr WHERE CompanyId=@c AND TypeId=@code", inp: ["code"], msg: "سندهایی از این نوع ثبت شده است" }],
    };
    default: return null;
  }
}

function ctxOf(req: NextRequest) {
  const raw = req.cookies.get("acc_ctx")?.value;
  try { return raw ? JSON.parse(raw) : {}; } catch { return {}; }
}

export async function GET(req: NextRequest, { params }: { params: Promise<{ entity: string }> }) {
  const s = await getSession();
  if (!s) return NextResponse.json({ ok: false, error: "دسترسی رد شد" }, { status: 401 });
  const { entity } = await params;
  const { companyId } = ctxOf(req);
  if (!companyId) return NextResponse.json({ ok: false, error: "شرکت انتخاب نشده است", code: "NO_CTX" }, { status: 400 });

  if (entity === "chart") {
    const rows = await q(
      `SELECT g.Code GroupCode, g.Title GroupTitle, g.AccNature,
              k.Code KolCode, k.Title KolTitle,
              m.Code MoeinCode, m.Title MoeinTitle, m.IsActive MoeinActive,
              m.Dl1TypeId, m.Dl2TypeId, m.Dl3TypeId,
              t1.Title Dl1Title, t2.Title Dl2Title, t3.Title Dl3Title
       FROM Acc.[Group] g
       LEFT JOIN Acc.Kol k ON k.CompanyId=g.CompanyId AND k.GroupCode=g.Code
       LEFT JOIN Acc.Moein m ON m.CompanyId=k.CompanyId AND m.KolCode=k.Code
       LEFT JOIN Acc.DlType t1 ON t1.DlTypeId=m.Dl1TypeId
       LEFT JOIN Acc.DlType t2 ON t2.DlTypeId=m.Dl2TypeId
       LEFT JOIN Acc.DlType t3 ON t3.DlTypeId=m.Dl3TypeId
       WHERE g.CompanyId=@c
       ORDER BY g.Code, k.Code, m.Code`, { c: companyId });
    return NextResponse.json({ ok: true, rows });
  }

  const mode = Number(await scalar("SELECT CodingMode FROM Prm.Company WHERE CompanyId=@c", { c: companyId }) || 2);
  const sp = spec(entity, mode);
  if (!sp) return NextResponse.json({ ok: false, error: "تعریف ناشناخته" }, { status: 404 });
  const rows = await q(`SELECT * FROM ${sp.table} WHERE CompanyId=@c ORDER BY 1`, { c: companyId });
  return NextResponse.json({ ok: true, rows, mode });
}

export async function POST(req: NextRequest, { params }: { params: Promise<{ entity: string }> }) {
  const s = await getSession();
  if (!s || !can(s, "master")) return NextResponse.json({ ok: false, error: "مجوز تعریف ندارید" }, { status: 403 });
  const { entity } = await params;
  const { companyId } = ctxOf(req);
  if (!companyId) return NextResponse.json({ ok: false, error: "شرکت انتخاب نشده" }, { status: 400 });
  const mode = Number(await scalar("SELECT CodingMode FROM Prm.Company WHERE CompanyId=@c", { c: companyId }) || 2);
  const sp = spec(entity, mode);
  if (!sp) return NextResponse.json({ ok: false, error: "تعریف ناشناخته" }, { status: 404 });
  const body = await req.json().catch(() => ({}));

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
    const ts = [vals.Dl1TypeId, vals.Dl2TypeId, vals.Dl3TypeId].filter(Boolean);
    if (new Set(ts).size !== ts.length)
      return NextResponse.json({ ok: false, error: "سطوح تفصیلی باید متمایز باشند" }, { status: 400 });
  }
  if (entity === "kol" && mode === 1) vals.GroupCode = null;

  const cols = Object.keys(vals);
  const names = cols.map((c) => `@${c}`);
  const inp: Record<string, unknown> = { ...vals, c: companyId };
  try {
    const r = await one<{ id: number }>(
      `INSERT INTO ${sp.table} (CompanyId, ${cols.join(",")}) OUTPUT INSERTED.* VALUES (@c, ${names.join(",")})`, inp);
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
  const { companyId } = ctxOf(req);
  const mode = Number(await scalar("SELECT CodingMode FROM Prm.Company WHERE CompanyId=@c", { c: companyId }) || 2);
  const sp = spec(entity, mode);
  if (!sp) return NextResponse.json({ ok: false, error: "تعریف ناشناخته" }, { status: 404 });
  const body = await req.json().catch(() => ({}));
  const key = Number(body.id || 0);
  if (!key) return NextResponse.json({ ok: false, error: "شناسه لازم است" }, { status: 400 });
  const keyCol = entity === "dl" ? "DlId" : entity === "dltypes" ? "DlTypeId" : entity === "dlctgries" ? "CtgryId"
    : entity === "groups" ? "GroupId" : entity === "kol" ? "KolId" : entity === "moein" ? "MoeinId" : entity === "stddesc" ? "StdDescId" : entity === "vchtypes" ? "TypeId" : "id";

  /* تغییر کد در صورت استفاده ممنوع (ارجاع سند/زیرمجموعه) */
  if (["groups", "kol", "moein", "dl"].includes(entity) && body.Code) {
    const old = await one<{ Code: string }>(`SELECT Code FROM ${sp.table} WHERE ${keyCol}=@id AND CompanyId=@c`, { id: key, c: companyId });
    if (old && String(old.Code) !== String(body.Code).trim()) {
      const used = await scalar(
        entity === "groups" ? "SELECT COUNT(*) FROM Acc.Kol WHERE CompanyId=@c AND GroupCode=@oc"
          : entity === "kol" ? "SELECT COUNT(*) FROM Acc.Moein WHERE CompanyId=@c AND KolCode=@oc"
            : entity === "moein" ? "SELECT COUNT(*) FROM Vch.Itm i JOIN Vch.Hdr h ON h.HdrId=i.HdrId WHERE h.CompanyId=@c AND i.MoeinCode=@oc"
              : "SELECT COUNT(*) FROM Vch.Itm i JOIN Vch.Hdr h ON h.HdrId=i.HdrId WHERE h.CompanyId=@c AND (i.Dl1Id=@oc OR i.Dl2Id=@oc OR i.Dl3Id=@oc)",
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
  const mode = Number(await scalar("SELECT CodingMode FROM Prm.Company WHERE CompanyId=@c", { c: companyId }) || 2);
  const sp = spec(entity, mode);
  if (!sp) return NextResponse.json({ ok: false, error: "تعریف ناشناخته" }, { status: 404 });

  const keyCol = entity === "dl" ? "DlId" : entity === "dltypes" ? "DlTypeId" : entity === "dlctgries" ? "CtgryId"
    : entity === "groups" ? "GroupId" : entity === "kol" ? "KolId" : entity === "moein" ? "MoeinId" : entity === "stddesc" ? "StdDescId" : entity === "vchtypes" ? "TypeId" : "id";
  const codeCol = entity === "groups" ? "Code" : entity === "kol" ? "Code" : entity === "moein" ? "Code" : entity === "dl" ? "DlId" : entity === "dltypes" ? "DlTypeId" : entity === "dlctgries" ? "CtgryId" : entity === "vchtypes" ? "TypeId" : "StdDescId";
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
