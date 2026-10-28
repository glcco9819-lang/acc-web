/* setup.js — ایجاد دیتابیس acc + اسکیما + دادهٔ پایه (اجرا روی سرور ویندوزی با node پرتابل)
   v1.4.0 — زنجیرهٔ کامل نصب تازه: 01 تا 06 (شامل لاگ فعالیت، فیلدهای سند و واژه‌نامهٔ داده) */
const sql = require("mssql");
const fs = require("fs");
const path = require("path");
const readline = require("readline");

const HOST = process.env.DB_HOST || "127.0.0.1";
const APP_USER = "acc_app", APP_PASS = "Acc!2026$Web#p7Km";

/* همهٔ فایل‌های 01 تا 06 افزایشی و Idempotent هستند — اجرای مجدد بی‌ضرر است */
const SQL_FILES = [
  "01_schema.sql",
  "02_seed.sql",
  "03_gnr.sql",
  "03b_audit.sql",
  "04_userlog.sql",
  "05_vch_fields.sql",
  "06_meta_dictionary.sql",
  "07_sample_data.sql",
  "08_review.sql",
];

function batches(file) {
  const raw = fs.readFileSync(file, "utf8");
  return raw.replace(/\r\n/g, "\n").split("\nGO").map((b) => b.trim()).filter(Boolean);
}

async function main() {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  const ask = (q) => new Promise((r) => rl.question(q, r));
  const saPass = await ask("Enter SA password: ");
  rl.close();

  const master = await new sql.ConnectionPool({ server: HOST, port: 1433, user: "sa", password: saPass, database: "master", options: { encrypt: false, trustServerCertificate: true }, requestTimeout: 120000 }).connect();
  const mreq = () => master.request();

  const db = await mreq().query("SELECT name FROM sys.databases WHERE name='acc'");
  if (db.recordset.length === 0) { await mreq().query("CREATE DATABASE [acc]"); console.log("DB acc: CREATED"); }
  else console.log("DB acc: exists");

  const lg = await mreq().query(`SELECT name FROM sys.sql_logins WHERE name='${APP_USER}'`);
  if (lg.recordset.length === 0) {
    await mreq().query(`CREATE LOGIN [${APP_USER}] WITH PASSWORD='${APP_PASS.replace(/'/g, "''")}', CHECK_POLICY=OFF`);
    console.log("login acc_app: CREATED");
  }
  await master.close();

  const acc = await new sql.ConnectionPool({ server: HOST, port: 1433, user: "sa", password: saPass, database: "acc", options: { encrypt: false, trustServerCertificate: true }, requestTimeout: 120000 }).connect();
  const areq = () => acc.request();
  const u = await areq().query(`SELECT name FROM sys.database_principals WHERE name='${APP_USER}'`);
  if (u.recordset.length === 0) {
    await areq().query(`CREATE USER [${APP_USER}] FOR LOGIN [${APP_USER}]`);
    await areq().query(`ALTER ROLE db_owner ADD MEMBER [${APP_USER}]`);
    console.log("user acc_app: db_owner");
  }

  const sqlDir = path.join(__dirname, "sql");
  for (const f of SQL_FILES) {
    const p = path.join(sqlDir, f);
    if (!fs.existsSync(p)) { console.log("MISSING:", p); process.exit(1); }
    const bs = batches(p);
    for (let i = 0; i < bs.length; i++) {
      try { await areq().query(bs[i]); }
      catch (e) { console.error(`x ${f} batch ${i+1}:`, String(e.message).slice(0, 200)); process.exit(1); }
    }
    console.log(`ok ${f} (${bs.length} batches)`);
  }
  await acc.close();
  console.log("SETUP DONE");
}

main().catch((e) => { console.error("SETUP FAILED:", String(e.message || e).slice(0, 300)); process.exit(1); });
