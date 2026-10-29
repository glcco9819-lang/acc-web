/* آپدیت خودکار پس‌زمینه — خواستهٔ کارفرما: «امکان آپدیت آنلاین تا خودت بتونی برنامه اپدیت کنی»
   هر ۱۵ دقیقه: بررسی ریلیز تازهٔ گیت‌هاب → اگر نسخه بالاتر بود:
   دانلود بسته به update/ + نوشتن UPDATE.flag + خروج تمیز سرور
   (راه‌انداز START-ACC.bat پس از خروج، بسته را نصب و سرویس را دوباره بالا می‌آورد) */

const REPO = process.env.UPDATE_REPO || "glcco9819-lang/acc-web";
const ASSET = process.env.UPDATE_ASSET || "ACCWeb.zip";
const INTERVAL_MS = 15 * 60 * 1000;
const FIRST_DELAY_MS = 90 * 1000;

export async function register() {
  console.log("[instrumentation] register() — runtime:", process.env.NEXT_RUNTIME);
  if (process.env.NEXT_RUNTIME !== "nodejs") return;

  /* v2.4.0 — خودترمیمی نصب‌کننده: جایگزینی update.ps1 قدیمی پوشهٔ ریشه با نسخهٔ مقاوم
     همراه همین بسته (app/update-latest.ps1). اسکریپت قدیمی هنگام قفل لحظه‌ای فایل
     شکست می‌خورد و نصب نیمه‌کاره می‌گذاشت؛ نسخهٔ جدید ۵ بار تلاش می‌کند.
     هر بار برنامه بالا می‌آید، اگر نسخهٔ ریشه قدیمی/خراب باشد به‌روز می‌شود. */
  try {
    const fs = await import("fs");
    const path = await import("path");
    const cwd = process.cwd();
    for (const [srcName, dstName] of [["update-latest.ps1", "update.ps1"], ["fix-update-latest.ps1", "fix-update.ps1"]] as const) {
      const src = path.join(cwd, "app", srcName);
      const dst = path.join(cwd, dstName);
      if (!fs.existsSync(src)) continue;
      const buf = fs.readFileSync(src);
      let need = true;
      try { need = !fs.readFileSync(dst).equals(buf); } catch { need = true; }
      if (need) {
        fs.writeFileSync(dst, buf);
        console.log(`[self-heal] ${dstName} به نسخهٔ همراه بسته به‌روز شد`);
      }
    }
  } catch (e: any) {
    console.log(`[self-heal] رد شد: ${String(e.message || e).slice(0, 100)}`);
  }

  /* مهاجرت‌های دیتابیس هنگام بوت — v2.1.0
     تا پیش از این، آپدیت آنلاین فقط بستهٔ برنامه را عوض می‌کرد و فایل‌های sql/
     هرگز روی دیتابیس مشتری اجرا نمی‌شدند. اکنون پس از هر آپدیت/راه‌اندازی،
     فایل‌های مهاجرتِ هنوز اعمال‌نشده (به‌ترتیب شماره) اجرا و ثبت می‌شوند. */
  if (process.env.NEXT_RUNTIME === "nodejs") {
    const { scheduleMigrations } = await import("./instrumentation-migrate");
    scheduleMigrations();
  }

  if (process.env.AUTO_UPDATE === "off") return;

  const run = async () => {
    try {
      const fs = await import("fs");
      const path = await import("path");
      const cwd = process.cwd();

      /* نسخهٔ جاری */
      let cur = "0.0.0";
      for (const p of ["version.json", "package.json"]) {
        try { const j = JSON.parse(fs.readFileSync(path.join(cwd, p), "utf8")); if (j.version) { cur = j.version; break; } } catch { /* - */ }
      }

      /* آپدیت معلق؟ فقط صبر برای ری‌استارت — دوباره دانلود نکن */
      if (fs.existsSync(path.join(cwd, "UPDATE.flag"))) return;

      const r = await fetch(`https://api.github.com/repos/${REPO}/releases/latest`, {
        headers: { "User-Agent": "acc-web-autoupdate", Accept: "application/vnd.github+json" },
        cache: "no-store",
      });
      if (!r.ok) return;
      const j: any = await r.json();
      const tag = String(j.tag_name || "");
      const asset = (j.assets || []).find((a: any) => a.name === ASSET);
      if (!tag || !asset) return;

      const cmp = (a: string, b: string) => {
        const pa = a.replace(/^v/, "").split(".").map(Number), pb = b.replace(/^v/, "").split(".").map(Number);
        for (let i = 0; i < 3; i++) { if ((pa[i] || 0) > (pb[i] || 0)) return 1; if ((pa[i] || 0) < (pb[i] || 0)) return -1; }
        return 0;
      };
      if (cmp(tag, cur) <= 0) return;

      /* دانلود بستهٔ تازه */
      console.log(`[auto-update] نسخهٔ تازه ${tag} یافت شد (جاری ${cur}) — دانلود...`);
      const d = await fetch(asset.browser_download_url, { headers: { "User-Agent": "acc-web-autoupdate" }, cache: "no-store" });
      if (!d.ok) return;
      const buf = Buffer.from(await d.arrayBuffer());
      if (buf.subarray(0, 2).toString() !== "PK") return; /* zip نامعتبر */

      const dir = path.join(cwd, "update");
      fs.mkdirSync(dir, { recursive: true });
      fs.writeFileSync(path.join(dir, ASSET), buf);
      fs.writeFileSync(path.join(cwd, "UPDATE.flag"), JSON.stringify({
        zip: path.join(dir, ASSET), from: cur, to: tag, at: new Date().toISOString(), by: "auto-update",
      }, null, 2));
      console.log(`[auto-update] بستهٔ ${tag} دانلود شد (${Math.round(buf.length / 1024)}KB) — خروج برای نصب...`);
      setTimeout(() => { try { process.exit(0); } catch { /* - */ } }, 1500);
    } catch (e: any) {
      console.log(`[auto-update] بررسی ناموفق: ${String(e.message || e).slice(0, 120)}`);
    }
  };

  setTimeout(run, FIRST_DELAY_MS);
  setInterval(run, INTERVAL_MS);
}
