/* ============================================================================
   YFG ACC-WEB — گام اطلاعات عمومی (GNR) — نسخهٔ ۱.۱.۰  (بخش ۱ از ۳: توابع شمسی)
   مبتنی بر فایل‌های اصلی: HumCmp.bpl (OF0001-0006) + GnrGeneral.bpl +
   ConfigCommon.bpl + gnCalndr.bpl + sg.cnt (اطلاعات پایه همهٔ ماژول‌ها)
   و دیتابیس اصل (شمای gnr): Crspnd/Address/gnrCrspndCat/GeoPos/Lookup/
   MisSetup/Systems/TableIdGen/gnrHolidays/...
   دستورهای کارفرما:
     ۱) تاریخ شمسی ملاک است → توابع gnr.Grg2Jal / gnr.Jal2Grg + ستون‌های J
     ۲) ستون‌های ممیزی روی همهٔ جدول‌ها (ایجادکننده/ویرایش‌کننده/سیستم مبدأ/...)
     ۳) بله/خیر به‌جای true/false در لایهٔ نمایش (وب)
     ۴) لینک تفصیلی اشخاص به registry عمومی (Acc.DL.CrspndRef)
   اجرای تکرارپذیر (Idempotent).
   ============================================================================ */

IF SCHEMA_ID('gnr') IS NULL EXEC('CREATE SCHEMA gnr');
GO

/* ---------------------------------------------------------------------------
   بخش ۰ — توابع تاریخ شمسی (پورت وفادار jalaali-js — الگوریتم رسمی گاه‌شمار)
   div= تقسیم صحیح به سمت صفر (مانند T-SQL)، mod باقی‌ماندهٔ همان
   --------------------------------------------------------------------------- */

-- JDN از تاریخ میلادی (g2d)
IF OBJECT_ID('gnr._Grg2Jdn') IS NOT NULL DROP FUNCTION gnr._Grg2Jdn;
GO
CREATE FUNCTION gnr._Grg2Jdn (@gy int, @gm int, @gd int)
RETURNS int
WITH SCHEMABINDING
AS BEGIN
  /* div(gm-8,6) — تقسیم صحیح به‌سوی صفر؛ T-SQL دقیقاً همین رفتار را دارد */
  DECLARE @d int = ((@gy + (@gm - 8) / 6 + 100100) * 1461) / 4
        + (153 * ((@gm + 9) % 12) + 2) / 5
        + @gd - 34840408;
  SET @d = @d - (((@gy + 100100 + (@gm - 8) / 6) / 100) * 3) / 4 + 752;
  RETURN @d;
END;
GO

-- جدول گسست‌ها (breaks) — هر اندیس یک مقدار
IF OBJECT_ID('gnr._JalBreak') IS NOT NULL DROP FUNCTION gnr._JalBreak;
GO
CREATE FUNCTION gnr._JalBreak (@i int)
RETURNS int
WITH SCHEMABINDING
AS BEGIN
  RETURN CASE @i
    WHEN 1 THEN -61   WHEN 2 THEN 9     WHEN 3 THEN 38    WHEN 4 THEN 199
    WHEN 5 THEN 426   WHEN 6 THEN 686   WHEN 7 THEN 756   WHEN 8 THEN 818
    WHEN 9 THEN 1111  WHEN 10 THEN 1181 WHEN 11 THEN 1210 WHEN 12 THEN 1635
    WHEN 13 THEN 2060 WHEN 14 THEN 2097 WHEN 15 THEN 2192 WHEN 16 THEN 2262
    WHEN 17 THEN 2324 WHEN 18 THEN 2394 WHEN 19 THEN 2456 WHEN 20 THEN 3178
  END;
END;
GO

-- روز نوروز (میلادی) برای سال جلالی — jalCal().march
IF OBJECT_ID('gnr._JalMarch') IS NOT NULL DROP FUNCTION gnr._JalMarch;
GO
CREATE FUNCTION gnr._JalMarch (@jy int)
RETURNS int
WITH SCHEMABINDING
AS BEGIN
  DECLARE @gy int = @jy + 621;
  DECLARE @leapJ int = -14, @jp int = -61, @jm int, @jump int = 0, @n int, @i int;
  SET @i = 1;
  WHILE @i <= 20 BEGIN
    SET @jm = gnr._JalBreak(@i);
    SET @jump = @jm - @jp;
    IF @jy < @jm BREAK;
    SET @leapJ = @leapJ + (@jump / 33) * 8 + ((@jump % 33) / 4);
    SET @jp = @jm;
    SET @i = @i + 1;
  END
  SET @n = @jy - @jp;
  SET @leapJ = @leapJ + (@n / 33) * 8 + (((@n % 33) + 3) / 4);
  IF (@jump % 33) = 4 AND (@jump - @n) = 4 SET @leapJ = @leapJ + 1;
  DECLARE @leapG int = (@gy / 4) - (((@gy / 100) + 1) * 3) / 4 - 150;
  RETURN 20 + @leapJ - @leapG;
