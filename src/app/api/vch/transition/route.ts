import { NextRequest, NextResponse } from "next/server";
import { one, scalar, tx } from "@/lib/db";
import { getSession, can } from "@/lib/auth";

/* گذار وضعیت سند [فرم‌های بررسي اسناد / قطعي كردن اسناد — acVchDef]
   review: موقت→بررسی‌شده (توسط بررسی‌کننده ≠ سازنده)
   unreview: بررسی‌شده→موقت
   finalize: بررسی‌شده→قطعی (توسط قطعی‌کننده ≠ بررسی‌کننده ≠ سازنده) + تراز مجدد
   unfinalize: ممنوع — سند قطعی فقط با سند برگشتی اصلاح می‌شود (اصل)
   v2.4.5 — اکشن «note» (یادداشت): تغییر وضعیت نمی‌دهد؛ یادداشت کاربر در ردپای
   عملیات سند (Action=8) ثبت می‌شود — طبق دسترسی کاربر (ثبت‌کننده/بررسی‌کننده/مدیر) */
const ACTS: Record<string, { from: number; to: number; log: number; role: string }> = {
  review: { from: 1, to: 2, log: 2, role: "review" },
  unreview: { from: 2, to: 1, log: 3, role: "review" },
  finalize: { from: 2, to: 3, log: 4, role: "finalize" },
};

export async function POST(req: NextRequest) {
  const s = await getSession();
  if (!s) return NextResponse.json({ ok: false, error: "دسترسی رد شد" }, { status: 401 });
  const body = await req.json().catch(() => ({}));
  const id = Number(body.id || 0);
  const action = String(body.action || "");
  if (!id) return NextResponse.json({ ok: false, error: "شناسهٔ سند لازم است" }, { status: 400 });

  /* v2.4.5 — یادداشت سند: بدون تغییر وضعیت، ثبت در ردپای عملیات (Action=8) */
  if (action === "note") {
    if (!can(s, "master")) return NextResponse.json({ ok: false, error: "دسترسی ثبت یادداشت ندارید" }, { status: 403 });
    const note = String(body.note || "").trim().slice(0, 500);
    if (!note) return NextResponse.json({ ok: false, error: "متن یادداشت خالی است" }, { status: 400 });
    const hdr = await one<any>("SELECT VoucherId FROM ACC.AccVoucher WHERE VoucherId=@id", { id });
    if (!hdr) return NextResponse.json({ ok: false, error: "سند یافت نشد" }, { status: 404 });
    try {
      await tx(async (run) => {
        await run(`INSERT INTO ACC.AccVoucherFlow (VoucherId, Action, ByUser, Note) VALUES (@id, 8, @u, @n)`,
          { id, u: s.username, n: note });
      });
      return NextResponse.json({ ok: true });
    } catch (e: any) {
      return NextResponse.json({ ok: false, error: String(e.message || e).slice(0, 300) }, { status: 400 });
    }
  }

  const cfg = ACTS[action];
  if (!cfg) return NextResponse.json({ ok: false, error: "عملیات ناشناخته — سند قطعی فقط با سند برگشتی اصلاح می‌شود" }, { status: 400 });
  if (!can(s, cfg.role)) return NextResponse.json({ ok: false, error: "نقش شما مجاز به این عملیات نیست" }, { status: 403 });

  const hdr = await one<any>("SELECT * FROM ACC.AccVoucher WHERE VoucherId=@id", { id });
  if (!hdr) return NextResponse.json({ ok: false, error: "سند یافت نشد" }, { status: 404 });
  if (hdr.State !== cfg.from)
    return NextResponse.json({ ok: false, error: `وضعیت سند با این عملیات هم‌خوان نیست (وضعیت فعلی: ${["", "موقت", "بررسی‌شده", "قطعی"][hdr.State]})` }, { status: 400 });

  /* maker ≠ checker ≠ finalizer */
  if (action === "review" && hdr.CreatedBy === s.username)
    return NextResponse.json({ ok: false, error: "سازندهٔ سند نمی‌تواند آن را بررسی کند (تفکیک وظایف)" }, { status: 403 });
  if (action === "finalize" && (hdr.CreatedBy === s.username || hdr.CheckedBy === s.username))
    return NextResponse.json({ ok: false, error: "قطعی‌کننده باید غیر از سازنده و بررسی‌کننده باشد (تفکیک وظایف)" }, { status: 403 });

  if (action === "finalize") {
    const bal = await one<{ D: number; C: number }>(
      "SELECT ISNULL(SUM(Dbt),0) D, ISNULL(SUM(Crt),0) C FROM ACC.AccVoucherItm WHERE VoucherId=@id", { id });
    const d = Number(bal?.D || 0), c = Number(bal?.C || 0);
    if (d !== c)
      return NextResponse.json({ ok: false, error: `سند تراز نیست (${d} ≠ ${c})` }, { status: 400 });
    const bad = await scalar(
      `SELECT COUNT(*) FROM ACC.AccVoucherItm i JOIN ACC.AccMoein m ON m.CompanyId=(SELECT CompanyId FROM ACC.AccVoucher WHERE VoucherId=@id) AND m.Code=i.MoeinCode
       WHERE i.VoucherId=@id AND ((m.Taf1TypeId IS NOT NULL AND i.Taf1Id IS NULL) OR (m.Taf2TypeId IS NOT NULL AND i.Taf2Id IS NULL) OR (m.Taf3TypeId IS NOT NULL AND i.Taf3Id IS NULL))`, { id });
    if (Number(bad) > 0)
      return NextResponse.json({ ok: false, error: "ردیف‌هایی بدون تفصیلی الزامی وجود دارد" }, { status: 400 });
  }

  try {
    await tx(async (run) => {
      if (action === "review") {
        await run(`UPDATE ACC.AccVoucher SET State=@to, CheckedBy=@u, CheckedAt=SYSDATETIME() WHERE VoucherId=@id AND State=@from`, { to: cfg.to, u: s.username, id, from: cfg.from });
      } else if (action === "unreview") {
        await run(`UPDATE ACC.AccVoucher SET State=@to, CheckedBy=NULL, CheckedAt=NULL WHERE VoucherId=@id AND State=@from`, { to: cfg.to, id, from: cfg.from });
      } else if (action === "finalize") {
        await run(`UPDATE ACC.AccVoucher SET State=@to, FinalizedBy=@u, FinalizedAt=SYSDATETIME() WHERE VoucherId=@id AND State=@from`, { to: cfg.to, u: s.username, id, from: cfg.from });
      }
      await run(`INSERT INTO ACC.AccVoucherFlow (VoucherId, Action, ByUser, Note) VALUES (@id, @a, @u, @n)`,
        { id, a: cfg.log, u: s.username, n: action === "review" ? "بررسی شد" : action === "unreview" ? "لغو بررسی" : "قطعی شد" });
    });
    return NextResponse.json({ ok: true });
  } catch (e: any) {
    return NextResponse.json({ ok: false, error: String(e.message || e).slice(0, 300) }, { status: 400 });
  }
}
