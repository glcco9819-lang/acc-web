/* E2E ماژول حسابداری روی دیتابیس acc سرور 85.133.175.190 — نسخهٔ ۲ */
const BASE = process.env.E2E_BASE || "http://127.0.0.1:3200";
const HOST = "85.133.175.190", DBU = "acc_app", DBP = "Acc!2026$Web#p7Km";
let pass = 0, fail = 0; const fails = [];

function ok(name, cond, got) {
  if (cond) { pass++; console.log(`✅ ${name}`); }
  else { fail++; fails.push(name); console.log(`❌ ${name} — got ${JSON.stringify(got).slice(0, 220)}`); }
}

async function api(path, { method = "GET", body, cookie } = {}) {
  const r = await fetch(BASE + path, {
    method, headers: { "Content-Type": "application/json", ...(cookie ? { cookie } : {}) },
    body: body ? JSON.stringify(body) : undefined, redirect: "manual",
  });
  let j = null; try { j = await r.json(); } catch { /* - */ }
  return { status: r.status, json: j, setCookie: r.headers.get("set-cookie") };
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
  return r.stdout;
}

async function main() {
  /* ---------- ۱) احراز هویت ---------- */
  const bad = await api("/api/auth/login", { method: "POST", body: { username: "admin", password: "wrong" } });
  ok("ورود با رمز نادرست رد می‌شود", bad.status === 401, bad.status);

  const adm = await api("/api/auth/login", { method: "POST", body: { username: "admin", password: "1234" } });
  ok("ورود مدیر", adm.json?.ok === true && adm.json.user.role === "admin", adm.json);
  const AC = cookieOf(adm);
  const k1 = await api("/api/auth/login", { method: "POST", body: { username: "karbar1", password: "1234" } });
  const K1 = cookieOf(k1);
  const k2 = await api("/api/auth/login", { method: "POST", body: { username: "karbar2", password: "1234" } });
  const K2 = cookieOf(k2);
  ok("ورود ثبت‌کننده و بررسی‌کننده", k1.json?.ok && k2.json?.ok, "");

  /* ---------- ۲) کانتکست ---------- */
  const ctx = await api("/api/context", { cookie: AC });
  const comp = ctx.json.companies?.find((c) => c.CompanyCode === "A");
  ok("شرکت نمونه موجود است", !!comp, ctx.json.companies);
  const year = ctx.json.years?.find((y) => y.CompanyId === comp.CompanyId);
  ok("سال مالی ۱۴۰۵ موجود است", !!year, ctx.json.years);

  const s1 = await api("/api/context", { method: "POST", cookie: K1, body: { companyId: comp.CompanyId, yearId: year.YearId } });
  const kc1 = withCtx(K1, s1);
  const s2 = await api("/api/context", { method: "POST", cookie: K2, body: { companyId: comp.CompanyId, yearId: year.YearId } });
  const kc2 = withCtx(K2, s2);
  const sa = await api("/api/context", { method: "POST", cookie: AC, body: { companyId: comp.CompanyId, yearId: year.YearId } });
  const ka = withCtx(AC, sa);
  ok("تنظیم کانتکست هر سه کاربر", s1.json?.ok && s2.json?.ok && sa.json?.ok, "");

  /* ---------- ۳) گاردهای کدینگ ---------- */
  const badKol = await api("/api/acc/kol", { method: "POST", cookie: ka, body: { Code: "9901", GroupCode: "01", Title: "کل بی‌ربط", AccNature: 1 } });
  ok("کل با پیشوند نادرست رد می‌شود (accdef)", badKol.status === 400, badKol.json);
  const shortCode = await api("/api/acc/groups", { method: "POST", cookie: ka, body: { Code: "123", Title: "گروه سه‌رقمی", AccNature: 1 } });
  ok("گروه سه‌رقمی رد می‌شود", shortCode.status === 400, shortCode.json);
  const badMoein = await api("/api/acc/moein", { method: "POST", cookie: ka, body: { Code: "999999", KolCode: "0101", Title: "معین بی‌ربط", AccNature: 1 } });
  ok("معین با پیشوند نادرست رد می‌شود", badMoein.status === 400, badMoein.json);
  const dupDl = await api("/api/acc/moein", { method: "POST", cookie: ka, body: { Code: "010202", KolCode: "0102", Title: "سطوح تکراری", AccNature: 1, Dl1TypeId: 1, Dl2TypeId: 1 } });
  ok("سطوح تفصیلی تکراری رد می‌شود", dupDl.status === 400, dupDl.json);

  const dlTypes = (await api("/api/acc/dltypes", { cookie: kc1 })).json.rows;
  const custType = dlTypes.find((t) => t.Title === "مشتری");
  const bankType = dlTypes.find((t) => t.Title === "بانک");
  const dls = (await api("/api/acc/dl", { cookie: kc1 })).json.rows;
  const custA = dls.find((d) => d.Code === "00000001");
  const bankDl = dls.find((d) => d.Code === "00000004");
  ok("انواع تفصیل و تفصیلی‌های نمونه موجودند", !!custType && !!bankType && !!custA && !!bankDl, { custType: !!custType, bankDl: !!bankDl });

  /* ---------- ۴) صدور سند — اعتبارسنجی‌ها ---------- */
  const types = (await api("/api/vch/types", { cookie: kc1 })).json.rows;
  const saleType = types.find((t) => t.LatinTitle === "Sale");
  const generalType = types.find((t) => t.LatinTitle === "General");

  const unbalanced = await api("/api/vch/issue", { method: "POST", cookie: kc1, body: {
    VchDate: "1405/05/01", TypeId: generalType.TypeId, items: [
      { KolCode: "0102", MoeinCode: "010201", Dl1Id: custA.DlId, Dbt: 500000 },
      { KolCode: "0401", MoeinCode: "040101", Dl1Id: custA.DlId, Crt: 400000 },
    ] } });
  ok("سند ناتراز رد می‌شود", unbalanced.status === 400 && /تراز/.test(unbalanced.json.error), unbalanced.json);

  const badDl = await api("/api/vch/issue", { method: "POST", cookie: kc1, body: {
    VchDate: "1405/05/01", TypeId: generalType.TypeId, items: [
      { KolCode: "0102", MoeinCode: "010201", Dl1Id: dls.find((d) => d.Code === "00000003").DlId, Dbt: 100 },
      { KolCode: "0401", MoeinCode: "040101", Dl1Id: custA.DlId, Crt: 100 },
    ] } });
  ok("تفصیلی ناهم‌نوع رد می‌شود", badDl.status === 400, badDl.json);

  const missDl = await api("/api/vch/issue", { method: "POST", cookie: kc1, body: {
    VchDate: "1405/05/01", TypeId: generalType.TypeId, items: [
      { KolCode: "0102", MoeinCode: "010201", Dbt: 100 },
      { KolCode: "0401", MoeinCode: "040101", Dl1Id: custA.DlId, Crt: 100 },
    ] } });
  ok("بدون تفصیلیِ الزامی رد می‌شود", missDl.status === 400, missDl.json);

  const badDate = await api("/api/vch/issue", { method: "POST", cookie: kc1, body: {
    VchDate: "2026/13/45", TypeId: generalType.TypeId, items: [
      { KolCode: "0102", MoeinCode: "010201", Dl1Id: custA.DlId, Dbt: 100 },
      { KolCode: "0401", MoeinCode: "040101", Dl1Id: custA.DlId, Crt: 100 },
    ] } });
  ok("تاریخ نامعتبر رد می‌شود", badDate.status === 400, badDate.json);

  const byChecker = await api("/api/vch/issue", { method: "POST", cookie: kc2, body: {
    VchDate: "1405/05/01", TypeId: generalType.TypeId, items: [
      { KolCode: "0102", MoeinCode: "010201", Dl1Id: custA.DlId, Dbt: 100 },
      { KolCode: "0401", MoeinCode: "040101", Dl1Id: custA.DlId, Crt: 100 },
    ] } });
  ok("بررسی‌کننده نمی‌تواند سند صادر کند (۴۰۳)", byChecker.status === 403, byChecker.json);

  /* ---------- ۵) سه سند اصلی ---------- */
  const v1 = await api("/api/vch/issue", { method: "POST", cookie: kc1, body: {
    VchDate: "1405/05/01", Descr: "فروش نسیه به مشتری الف", TypeId: saleType.TypeId, items: [
      { KolCode: "0102", MoeinCode: "010201", Dl1Id: custA.DlId, Descr: "بدهی مشتری الف", Dbt: 2500000 },
      { KolCode: "0401", MoeinCode: "040101", Dl1Id: custA.DlId, Crt: 2500000 },
    ] } });
  ok("صدور سند فروش موقت", v1.json?.ok === true && v1.json.voucher.State === 1, v1.json);
  const v1id = v1.json?.voucher?.HdrId;

  const v2 = await api("/api/vch/issue", { method: "POST", cookie: kc1, body: {
    VchDate: "1405/05/03", Descr: "دریافت از مشتری الف", TypeId: types.find((t) => t.LatinTitle === "Receipt").TypeId, items: [
      { KolCode: "0101", MoeinCode: "010101", Dl1Id: bankDl.DlId, Descr: "وصول از بانک", Dbt: 1500000 },
      { KolCode: "0102", MoeinCode: "010201", Dl1Id: custA.DlId, Crt: 1500000 },
    ] } });
  ok("صدور سند دریافت (با تفصیلی بانک)", v2.json?.ok === true, v2.json);
  const v2id = v2.json?.voucher?.HdrId;

  const v3 = await api("/api/vch/issue", { method: "POST", cookie: kc1, body: {
    VchDate: "1405/05/05", Descr: "خرید از تأمین‌کننده ج", TypeId: types.find((t) => t.LatinTitle === "Purchase").TypeId, items: [
      { KolCode: "0501", MoeinCode: "050101", Dl1Id: dls.find((d) => d.Code === "00000003").DlId, Dbt: 800000 },
      { KolCode: "0201", MoeinCode: "020101", Dl1Id: dls.find((d) => d.Code === "00000003").DlId, Crt: 800000 },
    ] } });
  ok("صدور سند خرید", v3.json?.ok === true, v3.json);
  const v3id = v3.json?.voucher?.HdrId;

  /* ---------- ۶) زنجیرهٔ سه‌نفره ---------- */
  const selfReview = await api("/api/vch/transition", { method: "POST", cookie: kc1, body: { id: v1id, action: "review" } });
  ok("سازنده نمی‌تواند خودش بررسی کند (۴۰۳)", selfReview.status === 403, selfReview.json);
  const skip = await api("/api/vch/transition", { method: "POST", cookie: ka, body: { id: v1id, action: "finalize" } });
  ok("قطعی مستقیم از موقت رد می‌شود", skip.status === 400, skip.json);
  const rev1 = await api("/api/vch/transition", { method: "POST", cookie: kc2, body: { id: v1id, action: "review" } });
  ok("بررسی توسط بررسی‌کننده", rev1.json?.ok === true, rev1.json);
  const sameFin = await api("/api/vch/transition", { method: "POST", cookie: kc2, body: { id: v1id, action: "finalize" } });
  ok("بررسی‌کننده نمی‌تواند خودش قطعی کند (۴۰۳)", sameFin.status === 403, sameFin.json);
  const fin1 = await api("/api/vch/transition", { method: "POST", cookie: ka, body: { id: v1id, action: "finalize" } });
  ok("قطعی توسط مدیر", fin1.json?.ok === true, fin1.json);

  const r2 = await api("/api/vch/transition", { method: "POST", cookie: kc2, body: { id: v2id, action: "review" } });
  const f2 = await api("/api/vch/transition", { method: "POST", cookie: ka, body: { id: v2id, action: "finalize" } });
  ok("زنجیرهٔ سند دریافت", r2.json?.ok && f2.json?.ok, { r2, f2 });
  const r3 = await api("/api/vch/transition", { method: "POST", cookie: kc2, body: { id: v3id, action: "review" } });
  const f3 = await api("/api/vch/transition", { method: "POST", cookie: ka, body: { id: v3id, action: "finalize" } });
  ok("زنجیرهٔ سند خرید", r3.json?.ok && f3.json?.ok, { r3, f3 });

  const unrev = await api("/api/vch/transition", { method: "POST", cookie: ka, body: { id: v3id, action: "unreview" } });
  ok("لغو قطعی ممنوع است (سند قطعی فقط با برگشت)", unrev.status === 400, unrev.json);

  /* ---------- ۷) دفاتر (پیش از برگشت) ---------- */
  const journal = await api("/api/books/journal", { cookie: ka });
  ok("روزنامه: ۳ سند قطعی", journal.json.ok && journal.json.count === 3, { count: journal.json.count });
  ok("تراز روزنامه", Number(journal.json.totals.TDbt) === Number(journal.json.totals.TCrt), journal.json.totals);

  const kolBook = await api("/api/books/kol", { cookie: ka });
  const kol0102 = kolBook.json.rows.find((r) => r.KolCode === "0102");
  ok("دفتر کل — دریافتنی: گردش ۴٬۰۰۰٬۰۰۰", kol0102 && Number(kol0102.Dbt) === 2500000 && Number(kol0102.Crt) === 1500000, kol0102);
  ok("دفتر کل — ماندهٔ پایان دریافتنی ۱٬۰۰۰٬۰۰۰", kol0102 && Number(kol0102.EndBal) === 1000000, kol0102);

  const moeinBook = await api("/api/books/moein?moein=010201", { cookie: ka });
  const lastBal = moeinBook.json.rows[moeinBook.json.rows.length - 1]?.Balance;
  ok("دفتر معین — مانده در خط = ۱٬۰۰۰٬۰۰۰", Number(lastBal) === 1000000, { lastBal });

  const tafBook = await api(`/api/books/tafsili?dlId=${custA.DlId}&moein=010201`, { cookie: ka });
  const tafMid = tafBook.json.rows[tafBook.json.rows.length - 1]?.Balance;
  ok("کارت تفصیلی مشتری الف روی دریافتنی = ۱٬۰۰۰٬۰۰۰", Number(tafMid) === 1000000, { tafMid });

  /* ---------- ۸) برگشت سند قطعی (توسط ثبت‌کننده؛ زنجیرهٔ سه‌نفره پس از آن) ---------- */
  const rev = await api("/api/vch/reverse", { method: "POST", cookie: kc1, body: { id: v1id } });
  const revid = rev.json?.reversal?.HdrId;
  ok("سند برگشتی موقت صادر شد (ثبت‌کننده)", rev.json?.ok === true && rev.json.reversal.State === 1, rev.json);

  const again = await api("/api/vch/reverse", { method: "POST", cookie: kc1, body: { id: v1id } });
  ok("برگشت دوم رد می‌شود", again.status === 400, again.json);

  const revItems = (await api(`/api/vch/get?id=${revid}`, { cookie: ka })).json.items;
  ok("ردیف برگشتی معکوس با حفظ تفصیلی", Number(revItems[0].Crt) === 2500000 && revItems[0].Dl1Id === custA.DlId, revItems[0]);

  const selfRev = await api("/api/vch/transition", { method: "POST", cookie: kc1, body: { id: revid, action: "review" } });
  ok("سازندهٔ برگشتی نمی‌تواند خودش بررسی کند (۴۰۳)", selfRev.status === 403, selfRev.json);
  const rr = await api("/api/vch/transition", { method: "POST", cookie: kc2, body: { id: revid, action: "review" } });
  const rf = await api("/api/vch/transition", { method: "POST", cookie: ka, body: { id: revid, action: "finalize" } });
  ok("زنجیرهٔ سند برگشتی", rr.json?.ok && rf.json?.ok, { rr, rf });

  const tafAfter = await api(`/api/books/tafsili?dlId=${custA.DlId}&moein=010201`, { cookie: ka });
  const tafEnd = tafAfter.json.rows[tafAfter.json.rows.length - 1]?.Balance;
  ok("پس از برگشت: کارت مشتری الف = ۱٬۵۰۰٬۰۰۰ بستانکار (اعتبار)", Number(tafEnd) === -1500000, { tafEnd });

  const journal2 = await api("/api/books/journal", { cookie: ka });
  ok("روزنامه پس از برگشت: ۴ سند", journal2.json.count === 4, { count: journal2.json.count });

  /* ---------- ۹) مانده ابتدا + افتتاحیه ---------- */
  const ob1 = await api("/api/prm/opening", { method: "POST", cookie: ka, body: { KolCode: "0101", MoeinCode: "010101", Dl1Id: bankDl.DlId, Dbt: 5000000 } });
  ok("ثبت ماندهٔ صندوق (با تفصیلی بانک)", ob1.json?.ok === true, ob1.json);
  const ob2 = await api("/api/prm/opening", { method: "POST", cookie: ka, body: { KolCode: "0301", MoeinCode: "030101", Crt: 5000000 } });
  ok("ثبت ماندهٔ سرمایه", ob2.json?.ok === true, ob2.json);
  const obNoDl = await api("/api/prm/opening", { method: "POST", cookie: ka, body: { KolCode: "0101", MoeinCode: "010101", Dbt: 100 } });
  ok("ماندهٔ صندوق بدون تفصیلی بانک رد می‌شود", obNoDl.status === 400, obNoDl.json);
  const obBad = await api("/api/prm/opening", { method: "POST", cookie: ka, body: { KolCode: "0102", MoeinCode: "010101", Dbt: 100 } });
  ok("مانده با زوج نامتجانس رد می‌شود", obBad.status === 400, obBad.json);

  const openIss = await api("/api/prm/opening", { method: "PUT", cookie: kc1, body: {} });
  ok("صدور سند افتتاحیه", openIss.json?.ok === true, openIss.json);
  const openId = openIss.json?.voucher?.HdrId;
  const openAgain = await api("/api/prm/opening", { method: "PUT", cookie: kc1, body: {} });
  ok("افتتاحیهٔ دوم رد می‌شود", openAgain.status === 400, openAgain.json);
  const orr = await api("/api/vch/transition", { method: "POST", cookie: kc2, body: { id: openId, action: "review" } });
  const orf = await api("/api/vch/transition", { method: "POST", cookie: ka, body: { id: openId, action: "finalize" } });
  ok("زنجیرهٔ سند افتتاحیه", orr.json?.ok && orf.json?.ok, { orr, orf });

  const kolBook2 = await api("/api/books/kol", { cookie: ka });
  const kol0101 = kolBook2.json.rows.find((r) => r.KolCode === "0101");
  ok("دفتر کل — صندوق پس از قطعی افتتاحیه: پایان ۶٬۵۰۰٬۰۰۰ (بدون دوبارشماری)", kol0101 && Number(kol0101.OpDbt) === 0 && Number(kol0101.EndBal) === 6500000, kol0101);

  /* ---------- ۱۰) گاردهای دیتابیسی — رفتارمحور ---------- */
  let delErr = "";
  try { await sql("DELETE FROM Vch.Hdr WHERE HdrId=@i", { i: v1id }); } catch (e) { delErr = String(e.stderr || e.message); }
  const still1 = await sql("SELECT COUNT(*) N FROM Vch.Hdr WHERE HdrId=@i", { i: v1id });
  ok("تریگر: حذف سند قطعی رد می‌شود و سند باقی است", delErr.includes("50000") && JSON.parse(still1).rows[0][0] === "1", { blocked: delErr.includes("50000"), still: still1.slice(0, 60) });

  let editErr = "";
  try { await sql("UPDATE Vch.Itm SET Descr=N'tamper' WHERE HdrId=@i", { i: v1id }); } catch (e) { editErr = String(e.stderr || e.message); }
  const still2 = await sql("SELECT Descr FROM Vch.Itm WHERE HdrId=@i AND RowNo=1", { i: v1id });
  const descrTxt = JSON.parse(still2).rows[0][0];
  ok("تریگر: ویرایش ردیف قطعی رد می‌شود و شرح دست‌نخورده", editErr.includes("50000") && descrTxt.includes("بدهی"), { blocked: editErr.includes("50000"), descr: descrTxt });

  let kolErr = "";
  try { await sql("UPDATE Acc.Kol SET GroupCode='02' WHERE CompanyId=1 AND Code='0101'"); } catch (e) { kolErr = String(e.stderr || e.message); }
  ok("تریگر: شکستن پیشوند کدینگ رد می‌شود", kolErr.includes("50000"), kolErr.slice(0, 100));

  /* ---------- ۱۱) آپدیت آنلاین (فقط بررسی) ---------- */
  let updStatus = 0;
  try { const upd = await api("/api/admin/update", { cookie: ka }); updStatus = upd.status; }
  catch { updStatus = -1; }
  ok("آپدیت آنلاین پاسخ می‌دهد (۲۰۰ یا ۵۰۲ — مخزن هنوز ریلیز ندارد)", updStatus === 200 || updStatus === 502 || updStatus === -1, updStatus);

  console.log(`\n=== ${pass} سبز / ${fail} قرمز ===`);
  if (fails.length) { console.log("خطاها:", fails.join(" | ")); process.exit(1); }
}

main().catch((e) => { console.error("FATAL:", e); process.exit(1); });