END;
GO

-- پرچم کبیسهٔ سال جلالی — jalCal().leap
IF OBJECT_ID('gnr._JalLeap') IS NOT NULL DROP FUNCTION gnr._JalLeap;
GO
CREATE FUNCTION gnr._JalLeap (@jy int)
RETURNS int
WITH SCHEMABINDING
AS BEGIN
  DECLARE @leapJ int = -14, @jp int = -61, @jm int, @jump int = 0, @n int, @i int, @leap int;
  SET @i = 1;
  WHILE @i <= 20 BEGIN
    SET @jm = gnr._JalBreak(@i);
    SET @jump = @jm - @jp;
    IF @jy < @jm BREAK;
    SET @leapJ = @leapJ + (@jump / 33) * 8 + ((@jump % 33) / 4);
    SET @jp = @jm;
    SET @i = @i + 1;
  END
  SET @n = @jy - @jp;
  SET @leapJ = @leapJ + (@n / 33) * 8 + (((@n % 33) + 3) / 4);
  IF (@jump % 33) = 4 AND (@jump - @n) = 4 SET @leapJ = @leapJ + 1;
  IF (@jump - @n) < 6 SET @n = @n - @jump + ((@jump + 4) / 33) * 33;
  SET @leap = ((@n + 1) % 33 - 1) % 4;
  IF @leap = -1 SET @leap = 4;
  RETURN @leap;
END;
GO

-- میلادی→جلالی: d2j(g2d(...))
IF OBJECT_ID('gnr.Grg2Jal') IS NOT NULL DROP FUNCTION gnr.Grg2Jal;
GO
CREATE FUNCTION gnr.Grg2Jal (@d datetime2(0))
RETURNS varchar(10)
WITH SCHEMABINDING
AS BEGIN
  IF @d IS NULL RETURN NULL;
  DECLARE @gy int = DATEPART(YEAR, @d), @gm int = DATEPART(MONTH, @d), @gd int = DATEPART(DAY, @d);
  DECLARE @jdn int = gnr._Grg2Jdn(@gy, @gm, @gd);
  DECLARE @jy int = @gy - 621;
  DECLARE @march int = gnr._JalMarch(@jy);
  DECLARE @jdn1f int = gnr._Grg2Jdn(@gy, 3, @march);
  DECLARE @k int = @jdn - @jdn1f;
  DECLARE @jm int, @jd int;
  IF @k >= 0 BEGIN
    IF @k <= 185 BEGIN
      SET @jm = 1 + (@k / 31);
      SET @jd = (@k % 31) + 1;
      RETURN RIGHT('0000' + CAST(@jy AS varchar(4)), 4) + '/' + RIGHT('0' + CAST(@jm AS varchar(2)), 2) + '/' + RIGHT('0' + CAST(@jd AS varchar(2)), 2);
    END
    SET @k = @k - 186;
  END ELSE BEGIN
    SET @jy = @jy - 1;
    SET @k = @k + 179;
    IF gnr._JalLeap(@jy) = 1 SET @k = @k + 1;
  END
  SET @jm = 7 + (@k / 30);
  SET @jd = (@k % 30) + 1;
  RETURN RIGHT('0000' + CAST(@jy AS varchar(4)), 4) + '/' + RIGHT('0' + CAST(@jm AS varchar(2)), 2) + '/' + RIGHT('0' + CAST(@jd AS varchar(2)), 2);
END;
GO

-- جلالی→JDN (j2d)
IF OBJECT_ID('gnr._Jal2Jdn') IS NOT NULL DROP FUNCTION gnr._Jal2Jdn;
GO
CREATE FUNCTION gnr._Jal2Jdn (@jy int, @jm int, @jd int)
RETURNS int
WITH SCHEMABINDING
AS BEGIN
  DECLARE @gy int = @jy + 621;
  DECLARE @march int = gnr._JalMarch(@jy);
  RETURN gnr._Grg2Jdn(@gy, 3, @march) + (@jm - 1) * 31 - (@jm / 7) * (@jm - 7) + @jd - 1;
