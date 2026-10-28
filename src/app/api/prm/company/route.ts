import { NextRequest, NextResponse } from "next/server";
import { q, one } from "@/lib/db";
import { getSession, can } from "@/lib/auth";

/* معرفی شرکت [اصول: استیجاری — چند شرکت در یک دیتابیس] */
export async function GET() {
  const s = await getSession();
  if (!s) return NextResponse.json({ ok: false, error: "دسترسی رد شد" }, { status: 401 });
  const rows = await q("SELECT CompanyId, CompanyCode, TitleFa, NationalId, EconomicCode, CodingMode, IsActive FROM Prm.Company ORDER BY CompanyCode");
  return NextResponse.json({ ok: true, rows });
}

export async function POST(req: NextRequest) {
  const s = await getSession();
  if (!s || s.role !== "admin") return NextResponse.json({ ok: false, error: "فقط مدیر سامانه" }, { status: 403 });
  const body = await req.json().catch(() => ({}));
  const code = String(body.CompanyCode || "").trim().slice(0, 10);
  const title = String(body.TitleFa || "").trim().slice(0, 200);
  const mode = Number(body.CodingMode || 2) === 1 ? 1 : 2;
  if (!code || !title) return NextResponse.json({ ok: false, error: "کد و عنوان شرکت الزامی است" }, { status: 400 });
  try {
    const row = await one(
      `INSERT INTO Prm.Company (CompanyCode, TitleFa, NationalId, EconomicCode, CodingMode) OUTPUT INSERTED.*
       VALUES (@code, @title, @nid, @eco, @mode)`,
      { code, title, nid: String(body.NationalId || "").slice(0, 15) || null, eco: String(body.EconomicCode || "").slice(0, 15) || null, mode });
    return NextResponse.json({ ok: true, row });
  } catch (e: any) {
    return NextResponse.json({ ok: false, error: String(e.message || e).includes("UNIQUE") ? "کد شرکت تکراری است" : String(e.message).slice(0, 200) }, { status: 400 });
  }
}
