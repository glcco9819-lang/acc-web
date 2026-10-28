/* ============================================================================
   YFG ACC-WEB — 07_sample_data.sql (اختیاری) — نسخهٔ 2.0.0
   دموی کامل «از صفر تا صد» در یک شرکت مستقل دوم (کد B) — دادهٔ واقعی‌نما:
   کدینگ استاندارد ترازنامه‌ای، ماندهٔ ابتدای دوره، ۹ سند واقع‌گرایانه
   (فروش نقدی/نسیه + مالیات بر ارزش افزوده، خرید، واریز/پرداخت، بهای تمام‌شده،
   هزینه‌ها، سند ارزی، هزینهٔ بانکی با پیگیری) در سه وضعیت موقت/بررسی‌شده/قطعی
   تا همهٔ دفاتر و ترازها بلافاصله دادهٔ زنده داشته باشند.
   * به دادهٔ شرکت واقعی (کد A) هیچ چیز اضافه نمی‌کند — کاملاً Idempotent.
   ============================================================================ */

/* ---------- شرکت دمو (مستقل از شرکت‌های موجود) ---------- */
IF NOT EXISTS (SELECT 1 FROM pob.Companies WHERE CompanyCode = N'B')
INSERT INTO pob.Companies (CompanyCode, TitleFa, NationalId, EconomicCode, CodingMode)
VALUES (N'B', N'شرکت نمونهٔ ب (دموی کامل)', N'10861234567', N'411987654', 2);
GO

DECLARE @c smallint = (SELECT CompanyId FROM pob.Companies WHERE CompanyCode = N'B');

/* ---------- سال مالی + دوره‌ها ---------- */
IF NOT EXISTS (SELECT 1 FROM pob.FiscalYear WHERE CompanyId = @c AND JalaliYear = 1405)
BEGIN
  INSERT INTO pob.FiscalYear (CompanyId, JalaliYear, Title, StartDate, EndDate)
  VALUES (@c, 1405, N'سال مالی ۱۴۰۵ (دمو)', '1405/01/01', '1405/12/29');
  INSERT INTO pob.FiscalPeriod (YearId, MonthNo, Title)
  SELECT y.YearId, p.MonthNo, p.Title
  FROM pob.FiscalYear y, (VALUES (1,N'فروردین'),(2,N'اردیبهشت'),(3,N'خرداد'),(4,N'تیر'),(5,N'مرداد'),(6,N'شهریور'),
    (7,N'مهر'),(8,N'آبان'),(9,N'آذر'),(10,N'دی'),(11,N'بهمن'),(12,N'اسفند')) p(MonthNo, Title)
  WHERE y.CompanyId = @c AND y.JalaliYear = 1405;
END
GO

DECLARE @c smallint = (SELECT CompanyId FROM pob.Companies WHERE CompanyCode = N'B');
DECLARE @y smallint = (SELECT YearId FROM pob.FiscalYear WHERE CompanyId = @c AND JalaliYear = 1405);

/* ---------- انواع سند ---------- */
IF NOT EXISTS (SELECT 1 FROM ACC.AccVoucherType WHERE CompanyId = @c)
INSERT INTO ACC.AccVoucherType (CompanyId, Title, LatinTitle) VALUES
 (@c, N'همکار', 'General'),
 (@c, N'فروش', 'Sales'),
 (@c, N'خرید', 'Purchase'),
 (@c, N'هزینه', 'Expense'),
 (@c, N'افتتاحیه', 'Opening');
GO

DECLARE @c smallint = (SELECT CompanyId FROM pob.Companies WHERE CompanyCode = N'B');

/* ---------- انواع تفصیل ---------- */
IF NOT EXISTS (SELECT 1 FROM ACC.AccTafsiliType WHERE CompanyId = @c)
INSERT INTO ACC.AccTafsiliType (CompanyId, Title, LatinTitle) VALUES
 (@c, N'مشتری', 'Customer'),
 (@c, N'تأمین‌کننده', 'Supplier'),
 (@c, N'بانک', 'Bank'),
 (@c, N'پروژه', 'Project');
GO

