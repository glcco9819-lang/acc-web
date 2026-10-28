import { NextRequest, NextResponse } from "next/server";
import { getSession } from "@/lib/auth";
import { readFileSync, writeFileSync, mkdirSync, existsSync, unlinkSync, renameSync, rmSync } from "fs";
import { join } from "path";

/* آپدیت آنلاین — خواستهٔ کارفرما: برنامه خودش نسخهٔ تازه را از گیت‌هاب می‌گیرد
   چرخه: check (مقایسهٔ نسخه) → apply (دانلود zip به update/ + نوشتن UPDATE.flag)
   → خروج سرور → run-server.cmd پس از خروج، zip را استخراج و سرویس را دوباره بالا می‌آورد */

const REPO = process.env.UPDATE_REPO || "glcco9819-lang/acc-web";
const ASSET = process.env.UPDATE_ASSET || "ACCWeb.zip";

function readVersion(): string {
  for (const p of ["version.json", "package.json"]) {
    try {
      const j = JSON.parse(readFileSync(join(process.cwd(), p), "utf8"));
      if (j.version) return j.version;
    } catch { /* next */ }
  }
  return "0.0.0";
}

async function latest(): Promise<{ tag: string; assetUrl: string | null; notes: string }> {
  const r = await fetch(`https://api.github.com/repos/${REPO}/releases/latest`, {
    headers: { "User-Agent": "acc-web-updater", Accept: "application/vnd.github+json" },
    cache: "no-store",
  });
  if (!r.ok) throw new Error(`GitHub: ${r.status}`);
  const j: any = await r.json();
  const asset = (j.assets || []).find((a: any) => a.name === ASSET);
  return { tag: String(j.tag_name || ""), assetUrl: asset ? asset.browser_download_url : null, notes: String(j.body || "") };
}

function cmp(a: string, b: string): number {
  const pa = a.replace(/^v/, "").split(".").map(Number);
  const pb = b.replace(/^v/, "").split(".").map(Number);
  for (let i = 0; i < 3; i++) { if ((pa[i] || 0) > (pb[i] || 0)) return 1; if ((pa[i] || 0) < (pb[i] || 0)) return -1; }
  return 0;
}

export async function GET() {
  const s = await getSession();
  if (!s || s.role !== "admin") return NextResponse.json({ ok: false, error: "فقط مدیر سامانه" }, { status: 403 });
  try {
    const cur = readVersion();
    const lat = await latest();
    const flag = existsSync(join(process.cwd(), "UPDATE.flag"));
    return NextResponse.json({
      ok: true, current: cur, latest: lat.tag, hasUpdate: cmp(lat.tag, cur) > 0,
      assetReady: !!lat.assetUrl, notes: lat.notes, pending: flag, repo: REPO,
    });
  } catch (e: any) {
    return NextResponse.json({ ok: false, error: `بررسی به‌روزرسانی ناموفق: ${String(e.message || e).slice(0, 200)}` }, { status: 502 });
  }
}

export async function POST(req: NextRequest) {
  const s = await getSession();
  if (!s || s.role !== "admin") return NextResponse.json({ ok: false, error: "فقط مدیر سامانه" }, { status: 403 });
  const body = await req.json().catch(() => ({}));
  const action = String(body.action || "");
  const cwd = process.cwd();

  if (action === "cancel") {
    const flag = join(cwd, "UPDATE.flag");
    if (existsSync(flag)) unlinkSync(flag);
    return NextResponse.json({ ok: true, message: "آپدیت معلق لغو شد" });
  }

  if (action === "restart") {
    /* راه‌اندازی مجدد برای نصب آپدیت معلق — خروج تمیز سرور؛ راه‌انداز (START-ACC.bat)
       پس از خروج UPDATE.flag را می‌بیند، update.ps1 بسته را نصب و سرویس را دوباره بالا می‌آورد */
    const flag = join(cwd, "UPDATE.flag");
    if (!existsSync(flag)) return NextResponse.json({ ok: false, error: "آپدیت معلق نیست" }, { status: 400 });
    setTimeout(() => { try { process.exit(0); } catch { /* - */ } }, 800);
    return NextResponse.json({ ok: true, message: "سرور تا چند ثانیه دیگر برای نصب آپدیت ری‌استارت می‌شود" });
  }

  if (action !== "apply") return NextResponse.json({ ok: false, error: "action نامعتبر" }, { status: 400 });

  try {
    const cur = readVersion();
    const lat = await latest();
    if (!lat.assetUrl) return NextResponse.json({ ok: false, error: "بستهٔ به‌روزرسانی در ریلیز یافت نشد" }, { status: 404 });
    if (cmp(lat.tag, cur) <= 0 && !body.force)
      return NextResponse.json({ ok: false, error: "نسخهٔ جاری به‌روز است" }, { status: 400 });

    const dir = join(cwd, "update");
    mkdirSync(dir, { recursive: true });
    const zipPath = join(dir, `${ASSET}`);
    const r = await fetch(lat.assetUrl, { headers: { "User-Agent": "acc-web-updater" }, cache: "no-store" });
    if (!r.ok) throw new Error(`دانلود: ${r.status}`);
    const buf = Buffer.from(await r.arrayBuffer());
    writeFileSync(zipPath, buf);

    /* اعتبارسنجی zip (PK) */
    if (buf.subarray(0, 2).toString() !== "PK") throw new Error("فایل دانلودشده zip نیست");

    writeFileSync(join(cwd, "UPDATE.flag"), JSON.stringify({
      zip: zipPath, from: cur, to: lat.tag, at: new Date().toISOString(), by: s.username,
    }, null, 2));

    return NextResponse.json({
      ok: true, message: `نسخهٔ ${lat.tag} دانلود شد (${Math.round(buf.length / 1024)}KB) — پس از «راه‌اندازی مجدد» آپدیت نصب می‌شود`,
      pending: true,
    });
  } catch (e: any) {
    return NextResponse.json({ ok: false, error: String(e.message || e).slice(0, 250) }, { status: 500 });
  }
}
