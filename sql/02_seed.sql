/* دادهٔ پایهٔ نمونه — Idempotent */
IF NOT EXISTS (SELECT 1 FROM pob.Companies WHERE CompanyCode = N'A')
INSERT INTO pob.Companies (CompanyCode, TitleFa, NationalId, EconomicCode, CodingMode)
VALUES (N'A', N'شرکت نمونه الف', N'14001234567', N'411567890', 2);
GO

DECLARE @co smallint = (SELECT CompanyId FROM pob.Companies WHERE CompanyCode = N'A');

/* کاربران — رمز 1234 */
IF NOT EXISTS (SELECT 1 FROM pob.AppUser WHERE Username = 'admin')
INSERT INTO pob.AppUser (Username, DisplayName, RoleCode, PassHash) VALUES
 ('admin',   N'مدیر سامانه',        'admin',     '77fb18dbce3d3b61420e44449c11e3214988914789922213d2049096a9d6754a'),
 ('karbar1', N'ثبت‌کننده اسناد',    'registrar', '77fb18dbce3d3b61420e44449c11e3214988914789922213d2049096a9d6754a'),
 ('karbar2', N'بررسی‌کننده اسناد',  'checker',   '77fb18dbce3d3b61420e44449c11e3214988914789922213d2049096a9d6754a');
GO

DECLARE @co2 smallint = (SELECT CompanyId FROM pob.Companies WHERE CompanyCode = N'A');
IF NOT EXISTS (SELECT 1 FROM pob.FiscalYear WHERE CompanyId = @co2 AND JalaliYear = 1405)
BEGIN
  DECLARE @y smallint;
  INSERT INTO pob.FiscalYear (CompanyId, JalaliYear, Title, StartDate, EndDate)
  VALUES (@co2, 1405, N'سال مالی ۱۴۰۵', '1405/01/01', '1405/12/29');
  SET @y = SCOPE_IDENTITY();
  INSERT INTO pob.FiscalPeriod (YearId, MonthNo, Title) VALUES
   (@y,1,N'فروردین'),(@y,2,N'اردیبهشت'),(@y,3,N'خرداد'),(@y,4,N'تیر'),(@y,5,N'مرداد'),(@y,6,N'شهریور'),
   (@y,7,N'مهر'),(@y,8,N'آبان'),(@y,9,N'آذر'),(@y,10,N'دی'),(@y,11,N'بهمن'),(@y,12,N'اسفند');
END
GO

/* انواع تفصیل [فرم: انواع تفصيل] */
DECLARE @co3 smallint = (SELECT CompanyId FROM pob.Companies WHERE CompanyCode = N'A');
IF NOT EXISTS (SELECT 1 FROM ACC.AccTafsiliType WHERE CompanyId = @co3)
INSERT INTO ACC.AccTafsiliType (CompanyId, Title, LatinTitle) VALUES
 (@co3, N'مشتری',        'Customer'),
 (@co3, N'تأمین‌کننده',  'Supplier'),
 (@co3, N'بانک',         'Bank'),
 (@co3, N'شعبه',         'Branch'),
 (@co3, N'پروژه',        'Project');
GO

