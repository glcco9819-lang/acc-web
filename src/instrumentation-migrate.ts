/* ============================================================================
   اجراکنندهٔ مهاجرت‌های دیتابیس هنگام بوت (v2.1.0) — فقط runtime Node
   (این فایل از instrumentation.ts داخل گارد NEXT_RUNTIME==='nodejs' ایمپورت می‌شود)
   تا پیش از v2.1.0 آپدیت آنلاین فقط بستهٔ برنامه را عوض می‌کرد و فایل‌های sql/
   هرگز روی دیتابیس مشتری اجرا نمی‌شدند. اکنون پس از هر آپدیت/راه‌اندازی،
   فایل‌های مهاجرتِ هنوز اعمال‌نشده (به‌ترتیب شماره) اجرا و در pob.AppliedMigration
   ثبت می‌شوند. همهٔ فایل‌های 01→08 افزایشی و Idempotent هستند — اجرای مجدد بی‌ضرر.
   ============================================================================ */

const MIGRATION_EXCLUDE = new Set([
  "07_sample_data.sql",        /* دادهٔ نمونه فقط برای نصب تازه (setup.js) */
  "10_snapshot_v1.2.0.sql",    /* مهاجرت‌های یک‌بارهٔ v1.2.0 — مسیر قدیمی */
  "11_datacopy_v1.2.0.sql",
  "12_dropold_v1.2.0.sql",
]);

export function scheduleMigrations() {
  setTimeout(() => { runMigrations().catch((e) => console.log("[migrate] خطای غیرمنتظره:", String(e?.message || e).slice(0, 200))); }, 10_000);
}

async function runMigrations(): Promise<void> {
  console.log("[migrate] شروع بررسی مهاجرت‌ها…");
  const fs = await import("fs");
  const path = await import("path");
  const cwd = process.cwd();
  /* پوشهٔ sql: داخل خود app (بستهٔ تازه) یا ریشهٔ نصب (یک پوشه بالاتر) */
  const candidates = [path.join(cwd, "sql"), path.join(cwd, "..", "sql")];
  const dir = candidates.find((d) => fs.existsSync(d));
  if (!dir) return;
  const files = fs.readdirSync(dir)
    .filter((f) => /^\d{2}[a-z]?_.*\.sql$/i.test(f) && !MIGRATION_EXCLUDE.has(f))
    .sort();
  if (!files.length) return;

  try {
    const { getPool } = await import("./lib/db");
    const pool = await getPool();
    /* جدول ثبت — با اتصال خام بدون پیشوند کانتکست (DDL) */
    {
      const r = pool.request();
      await r.query(`IF OBJECT_ID('pob.AppliedMigration') IS NULL
             CREATE TABLE pob.AppliedMigration (
               Name varchar(100) NOT NULL CONSTRAINT PK_AppliedMigration PRIMARY KEY,
               AppliedAt datetime2(0) NOT NULL CONSTRAINT DF_AppliedMigration_At DEFAULT(SYSUTCDATETIME())
             )`);
    }
    const doneRows = await new Promise<any[]>((resolve, reject) => {
      pool.request().query(`SELECT Name FROM pob.AppliedMigration`).then((x: any) => resolve(x.recordset || [])).catch(reject);
    });
    const done = new Set(doneRows.map((r: any) => String(r.Name)));

    for (const f of files) {
      if (done.has(f)) continue;
      const raw = fs.readFileSync(path.join(dir, f), "utf8").replace(/\r\n/g, "\n");
      /* دستور USE — اتصال از قبل به دیتابیس درست (db-config) است */
      const batches = raw.split("\nGO")
        .map((b) => b.split("\n").filter((l) => !/^\s*USE\s/i.test(l)).join("\n").trim())
        .filter(Boolean);
      let ok = 0, bad = 0;
      for (const b of batches) {
        try { await pool.request().query(b); ok += 1; }
        catch (e: any) {
          bad += 1;
          console.log(`[migrate] ${f} — خطا در یک دسته: ${String(e?.message || e).slice(0, 200)}`);
        }
      }
      /* فقط وقتی همهٔ دسته‌ها سالم بود ثبت می‌شود تا بار بعد دوباره تلاش شود (فایل‌ها Idempotent اند) */
      if (bad === 0) {
        await pool.request().input("n", f).query(`INSERT INTO pob.AppliedMigration (Name) VALUES (@n)`);
        console.log(`[migrate] ${f} اجرا شد (${ok}/${batches.length} دسته)`);
      } else {
        console.log(`[migrate] ${f} ناقص — ${ok}/${batches.length} دسته موفق، ${bad} خطا؛ در راه‌اندازی بعدی دوباره تلاش می‌شود`);
      }
    }
  } catch (e: any) {
    console.log(`[migrate] اجرای مهاجرت‌ها ناموفق: ${String(e?.message || e).slice(0, 200)}`);
  }
}