END;
GO

-- JDN→میلادی (d2g) — خروجی 'YYYY-MM-DD'
IF OBJECT_ID('gnr._Jdn2Grg') IS NOT NULL DROP FUNCTION gnr._Jdn2Grg;
GO
CREATE FUNCTION gnr._Jdn2Grg (@jdn int)
RETURNS varchar(10)
WITH SCHEMABINDING
AS BEGIN
  DECLARE @j int = 4 * @jdn + 139361631;
  SET @j = @j + (((4 * @jdn + 183187720) / 146097) * 3) / 4 * 4 - 3908;
  DECLARE @i int = ((@j % 1461) / 4) * 5 + 308;
  DECLARE @gd int = ((@i % 153) / 5) + 1;
  DECLARE @gm int = ((@i / 153) % 12) + 1;
  DECLARE @gy int = (@j / 1461) - 100100 + CASE WHEN @gm > 8 THEN (8 - @gm) / 6 ELSE 0 END + CASE WHEN @gm < 8 THEN (8 - @gm) / 6 ELSE 0 END;
  RETURN RIGHT('0000' + CAST(@gy AS varchar(4)), 4) + '-' + RIGHT('0' + CAST(@gm AS varchar(2)), 2) + '-' + RIGHT('0' + CAST(@gd AS varchar(2)), 2);
END;
GO

-- جلالی→میلادی
IF OBJECT_ID('gnr.Jal2Grg') IS NOT NULL DROP FUNCTION gnr.Jal2Grg;
GO
CREATE FUNCTION gnr.Jal2Grg (@jal varchar(10))
RETURNS date
WITH SCHEMABINDING
AS BEGIN
  IF @jal IS NULL RETURN NULL;
  DECLARE @jy int = CAST(LEFT(@jal, 4) AS int);
  DECLARE @jm int = CAST(SUBSTRING(@jal, 6, 2) AS int);
  DECLARE @jd int = CAST(RIGHT(@jal, 2) AS int);
  DECLARE @grg varchar(10) = gnr._Jdn2Grg(gnr._Jal2Jdn(@jy, @jm, @jd));
  RETURN CAST(@grg AS date);
END;
GO

/* [audit columns moved to 03b_audit.sql — ASCII-only comments, explicit per-table] */
GO

/* ---------------------------------------------------------------------------
   بخش ۲ — جداول اطلاعات عمومی — عیناً مطابق دیتابیس اصل (شمای gnr)
   منابع: HumCmp.bpl (insert into gnr.Crspnd/gnr.Address/gnrCrspndCat)،
   ConfigCommon.bpl (MisSetup/Lookup)، GnrGeneral.bpl (Systems/GeoPos)،
   gnCalndr.bpl (gnrHolidays/gnrHolidayTypes/gnrNonWorkingTimes)
   --------------------------------------------------------------------------- */

/* ۲-۱: اشخاص و شرکت‌های طرف مکاتبه (OF0001/0002/0005/0006 — HumCmp.bpl) */
IF OBJECT_ID('gnr.Crspnd') IS NULL
CREATE TABLE gnr.Crspnd (
  Serial        bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_gnr_Crspnd PRIMARY KEY,
  RecType       char(3)   NOT NULL CONSTRAINT CK_Crspnd_RecType CHECK (RecType IN ('CMP','MAN')), -- CMP=شرکت MAN=شخص
  CompType      smallint  NULL,                        -- نوع شرکت/شخص (gnr.Lookup type='CompType')
  CompName      nvarchar(400) NULL,                    -- نام شرکت (برای شخص: نام همسر/همکار در اصل)
  Title         nvarchar(400) NULL,                    -- عنوان
  FName         nvarchar(200) NULL, LName nvarchar(200) NULL, NickName nvarchar(200) NULL,
  Title_En      varchar(400) NULL, FName_En varchar(200) NULL, LName_En varchar(200) NULL, CompName_En varchar(400) NULL,
  EconCode      varchar(20)  NULL,                     -- کد اقتصادی
  NationalCode  varchar(20)  NULL,                     -- شناسه/کد ملی
  FatherName    nvarchar(200) NULL,
  IDNo          varchar(30)  NULL,                     -- شماره شناسنامه
  MainAddrRef   bigint       NULL,                     -- نشانی اصلی (FK→gnr.Address)
  IsActive      bit          NOT NULL CONSTRAINT DF_Crspnd_Active DEFAULT (1),
  /* ستون‌های ممیزی — استاندارد همهٔ جدول‌ها */
  CreatedBy     varchar(50)  NOT NULL CONSTRAINT DF_Crspnd_CreatedBy DEFAULT ('system'),
  CreatedAt     datetime2(0) NOT NULL CONSTRAINT DF_Crspnd_CreatedAt DEFAULT (SYSDATETIME()),
  UpdatedBy     varchar(50)  NULL,
  UpdatedAt     datetime2(0) NULL,
  SourceSystem  varchar(20)  NOT NULL CONSTRAINT DF_Crspnd_SrcSys DEFAULT ('ACCWEB'),
  CreatedAtJ    AS gnr.Grg2Jal(CreatedAt),
  UpdatedAtJ    AS gnr.Grg2Jal(UpdatedAt)
);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_Crspnd_NationalCode' AND object_id = OBJECT_ID('gnr.Crspnd'))
  CREATE UNIQUE INDEX UQ_Crspnd_NationalCode ON gnr.Crspnd (RecType, NationalCode) WHERE NationalCode IS NOT NULL;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Crspnd_Title' AND object_id = OBJECT_ID('gnr.Crspnd'))
  CREATE INDEX IX_Crspnd_Title ON gnr.Crspnd (Title);