DECLARE @c smallint = (SELECT CompanyId FROM pob.Companies WHERE CompanyCode = N'B');

/* ---------- تفصیلی‌ها (کد ۸ رقم — یکتا در شرکت) ---------- */
IF NOT EXISTS (SELECT 1 FROM ACC.AccTafsili WHERE CompanyId = @c)
BEGIN
  DECLARE @tCust smallint = (SELECT TafsiliTypeId FROM ACC.AccTafsiliType WHERE CompanyId=@c AND Title=N'مشتری');
  DECLARE @tSup smallint  = (SELECT TafsiliTypeId FROM ACC.AccTafsiliType WHERE CompanyId=@c AND Title=N'تأمین‌کننده');
  DECLARE @tBank smallint = (SELECT TafsiliTypeId FROM ACC.AccTafsiliType WHERE CompanyId=@c AND Title=N'بانک');
  DECLARE @tPrj smallint  = (SELECT TafsiliTypeId FROM ACC.AccTafsiliType WHERE CompanyId=@c AND Title=N'پروژه');

  INSERT INTO ACC.AccTafsili (CompanyId, TafsiliTypeId, Code, Title, LatinTitle) VALUES
   (@c, @tCust, '10000001', N'شرکت آریا صنعت',   'Aria Sanat Co'),
   (@c, @tCust, '10000002', N'بازرگانی مهر',     'Mehr Trading Co'),
   (@c, @tCust, '10000003', N'پخش نوین',         'Novin Distribution Co'),
   (@c, @tSup,  '20000001', N'فلزکاران تهران',   'Tehran Metalworks Co'),
   (@c, @tSup,  '20000002', N'پلاستیک ایران',    'Iran Plastic Co'),
   (@c, @tBank, '30000001', N'بانک ملی — شعبهٔ مرکزی', 'Melli Bank HQ'),
   (@c, @tBank, '30000002', N'بانک سامان — شهرک',      'Saman Bank Shahrak'),
   (@c, @tPrj,  '40000001', N'پروژهٔ سوله',      'Soleh Project'),
   (@c, @tPrj,  '40000002', N'پروژهٔ کارگاه ۲',  'Workshop 2 Project');
END
GO

DECLARE @c smallint = (SELECT CompanyId FROM pob.Companies WHERE CompanyCode = N'B');

/* ---------- شجرهٔ حساب‌ها — کدینگ استاندارد ترازنامه‌ای ---------- */
IF NOT EXISTS (SELECT 1 FROM ACC.AccGroup WHERE CompanyId = @c)
BEGIN
  INSERT INTO ACC.AccGroup (CompanyId, Code, Title, AccNature) VALUES
   (@c, '01', N'دارایی‌ها',  1),
   (@c, '02', N'بدهی‌ها',    2),
   (@c, '03', N'سرمایه',     2),
   (@c, '04', N'درآمدها',    2),
   (@c, '05', N'هزینه‌ها',   1);

  INSERT INTO ACC.AccKol (CompanyId, Code, GroupCode, Title, AccNature) VALUES
   (@c, '0101', '01', N'صندوق و بانک',              1),
   (@c, '0102', '01', N'حساب‌های دریافتنی تجاری',   1),
   (@c, '0103', '01', N'موجودی کالا',               1),
   (@c, '0104', '01', N'دارایی‌های ثابت',           1),
   (@c, '0201', '02', N'حساب‌های پرداختنی تجاری',   2),
   (@c, '0202', '02', N'مالیات و عوارض',            2),
   (@c, '0301', '03', N'سرمایه',                    2),
   (@c, '0302', '03', N'سود (زیان) انباشته',        2),
   (@c, '0401', '04', N'فروش',                      2),
   (@c, '0501', '05', N'بهای تمام‌شده کالای فروش‌رفته', 1),
   (@c, '0502', '05', N'هزینه‌های عملیاتی و اداری', 1);
END
GO

DECLARE @c smallint = (SELECT CompanyId FROM pob.Companies WHERE CompanyCode = N'B');