/* شجرهٔ حساب‌ها — حالت ۲ مطابق accdef (گروه ۲/کل ۴/معین ۶) */
DECLARE @co4 smallint = (SELECT CompanyId FROM pob.Companies WHERE CompanyCode = N'A');
IF NOT EXISTS (SELECT 1 FROM ACC.AccGroup WHERE CompanyId = @co4)
BEGIN
  INSERT INTO ACC.AccGroup (CompanyId, Code, Title, AccNature) VALUES
   (@co4, '01', N'دارایی‌ها',        1),
   (@co4, '02', N'بدهی‌ها',          2),
   (@co4, '03', N'سرمایه',           2),
   (@co4, '04', N'درآمدها',          2),
   (@co4, '05', N'هزینه‌ها',         1);

  INSERT INTO ACC.AccKol (CompanyId, Code, GroupCode, Title, AccNature) VALUES
   (@co4, '0101', '01', N'صندوق و بانک',              1),
   (@co4, '0102', '01', N'حساب‌های دریافتنی',          1),
   (@co4, '0201', '02', N'حساب‌های پرداختنی',          2),
   (@co4, '0301', '03', N'سرمایه',                    2),
   (@co4, '0401', '04', N'فروش',                      2),
   (@co4, '0501', '05', N'هزینه‌های عمومی',           1);

  /* معین‌ها با ارتباط سطوح تفصیلی چهارم/پنجم/ششم */
  DECLARE @tCust smallint = (SELECT TafsiliTypeId FROM ACC.AccTafsiliType WHERE CompanyId=@co4 AND Title=N'مشتری');
  DECLARE @tSup  smallint = (SELECT TafsiliTypeId FROM ACC.AccTafsiliType WHERE CompanyId=@co4 AND Title=N'تأمین‌کننده');
  DECLARE @tBank smallint = (SELECT TafsiliTypeId FROM ACC.AccTafsiliType WHERE CompanyId=@co4 AND Title=N'بانک');
  INSERT INTO ACC.AccMoein (CompanyId, Code, KolCode, Title, AccNature, Taf1TypeId, Taf2TypeId, Trackable) VALUES
   (@co4, '010101', '0101', N'صندوق عملیاتی',      1, @tBank, NULL, 0),
   (@co4, '010201', '0102', N'دریافتنی از مشتریان', 1, @tCust, NULL, 1),
   (@co4, '020101', '0201', N'پرداختنی به تأمین‌کنندگان', 2, @tSup, NULL, 1),
   (@co4, '030101', '0301', N'سرمایه اولیه',        2, NULL, NULL, 0),
   (@co4, '040101', '0401', N'فروش کالا',           2, @tCust, NULL, 0),
   (@co4, '050101', '0501', N'هزینه‌های اداری',     1, @tSup, NULL, 0);

  /* انواع سند [فرم: تعريف انواع سند] */
  INSERT INTO ACC.AccVoucherType (CompanyId, Title, LatinTitle) VALUES
   (@co4, N'سند افتتاحیه',  'Opening'),
   (@co4, N'سند فروش',      'Sale'),
   (@co4, N'سند خرید',      'Purchase'),
   (@co4, N'سند دریافت',    'Receipt'),
   (@co4, N'سند پرداخت',    'Payment'),
   (@co4, N'سند عمومی',     'General');

  /* تفصیلی‌ها — کد ۸ رقمی، والد ندارند */
  INSERT INTO ACC.AccTafsili (CompanyId, TafsiliTypeId, Code, Title, LatinTitle) VALUES
   (@co4, @tCust, '00000001', N'مشتری الف', 'Customer-A'),
   (@co4, @tCust, '00000002', N'مشتری ب',   'Customer-B'),
   (@co4, @tSup,  '00000003', N'تأمین‌کننده ج', 'Supplier-C'),
   (@co4, @tBank, '00000004', N'بانک ملی — شعبه مرکزی', 'Bank-Melli');

  /* طبقه‌بندی تفصیلی */
  DECLARE @ct1 smallint, @ct2 smallint;
  INSERT INTO ACC.AccTafsiliCategory (CompanyId, Title) VALUES (@co4, N'مشتریان داخلی'); SET @ct1 = SCOPE_IDENTITY();
  INSERT INTO ACC.AccTafsiliCategory (CompanyId, Title) VALUES (@co4, N'تأمین‌کنندگان رسمی'); SET @ct2 = SCOPE_IDENTITY();
  INSERT INTO ACC.AccTafsiliCategoryLink (CategoryId, TafsiliId)
  SELECT @ct1, TafsiliId FROM ACC.AccTafsili WHERE CompanyId=@co4 AND Code IN ('00000001','00000002');
  INSERT INTO ACC.AccTafsiliCategoryLink (CategoryId, TafsiliId)
  SELECT @ct2, TafsiliId FROM ACC.AccTafsili WHERE CompanyId=@co4 AND Code = '00000003';
END
GO