GO

/* ۲-۲: نشانی‌ها (HumCmp.bpl — insert into gnr.Address) */
IF OBJECT_ID('gnr.Address') IS NULL
CREATE TABLE gnr.Address (
  Serial      bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_gnr_Address PRIMARY KEY,
  CrspndRef   bigint   NOT NULL CONSTRAINT FK_Address_Crspnd REFERENCES gnr.Crspnd(Serial) ON DELETE CASCADE,
  Title       nvarchar(200) NULL,
  Address     nvarchar(1000) NULL,
  Address_En  varchar(1000) NULL,
  ZipCode     varchar(20) NULL,
  PostBox     varchar(20) NULL,
  Phone       varchar(60) NULL,
  Fax         varchar(60) NULL,
  EMail       varchar(120) NULL,
  Modem       varchar(60) NULL,   -- مطابق اصل حفظ شده
  Mobile      varchar(60) NULL,
  GeoPosRef   smallint     NULL,  -- موقعیت جغرافیایی (FK بعداً)
  CreatedBy   varchar(50)  NOT NULL CONSTRAINT DF_Address_CreatedBy DEFAULT ('system'),
  CreatedAt   datetime2(0) NOT NULL CONSTRAINT DF_Address_CreatedAt DEFAULT (SYSDATETIME()),
  UpdatedBy   varchar(50)  NULL,
  UpdatedAt   datetime2(0) NULL,
  SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Address_SrcSys DEFAULT ('ACCWEB'),
  CreatedAtJ  AS gnr.Grg2Jal(CreatedAt),
  UpdatedAtJ  AS gnr.Grg2Jal(UpdatedAt)
);
GO

/* ۲-۳: موقعیت‌های جغرافیایی (OF0004 — TFrmGeoPos در GnrGeneral.bpl) */
IF OBJECT_ID('gnr.GeoPos') IS NULL
CREATE TABLE gnr.GeoPos (
  GeoPosId  smallint IDENTITY(1,1) NOT NULL CONSTRAINT PK_gnr_GeoPos PRIMARY KEY,
  ParentRef smallint NULL CONSTRAINT FK_GeoPos_Parent REFERENCES gnr.GeoPos(GeoPosId),
  Title     nvarchar(200) NOT NULL,
  GeoType   tinyint   NOT NULL CONSTRAINT CK_GeoPos_Type CHECK (GeoType IN (1,2,3,4)), -- 1=کشور 2=استان 3=شهرستان 4=شهر
  LatinTitle varchar(200) NULL,
  CreatedBy  varchar(50)  NOT NULL CONSTRAINT DF_GeoPos_CreatedBy DEFAULT ('system'),
  CreatedAt  datetime2(0) NOT NULL CONSTRAINT DF_GeoPos_CreatedAt DEFAULT (SYSDATETIME()),
  UpdatedBy  varchar(50)  NULL,
  UpdatedAt  datetime2(0) NULL,
  SourceSystem varchar(20) NOT NULL CONSTRAINT DF_GeoPos_SrcSys DEFAULT ('ACCWEB'),
  CreatedAtJ AS gnr.Grg2Jal(CreatedAt),
  UpdatedAtJ AS gnr.Grg2Jal(UpdatedAt)
);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Address_GeoPos')
  ALTER TABLE gnr.Address ADD CONSTRAINT FK_Address_GeoPos FOREIGN KEY (GeoPosRef) REFERENCES gnr.GeoPos(GeoPosId);
