/* E2E لاگ سیستم (pob.UserLog) — تریگرهای پیش‌زمینه + پنجرهٔ نمایش + حذف بازه‌ای */
const BASE = process.env.E2E_BASE || "http://127.0.0.1:3200";
const HOST = "85.133.175.190", DBU = "acc_app", DBP = "Acc!2026$Web#p7Km";
let pass = 0, fail = 0; const fails = [];

function ok(name, cond, got) {
  if (cond) { pass++; console.log(`✅ ${name}`); }
  else { fail++; fails.push(name); console.log(`❌ ${name} — got ${JSON.stringify(got).slice(0, 220)}`); }
}

async function api(path, { method = "GET", body, cookie } = {}) {
  /* connection: close — جلوگیری از گیرکردن POST روی سوکت keep-alive منقضی‌شده پس از وقفهٔ sql() */
  const r = await fetch(BASE + path, {
    method, headers: { "Content-Type": "application/json", connection: "close", ...(cookie ? { cookie } : {}) },
    body: body ? JSON.stringify(body) : undefined, redirect: "manual",
  }).catch(() => null);
  if (!r) return retry(path, { method, body, cookie });
  let j = null; try { j = await r.json(); } catch { /* - */ }
  return { status: r.status, json: j, setCookie: r.headers.get("set-cookie") };
}
function retry(path, opts) {
  return new Promise((resolve) => setTimeout(async () => {
    try {
      const r2 = await fetch(BASE + path, {
        method: opts.method || "GET",
        headers: { "Content-Type": "application/json", connection: "close", ...(opts.cookie ? { cookie: opts.cookie } : {}) },
        body: opts.body ? JSON.stringify(opts.body) : undefined, redirect: "manual",
      });
      let j2 = null; try { j2 = await r2.json(); } catch { /* - */ }
      resolve({ status: r2.status, json: j2, setCookie: r2.headers.get("set-cookie") });
    } catch { resolve({ status: 0, json: null, setCookie: null }); }
  }, 500));
}
function cookieOf(r) { return (r.setCookie || "").split(";")[0]; }
function withCtx(sessCookie, ctxResp) {
  const ctxPart = (ctxResp.setCookie || "").split(";").find((c) => c.includes("acc_ctx")) || "";
  return sessCookie + "; " + ctxPart;
}

async function sql(sqlText, args) {
  const { spawnSync } = await import("child_process");
  const converted = sqlText.replace(/@(\w+)/g, "%($1)s");
  const r = spawnSync("python", ["-c", `
import pymssql, os, json
c = pymssql.connect(server='${HOST}', port=1433, user='${DBU}', password='${DBP}', database='acc', charset='UTF-8', login_timeout=15, timeout=60)
cur = c.cursor()
cur.execute(os.environ['SQLTEXT'], json.loads(os.environ['SQLARGS']))
try:
    rows = [list(map(str, r)) for r in cur.fetchall()]
except Exception:
    rows = []
c.commit(); c.close()
print(json.dumps({'rows': rows}))
`], { encoding: "utf8", env: { ...process.env, SQLTEXT: converted, SQLARGS: JSON.stringify(args || []) } });
  if (r.status !== 0) throw new Error((r.stderr || "") + (r.stdout || ""));
  return JSON.parse(r.stdout).rows;
}

