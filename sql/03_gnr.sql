/* ============================================================================
   YFG ACC-WEB — گام اطلاعات عمومی (شمای pob) — نسخهٔ ۱.۳.۰ (بخش ۱ از ۳: توابع شمسی)
   همتاسازی اطلاعات عمومی فایل‌های اصلی (HumCmp.bpl / GnrGeneral.bpl /
   ConfigCommon.bpl / gnCalndr.bpl / sg.cnt) با نام‌گذاری نقش‌محور و پیشوند YFG
   مطابق دستور کارفرما: نام‌ها عیناً کپی نشود (رعایت حق مؤلف) — معادل‌ها در
   sql/10_migration_v1.2.0_yfg_rename.sql مستند است.
   دستورهای کارفرما:
     ۱) تاریخ شمسی ملاک است → توابع pob.GrgToJalali / pob.JalToGrg + ستون‌های J
     ۲) ستون‌های ممیزی روی همهٔ جدول‌ها (ایجادکننده/ویرایش‌کننده/سیستم مبدأ/...)
     ۳) بله/خیر به‌جای true/false در لایهٔ نمایش (وب)
     ۴) لینک تفصیلی اشخاص به registry عمومی (ACC.AccTafsili.PartyRef)
   اجرای تکرارپذیر (Idempotent).
   ============================================================================ */

IF SCHEMA_ID('pob') IS NULL EXEC('CREATE SCHEMA pob');
GO

/* ---------------------------------------------------------------------------
   بخش ۰ — توابع تاریخ شمسی (پورت وفادار jalaali-js — الگوریتم رسمی گاه‌شمار)
   div= تقسیم صحیح به سمت صفر (مانند T-SQL)، mod باقی‌ماندهٔ همان
   --------------------------------------------------------------------------- */