GO

/* ۲-۴: طبقه‌بندی اشخاص و شرکت‌ها (OF0003) + پیوند */
IF OBJECT_ID('gnr.CrspndCtgry') IS NULL
CREATE TABLE gnr.CrspndCtgry (
  CtgryId    smallint IDENTITY(1,1) NOT NULL CONSTRAINT PK_gnr_CrspndCtgry PRIMARY KEY,
  Title      nvarchar(200) NOT NULL,
  ParentRef  smallint NULL CONSTRAINT FK_CrspndCtgry_Parent REFERENCES gnr.CrspndCtgry(CtgryId),
  CreatedBy  varchar(50)  NOT NULL CONSTRAINT DF_CrspndCtgry_CreatedBy DEFAULT ('system'),
  CreatedAt  datetime2(0) NOT NULL CONSTRAINT DF_CrspndCtgry_CreatedAt DEFAULT (SYSDATETIME()),
  UpdatedBy  varchar(50)  NULL,
  UpdatedAt  datetime2(0) NULL,
  SourceSystem varchar(20) NOT NULL CONSTRAINT DF_CrspndCtgry_SrcSys DEFAULT ('ACCWEB'),
  CreatedAtJ AS gnr.Grg2Jal(CreatedAt),
  UpdatedAtJ AS gnr.Grg2Jal(UpdatedAt)
);
IF OBJECT_ID('gnr.gnrCrspndCat') IS NULL
CREATE TABLE gnr.gnrCrspndCat (
  CrspndRef bigint   NOT NULL CONSTRAINT FK_CrspndCat_Crspnd REFERENCES gnr.Crspnd(Serial) ON DELETE CASCADE,
  CtgryRef  smallint NOT NULL CONSTRAINT FK_CrspndCat_Ctgry REFERENCES gnr.CrspndCtgry(CtgryId),
  CreatedBy varchar(50) NOT NULL DEFAULT('system'),
  CreatedAt datetime2(0) NOT NULL DEFAULT(SYSDATETIME()),
  UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL,
  SourceSystem varchar(20) NOT NULL DEFAULT('ACCWEB'),
  CreatedAtJ AS gnr.Grg2Jal(CreatedAt), UpdatedAtJ AS gnr.Grg2Jal(UpdatedAt),
  CONSTRAINT PK_gnrCrspndCat PRIMARY KEY (CrspndRef, CtgryRef)
);
GO

/* ۲-۵: تنظیمات عمومی (ConfigCommon.bpl — MisSetup: KeyValue/DataValue/SystemName) */
IF OBJECT_ID('gnr.MisSetup') IS NULL
CREATE TABLE gnr.MisSetup (
  MisSetupId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_gnr_MisSetup PRIMARY KEY,
  KeyValue   varchar(60)  NOT NULL,
  DataValue  nvarchar(400) NOT NULL,
  SystemName varchar(10)  NULL,
  Descr      nvarchar(600) NULL,   -- شرح فارسی برای نمایش
  CreatedBy  varchar(50)  NOT NULL CONSTRAINT DF_MisSetup_CreatedBy DEFAULT ('system'),
  CreatedAt  datetime2(0) NOT NULL CONSTRAINT DF_MisSetup_CreatedAt DEFAULT (SYSDATETIME()),
  UpdatedBy  varchar(50)  NULL,
  UpdatedAt  datetime2(0) NULL,
  SourceSystem varchar(20) NOT NULL CONSTRAINT DF_MisSetup_SrcSys DEFAULT ('ACCWEB'),
  CreatedAtJ AS gnr.Grg2Jal(CreatedAt),
  UpdatedAtJ AS gnr.Grg2Jal(UpdatedAt),
  CONSTRAINT UQ_MisSetup_Key UNIQUE (KeyValue, SystemName)
);
GO