/* ---------- معین‌ها با اتصال سطوح تفصیلی ۴ ---------- */
IF NOT EXISTS (SELECT 1 FROM ACC.AccMoein WHERE CompanyId = @c)
BEGIN
  DECLARE @tCust2 smallint = (SELECT TafsiliTypeId FROM ACC.AccTafsiliType WHERE CompanyId=@c AND Title=N'مشتری');
  DECLARE @tSup2 smallint  = (SELECT TafsiliTypeId FROM ACC.AccTafsiliType WHERE CompanyId=@c AND Title=N'تأمین‌کننده');
  DECLARE @tBank2 smallint = (SELECT TafsiliTypeId FROM ACC.AccTafsiliType WHERE CompanyId=@c AND Title=N'بانک');

  INSERT INTO ACC.AccMoein (CompanyId, Code, KolCode, Title, AccNature, Taf1TypeId, Trackable) VALUES
   (@c, '010101', '0101', N'صندوق',                          1, NULL,      1),
   (@c, '010102', '0101', N'بانک ملی',                       1, @tBank2,   0),
   (@c, '010103', '0101', N'بانک سامان',                     1, @tBank2,   0),
   (@c, '010201', '0102', N'مشتریان',                        1, @tCust2,   0),
   (@c, '010202', '0102', N'اسناد دریافتنی',                 1, @tCust2,   0),
   (@c, '010301', '0103', N'موجودی کالا',                    1, NULL,      0),
   (@c, '010401', '0104', N'وسایل نقلیه',                    1, NULL,      0),
   (@c, '010402', '0104', N'اثاثهٔ اداری',                   1, NULL,      0),
   (@c, '020101', '0201', N'تأمین‌کنندگان',                  2, @tSup2,    0),
   (@c, '020201', '0202', N'مالیات بر ارزش افزوده',          2, NULL,      0),
   (@c, '030101', '0301', N'سرمایهٔ ثبت‌شده',                2, NULL,      0),
   (@c, '030201', '0302', N'سود انباشته',                    2, NULL,      0),
   (@c, '040101', '0401', N'فروش داخلی',                     2, @tCust2,   0),
   (@c, '050101', '0501', N'بهای تمام‌شدهٔ کالای فروش‌رفته', 1, NULL,      0),
   (@c, '050201', '0502', N'حقوق و دستمزد',                 1, NULL,      0),
   (@c, '050202', '0502', N'اجاره',                          1, NULL,      0),
   (@c, '050203', '0502', N'آب، برق و گاز',                  1, NULL,      0),
   (@c, '050204', '0502', N'هزینه‌های بانکی',                1, @tBank2,   0),
   (@c, '050205', '0502', N'پست و مخابرات',                  1, NULL,      0);
END
GO

DECLARE @c smallint = (SELECT CompanyId FROM pob.Companies WHERE CompanyCode = N'B');

/* ---------- ارزها + شعبه ---------- */
IF NOT EXISTS (SELECT 1 FROM ACC.AccFx WHERE CompanyId = @c)
BEGIN
  INSERT INTO ACC.AccFx (CompanyId, Code, Title, LatinTitle, IsBase) VALUES
   (@c, 'IRR', N'ریال', 'Iranian Rial', 1),
   (@c, 'USD', N'دلار آمریکا', 'US Dollar', 0),
   (@c, 'EUR', N'یورو', 'Euro', 0);
  INSERT INTO ACC.AccBranch (CompanyId, Code, Title) VALUES
   (@c, '1', N'دفتر مرکزی'), (@c, '2', N'شعبهٔ تهران');
END
GO

/* ============================================================================
   ماندهٔ ابتدای دوره ۱۴۰۵ (تراز: بدهکار ۵٬۲۰۰٬۰۰۰٬۰۰۰ = بستانکار ۵٬۲۰۰٬۰۰۰٬۰۰۰)
   ============================================================================ */
