/* E2E اطلاعات عمومی (gnr) روی دیتابیس acc — نسخهٔ ۱ */
const BASE = process.env.E2E_BASE || "http://127.0.0.1:3200";
let pass = 0, fail = 0; const fails = [];

function ok(name, cond, got) {
  if (cond) { pass++; console.log(`✅ ${name}`); }
  else { fail++; fails.push(name); console.log(`❌ ${name} — got ${JSON.stringify(got).slice(0, 200)}`); }
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

async function main() {
  /* ورود مدیر */
  const bad = await api("/api/auth/login", { method: "POST", body: { username: "admin", password: "wrong" } });
  ok("ورود با رمز نادرست رد می‌شود", bad.status === 401 || bad.status === 400, bad.status);
  const lg = await api("/api/auth/login", { method: "POST", body: { username: "admin", password: "1234" } });
  ok("ورود مدیر", lg.json?.ok === true, lg.json);
  const ka = cookieOf(lg);

  /* --- اشخاص و شرکت‌ها --- */
  const cmp = await api("/api/gnr/crspnd", { method: "POST", cookie: ka, body: { RecType: "CMP", Title: "شرکت آزمون عمومی", CompType: 2, NationalCode: "1111222233", EconCode: "411122333", IsActive: 1 } });
  ok("ثبت شرکت", cmp.json?.ok === true, cmp.json);
  ok("ممیزی: ایجادکننده = admin", cmp.json?.row?.CreatedBy === "admin", cmp.json?.row?.CreatedBy);
  ok("ممیزی: تاریخ ایجاد شمسی پر شده", /^\d{4}\/\d{2}\/\d{2}$/.test(cmp.json?.row?.CreatedAtJ || ""), cmp.json?.row?.CreatedAtJ);
  ok("ممیزی: سیستم مبدأ = ACCWEB", cmp.json?.row?.SourceSystem === "ACCWEB", cmp.json?.row?.SourceSystem);
  const cmpId = cmp.json?.row?.Serial;

  const man = await api("/api/gnr/crspnd", { method: "POST", cookie: ka, body: { RecType: "MAN", FName: "علی", LName: "محمدی", NationalCode: "0099887766", IsActive: 1 } });
  ok("ثبت شخص حقیقی", man.json?.ok === true, man.json);
  const manId = man.json?.row?.Serial;

  const dup = await api("/api/gnr/crspnd", { method: "POST", cookie: ka, body: { RecType: "CMP", Title: "تکراری", NationalCode: "1111222233" } });
  ok("کد ملی تکراری رد می‌شود", dup.status === 400, dup.json);
  const noTitle = await api("/api/gnr/crspnd", { method: "POST", cookie: ka, body: { RecType: "CMP" } });
  ok("شرکت بدون عنوان رد می‌شود", noTitle.status === 400, noTitle.json);

  const upd = await api("/api/gnr/crspnd", { method: "PUT", cookie: ka, body: { id: cmpId, Title: "شرکت آزمون عمومی (اصلاح‌شده)" } });
  ok("اصلاح شرکت", upd.json?.ok === true, upd.json);
  const after = await api("/api/gnr/crspnd", { cookie: ka });
  const row = (after.json?.rows || []).find((r) => r.Serial === cmpId);
  ok("ممیزی ویرایش: ویرایش‌کننده = admin", row?.UpdatedBy === "admin", row?.UpdatedBy);
  ok("ممیزی ویرایش: تاریخ ویرایش شمسی", /^\d{4}\/\d{2}\/\d{2}$/.test(row?.UpdatedAtJ || ""), row?.UpdatedAtJ);

  /* --- نشانی‌ها --- */
  const addr = await api("/api/gnr/address?p=" + cmpId, { method: "POST", cookie: ka, body: { Title: "دفتر مرکزی", Address: "تهران، خیابان آزمون", ZipCode: "1234567890", Phone: "021-11112222" } });
  ok("ثبت نشانی", addr.json?.ok === true, addr.json);
  const addrList = await api(`/api/gnr/address?p=${cmpId}`, { cookie: ka });
  ok("فهرست نشانی شخص", (addrList.json?.rows || []).length >= 1, addrList.json?.rows?.length);

  /* --- طبقه‌بندی --- */
  const ctg = await api("/api/gnr/ctgry", { method: "POST", cookie: ka, body: { Title: "تأمین‌کنندگان کلیدی" } });
  ok("ثبت طبقه‌بندی", ctg.json?.ok === true, ctg.json);
  const ctgId = ctg.json?.row?.CtgryId;
  const cat = await api(`/api/gnr/crspndcat?p=${cmpId}`, { method: "POST", cookie: ka, body: { CtgryRef: ctgId } });
  ok("اختصاص طبقه‌بندی به شخص", cat.json?.ok === true, cat.json);

  /* --- موقعیت جغرافیایی --- */
  const geo = await api("/api/gnr/geopos", { method: "POST", cookie: ka, body: { Title: "شهرک صنعتی آزمون", GeoType: 4, ParentRef: 2 } });
  ok("ثبت موقعیت جغرافیایی", geo.json?.ok === true, geo.json);

  /* --- تنظیمات عمومی --- */
  const ms = await api("/api/gnr/missetup", { method: "POST", cookie: ka, body: { KeyValue: "E2E_TestKey", DataValue: "1", SystemName: "ACC", Descr: "کلید آزمون خودکار" } });
  ok("ثبت تنظیم عمومی", ms.json?.ok === true, ms.json);
  const msId = ms.json?.row?.MisSetupId;

  /* --- تعطیلات (تاریخ شمسی ملاک) --- */
  const badDate = await api("/api/gnr/holidays", { method: "POST", cookie: ka, body: { JDate: "2026-03-21", Descr: "نوروز" } });
  ok("تاریخ میلادی برای تعطیلی رد می‌شود (شمسی ملاک)", badDate.status === 400, badDate.json);
  const hol = await api("/api/gnr/holidays", { method: "POST", cookie: ka, body: { JDate: "1405/01/01", Descr: "نوروز ۱۴۰۵" } });
  ok("ثبت تعطیلی با تاریخ شمسی", hol.json?.ok === true, hol.json);
  ok("معادل میلادی خودکار = 2026-03-21", (hol.json?.row?.GDate || "").startsWith("2026-03-21"), hol.json?.row?.GDate);
  const holId = hol.json?.row?.HolidayId;

  /* --- حذف‌های محافظت‌شده --- */
  const delCmp = await api(`/api/gnr/crspnd?id=${cmpId}`, { method: "DELETE", cookie: ka });
  ok("حذف شخص دارای نشانی رد می‌شود", delCmp.status === 400, delCmp.json);
  const delCtg = await api(`/api/gnr/ctgry?id=${ctgId}`, { method: "DELETE", cookie: ka });
  ok("حذف طبقه دارای عضو رد می‌شود", delCtg.status === 400, delCtg.json);

  /* --- پاکسازی --- */
  const delAddr = await api(`/api/gnr/address?id=${addr.json?.row?.Serial}`, { method: "DELETE", cookie: ka });
  ok("حذف نشانی", delAddr.json?.ok === true, delAddr.json);
  const delCat = await api(`/api/gnr/crspndcat?id=${cmpId}`, { method: "DELETE", cookie: ka });
  ok("حذف پیوند طبقه‌بندی", delCat.json?.ok === true, delCat.json);
  const delCtg2 = await api(`/api/gnr/ctgry?id=${ctgId}`, { method: "DELETE", cookie: ka });
  ok("حذف طبقه‌بندی پس از خالی شدن", delCtg2.json?.ok === true, delCtg2.json);
  const delCmp2 = await api(`/api/gnr/crspnd?id=${cmpId}`, { method: "DELETE", cookie: ka });
  ok("حذف شرکت پس از خالی شدن", delCmp2.json?.ok === true, delCmp2.json);
  await api(`/api/gnr/crspnd?id=${manId}`, { method: "DELETE", cookie: ka });
  await api(`/api/gnr/missetup?id=${msId}`, { method: "DELETE", cookie: ka });
  await api(`/api/gnr/holidays?id=${holId}`, { method: "DELETE", cookie: ka });
  await api(`/api/gnr/geopos?id=${geo.json?.row?.GeoPosId}`, { method: "DELETE", cookie: ka });

  console.log(`\n=== ${pass} سبز / ${fail} قرمز ===`);
  if (fails.length) { console.log("خطاها:", fails.join(" | ")); process.exit(1); }
}

main().catch((e) => { console.error("FATAL:", e.message); process.exit(1); });