/* ۲-۶: مرجع عمومی کدها (ConfigCommon.bpl — Lookup: type/code/title/aux/SystemName) */
IF OBJECT_ID('gnr.Lookup') IS NULL
CREATE TABLE gnr.Lookup (
  LookupId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_gnr_Lookup PRIMARY KEY,
  [Type]   varchar(40)  NOT NULL,
  Code     int          NOT NULL,
  Title    nvarchar(200) NOT NULL,
  Aux      varchar(100) NULL,
  SystemName varchar(10) NULL,
  CreatedBy  varchar(50)  NOT NULL CONSTRAINT DF_Lookup_CreatedBy DEFAULT ('system'),
  CreatedAt  datetime2(0) NOT NULL CONSTRAINT DF_Lookup_CreatedAt DEFAULT (SYSDATETIME()),
  UpdatedBy  varchar(50)  NULL,
  UpdatedAt  datetime2(0) NULL,
  SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Lookup_SrcSys DEFAULT ('ACCWEB'),
  CreatedAtJ AS gnr.Grg2Jal(CreatedAt),
  UpdatedAtJ AS gnr.Grg2Jal(UpdatedAt),
  CONSTRAINT UQ_Lookup_TypeCode UNIQUE ([Type], Code)
);
GO

/* ۲-۷: ثبت سامانه‌ها (GnrGeneral.bpl — gnr.Systems) */
IF OBJECT_ID('gnr.Systems') IS NULL
CREATE TABLE gnr.Systems (
  SystemCode varchar(10) NOT NULL CONSTRAINT PK_gnr_Systems PRIMARY KEY,
  TitleFa    nvarchar(200) NOT NULL,
  LatinTitle varchar(100) NULL,
  IsActive   bit NOT NULL CONSTRAINT DF_Systems_Active DEFAULT (1),
  CreatedBy  varchar(50)  NOT NULL CONSTRAINT DF_Systems_CreatedBy DEFAULT ('system'),
  CreatedAt  datetime2(0) NOT NULL CONSTRAINT DF_Systems_CreatedAt DEFAULT (SYSDATETIME()),
  UpdatedBy  varchar(50)  NULL,
  UpdatedAt  datetime2(0) NULL,
  SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Systems_SrcSys DEFAULT ('ACCWEB'),
  CreatedAtJ AS gnr.Grg2Jal(CreatedAt),
  UpdatedAtJ AS gnr.Grg2Jal(UpdatedAt)
);
GO

/* ۲-۸: تولید شناسه (gnr.TableIdGen — مطابق اصل) */
IF OBJECT_ID('gnr.TableIdGen') IS NULL
CREATE TABLE gnr.TableIdGen (
  TableName varchar(60) NOT NULL CONSTRAINT PK_gnr_TableIdGen PRIMARY KEY,
  LastId    bigint NOT NULL DEFAULT (0),
  CreatedBy varchar(50) NOT NULL DEFAULT ('system'),
  CreatedAt datetime2(0) NOT NULL DEFAULT (SYSDATETIME()),
  UpdatedBy varchar(50) NULL,
  UpdatedAt datetime2(0) NULL,
  SourceSystem varchar(20) NOT NULL DEFAULT ('ACCWEB')
);
GO

/* ۲-۹: تقویم و تعطیلات (gnCalndr.bpl — gnrHolidayTypes/gnrHolidays/gnrNonWorkingTimes) */
IF OBJECT_ID('gnr.gnrHolidayTypes') IS NULL
CREATE TABLE gnr.gnrHolidayTypes (
  HolidayTypeId smallint IDENTITY(1,1) NOT NULL CONSTRAINT PK_gnr_HolidayTypes PRIMARY KEY,
  Title nvarchar(100) NOT NULL,
  IsActive bit NOT NULL DEFAULT (1),
  CreatedBy varchar(50) NOT NULL DEFAULT ('system'),
  CreatedAt datetime2(0) NOT NULL DEFAULT (SYSDATETIME()),
  UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL,
  SourceSystem varchar(20) NOT NULL DEFAULT ('ACCWEB'),
  CreatedAtJ AS gnr.Grg2Jal(CreatedAt)
);
IF OBJECT_ID('gnr.gnrHolidays') IS NULL
CREATE TABLE gnr.gnrHolidays (
  HolidayId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_gnr_Holidays PRIMARY KEY,
  JDate     char(10) NOT NULL,          -- تاریخ شمسی ملاک
  GDate     AS gnr.Jal2Grg(JDate) PERSISTED,
  HolidayTypeRef smallint NULL CONSTRAINT FK_Holidays_Type REFERENCES gnr.gnrHolidayTypes(HolidayTypeId),
  Descr     nvarchar(400) NULL,
  CreatedBy varchar(50) NOT NULL DEFAULT ('system'),
  CreatedAt datetime2(0) NOT NULL DEFAULT (SYSDATETIME()),
  UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL,
  SourceSystem varchar(20) NOT NULL DEFAULT ('ACCWEB'),
  CreatedAtJ AS gnr.Grg2Jal(CreatedAt),
  CONSTRAINT UQ_Holidays_JDate UNIQUE (JDate)
);
IF OBJECT_ID('gnr.gnrNonWorkingTimes') IS NULL
CREATE TABLE gnr.gnrNonWorkingTimes (
  NonWorkId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_gnr_NonWorkingTimes PRIMARY KEY,
  JDate     char(10) NOT NULL,
  FromTime  char(5)  NULL,
  ToTime    char(5)  NULL,
  Descr     nvarchar(400) NULL,
  CreatedBy varchar(50) NOT NULL DEFAULT ('system'),
  CreatedAt datetime2(0) NOT NULL DEFAULT (SYSDATETIME()),
  UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL,
  SourceSystem varchar(20) NOT NULL DEFAULT ('ACCWEB')
);
GO