DECLARE @c smallint = (SELECT CompanyId FROM pob.Companies WHERE CompanyCode = N'B');
DECLARE @y smallint = (SELECT YearId FROM pob.FiscalYear WHERE CompanyId = @c AND JalaliYear = 1405);
IF NOT EXISTS (SELECT 1 FROM ACC.AccOpeningBalance WHERE CompanyId = @c AND YearId = @y)
BEGIN
  DECLARE @dSup int = (SELECT TafsiliId FROM ACC.AccTafsili WHERE CompanyId=@c AND Code='20000001');

  INSERT INTO ACC.AccOpeningBalance (CompanyId, YearId, KolCode, MoeinCode, Taf1Id, Dbt, Crt, CreatedBy, SourceSystem) VALUES
   (@c, @y, '0101', '010101', NULL, 500000000, 0, 'admin', 'ACCWEB'),
   (@c, @y, '0101', '010102', NULL, 1500000000, 0, 'admin', 'ACCWEB'),
   (@c, @y, '0103', '010301', NULL, 800000000, 0, 'admin', 'ACCWEB'),
   (@c, @y, '0104', '010401', NULL, 2000000000, 0, 'admin', 'ACCWEB'),
   (@c, @y, '0104', '010402', NULL, 400000000, 0, 'admin', 'ACCWEB'),
   (@c, @y, '0201', '020101', @dSup, 0, 600000000, 'admin', 'ACCWEB'),
   (@c, @y, '0301', '030101', NULL, 0, 4000000000, 'admin', 'ACCWEB'),
   (@c, @y, '0302', '030201', NULL, 0, 600000000, 'admin', 'ACCWEB');
END
GO

/* ============================================================================
   اسناد واقع‌گرایانهٔ فروردین تا خرداد ۱۴۰۵
   وضعیت ۳=قطعی (V1..V7) · ۲=بررسی‌شده (V8 ارزی) · ۱=موقت (V9 هزینهٔ بانکی)
   ============================================================================ */
DECLARE @c smallint = (SELECT CompanyId FROM pob.Companies WHERE CompanyCode = N'B');
DECLARE @y smallint = (SELECT YearId FROM pob.FiscalYear WHERE CompanyId = @c AND JalaliYear = 1405);