-- JDN از تاریخ میلادی (g2d)
IF OBJECT_ID('pob._GrgToJdn') IS NULL
EXEC('CREATE FUNCTION pob._GrgToJdn (@gy int, @gm int, @gd int)
RETURNS int
WITH SCHEMABINDING
AS BEGIN
  /* div(gm-8,6) — تقسیم صحیح به‌سوی صفر؛ T-SQL دقیقاً همین رفتار را دارد */
  DECLARE @d int = ((@gy + (@gm - 8) / 6 + 100100) * 1461) / 4
        + (153 * ((@gm + 9) % 12) + 2) / 5
        + @gd - 34840408;
  SET @d = @d - (((@gy + 100100 + (@gm - 8) / 6) / 100) * 3) / 4 + 752;
  RETURN @d;
END;');
GO

-- جدول گسست‌ها (breaks) — هر اندیس یک مقدار
IF OBJECT_ID('pob._JalBreaks') IS NULL
EXEC('CREATE FUNCTION pob._JalBreaks (@i int)
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
END;');
GO

-- روز نوروز (میلادی) برای سال جلالی — jalCal().march
IF OBJECT_ID('pob._JalNowruz') IS NULL
EXEC('CREATE FUNCTION pob._JalNowruz (@jy int)
RETURNS int
WITH SCHEMABINDING
AS BEGIN
  DECLARE @gy int = @jy + 621;
  DECLARE @leapJ int = -14, @jp int = -61, @jm int, @jump int = 0, @n int, @i int;
  SET @i = 1;
  WHILE @i <= 20 BEGIN
    SET @jm = pob._JalBreaks(@i);
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
END;');
GO

-- پرچم کبیسهٔ سال جلالی — jalCal().leap
IF OBJECT_ID('pob._JalLeap') IS NULL
EXEC('CREATE FUNCTION pob._JalLeap (@jy int)
RETURNS int
WITH SCHEMABINDING
AS BEGIN
  DECLARE @leapJ int = -14, @jp int = -61, @jm int, @jump int = 0, @n int, @i int, @leap int;
  SET @i = 1;
  WHILE @i <= 20 BEGIN
    SET @jm = pob._JalBreaks(@i);
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
END;');
GO

-- میلادی→جلالی: d2j(g2d(...))
IF OBJECT_ID('pob.GrgToJalali') IS NULL
EXEC('CREATE FUNCTION pob.GrgToJalali (@d datetime2(0))
RETURNS varchar(10)
WITH SCHEMABINDING
AS BEGIN
  IF @d IS NULL RETURN NULL;
  DECLARE @gy int = DATEPART(YEAR, @d), @gm int = DATEPART(MONTH, @d), @gd int = DATEPART(DAY, @d);
  DECLARE @jdn int = pob._GrgToJdn(@gy, @gm, @gd);
  DECLARE @jy int = @gy - 621;
  DECLARE @march int = pob._JalNowruz(@jy);
  DECLARE @jdn1f int = pob._GrgToJdn(@gy, 3, @march);
  DECLARE @k int = @jdn - @jdn1f;
  DECLARE @jm int, @jd int;
  IF @k >= 0 BEGIN
    IF @k <= 185 BEGIN
      SET @jm = 1 + (@k / 31);
      SET @jd = (@k % 31) + 1;
      RETURN RIGHT(''0000'' + CAST(@jy AS varchar(4)), 4) + ''/'' + RIGHT(''0'' + CAST(@jm AS varchar(2)), 2) + ''/'' + RIGHT(''0'' + CAST(@jd AS varchar(2)), 2);
    END
    SET @k = @k - 186;
  END ELSE BEGIN
    SET @jy = @jy - 1;
    SET @k = @k + 179;
    IF pob._JalLeap(@jy) = 1 SET @k = @k + 1;
  END
  SET @jm = 7 + (@k / 30);
  SET @jd = (@k % 30) + 1;
  RETURN RIGHT(''0000'' + CAST(@jy AS varchar(4)), 4) + ''/'' + RIGHT(''0'' + CAST(@jm AS varchar(2)), 2) + ''/'' + RIGHT(''0'' + CAST(@jd AS varchar(2)), 2);
END;');
GO

-- جلالی→JDN (j2d)
IF OBJECT_ID('pob._JalToJdn') IS NULL
EXEC('CREATE FUNCTION pob._JalToJdn (@jy int, @jm int, @jd int)
RETURNS int
WITH SCHEMABINDING
AS BEGIN
  DECLARE @gy int = @jy + 621;
  DECLARE @march int = pob._JalNowruz(@jy);
  RETURN pob._GrgToJdn(@gy, 3, @march) + (@jm - 1) * 31 - (@jm / 7) * (@jm - 7) + @jd - 1;
END;');
GO

-- JDN→میلادی (d2g) — خروجی 'YYYY-MM-DD'
IF OBJECT_ID('pob._JdnToGrg') IS NULL
EXEC('CREATE FUNCTION pob._JdnToGrg (@jdn int)
RETURNS varchar(10)
WITH SCHEMABINDING
AS BEGIN
  DECLARE @j int = 4 * @jdn + 139361631;
  SET @j = @j + (((4 * @jdn + 183187720) / 146097) * 3) / 4 * 4 - 3908;
  DECLARE @i int = ((@j % 1461) / 4) * 5 + 308;
  DECLARE @gd int = ((@i % 153) / 5) + 1;
  DECLARE @gm int = ((@i / 153) % 12) + 1;
  DECLARE @gy int = (@j / 1461) - 100100 + CASE WHEN @gm > 8 THEN (8 - @gm) / 6 ELSE 0 END + CASE WHEN @gm < 8 THEN (8 - @gm) / 6 ELSE 0 END;
  RETURN RIGHT(''0000'' + CAST(@gy AS varchar(4)), 4) + ''-'' + RIGHT(''0'' + CAST(@gm AS varchar(2)), 2) + ''-'' + RIGHT(''0'' + CAST(@gd AS varchar(2)), 2);
END;');
GO

-- جلالی→میلادی
IF OBJECT_ID('pob.JalToGrg') IS NULL
-- Deterministic: string-to-date CAST depends on session DATEFORMAT, so DATEFROMPARTS is used
EXEC('CREATE FUNCTION pob.JalToGrg (@jal varchar(10))
RETURNS date
WITH SCHEMABINDING
AS BEGIN
  IF @jal IS NULL RETURN NULL;
  DECLARE @jy int = CAST(LEFT(@jal, 4) AS int);
  DECLARE @jm int = CAST(SUBSTRING(@jal, 6, 2) AS int);
  DECLARE @jd int = CAST(RIGHT(@jal, 2) AS int);
  DECLARE @grg varchar(10) = pob._JdnToGrg(pob._JalToJdn(@jy, @jm, @jd));
  DECLARE @gy int = CAST(LEFT(@grg, 4) AS int);
  DECLARE @gmo int = CAST(SUBSTRING(@grg, 6, 2) AS int);
  DECLARE @gda int = CAST(RIGHT(@grg, 2) AS int);
  RETURN DATEFROMPARTS(@gy, @gmo, @gda);
END;');
GO

/* [audit columns moved to 03b_audit.sql — ASCII-only comments, explicit per-table] */
GO

/* ---------------------------------------------------------------------------
   بخش ۲ — جداول اطلاعات عمومی (شمای pob) — ساختار همتای اطلاعات عمومی فایل‌های اصلی
   با نام‌گذاری نقش‌محور YFG (رعایت حق مؤلف):
   HumCmp.bpl → pob.Party / pob.PartyAddress / pob.PartyCategoryLink
   ConfigCommon.bpl → pob.AppSetting / pob.CodeList
   GnrGeneral.bpl → pob.SubSystem / pob.GeoPlace
   gnCalndr.bpl → pob.Holiday / pob.HolidayType / pob.NonWorkingTime
   --------------------------------------------------------------------------- */

/* ۲-۱: اشخاص و شرکت‌های طرف مکاتبه (OF0001/0002/0005/0006 — HumCmp.bpl) */
IF OBJECT_ID('pob.Party') IS NULL
CREATE TABLE pob.Party (
  Serial        bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_Party PRIMARY KEY,
  RecType       char(3)   NOT NULL CONSTRAINT CK_Party_RecType CHECK (RecType IN ('CMP','MAN')), -- CMP=شرکت MAN=شخص
  PartyKind      smallint  NULL,                        -- نوع شرکت/شخص (pob.CodeList type='PartyKind')
  CompName      nvarchar(400) NULL,                    -- نام شرکت (برای شخص: نام همسر/همکار در اصل)
  Title         nvarchar(400) NULL,                    -- عنوان
  FName         nvarchar(200) NULL, LName nvarchar(200) NULL, NickName nvarchar(200) NULL,
  Title_En      varchar(400) NULL, FName_En varchar(200) NULL, LName_En varchar(200) NULL, CompName_En varchar(400) NULL,
  EconCode      varchar(20)  NULL,                     -- کد اقتصادی
  NationalCode  varchar(20)  NULL,                     -- شناسه/کد ملی
  FatherName    nvarchar(200) NULL,
  IDNo          varchar(30)  NULL,                     -- شماره شناسنامه
  MainAddrRef   bigint       NULL,                     -- نشانی اصلی (FK→pob.PartyAddress)
  IsActive      bit          NOT NULL CONSTRAINT DF_Party_Active DEFAULT (1),
  /* ستون‌های ممیزی — استاندارد همهٔ جدول‌ها */
  CreatedBy     varchar(50)  NOT NULL CONSTRAINT DF_Party_CreatedBy DEFAULT ('system'),
  CreatedAt     datetime2(0) NOT NULL CONSTRAINT DF_Party_CreatedAt DEFAULT (SYSDATETIME()),
  UpdatedBy     varchar(50)  NULL,
  UpdatedAt     datetime2(0) NULL,
  SourceSystem  varchar(20)  NOT NULL CONSTRAINT DF_Party_SrcSys DEFAULT ('ACCWEB'),
  CreatedAtJ    AS pob.GrgToJalali(CreatedAt),
  UpdatedAtJ    AS pob.GrgToJalali(UpdatedAt)
);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_Party_NationalCode' AND object_id = OBJECT_ID('pob.Party'))
  CREATE UNIQUE INDEX UQ_Party_NationalCode ON pob.Party (RecType, NationalCode) WHERE NationalCode IS NOT NULL;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Party_Title' AND object_id = OBJECT_ID('pob.Party'))
  CREATE INDEX IX_Party_Title ON pob.Party (Title);
GO

/* ۲-۲: نشانی‌ها (HumCmp.bpl — insert into pob.PartyAddress) */
IF OBJECT_ID('pob.PartyAddress') IS NULL
CREATE TABLE pob.PartyAddress (
  Serial      bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_PartyAddress PRIMARY KEY,
  PartyRef   bigint   NOT NULL CONSTRAINT FK_Address_Party REFERENCES pob.Party(Serial) ON DELETE CASCADE,
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
  GeoPlaceRef   smallint     NULL,  -- موقعیت جغرافیایی (FK بعداً)
  CreatedBy   varchar(50)  NOT NULL CONSTRAINT DF_Address_CreatedBy DEFAULT ('system'),
  CreatedAt   datetime2(0) NOT NULL CONSTRAINT DF_Address_CreatedAt DEFAULT (SYSDATETIME()),
  UpdatedBy   varchar(50)  NULL,
  UpdatedAt   datetime2(0) NULL,
  SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Address_SrcSys DEFAULT ('ACCWEB'),
  CreatedAtJ  AS pob.GrgToJalali(CreatedAt),
  UpdatedAtJ  AS pob.GrgToJalali(UpdatedAt)
);
GO

/* ۲-۳: موقعیت‌های جغرافیایی (OF0004 — TFrmGeoPos در GnrGeneral.bpl) */
IF OBJECT_ID('pob.GeoPlace') IS NULL
CREATE TABLE pob.GeoPlace (
  GeoPlaceId  smallint IDENTITY(1,1) NOT NULL CONSTRAINT PK_GeoPlace PRIMARY KEY,
  ParentRef smallint NULL CONSTRAINT FK_GeoPlace_Parent REFERENCES pob.GeoPlace(GeoPlaceId),
  Title     nvarchar(200) NOT NULL,
  GeoType   tinyint   NOT NULL CONSTRAINT CK_GeoPlace_Type CHECK (GeoType IN (1,2,3,4)), -- 1=کشور 2=استان 3=شهرستان 4=شهر
  LatinTitle varchar(200) NULL,
  CreatedBy  varchar(50)  NOT NULL CONSTRAINT DF_GeoPlace_CreatedBy DEFAULT ('system'),
  CreatedAt  datetime2(0) NOT NULL CONSTRAINT DF_GeoPlace_CreatedAt DEFAULT (SYSDATETIME()),
  UpdatedBy  varchar(50)  NULL,
  UpdatedAt  datetime2(0) NULL,
  SourceSystem varchar(20) NOT NULL CONSTRAINT DF_GeoPlace_SrcSys DEFAULT ('ACCWEB'),
  CreatedAtJ AS pob.GrgToJalali(CreatedAt),
  UpdatedAtJ AS pob.GrgToJalali(UpdatedAt)
);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Address_GeoPlace')
  ALTER TABLE pob.PartyAddress ADD CONSTRAINT FK_Address_GeoPlace FOREIGN KEY (GeoPlaceRef) REFERENCES pob.GeoPlace(GeoPlaceId);
GO

/* ۲-۴: طبقه‌بندی اشخاص و شرکت‌ها (OF0003) + پیوند */
IF OBJECT_ID('pob.PartyCategory') IS NULL
CREATE TABLE pob.PartyCategory (
  CategoryId    smallint IDENTITY(1,1) NOT NULL CONSTRAINT PK_PartyCategory PRIMARY KEY,
  Title      nvarchar(200) NOT NULL,
  ParentRef  smallint NULL CONSTRAINT FK_PartyCategory_Parent REFERENCES pob.PartyCategory(CategoryId),
  CreatedBy  varchar(50)  NOT NULL CONSTRAINT DF_PartyCategory_CreatedBy DEFAULT ('system'),
  CreatedAt  datetime2(0) NOT NULL CONSTRAINT DF_PartyCategory_CreatedAt DEFAULT (SYSDATETIME()),
  UpdatedBy  varchar(50)  NULL,
  UpdatedAt  datetime2(0) NULL,
  SourceSystem varchar(20) NOT NULL CONSTRAINT DF_PartyCategory_SrcSys DEFAULT ('ACCWEB'),
  CreatedAtJ AS pob.GrgToJalali(CreatedAt),
  UpdatedAtJ AS pob.GrgToJalali(UpdatedAt)
);
IF OBJECT_ID('pob.PartyCategoryLink') IS NULL
CREATE TABLE pob.PartyCategoryLink (
  PartyRef bigint   NOT NULL CONSTRAINT FK_PartyCategoryLink_Party REFERENCES pob.Party(Serial) ON DELETE CASCADE,
  CategoryRef  smallint NOT NULL CONSTRAINT FK_PartyCategoryLink_Ctgry REFERENCES pob.PartyCategory(CategoryId),
  CreatedBy varchar(50) NOT NULL DEFAULT('system'),
  CreatedAt datetime2(0) NOT NULL DEFAULT(SYSDATETIME()),
  UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL,
  SourceSystem varchar(20) NOT NULL DEFAULT('ACCWEB'),
  CreatedAtJ AS pob.GrgToJalali(CreatedAt), UpdatedAtJ AS pob.GrgToJalali(UpdatedAt),
  CONSTRAINT PK_PartyCategoryLink PRIMARY KEY (PartyRef, CategoryRef)
);
GO

/* ۲-۵: تنظیمات عمومی (ConfigCommon.bpl — AppSetting: KeyValue/DataValue/SystemName) */
IF OBJECT_ID('pob.AppSetting') IS NULL
CREATE TABLE pob.AppSetting (
  SettingId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_AppSetting PRIMARY KEY,
  KeyValue   varchar(60)  NOT NULL,
  DataValue  nvarchar(400) NOT NULL,
  SystemName varchar(10)  NULL,
  Descr      nvarchar(600) NULL,   -- شرح فارسی برای نمایش
  CreatedBy  varchar(50)  NOT NULL CONSTRAINT DF_AppSetting_CreatedBy DEFAULT ('system'),
  CreatedAt  datetime2(0) NOT NULL CONSTRAINT DF_AppSetting_CreatedAt DEFAULT (SYSDATETIME()),
  UpdatedBy  varchar(50)  NULL,
  UpdatedAt  datetime2(0) NULL,
  SourceSystem varchar(20) NOT NULL CONSTRAINT DF_AppSetting_SrcSys DEFAULT ('ACCWEB'),
  CreatedAtJ AS pob.GrgToJalali(CreatedAt),
  UpdatedAtJ AS pob.GrgToJalali(UpdatedAt),
  CONSTRAINT UQ_AppSetting_Key UNIQUE (KeyValue, SystemName)
);
GO

/* ۲-۶: مرجع عمومی کدها (ConfigCommon.bpl — Lookup: type/code/title/aux/SystemName) */
IF OBJECT_ID('pob.CodeList') IS NULL
CREATE TABLE pob.CodeList (
  CodeId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_CodeList PRIMARY KEY,
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
  CreatedAtJ AS pob.GrgToJalali(CreatedAt),
  UpdatedAtJ AS pob.GrgToJalali(UpdatedAt),
  CONSTRAINT UQ_CodeList_TypeCode UNIQUE ([Type], Code)
);
GO

/* ۲-۷: ثبت سامانه‌ها (GnrGeneral.bpl — pob.SubSystem) */
IF OBJECT_ID('pob.SubSystem') IS NULL
CREATE TABLE pob.SubSystem (
  SystemCode varchar(10) NOT NULL CONSTRAINT PK_SubSystem PRIMARY KEY,
  TitleFa    nvarchar(200) NOT NULL,
  LatinTitle varchar(100) NULL,
  IsActive   bit NOT NULL CONSTRAINT DF_Systems_Active DEFAULT (1),
  CreatedBy  varchar(50)  NOT NULL CONSTRAINT DF_Systems_CreatedBy DEFAULT ('system'),
  CreatedAt  datetime2(0) NOT NULL CONSTRAINT DF_Systems_CreatedAt DEFAULT (SYSDATETIME()),
  UpdatedBy  varchar(50)  NULL,
  UpdatedAt  datetime2(0) NULL,
  SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Systems_SrcSys DEFAULT ('ACCWEB'),
  CreatedAtJ AS pob.GrgToJalali(CreatedAt),
  UpdatedAtJ AS pob.GrgToJalali(UpdatedAt)
);
GO

/* ۲-۸: تولید شناسه (pob.IdSequence — مطابق اصل) */
IF OBJECT_ID('pob.IdSequence') IS NULL
CREATE TABLE pob.IdSequence (
  TableName varchar(60) NOT NULL CONSTRAINT PK_IdSequence PRIMARY KEY,
  LastId    bigint NOT NULL DEFAULT (0),
  CreatedBy varchar(50) NOT NULL DEFAULT ('system'),
  CreatedAt datetime2(0) NOT NULL DEFAULT (SYSDATETIME()),
  UpdatedBy varchar(50) NULL,
  UpdatedAt datetime2(0) NULL,
  SourceSystem varchar(20) NOT NULL DEFAULT ('ACCWEB')
);
GO

/* ۲-۹: تقویم و تعطیلات (gnCalndr.bpl — pob.HolidayType/pob.Holiday/pob.NonWorkingTime) */
IF OBJECT_ID('pob.HolidayType') IS NULL
CREATE TABLE pob.HolidayType (
  HolidayTypeId smallint IDENTITY(1,1) NOT NULL CONSTRAINT PK_HolidayType PRIMARY KEY,
  Title nvarchar(100) NOT NULL,
  IsActive bit NOT NULL DEFAULT (1),
  CreatedBy varchar(50) NOT NULL DEFAULT ('system'),
  CreatedAt datetime2(0) NOT NULL DEFAULT (SYSDATETIME()),
  UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL,
  SourceSystem varchar(20) NOT NULL DEFAULT ('ACCWEB'),
  CreatedAtJ AS pob.GrgToJalali(CreatedAt)
);
IF OBJECT_ID('pob.Holiday') IS NULL
CREATE TABLE pob.Holiday (
  HolidayId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_Holiday PRIMARY KEY,
  JDate     char(10) NOT NULL,          -- تاریخ شمسی ملاک
  GDate     AS pob.JalToGrg(JDate) PERSISTED,
  HolidayTypeRef smallint NULL CONSTRAINT FK_Holiday_Type REFERENCES pob.HolidayType(HolidayTypeId),
  Descr     nvarchar(400) NULL,
  CreatedBy varchar(50) NOT NULL DEFAULT ('system'),
  CreatedAt datetime2(0) NOT NULL DEFAULT (SYSDATETIME()),
  UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL,
  SourceSystem varchar(20) NOT NULL DEFAULT ('ACCWEB'),
  CreatedAtJ AS pob.GrgToJalali(CreatedAt),
  CONSTRAINT UQ_Holiday_JDate UNIQUE (JDate)
);
IF OBJECT_ID('pob.NonWorkingTime') IS NULL
CREATE TABLE pob.NonWorkingTime (
  NonWorkId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_NonWorkingTime PRIMARY KEY,
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
   بخش ۳ — لینک اطلاعات عمومی به حسابداری (الگوی اصل: PartyRef)
   تفصیلیِ نوع «شخص/شرکت» به registry عمومی گره می‌خورد
   --------------------------------------------------------------------------- */
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('ACC.AccTafsili') AND name = 'PartyRef')
  ALTER TABLE ACC.AccTafsili ADD PartyRef bigint NULL CONSTRAINT FK_Tafsili_Party REFERENCES pob.Party(Serial);
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('ACC.AccTafsiliType') AND name = 'CodeListType')
  ALTER TABLE ACC.AccTafsiliType ADD CodeListType varchar(40) NULL; -- نوع مرتبط در pob.CodeList (مثل PartyKind)
GO

/* ---------------------------------------------------------------------------
   بخش ۴ — داده‌های پایهٔ اطلاعات عمومی
   --------------------------------------------------------------------------- */

/* سامانه‌ها (مطابق Systems اصل) */
IF NOT EXISTS (SELECT 1 FROM pob.SubSystem WHERE SystemCode = 'ACC')
  INSERT INTO pob.SubSystem (SystemCode, TitleFa, LatinTitle) VALUES ('ACC', N'حسابداری', 'Accounting');
IF NOT EXISTS (SELECT 1 FROM pob.SubSystem WHERE SystemCode = 'GEN')
  INSERT INTO pob.SubSystem (SystemCode, TitleFa, LatinTitle) VALUES ('GEN', N'اطلاعات عمومی', 'General');

/* تنظیمات عمومی — الگوی SgDefaultData/AppSetting اصل (تقویم شمسی ملاک) */
IF NOT EXISTS (SELECT 1 FROM pob.AppSetting WHERE KeyValue = 'DefaultCalendar')
  INSERT INTO pob.AppSetting (KeyValue, DataValue, SystemName, Descr) VALUES
    ('DefaultCalendar', N'HEJRI', 'GEN', N'تقویم پیش‌فرض سامانه — شمسی ملاک است (دستور کارفرما)');
IF NOT EXISTS (SELECT 1 FROM pob.AppSetting WHERE KeyValue = 'StartMonth')
  INSERT INTO pob.AppSetting (KeyValue, DataValue, SystemName, Descr) VALUES
    ('StartMonth', N'1', 'GEN', N'ماه شروع سال مالی (فروردین)');
IF NOT EXISTS (SELECT 1 FROM pob.AppSetting WHERE KeyValue = 'AccLen')
  INSERT INTO pob.AppSetting (KeyValue, DataValue, SystemName, Descr) VALUES
    ('AccLen', N'4', 'ACC', N'تعداد ارقام حساب کل');
IF NOT EXISTS (SELECT 1 FROM pob.AppSetting WHERE KeyValue = 'DlLen')
  INSERT INTO pob.AppSetting (KeyValue, DataValue, SystemName, Descr) VALUES
    ('DlLen', N'8', 'ACC', N'تعداد ارقام حساب تفصیلی (DLKEYLEN اصل)');
IF NOT EXISTS (SELECT 1 FROM pob.AppSetting WHERE KeyValue = 'VchNoStart')
  INSERT INTO pob.AppSetting (KeyValue, DataValue, SystemName, Descr) VALUES
    ('VchNoStart', N'1', 'ACC', N'شروع شماره اسناد حسابداری');
IF NOT EXISTS (SELECT 1 FROM pob.AppSetting WHERE KeyValue = 'BoolDisplay')
  INSERT INTO pob.AppSetting (KeyValue, DataValue, SystemName, Descr) VALUES
    ('BoolDisplay', N'بله/خیر', 'GEN', N'نمایش مقادیر منطقی: بله/خیر (به‌جای true/false) — دستور کارفرما');
IF NOT EXISTS (SELECT 1 FROM pob.AppSetting WHERE KeyValue = 'DateStandard')
  INSERT INTO pob.AppSetting (KeyValue, DataValue, SystemName, Descr) VALUES
    ('DateStandard', N'JALALI', 'GEN', N'استاندارد تاریخ: شمسی (تاریخ ایجاد/ویرایش/اسناد)');

/* انواع شخص/شرکت — PartyKind (الگوی vwCompType اصل) */
IF NOT EXISTS (SELECT 1 FROM pob.CodeList WHERE [Type] = 'PartyKind' AND Code = 1)
  INSERT INTO pob.CodeList ([Type], Code, Title, SystemName) VALUES ('PartyKind', 1, N'شخص حقیقی', 'GEN');
IF NOT EXISTS (SELECT 1 FROM pob.CodeList WHERE [Type] = 'PartyKind' AND Code = 2)
  INSERT INTO pob.CodeList ([Type], Code, Title, SystemName) VALUES ('PartyKind', 2, N'شخص حقوقی', 'GEN');
IF NOT EXISTS (SELECT 1 FROM pob.CodeList WHERE [Type] = 'PartyKind' AND Code = 3)
  INSERT INTO pob.CodeList ([Type], Code, Title, SystemName) VALUES ('PartyKind', 3, N'موسسه دولتی', 'GEN');

/* انواع تعطیلات (gnCalndr اصل) */
IF NOT EXISTS (SELECT 1 FROM pob.HolidayType WHERE Title = N'رسمی')
  INSERT INTO pob.HolidayType (Title) VALUES (N'رسمی');
IF NOT EXISTS (SELECT 1 FROM pob.HolidayType WHERE Title = N'مذهبی')
  INSERT INTO pob.HolidayType (Title) VALUES (N'مذهبی');
IF NOT EXISTS (SELECT 1 FROM pob.HolidayType WHERE Title = N'سازمانی')
  INSERT INTO pob.HolidayType (Title) VALUES (N'سازمانی');

/* موقعیت‌های جغرافیایی پایه — ایران (OF0004) */
IF NOT EXISTS (SELECT 1 FROM pob.GeoPlace WHERE GeoType = 1)
BEGIN
  INSERT INTO pob.GeoPlace (Title, GeoType, LatinTitle) VALUES (N'ایران', 1, 'Iran');
  DECLARE @ir smallint = SCOPE_IDENTITY();
  INSERT INTO pob.GeoPlace (ParentRef, Title, GeoType) VALUES
    (@ir, N'تهران', 2), (@ir, N'اصفهان', 2), (@ir, N'خراسان رضوی', 2),
    (@ir, N'فارس', 2), (@ir, N'آذربایجان شرقی', 2);
END
GO

/* ---------------------------------------------------------------------------
   بخش ۵ — تاریخ‌گذاری رخدادها برای جدول‌های ممیزی‌شده (حفظ ردپای موجود)
   --------------------------------------------------------------------------- */
IF OBJECT_ID('ACC.AccVoucher') IS NOT NULL
  UPDATE ACC.AccVoucher SET SourceSystem = 'ACC' WHERE SourceSystem = 'ACCWEB' AND CreatedBy <> 'system';
GO

/* ---------------------------------------------------------------------------
   بخش ۶ — راستی‌آزمایی چاپی
   --------------------------------------------------------------------------- */
PRINT '=== pob layer deployed ===';
SELECT N'pob.Party' AS tbl, COUNT(*) AS rows FROM pob.Party
UNION ALL SELECT N'pob.PartyAddress', COUNT(*) FROM pob.PartyAddress
UNION ALL SELECT N'pob.GeoPlace', COUNT(*) FROM pob.GeoPlace
UNION ALL SELECT N'pob.PartyCategory', COUNT(*) FROM pob.PartyCategory
UNION ALL SELECT N'pob.AppSetting', COUNT(*) FROM pob.AppSetting
UNION ALL SELECT N'pob.CodeList', COUNT(*) FROM pob.CodeList
UNION ALL SELECT N'pob.SubSystem', COUNT(*) FROM pob.SubSystem
UNION ALL SELECT N'pob.Holiday', COUNT(*) FROM pob.Holiday;
GO