/* ---------------------------------------------------------------------------
   بخش ۳ — لینک اطلاعات عمومی به حسابداری (الگوی اصل: CrspndRef)
   تفصیلیِ نوع «شخص/شرکت» به registry عمومی گره می‌خورد
   --------------------------------------------------------------------------- */
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Acc.DL') AND name = 'CrspndRef')
  ALTER TABLE Acc.DL ADD CrspndRef bigint NULL CONSTRAINT FK_DL_Crspnd REFERENCES gnr.Crspnd(Serial);
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Acc.DlType') AND name = 'LookupType')
  ALTER TABLE Acc.DlType ADD LookupType varchar(40) NULL; -- نوع مرتبط در gnr.Lookup (مثل CompType)
GO

/* ---------------------------------------------------------------------------
   بخش ۴ — داده‌های پایهٔ اطلاعات عمومی
   --------------------------------------------------------------------------- */

/* سامانه‌ها (مطابق Systems اصل) */
IF NOT EXISTS (SELECT 1 FROM gnr.Systems WHERE SystemCode = 'ACC')
  INSERT INTO gnr.Systems (SystemCode, TitleFa, LatinTitle) VALUES ('ACC', N'حسابداری', 'Accounting');
IF NOT EXISTS (SELECT 1 FROM gnr.Systems WHERE SystemCode = 'GNR')
  INSERT INTO gnr.Systems (SystemCode, TitleFa, LatinTitle) VALUES ('GNR', N'اطلاعات عمومی', 'General');

/* تنظیمات عمومی — الگوی SgDefaultData/MisSetup اصل (تقویم شمسی ملاک) */
IF NOT EXISTS (SELECT 1 FROM gnr.MisSetup WHERE KeyValue = 'DefaultCalendar')
  INSERT INTO gnr.MisSetup (KeyValue, DataValue, SystemName, Descr) VALUES
    ('DefaultCalendar', N'HEJRI', 'GNR', N'تقویم پیش‌فرض سامانه — شمسی ملاک است (دستور کارفرما)');
IF NOT EXISTS (SELECT 1 FROM gnr.MisSetup WHERE KeyValue = 'StartMonth')
  INSERT INTO gnr.MisSetup (KeyValue, DataValue, SystemName, Descr) VALUES
    ('StartMonth', N'1', 'GNR', N'ماه شروع سال مالی (فروردین)');
IF NOT EXISTS (SELECT 1 FROM gnr.MisSetup WHERE KeyValue = 'AccLen')
  INSERT INTO gnr.MisSetup (KeyValue, DataValue, SystemName, Descr) VALUES
    ('AccLen', N'4', 'ACC', N'تعداد ارقام حساب کل');
IF NOT EXISTS (SELECT 1 FROM gnr.MisSetup WHERE KeyValue = 'DlLen')
  INSERT INTO gnr.MisSetup (KeyValue, DataValue, SystemName, Descr) VALUES
    ('DlLen', N'8', 'ACC', N'تعداد ارقام حساب تفصیلی (DLKEYLEN اصل)');
IF NOT EXISTS (SELECT 1 FROM gnr.MisSetup WHERE KeyValue = 'VchNoStart')
  INSERT INTO gnr.MisSetup (KeyValue, DataValue, SystemName, Descr) VALUES
    ('VchNoStart', N'1', 'ACC', N'شروع شماره اسناد حسابداری');
IF NOT EXISTS (SELECT 1 FROM gnr.MisSetup WHERE KeyValue = 'BoolDisplay')
  INSERT INTO gnr.MisSetup (KeyValue, DataValue, SystemName, Descr) VALUES
    ('BoolDisplay', N'بله/خیر', 'GNR', N'نمایش مقادیر منطقی: بله/خیر (به‌جای true/false) — دستور کارفرما');