IF NOT EXISTS (SELECT 1 FROM ACC.AccVoucher WHERE CompanyId = @c AND YearId = @y)
BEGIN
  DECLARE @tOpen smallint = (SELECT VoucherTypeId FROM ACC.AccVoucherType WHERE CompanyId=@c AND LatinTitle='Opening');
  DECLARE @tSale smallint = (SELECT VoucherTypeId FROM ACC.AccVoucherType WHERE CompanyId=@c AND LatinTitle='Sales');
  DECLARE @tBuy smallint  = (SELECT VoucherTypeId FROM ACC.AccVoucherType WHERE CompanyId=@c AND LatinTitle='Purchase');
  DECLARE @tExp smallint  = (SELECT VoucherTypeId FROM ACC.AccVoucherType WHERE CompanyId=@c AND LatinTitle='Expense');
  DECLARE @tGen smallint  = (SELECT VoucherTypeId FROM ACC.AccVoucherType WHERE CompanyId=@c AND LatinTitle='General');

  DECLARE @dAria int  = (SELECT TafsiliId FROM ACC.AccTafsili WHERE CompanyId=@c AND Code='10000001');
  DECLARE @dMehr int  = (SELECT TafsiliId FROM ACC.AccTafsili WHERE CompanyId=@c AND Code='10000002');
  DECLARE @dFlz int   = (SELECT TafsiliId FROM ACC.AccTafsili WHERE CompanyId=@c AND Code='20000001');
  DECLARE @dPls int   = (SELECT TafsiliId FROM ACC.AccTafsili WHERE CompanyId=@c AND Code='20000002');
  DECLARE @dMelli int = (SELECT TafsiliId FROM ACC.AccTafsili WHERE CompanyId=@c AND Code='30000001');
  DECLARE @dSaman int = (SELECT TafsiliId FROM ACC.AccTafsili WHERE CompanyId=@c AND Code='30000002');
  DECLARE @fxUsd int  = (SELECT FxId FROM ACC.AccFx WHERE CompanyId=@c AND Code='USD');

  DECLARE @h TABLE (VchNo int, VoucherId int);

  /* V0 — افتتاحیه (قطعی) */
  INSERT INTO ACC.AccVoucher (CompanyId, YearId, FolioNo, VchNo, VoucherTypeId, VchDate, Descr, State, SourceModule, CreatedBy, CheckedBy, CheckedAt, FinalizedBy, FinalizedAt, DayNo)
  VALUES (@c, @y, 1, 1, @tOpen, '1405/01/01', N'سند افتتاحیهٔ سال مالی ۱۴۰۵', 3, 'ACC', 'karbar1', 'karbar2', SYSDATETIME(), 'admin', SYSDATETIME(), 1);
  INSERT INTO @h VALUES (1, SCOPE_IDENTITY());
  DECLARE @h0 int = (SELECT VoucherId FROM @h WHERE VchNo=1);
  INSERT INTO ACC.AccVoucherItm (VoucherId, RowNo, KolCode, MoeinCode, Taf1Id, Descr, Dbt, Crt) VALUES
   (@h0, 1, '0101', '010101', NULL, N'ماندهٔ ابتدای صندوق', 500000000, 0),
   (@h0, 2, '0101', '010102', @dMelli, N'ماندهٔ ابتدای بانک ملی', 1500000000, 0),
   (@h0, 3, '0103', '010301', NULL, N'ماندهٔ ابتدای موجودی کالا', 800000000, 0),
   (@h0, 4, '0104', '010401', NULL, N'خودرو', 2000000000, 0),
   (@h0, 5, '0104', '010402', NULL, N'اثاثهٔ اداری', 400000000, 0),
   (@h0, 6, '0201', '020101', @dFlz, N'بستانکاری فلزکاران تهران', 0, 600000000),
   (@h0, 7, '0301', '030101', NULL, N'سرمایهٔ ثبت‌شده', 0, 4000000000),
   (@h0, 8, '0302', '030201', NULL, N'سود انباشته', 0, 600000000);
  INSERT INTO ACC.AccVoucherFlow (VoucherId, Action, ByUser, Note) VALUES
   (@h0, 1, 'karbar1', N'صدور سند'), (@h0, 2, 'karbar2', N'بررسی شد'), (@h0, 4, 'admin', N'قطعی شد');

  /* V1 — فروش نقدی با مالیات بر ارزش افزوده (قطعی) */
  INSERT INTO ACC.AccVoucher (CompanyId, YearId, FolioNo, VchNo, VoucherTypeId, VchDate, Descr, State, SourceModule, CreatedBy, CheckedBy, CheckedAt, FinalizedBy, FinalizedAt, DayNo)
  VALUES (@c, @y, 2, 2, @tSale, '1405/01/05', N'فروش نقدی به شرکت آریا صنعت طبق فاکتور ۱۴۰۵-۰۱۲', 3, 'ACC', 'karbar1', 'karbar2', SYSDATETIME(), 'admin', SYSDATETIME(), 1);
  INSERT INTO @h VALUES (2, SCOPE_IDENTITY());
  DECLARE @h1 int = (SELECT VoucherId FROM @h WHERE VchNo=2);
  INSERT INTO ACC.AccVoucherItm (VoucherId, RowNo, KolCode, MoeinCode, Descr, Dbt, Crt) VALUES
   (@h1, 1, '0101', '010101', N'دریافت نقدی فاکتور ۱۴۰۵-۰۱۲', 330000000, 0),
   (@h1, 2, '0401', '040101', N'فروش به شرکت آریا صنعت', 0, 300000000),
   (@h1, 3, '0202', '020201', N'مالیات بر ارزش افزودهٔ فروش', 0, 30000000);
  /* تفصیلی فروش: مشتری آریا */
  UPDATE ACC.AccVoucherItm SET Taf1Id=@dAria WHERE VoucherId=@h1 AND MoeinCode='040101';
  INSERT INTO ACC.AccVoucherFlow (VoucherId, Action, ByUser, Note) VALUES
   (@h1, 1, 'karbar1', N'صدور سند'), (@h1, 2, 'karbar2', N'بررسی شد'), (@h1, 4, 'admin', N'قطعی شد');

  /* V2 — فروش نسیه (قطعی) */
  INSERT INTO ACC.AccVoucher (CompanyId, YearId, FolioNo, VchNo, VoucherTypeId, VchDate, Descr, State, SourceModule, CreatedBy, CheckedBy, CheckedAt, FinalizedBy, FinalizedAt, DayNo)
  VALUES (@c, @y, 3, 3, @tSale, '1405/01/15', N'فروش نسیه به بازرگانی مهر — مدت ۳ ماه', 3, 'ACC', 'karbar1', 'karbar2', SYSDATETIME(), 'admin', SYSDATETIME(), 2);
  INSERT INTO @h VALUES (3, SCOPE_IDENTITY());
  DECLARE @h2 int = (SELECT VoucherId FROM @h WHERE VchNo=3);
  INSERT INTO ACC.AccVoucherItm (VoucherId, RowNo, KolCode, MoeinCode, Taf1Id, Descr, Dbt, Crt) VALUES
   (@h2, 1, '0102', '010201', @dMehr, N'طلب از بازرگانی مهر', 550000000, 0),
   (@h2, 2, '0401', '040101', @dMehr, N'فروش به بازرگانی مهر', 0, 500000000),
   (@h2, 3, '0202', '020201', NULL, N'مالیات بر ارزش افزودهٔ فروش', 0, 50000000);
  INSERT INTO ACC.AccVoucherFlow (VoucherId, Action, ByUser, Note) VALUES
   (@h2, 1, 'karbar1', N'صدور سند'), (@h2, 2, 'karbar2', N'بررسی شد'), (@h2, 4, 'admin', N'قطعی شد');

  /* V3 — خرید نسیه (قطعی) */
  INSERT INTO ACC.AccVoucher (CompanyId, YearId, FolioNo, VchNo, VoucherTypeId, VchDate, Descr, State, SourceModule, CreatedBy, CheckedBy, CheckedAt, FinalizedBy, FinalizedAt, DayNo)
  VALUES (@c, @y, 4, 4, @tBuy, '1405/01/20', N'خرید کالا از پلاستیک ایران طبق فاکتور ۸۸۱۲', 3, 'ACC', 'karbar1', 'karbar2', SYSDATETIME(), 'admin', SYSDATETIME(), 3);
  INSERT INTO @h VALUES (4, SCOPE_IDENTITY());
  DECLARE @h3 int = (SELECT VoucherId FROM @h WHERE VchNo=4);
  INSERT INTO ACC.AccVoucherItm (VoucherId, RowNo, KolCode, MoeinCode, Taf1Id, Descr, Dbt, Crt) VALUES
   (@h3, 1, '0103', '010301', NULL, N'ورود کالا به انبار', 420000000, 0),
   (@h3, 2, '0202', '020201', NULL, N'مالیات بر ارزش افزودهٔ خرید', 42000000, 0),
   (@h3, 3, '0201', '020101', @dPls, N'بستانکاری پلاستیک ایران', 0, 462000000);
  INSERT INTO ACC.AccVoucherFlow (VoucherId, Action, ByUser, Note) VALUES
   (@h3, 1, 'karbar1', N'صدور سند'), (@h3, 2, 'karbar2', N'بررسی شد'), (@h3, 4, 'admin', N'قطعی شد');

  /* V4 — واریز مشتری به بانک (قطعی) */
  INSERT INTO ACC.AccVoucher (CompanyId, YearId, FolioNo, VchNo, VoucherTypeId, VchDate, Descr, State, SourceModule, CreatedBy, CheckedBy, CheckedAt, FinalizedBy, FinalizedAt, DayNo)
  VALUES (@c, @y, 5, 5, @tGen, '1405/02/02', N'واریز چک بازرگانی مهر به حساب بانک ملی', 3, 'ACC', 'karbar1', 'karbar2', SYSDATETIME(), 'admin', SYSDATETIME(), 1);
  INSERT INTO @h VALUES (5, SCOPE_IDENTITY());
  DECLARE @h4 int = (SELECT VoucherId FROM @h WHERE VchNo=5);
  INSERT INTO ACC.AccVoucherItm (VoucherId, RowNo, KolCode, MoeinCode, Taf1Id, Descr, Dbt, Crt) VALUES
   (@h4, 1, '0101', '010102', @dMelli, N'واریز به بانک ملی', 500000000, 0),
   (@h4, 2, '0102', '010201', @dMehr, N'تسویهٔ طلب بازرگانی مهر', 0, 500000000);
  INSERT INTO ACC.AccVoucherFlow (VoucherId, Action, ByUser, Note) VALUES
   (@h4, 1, 'karbar1', N'صدور سند'), (@h4, 2, 'karbar2', N'بررسی شد'), (@h4, 4, 'admin', N'قطعی شد');

  /* V5 — پرداخت به تأمین‌کننده (قطعی) */
  INSERT INTO ACC.AccVoucher (CompanyId, YearId, FolioNo, VchNo, VoucherTypeId, VchDate, Descr, State, SourceModule, CreatedBy, CheckedBy, CheckedAt, FinalizedBy, FinalizedAt, DayNo)
  VALUES (@c, @y, 6, 6, @tGen, '1405/02/10', N'پرداخت به فلزکاران تهران — حوالهٔ بانکی ۴۵۲۱', 3, 'ACC', 'karbar1', 'karbar2', SYSDATETIME(), 'admin', SYSDATETIME(), 1);
  INSERT INTO @h VALUES (6, SCOPE_IDENTITY());
  DECLARE @h5 int = (SELECT VoucherId FROM @h WHERE VchNo=6);
  INSERT INTO ACC.AccVoucherItm (VoucherId, RowNo, KolCode, MoeinCode, Taf1Id, Descr, Dbt, Crt) VALUES
   (@h5, 1, '0201', '020101', @dFlz, N'تسویهٔ بستانکاری فلزکاران تهران', 300000000, 0),
   (@h5, 2, '0101', '010102', @dMelli, N'حوالهٔ بانکی از بانک ملی', 0, 300000000);
  INSERT INTO ACC.AccVoucherFlow (VoucherId, Action, ByUser, Note) VALUES
   (@h5, 1, 'karbar1', N'صدور سند'), (@h5, 2, 'karbar2', N'بررسی شد'), (@h5, 4, 'admin', N'قطعی شد');

  /* V6 — بهای تمام‌شدهٔ کالای فروش‌رفته (قطعی) */
  INSERT INTO ACC.AccVoucher (CompanyId, YearId, FolioNo, VchNo, VoucherTypeId, VchDate, Descr, State, SourceModule, CreatedBy, CheckedBy, CheckedAt, FinalizedBy, FinalizedAt, DayNo)
  VALUES (@c, @y, 7, 7, @tExp, '1405/02/18', N'ثبت بهای تمام‌شدهٔ کالای فروش‌رفتهٔ فروردین', 3, 'ACC', 'karbar1', 'karbar2', SYSDATETIME(), 'admin', SYSDATETIME(), 2);
  INSERT INTO @h VALUES (7, SCOPE_IDENTITY());
  DECLARE @h6 int = (SELECT VoucherId FROM @h WHERE VchNo=7);
  INSERT INTO ACC.AccVoucherItm (VoucherId, RowNo, KolCode, MoeinCode, Descr, Dbt, Crt) VALUES
   (@h6, 1, '0501', '050101', N'بهای تمام‌شدهٔ فروش فروردین', 260000000, 0),
   (@h6, 2, '0103', '010301', N'کاهش موجودی کالا', 0, 260000000);
  INSERT INTO ACC.AccVoucherFlow (VoucherId, Action, ByUser, Note) VALUES
   (@h6, 1, 'karbar1', N'صدور سند'), (@h6, 2, 'karbar2', N'بررسی شد'), (@h6, 4, 'admin', N'قطعی شد');

  /* V7 — هزینه‌های عملیاتی اسفندماه قبل (قطعی) */
  INSERT INTO ACC.AccVoucher (CompanyId, YearId, FolioNo, VchNo, VoucherTypeId, VchDate, Descr, State, SourceModule, CreatedBy, CheckedBy, CheckedAt, FinalizedBy, FinalizedAt, DayNo)
  VALUES (@c, @y, 8, 8, @tExp, '1405/02/25', N'حقوق و اجاره و خدمات شهری اردیبهشت', 3, 'ACC', 'karbar1', 'karbar2', SYSDATETIME(), 'admin', SYSDATETIME(), 3);
  INSERT INTO @h VALUES (8, SCOPE_IDENTITY());
  DECLARE @h7 int = (SELECT VoucherId FROM @h WHERE VchNo=8);
  INSERT INTO ACC.AccVoucherItm (VoucherId, RowNo, KolCode, MoeinCode, Descr, Dbt, Crt) VALUES
   (@h7, 1, '0502', '050201', N'حقوق و دستمزد اردیبهشت', 180000000, 0),
   (@h7, 2, '0502', '050202', N'اجارهٔ دفتر مرکزی', 60000000, 0),
   (@h7, 3, '0502', '050203', N'آب و برق و گاز', 12000000, 0),
   (@h7, 4, '0101', '010102', N'پرداخت از بانک ملی', 0, 252000000);
  INSERT INTO ACC.AccVoucherFlow (VoucherId, Action, ByUser, Note) VALUES
   (@h7, 1, 'karbar1', N'صدور سند'), (@h7, 2, 'karbar2', N'بررسی شد'), (@h7, 4, 'admin', N'قطعی شد');

  /* V8 — خرید ارز (بررسی‌شده — با سه‌تایی ارز در قلم) */
  INSERT INTO ACC.AccVoucher (CompanyId, YearId, FolioNo, VchNo, VoucherTypeId, VchDate, Descr, State, SourceModule, CreatedBy, CheckedBy, CheckedAt, DayNo)
  VALUES (@c, @y, 9, 9, @tGen, '1405/03/03', N'خرید ۱۰٬۰۰۰ دلار از بازار آزاد و عودت به حساب ارزی', 2, 'ACC', 'karbar1', 'karbar2', SYSDATETIME(), 1);
  INSERT INTO @h VALUES (9, SCOPE_IDENTITY());
  DECLARE @h8 int = (SELECT VoucherId FROM @h WHERE VchNo=9);
  INSERT INTO ACC.AccVoucherItm (VoucherId, RowNo, KolCode, MoeinCode, Taf1Id, Descr, Dbt, Crt, FxId, FxAmount, FxRate) VALUES
   (@h8, 1, '0101', '010103', @dSaman, N'افتتاح حساب ارزی سامان — ۱۰٬۰۰۰ دلار', 1000000000, 0, @fxUsd, 10000, 100000),
   (@h8, 2, '0101', '010102', @dMelli, N'برداشت از حساب ریالی بانک ملی', 0, 1000000000);
  INSERT INTO ACC.AccVoucherFlow (VoucherId, Action, ByUser, Note) VALUES
   (@h8, 1, 'karbar1', N'صدور سند'), (@h8, 2, 'karbar2', N'بررسی شد');

  /* V9 — هزینهٔ بانکی با پیگیری (موقت) */
  INSERT INTO ACC.AccVoucher (CompanyId, YearId, FolioNo, VchNo, VoucherTypeId, VchDate, Descr, State, SourceModule, CreatedBy, DayNo)
  VALUES (@c, @y, 10, 10, @tExp, '1405/03/12', N'کارمزد و هزینهٔ بانکی اسفند', 1, 'ACC', 'karbar1', 2);
  INSERT INTO @h VALUES (10, SCOPE_IDENTITY());
  DECLARE @h9 int = (SELECT VoucherId FROM @h WHERE VchNo=10);
  INSERT INTO ACC.AccVoucherItm (VoucherId, RowNo, KolCode, MoeinCode, Taf1Id, Descr, Dbt, Crt, TrackNo, TrackDate) VALUES
   (@h9, 1, '0502', '050204', @dSaman, N'کارمزد انتقال ارز', 8500000, 0, 'TRK-1405-001', '1405/03/12'),
   (@h9, 2, '0101', '010103', @dSaman, N'برداشت از بانک سامان', 0, 8500000);
  INSERT INTO ACC.AccVoucherFlow (VoucherId, Action, ByUser, Note) VALUES (@h9, 1, 'karbar1', N'صدور سند');
END
GO

PRINT N'07_sample_data.sql — دموی کامل شرکت B آماده شد (شرکت A دست‌نخورده ماند).';
GO