async function main() {
  /* ---------- ۱) مجوزها ---------- */
  const noAuth = await api("/api/log");
  ok("لاگ بدون ورود رد می‌شود (۴۰۱)", noAuth.status === 401, noAuth.status);

  const adm = await api("/api/auth/login", { method: "POST", body: { username: "admin", password: "1234" } });
  ok("ورود مدیر", adm.json?.ok === true, adm.json);
  const AC = cookieOf(adm);
  const k1 = await api("/api/auth/login", { method: "POST", body: { username: "karbar1", password: "1234" } });
  const K1 = cookieOf(k1);
  const k2 = await api("/api/auth/login", { method: "POST", body: { username: "karbar2", password: "1234" } });
  const K2 = cookieOf(k2);

  const ctx = await api("/api/context", { cookie: AC });
  const comp = ctx.json.companies?.find((c) => c.CompanyCode === "A");
  const year = ctx.json.years?.find((y) => y.CompanyId === comp.CompanyId);
  const ctxSet = await api("/api/context", { method: "POST", cookie: AC, body: { companyId: comp.CompanyId, yearId: year.YearId } });
  const AC2 = withCtx(AC, ctxSet);
  const ctxSet1 = await api("/api/context", { method: "POST", cookie: K1, body: { companyId: comp.CompanyId, yearId: year.YearId } });
  const K12 = withCtx(K1, ctxSet1);
  const ctxSet2 = await api("/api/context", { method: "POST", cookie: K2, body: { companyId: comp.CompanyId, yearId: year.YearId } });
  const K22 = withCtx(K2, ctxSet2);

  const denied = await api("/api/log", { cookie: K12 });
  ok("لاگ برای غیرمدیر رد می‌شود (۴۰۳)", denied.status === 403, denied.status);

  /* ---------- ۲) ثبت ورود ---------- */
  const today = await sql("SELECT pob.FnLogDate()");
  const T = today[0][0];
  const loginRows = await sql(
    `SELECT UserLogId, UserName, LogDate, ComputerName, IpAddress FROM pob.UserLog
     WHERE UserName=@u AND ActivityType=4 AND LogDate=@d ORDER BY UserLogId DESC`, { u: "admin", d: T });
  ok("ورود مدیر در لاگ ثبت شد", loginRows.length >= 1, loginRows.length);
  ok("سطر ورود: تاریخ شمسی امروز", loginRows[0]?.[2] === T, loginRows[0]);
  ok("سطر ورود: IP ثبت شده", (loginRows[0]?.[4] || "") !== "", loginRows[0]?.[4]);

  /* ---------- ۳) لاگ ایجاد/ویرایش/حذف تعاریف ---------- */
  let g = await api("/api/acc/groups", { method: "POST", cookie: AC2, body: { Code: "99", Title: "گروه آزمون لاگ", AccNature: 1 } });
  if (g.status === 400) { /* از اجرای قبلی مانده */
    g = { json: { row: (await api("/api/acc/groups", { cookie: AC2 })).json.rows.find((r) => r.Code === "99") } };
  }
  const gid = g.json.row.GroupId;
  ok("ایجاد گروه آزمون", !!gid, g.json);

  const insLog = await sql(
    `SELECT DocInfo, SubSystem FROM pob.UserLog WHERE TableName='AccGroup' AND ActivityType=1 AND RecId=@id`, { id: gid });
  ok("ایجاد گروه در لاگ است", insLog.length >= 1, insLog.length);
  ok("DocInfo ایجاد: کد — عنوان", insLog[0]?.[0]?.includes("99") && insLog[0]?.[0]?.includes("گروه آزمون لاگ"), insLog[0]);

  const upd = await api("/api/acc/groups", { method: "PUT", cookie: AC2, body: { id: gid, Code: "99", Title: "گروه آزمون لاگ ویرایش", AccNature: 2 } });
  ok("ویرایش گروه انجام شد", upd.json?.ok === true, upd.json);
  const updLog = await sql(
    `SELECT FieldName, OldValue, NewValue, ActivityType FROM pob.UserLog
     WHERE TableName='AccGroup' AND RecId=@id AND ActivityType=2 ORDER BY UserLogId DESC`, { id: gid });
  const flds = updLog.map((r) => r[0]);
  ok("ویرایش: سطر فیلد Title با قبلی/جدید", flds.includes("Title"), updLog);
  const tRow = updLog.find((r) => r[0] === "Title");
  ok("مقدار قبلی/جدید Title درست است", tRow && tRow[1] === "گروه آزمون لاگ" && tRow[2] === "گروه آزمون لاگ ویرایش", tRow);
  ok("ویرایش: سطر فیلد AccNature (2→...)", flds.includes("AccNature"), updLog);

  const del = await api(`/api/acc/groups?id=${gid}`, { method: "DELETE", cookie: AC2 });
  ok("حذف گروه انجام شد", del.json?.ok === true, del.json);
  const delLog = await sql(
    `SELECT ActivityType FROM pob.UserLog WHERE TableName='AccGroup' AND RecId=@id AND ActivityType=3`, { id: gid });
  ok("حذف گروه در لاگ است", delLog.length >= 1, delLog.length);

  /* ---------- ۴) لاگ سند: ایجاد + ردیف‌ها + گذار وضعیت ---------- */
  const types = (await api("/api/vch/types", { cookie: AC2 })).json.rows;
  const generalType = types.find((t) => t.LatinTitle === "General");
  const custA = (await sql(`SELECT TafsiliId FROM ACC.AccTafsili WHERE CompanyId=@c AND Code='00000001'`, { c: comp.CompanyId }))[0][0];
  const iss = await api("/api/vch/issue", { method: "POST", cookie: AC2, body: {
    VchDate: T, VoucherTypeId: generalType.VoucherTypeId, items: [
      { KolCode: "0102", MoeinCode: "010201", Taf1Id: Number(custA), Dbt: 250000 },
      { KolCode: "0401", MoeinCode: "040101", Taf1Id: Number(custA), Crt: 250000 },
    ] } });
  ok("سند آزمون صادر شد", iss.json?.ok === true, iss.json);
  const vid = iss.json?.voucher?.VoucherId;

  const vhLog = await sql(
    `SELECT ActivityType, DocInfo FROM pob.UserLog WHERE TableName='AccVoucher' AND RecId=@id AND ActivityType=1`, { id: vid });
  ok("صدور سند در لاگ است (یک سطر)", vhLog.length === 1, vhLog.length);
  ok("DocInfo سند: شماره و تاریخ", vhLog[0]?.[1]?.includes("سند شمارهٔ") && vhLog[0]?.[1]?.includes(T), vhLog[0]);

  const viLog = await sql(
    `SELECT DocInfo FROM pob.UserLog WHERE TableName='AccVoucherItm' AND ActivityType=1
     AND UserLogId > (SELECT MAX(UserLogId) FROM pob.UserLog WHERE TableName='AccVoucher' AND RecId=@id AND ActivityType=1)`, { id: vid });
  ok("ردیف‌های سند: یک سطر تجمیعی با تعداد", viLog.length === 1 && viLog[0][0].includes("2 ردیف"), viLog);

  const rev = await api("/api/vch/transition", { method: "POST", cookie: K22, body: { id: vid, action: "review" } });
  ok("بررسی سند انجام شد", rev.json?.ok === true, rev.json);
  const stLog = await sql(
    `SELECT FieldName, OldValue, NewValue FROM pob.UserLog
     WHERE TableName='AccVoucher' AND RecId=@id AND FieldName='State' ORDER BY UserLogId DESC`, { id: vid });
  ok("گذار وضعیت در لاگ: State 1→2", stLog[0]?.[1] === "1" && stLog[0]?.[2] === "2", stLog);

  /* ---------- ۵) فیلترها ---------- */
  const L = (p) => api(`/api/log?${new URLSearchParams(p)}`, { cookie: AC });
  const byUser = await L({ user: "admin" });
  ok("فیلتر نام کاربری", byUser.json?.ok && byUser.json.rows.every((r) => r.UserName === "admin") && byUser.json.rows.length > 0, byUser.json?.total);
  const bySys = await L({ sys: "ACC" });
  ok("فیلتر سیستم", bySys.json.rows.every((r) => r.SubSystem === "ACC") && bySys.json.rows.length > 0, bySys.json?.total);
  const byAct = await L({ act: "4" });
  ok("فیلتر نوع فعالیت", byAct.json.rows.every((r) => r.ActivityType === 4) && byAct.json.rows.length > 0, byAct.json?.total);
  const empty = await L({ from: "1403/01/01", to: "1403/12/29" });
  ok("فیلتر تاریخ بدون نتیجه", empty.json?.ok && empty.json.total === 0, empty.json?.total);
  const badDate = await L({ from: "2026-01-01" });
  ok("تاریخ غیرشمسی رد می‌شود", badDate.status === 400, badDate.status);
  const pag = await L({ page: "1" });
  ok("صفحه‌بندی ۵۰ سطری", pag.json.rows.length <= 50 && pag.json.total >= pag.json.rows.length, { n: pag.json.rows.length, t: pag.json.total });
  const usersList = await L({});
  ok("لیست کاربران برای فیلتر", Array.isArray(usersList.json.users) && usersList.json.users.includes("admin"), usersList.json?.users);

  /* ---------- ۶) حذف بازه‌ای ---------- */
  await sql(`INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ActivityType, SubSystem, TableName, DocInfo)
             VALUES ('admin', '1403/05/05', '10:00:00', 1, 'ACC', 'Test', N'سطر آزمون ۱'),
                    ('admin', '1403/05/06', '10:00:00', 1, 'ACC', 'Test', N'سطر آزمون ۲')`);
  const delNoRange = await api("/api/log", { method: "DELETE", cookie: AC, body: {} });
  ok("حذف بدون بازه رد می‌شود", delNoRange.status === 400, delNoRange.status);
  const delByReg = await api("/api/log", { method: "DELETE", cookie: K12, body: { from: "1403/05/01", to: "1403/05/30" } });
  ok("حذف لاگ برای غیرمدیر رد می‌شود (۴۰۳)", delByReg.status === 403, delByReg.status);
  const delRange = await api("/api/log", { method: "DELETE", cookie: AC, body: { from: "1403/05/01", to: "1403/05/30" } });
  ok("حذف بازه‌ای انجام شد (۲ سطر)", delRange.json?.ok && delRange.json.deleted === 2, delRange.json);
  const gone = await sql(`SELECT COUNT(*) FROM pob.UserLog WHERE TableName='Test'`);
  ok("سطرهای بازه حذف شدند", Number(gone[0][0]) === 0, gone);
  const delSelfLog = await sql(
    `SELECT TOP 1 ActivityType, TableName, DocInfo FROM pob.UserLog WHERE TableName='UserLog' AND ActivityType=3 ORDER BY UserLogId DESC`);
  ok("خودِ حذف در لاگ ثبت شد", delSelfLog.length === 1 && delSelfLog[0][2].includes("سطر لاگ"), delSelfLog);

  /* ---------- ۷) خروج ---------- */
  const out = await api("/api/auth/login", { method: "DELETE", cookie: AC });
  ok("خروج انجام شد", out.json?.ok === true, out.json);
  const outLog = await sql(
    `SELECT TOP 1 ActivityType, UserName FROM pob.UserLog WHERE UserName='admin' AND ActivityType=5 ORDER BY UserLogId DESC`);
  ok("خروج در لاگ ثبت شد", outLog.length === 1, outLog);

  console.log(`\n=== E2E لاگ: ${pass} سبز، ${fail} سرخ ===`);
  if (fail) { console.log("FAILS:", fails.join(" | ")); process.exit(1); }
}

main().catch((e) => { console.error("E2E CRASH:", e); process.exit(1); });