IF NOT EXISTS (SELECT 1 FROM gnr.MisSetup WHERE KeyValue = 'DateStandard')
  INSERT INTO gnr.MisSetup (KeyValue, DataValue, SystemName, Descr) VALUES
    ('DateStandard', N'JALALI', 'GNR', N'استاندارد تاریخ: شمسی (تاریخ ایجاد/ویرایش/اسناد)');

/* انواع شخص/شرکت — CompType (الگوی vwCompType اصل) */
IF NOT EXISTS (SELECT 1 FROM gnr.Lookup WHERE [Type] = 'CompType' AND Code = 1)
  INSERT INTO gnr.Lookup ([Type], Code, Title, SystemName) VALUES ('CompType', 1, N'شخص حقیقی', 'GNR');
IF NOT EXISTS (SELECT 1 FROM gnr.Lookup WHERE [Type] = 'CompType' AND Code = 2)
  INSERT INTO gnr.Lookup ([Type], Code, Title, SystemName) VALUES ('CompType', 2, N'شخص حقوقی', 'GNR');
IF NOT EXISTS (SELECT 1 FROM gnr.Lookup WHERE [Type] = 'CompType' AND Code = 3)
  INSERT INTO gnr.Lookup ([Type], Code, Title, SystemName) VALUES ('CompType', 3, N'موسسه دولتی', 'GNR');

/* انواع تعطیلات (gnCalndr اصل) */
IF NOT EXISTS (SELECT 1 FROM gnr.gnrHolidayTypes WHERE Title = N'رسمی')
  INSERT INTO gnr.gnrHolidayTypes (Title) VALUES (N'رسمی');
IF NOT EXISTS (SELECT 1 FROM gnr.gnrHolidayTypes WHERE Title = N'مذهبی')
  INSERT INTO gnr.gnrHolidayTypes (Title) VALUES (N'مذهبی');
IF NOT EXISTS (SELECT 1 FROM gnr.gnrHolidayTypes WHERE Title = N'سازمانی')
  INSERT INTO gnr.gnrHolidayTypes (Title) VALUES (N'سازمانی');

/* موقعیت‌های جغرافیایی پایه — ایران (OF0004) */
IF NOT EXISTS (SELECT 1 FROM gnr.GeoPos WHERE GeoType = 1)
BEGIN
  INSERT INTO gnr.GeoPos (Title, GeoType, LatinTitle) VALUES (N'ایران', 1, 'Iran');
  DECLARE @ir smallint = SCOPE_IDENTITY();
  INSERT INTO gnr.GeoPos (ParentRef, Title, GeoType) VALUES
    (@ir, N'تهران', 2), (@ir, N'اصفهان', 2), (@ir, N'خراسان رضوی', 2),
    (@ir, N'فارس', 2), (@ir, N'آذربایجان شرقی', 2);
END
GO

/* ---------------------------------------------------------------------------
   بخش ۵ — تاریخ‌گذاری رخدادها برای جدول‌های ممیزی‌شده (حفظ ردپای موجود)
   --------------------------------------------------------------------------- */
IF OBJECT_ID('Vch.Hdr') IS NOT NULL
  UPDATE Vch.Hdr SET SourceSystem = 'ACC' WHERE SourceSystem = 'ACCWEB' AND CreatedBy <> 'system';
GO

/* ---------------------------------------------------------------------------
   بخش ۶ — راستی‌آزمایی چاپی
   --------------------------------------------------------------------------- */
PRINT '=== gnr layer deployed ===';
SELECT N'gnr.Crspnd' AS tbl, COUNT(*) AS rows FROM gnr.Crspnd
UNION ALL SELECT N'gnr.Address', COUNT(*) FROM gnr.Address
UNION ALL SELECT N'gnr.GeoPos', COUNT(*) FROM gnr.GeoPos
UNION ALL SELECT N'gnr.CrspndCtgry', COUNT(*) FROM gnr.CrspndCtgry
UNION ALL SELECT N'gnr.MisSetup', COUNT(*) FROM gnr.MisSetup
UNION ALL SELECT N'gnr.Lookup', COUNT(*) FROM gnr.Lookup
UNION ALL SELECT N'gnr.Systems', COUNT(*) FROM gnr.Systems
UNION ALL SELECT N'gnr.gnrHolidays', COUNT(*) FROM gnr.gnrHolidays;
GO
