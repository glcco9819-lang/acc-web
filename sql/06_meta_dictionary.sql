/* ============================================================
   YFG ACC-WEB — دیتابیس acc — ۰۶: واژه‌نامهٔ داده (درخواست کارفرما)
   سه جدول مرجع برای مستندسازی خودکار دیتابیس:
     YFG.TableName  : نام جدول انگلیسی + شمای جدول + نام فارسی بر اساس نقش (مثل «لیست اسناد»)
     YFG.FieldName  : نام فیلد + نام جدول + شما + نام فارسی بر اساس نقش (مثل «شماره سند») + ماژول
     YFG.LinkField  : فیلد مبدأ + فیلد لینک + جدول/شمای لینک + نام فارسی + نقش فیلد در پیوند
   هم‌گام‌سازی خودکار: هر بار اجرا، جدول‌ها/ستون‌های تازه از INFORMATION_SCHEMA ثبت می‌شوند
   و نام‌های فارسی شناخته‌شده تازه‌سازی می‌گردند — اجرای مجدد بی‌خطر است (Idempotent)
   استانداردها: بله/خیر bit · ستون‌های ممیزی کامل · SourceSystem · تریگر UserLog
   ============================================================ */

/* ---------- بخش ۱: شمای YFG ---------- */
IF SCHEMA_ID('YFG') IS NULL EXEC('CREATE SCHEMA YFG');
GO
/* ---------- بخش ۲: YFG.TableName ---------- */
IF OBJECT_ID('YFG.TableName') IS NULL
CREATE TABLE YFG.TableName (
  TableId   int          IDENTITY(1,1) NOT NULL CONSTRAINT PK_YFG_TableName PRIMARY KEY,
  TableSchema varchar(50)   NOT NULL,                /* شمای جدول */
  TableName varchar(128)  NOT NULL,                /* نام جدول انگلیسی */
  TableFa   nvarchar(200) NOT NULL,                /* نام فارسی بر اساس نقش */
  Module    nvarchar(50)  NOT NULL CONSTRAINT DF_YFGT_Module DEFAULT(N'عمومی'), /* ماژول */
  IsLookup  bit           NOT NULL CONSTRAINT DF_YFGT_Lookup DEFAULT(0),        /* جدول مرجع — بله/خیر */
  IsActive  bit           NOT NULL CONSTRAINT DF_YFGT_Active DEFAULT(1),
  CreatedBy varchar(50)   NOT NULL CONSTRAINT DF_YFGT_CB DEFAULT('system'),
  CreatedAt datetime2(0)  NOT NULL CONSTRAINT DF_YFGT_CA DEFAULT(SYSDATETIME()),
  UpdatedBy varchar(50)   NULL,
  UpdatedAt datetime2(0)  NULL,
  SourceSystem varchar(20) NOT NULL CONSTRAINT DF_YFGT_SS DEFAULT('ACCWEB'),
  CreatedAtJ AS pob.GrgToJalali(CreatedAt),
  UpdatedAtJ AS pob.GrgToJalali(UpdatedAt),
  CONSTRAINT UQ_YFG_TableName UNIQUE(TableSchema, TableName)
);
GO

/* ---------- بخش ۳: YFG.FieldName ---------- */
IF OBJECT_ID('YFG.FieldName') IS NULL
CREATE TABLE YFG.FieldName (
  FieldId   int          IDENTITY(1,1) NOT NULL CONSTRAINT PK_YFG_FieldName PRIMARY KEY,
  TableSchema varchar(50)   NOT NULL,                /* شما */
  TableName varchar(128)  NOT NULL,                /* نام تیبل */
  FieldName varchar(128)  NOT NULL,                /* نام فیلد انگلیسی */
  FieldFa   nvarchar(200) NOT NULL,                /* نام فارسی بر اساس نقش */
  Module    nvarchar(50)  NOT NULL CONSTRAINT DF_YFGF_Module DEFAULT(N'عمومی'), /* ماژول */
  DataType  varchar(30)   NULL,                    /* نوع داده */
  IsActive  bit           NOT NULL CONSTRAINT DF_YFGF_Active DEFAULT(1),
  CreatedBy varchar(50)   NOT NULL CONSTRAINT DF_YFGF_CB DEFAULT('system'),
  CreatedAt datetime2(0)  NOT NULL CONSTRAINT DF_YFGF_CA DEFAULT(SYSDATETIME()),
  UpdatedBy varchar(50)   NULL,
  UpdatedAt datetime2(0)  NULL,
  SourceSystem varchar(20) NOT NULL CONSTRAINT DF_YFGF_SS DEFAULT('ACCWEB'),
  CreatedAtJ AS pob.GrgToJalali(CreatedAt),
  UpdatedAtJ AS pob.GrgToJalali(UpdatedAt),
  CONSTRAINT UQ_YFG_FieldName UNIQUE(TableSchema, TableName, FieldName)
);
GO

/* ---------- بخش ۴: YFG.LinkField ---------- */
IF OBJECT_ID('YFG.LinkField') IS NULL
CREATE TABLE YFG.LinkField (
  LinkId    int          IDENTITY(1,1) NOT NULL CONSTRAINT PK_YFG_LinkField PRIMARY KEY,
  TableSchema varchar(50)   NOT NULL,                /* شمای جدول مبدأ */
  TableName varchar(128)  NOT NULL,                /* نام جدول مبدأ */
  FieldName varchar(128)  NOT NULL,                /* نام فیلد مبدأ */
  FieldFa   nvarchar(200) NOT NULL,                /* نام فارسی فیلد بر اساس نقش */
  LinkTableSchema varchar(50)  NOT NULL,           /* شمای تیبل لینک */
  LinkTableName varchar(128) NOT NULL,            /* نام تیبل لینک */
  LinkFieldName varchar(128) NOT NULL,            /* نام فیلد لینک */
  LinkFieldFa nvarchar(200) NOT NULL,             /* نام فارسی فیلد لینک */
  LinkRole  nvarchar(200) NULL,                   /* نقش فیلد در فیلد لینک */
  IsActive  bit           NOT NULL CONSTRAINT DF_YFGL_Active DEFAULT(1),
  CreatedBy varchar(50)   NOT NULL CONSTRAINT DF_YFGL_CB DEFAULT('system'),
  CreatedAt datetime2(0)  NOT NULL CONSTRAINT DF_YFGL_CA DEFAULT(SYSDATETIME()),
  UpdatedBy varchar(50)   NULL,
  UpdatedAt datetime2(0)  NULL,
  SourceSystem varchar(20) NOT NULL CONSTRAINT DF_YFGL_SS DEFAULT('ACCWEB'),
  CreatedAtJ AS pob.GrgToJalali(CreatedAt),
  UpdatedAtJ AS pob.GrgToJalali(UpdatedAt),
  CONSTRAINT UQ_YFG_LinkField UNIQUE(TableSchema, TableName, FieldName, LinkTableSchema, LinkTableName, LinkFieldName)
);
GO

/* ---------- بخش ۵: ثبت جدول‌ها (نام فارسی بر اساس نقش) — هم‌گام‌سازی ---------- */
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='ACC' AND TableName='AccBranch')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  VALUES ('ACC', 'AccBranch', N'تعریف شعب', N'حسابداری', 1);
UPDATE YFG.TableName SET TableFa=N'تعریف شعب', Module=N'حسابداری', IsLookup=1
WHERE TableSchema='ACC' AND TableName='AccBranch' AND (TableFa<>N'تعریف شعب' OR Module<>N'حسابداری' OR IsLookup<>1);
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='ACC' AND TableName='AccFx')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  VALUES ('ACC', 'AccFx', N'تعریف ارزها', N'حسابداری', 1);
UPDATE YFG.TableName SET TableFa=N'تعریف ارزها', Module=N'حسابداری', IsLookup=1
WHERE TableSchema='ACC' AND TableName='AccFx' AND (TableFa<>N'تعریف ارزها' OR Module<>N'حسابداری' OR IsLookup<>1);
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='ACC' AND TableName='AccGroup')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  VALUES ('ACC', 'AccGroup', N'گروه‌های حساب کل', N'حسابداری', 1);
UPDATE YFG.TableName SET TableFa=N'گروه‌های حساب کل', Module=N'حسابداری', IsLookup=1
WHERE TableSchema='ACC' AND TableName='AccGroup' AND (TableFa<>N'گروه‌های حساب کل' OR Module<>N'حسابداری' OR IsLookup<>1);
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='ACC' AND TableName='AccKol')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  VALUES ('ACC', 'AccKol', N'کدینگ حساب‌های کل', N'حسابداری', 1);
UPDATE YFG.TableName SET TableFa=N'کدینگ حساب‌های کل', Module=N'حسابداری', IsLookup=1
WHERE TableSchema='ACC' AND TableName='AccKol' AND (TableFa<>N'کدینگ حساب‌های کل' OR Module<>N'حسابداری' OR IsLookup<>1);
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='ACC' AND TableName='AccMoein')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  VALUES ('ACC', 'AccMoein', N'کدینگ حساب‌های معین', N'حسابداری', 1);
UPDATE YFG.TableName SET TableFa=N'کدینگ حساب‌های معین', Module=N'حسابداری', IsLookup=1
WHERE TableSchema='ACC' AND TableName='AccMoein' AND (TableFa<>N'کدینگ حساب‌های معین' OR Module<>N'حسابداری' OR IsLookup<>1);
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='ACC' AND TableName='AccOpeningBalance')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  VALUES ('ACC', 'AccOpeningBalance', N'ماندهٔ افتتاحیهٔ حساب‌ها', N'حسابداری', 0);
UPDATE YFG.TableName SET TableFa=N'ماندهٔ افتتاحیهٔ حساب‌ها', Module=N'حسابداری', IsLookup=0
WHERE TableSchema='ACC' AND TableName='AccOpeningBalance' AND (TableFa<>N'ماندهٔ افتتاحیهٔ حساب‌ها' OR Module<>N'حسابداری' OR IsLookup<>0);
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='ACC' AND TableName='AccStdNarration')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  VALUES ('ACC', 'AccStdNarration', N'شرح‌های استاندارد سند', N'حسابداری', 1);
UPDATE YFG.TableName SET TableFa=N'شرح‌های استاندارد سند', Module=N'حسابداری', IsLookup=1
WHERE TableSchema='ACC' AND TableName='AccStdNarration' AND (TableFa<>N'شرح‌های استاندارد سند' OR Module<>N'حسابداری' OR IsLookup<>1);
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='ACC' AND TableName='AccTafsili')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  VALUES ('ACC', 'AccTafsili', N'حساب‌های تفصیلی', N'حسابداری', 1);
UPDATE YFG.TableName SET TableFa=N'حساب‌های تفصیلی', Module=N'حسابداری', IsLookup=1
WHERE TableSchema='ACC' AND TableName='AccTafsili' AND (TableFa<>N'حساب‌های تفصیلی' OR Module<>N'حسابداری' OR IsLookup<>1);
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='ACC' AND TableName='AccTafsiliCategory')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  VALUES ('ACC', 'AccTafsiliCategory', N'طبقه‌بندی تفصیلی', N'حسابداری', 1);
UPDATE YFG.TableName SET TableFa=N'طبقه‌بندی تفصیلی', Module=N'حسابداری', IsLookup=1
WHERE TableSchema='ACC' AND TableName='AccTafsiliCategory' AND (TableFa<>N'طبقه‌بندی تفصیلی' OR Module<>N'حسابداری' OR IsLookup<>1);
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='ACC' AND TableName='AccTafsiliCategoryLink')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  VALUES ('ACC', 'AccTafsiliCategoryLink', N'پیوند تفصیلی به طبقه‌بندی', N'حسابداری', 0);
UPDATE YFG.TableName SET TableFa=N'پیوند تفصیلی به طبقه‌بندی', Module=N'حسابداری', IsLookup=0
WHERE TableSchema='ACC' AND TableName='AccTafsiliCategoryLink' AND (TableFa<>N'پیوند تفصیلی به طبقه‌بندی' OR Module<>N'حسابداری' OR IsLookup<>0);
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='ACC' AND TableName='AccTafsiliType')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  VALUES ('ACC', 'AccTafsiliType', N'انواع تفصیلی', N'حسابداری', 1);
UPDATE YFG.TableName SET TableFa=N'انواع تفصیلی', Module=N'حسابداری', IsLookup=1
WHERE TableSchema='ACC' AND TableName='AccTafsiliType' AND (TableFa<>N'انواع تفصیلی' OR Module<>N'حسابداری' OR IsLookup<>1);
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='ACC' AND TableName='AccVoucher')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  VALUES ('ACC', 'AccVoucher', N'اسناد حسابداری (لیست اسناد)', N'حسابداری', 0);
UPDATE YFG.TableName SET TableFa=N'اسناد حسابداری (لیست اسناد)', Module=N'حسابداری', IsLookup=0
WHERE TableSchema='ACC' AND TableName='AccVoucher' AND (TableFa<>N'اسناد حسابداری (لیست اسناد)' OR Module<>N'حسابداری' OR IsLookup<>0);
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='ACC' AND TableName='AccVoucherFlow')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  VALUES ('ACC', 'AccVoucherFlow', N'جریان وضعیت اسناد', N'حسابداری', 0);
UPDATE YFG.TableName SET TableFa=N'جریان وضعیت اسناد', Module=N'حسابداری', IsLookup=0
WHERE TableSchema='ACC' AND TableName='AccVoucherFlow' AND (TableFa<>N'جریان وضعیت اسناد' OR Module<>N'حسابداری' OR IsLookup<>0);
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='ACC' AND TableName='AccVoucherItm')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  VALUES ('ACC', 'AccVoucherItm', N'اقلام اسناد حسابداری', N'حسابداری', 0);
UPDATE YFG.TableName SET TableFa=N'اقلام اسناد حسابداری', Module=N'حسابداری', IsLookup=0
WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND (TableFa<>N'اقلام اسناد حسابداری' OR Module<>N'حسابداری' OR IsLookup<>0);
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='ACC' AND TableName='AccVoucherType')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  VALUES ('ACC', 'AccVoucherType', N'انواع سند حسابداری', N'حسابداری', 1);
UPDATE YFG.TableName SET TableFa=N'انواع سند حسابداری', Module=N'حسابداری', IsLookup=1
WHERE TableSchema='ACC' AND TableName='AccVoucherType' AND (TableFa<>N'انواع سند حسابداری' OR Module<>N'حسابداری' OR IsLookup<>1);
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='ACC' AND TableName='AccVwChart')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  VALUES ('ACC', 'AccVwChart', N'نمای درختی کدینگ حساب‌ها', N'حسابداری', 0);
UPDATE YFG.TableName SET TableFa=N'نمای درختی کدینگ حساب‌ها', Module=N'حسابداری', IsLookup=0
WHERE TableSchema='ACC' AND TableName='AccVwChart' AND (TableFa<>N'نمای درختی کدینگ حساب‌ها' OR Module<>N'حسابداری' OR IsLookup<>0);
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='YFG' AND TableName='FieldName')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  VALUES ('YFG', 'FieldName', N'واژه‌نامهٔ فیلدها', N'واژه‌نامه', 1);
UPDATE YFG.TableName SET TableFa=N'واژه‌نامهٔ فیلدها', Module=N'واژه‌نامه', IsLookup=1
WHERE TableSchema='YFG' AND TableName='FieldName' AND (TableFa<>N'واژه‌نامهٔ فیلدها' OR Module<>N'واژه‌نامه' OR IsLookup<>1);
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='YFG' AND TableName='LinkField')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  VALUES ('YFG', 'LinkField', N'واژه‌نامهٔ پیوندها', N'واژه‌نامه', 1);
UPDATE YFG.TableName SET TableFa=N'واژه‌نامهٔ پیوندها', Module=N'واژه‌نامه', IsLookup=1
WHERE TableSchema='YFG' AND TableName='LinkField' AND (TableFa<>N'واژه‌نامهٔ پیوندها' OR Module<>N'واژه‌نامه' OR IsLookup<>1);
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='YFG' AND TableName='TableName')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  VALUES ('YFG', 'TableName', N'واژه‌نامهٔ جدول‌ها', N'واژه‌نامه', 1);
UPDATE YFG.TableName SET TableFa=N'واژه‌نامهٔ جدول‌ها', Module=N'واژه‌نامه', IsLookup=1
WHERE TableSchema='YFG' AND TableName='TableName' AND (TableFa<>N'واژه‌نامهٔ جدول‌ها' OR Module<>N'واژه‌نامه' OR IsLookup<>1);
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='pob' AND TableName='AppSetting')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  VALUES ('pob', 'AppSetting', N'تنظیمات برنامه', N'عمومی (بستر)', 1);
UPDATE YFG.TableName SET TableFa=N'تنظیمات برنامه', Module=N'عمومی (بستر)', IsLookup=1
WHERE TableSchema='pob' AND TableName='AppSetting' AND (TableFa<>N'تنظیمات برنامه' OR Module<>N'عمومی (بستر)' OR IsLookup<>1);
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='pob' AND TableName='AppUser')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  VALUES ('pob', 'AppUser', N'کاربران برنامه', N'عمومی (بستر)', 1);
UPDATE YFG.TableName SET TableFa=N'کاربران برنامه', Module=N'عمومی (بستر)', IsLookup=1
WHERE TableSchema='pob' AND TableName='AppUser' AND (TableFa<>N'کاربران برنامه' OR Module<>N'عمومی (بستر)' OR IsLookup<>1);
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='pob' AND TableName='CodeList')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  VALUES ('pob', 'CodeList', N'فهرست‌های کد ثابت', N'عمومی (بستر)', 1);
UPDATE YFG.TableName SET TableFa=N'فهرست‌های کد ثابت', Module=N'عمومی (بستر)', IsLookup=1
WHERE TableSchema='pob' AND TableName='CodeList' AND (TableFa<>N'فهرست‌های کد ثابت' OR Module<>N'عمومی (بستر)' OR IsLookup<>1);
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='pob' AND TableName='Companies')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  VALUES ('pob', 'Companies', N'لیست شرکت‌ها', N'عمومی (بستر)', 1);
UPDATE YFG.TableName SET TableFa=N'لیست شرکت‌ها', Module=N'عمومی (بستر)', IsLookup=1
WHERE TableSchema='pob' AND TableName='Companies' AND (TableFa<>N'لیست شرکت‌ها' OR Module<>N'عمومی (بستر)' OR IsLookup<>1);
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='pob' AND TableName='FiscalPeriod')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  VALUES ('pob', 'FiscalPeriod', N'دوره‌های مالی (ماه‌ها)', N'عمومی (بستر)', 1);
UPDATE YFG.TableName SET TableFa=N'دوره‌های مالی (ماه‌ها)', Module=N'عمومی (بستر)', IsLookup=1
WHERE TableSchema='pob' AND TableName='FiscalPeriod' AND (TableFa<>N'دوره‌های مالی (ماه‌ها)' OR Module<>N'عمومی (بستر)' OR IsLookup<>1);
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='pob' AND TableName='FiscalYear')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  VALUES ('pob', 'FiscalYear', N'سال‌های مالی', N'عمومی (بستر)', 1);
UPDATE YFG.TableName SET TableFa=N'سال‌های مالی', Module=N'عمومی (بستر)', IsLookup=1
WHERE TableSchema='pob' AND TableName='FiscalYear' AND (TableFa<>N'سال‌های مالی' OR Module<>N'عمومی (بستر)' OR IsLookup<>1);
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='pob' AND TableName='GeoPlace')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  VALUES ('pob', 'GeoPlace', N'تقسیمات جغرافیایی', N'عمومی (بستر)', 1);
UPDATE YFG.TableName SET TableFa=N'تقسیمات جغرافیایی', Module=N'عمومی (بستر)', IsLookup=1
WHERE TableSchema='pob' AND TableName='GeoPlace' AND (TableFa<>N'تقسیمات جغرافیایی' OR Module<>N'عمومی (بستر)' OR IsLookup<>1);
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='pob' AND TableName='Holiday')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  VALUES ('pob', 'Holiday', N'تعطیلات و تقویم', N'عمومی (بستر)', 1);
UPDATE YFG.TableName SET TableFa=N'تعطیلات و تقویم', Module=N'عمومی (بستر)', IsLookup=1
WHERE TableSchema='pob' AND TableName='Holiday' AND (TableFa<>N'تعطیلات و تقویم' OR Module<>N'عمومی (بستر)' OR IsLookup<>1);
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='pob' AND TableName='HolidayType')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  VALUES ('pob', 'HolidayType', N'انواع تعطیلات', N'عمومی (بستر)', 1);
UPDATE YFG.TableName SET TableFa=N'انواع تعطیلات', Module=N'عمومی (بستر)', IsLookup=1
WHERE TableSchema='pob' AND TableName='HolidayType' AND (TableFa<>N'انواع تعطیلات' OR Module<>N'عمومی (بستر)' OR IsLookup<>1);
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='pob' AND TableName='IdSequence')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  VALUES ('pob', 'IdSequence', N'شمارنده‌های یکتا', N'عمومی (بستر)', 0);
UPDATE YFG.TableName SET TableFa=N'شمارنده‌های یکتا', Module=N'عمومی (بستر)', IsLookup=0
WHERE TableSchema='pob' AND TableName='IdSequence' AND (TableFa<>N'شمارنده‌های یکتا' OR Module<>N'عمومی (بستر)' OR IsLookup<>0);
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='pob' AND TableName='NonWorkingTime')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  VALUES ('pob', 'NonWorkingTime', N'ساعات غیرکاری', N'عمومی (بستر)', 1);
UPDATE YFG.TableName SET TableFa=N'ساعات غیرکاری', Module=N'عمومی (بستر)', IsLookup=1
WHERE TableSchema='pob' AND TableName='NonWorkingTime' AND (TableFa<>N'ساعات غیرکاری' OR Module<>N'عمومی (بستر)' OR IsLookup<>1);
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='pob' AND TableName='Party')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  VALUES ('pob', 'Party', N'اشخاص و طرف حساب‌ها', N'عمومی (بستر)', 1);
UPDATE YFG.TableName SET TableFa=N'اشخاص و طرف حساب‌ها', Module=N'عمومی (بستر)', IsLookup=1
WHERE TableSchema='pob' AND TableName='Party' AND (TableFa<>N'اشخاص و طرف حساب‌ها' OR Module<>N'عمومی (بستر)' OR IsLookup<>1);
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='pob' AND TableName='PartyAddress')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  VALUES ('pob', 'PartyAddress', N'نشانی اشخاص', N'عمومی (بستر)', 1);
UPDATE YFG.TableName SET TableFa=N'نشانی اشخاص', Module=N'عمومی (بستر)', IsLookup=1
WHERE TableSchema='pob' AND TableName='PartyAddress' AND (TableFa<>N'نشانی اشخاص' OR Module<>N'عمومی (بستر)' OR IsLookup<>1);
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='pob' AND TableName='PartyCategory')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  VALUES ('pob', 'PartyCategory', N'دسته‌بندی اشخاص', N'عمومی (بستر)', 1);
UPDATE YFG.TableName SET TableFa=N'دسته‌بندی اشخاص', Module=N'عمومی (بستر)', IsLookup=1
WHERE TableSchema='pob' AND TableName='PartyCategory' AND (TableFa<>N'دسته‌بندی اشخاص' OR Module<>N'عمومی (بستر)' OR IsLookup<>1);
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='pob' AND TableName='PartyCategoryLink')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  VALUES ('pob', 'PartyCategoryLink', N'پیوند شخص به دسته‌بندی', N'عمومی (بستر)', 0);
UPDATE YFG.TableName SET TableFa=N'پیوند شخص به دسته‌بندی', Module=N'عمومی (بستر)', IsLookup=0
WHERE TableSchema='pob' AND TableName='PartyCategoryLink' AND (TableFa<>N'پیوند شخص به دسته‌بندی' OR Module<>N'عمومی (بستر)' OR IsLookup<>0);
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='pob' AND TableName='SubSystem')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  VALUES ('pob', 'SubSystem', N'زیرسیستم‌ها', N'عمومی (بستر)', 1);
UPDATE YFG.TableName SET TableFa=N'زیرسیستم‌ها', Module=N'عمومی (بستر)', IsLookup=1
WHERE TableSchema='pob' AND TableName='SubSystem' AND (TableFa<>N'زیرسیستم‌ها' OR Module<>N'عمومی (بستر)' OR IsLookup<>1);
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='pob' AND TableName='UserLog')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  VALUES ('pob', 'UserLog', N'لاگ فعالیت کاربران', N'عمومی (بستر)', 0);
UPDATE YFG.TableName SET TableFa=N'لاگ فعالیت کاربران', Module=N'عمومی (بستر)', IsLookup=0
WHERE TableSchema='pob' AND TableName='UserLog' AND (TableFa<>N'لاگ فعالیت کاربران' OR Module<>N'عمومی (بستر)' OR IsLookup<>0);
GO

/* ---------- بخش ۶: ثبت همهٔ فیلدها (نام فارسی بر اساس نقش) — هم‌گام‌سازی ---------- */
/* --- ACC.AccBranch --- */
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='ACC' AND TableName='AccBranch')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  SELECT 'ACC', 'AccBranch', 'AccBranch', N'حسابداری', 0
  WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccBranch');
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccBranch' AND COLUMN_NAME='BranchId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccBranch' AND FieldName='BranchId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccBranch', 'BranchId', N'شناسهٔ شعبه', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccBranch' AND COLUMN_NAME='BranchId';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ شعبه', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccBranch' AND FieldName='BranchId' AND (FieldFa<>N'شناسهٔ شعبه' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccBranch' AND COLUMN_NAME='Code')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccBranch' AND FieldName='Code')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccBranch', 'Code', N'کد شعبه', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccBranch' AND COLUMN_NAME='Code';
  UPDATE YFG.FieldName SET FieldFa=N'کد شعبه', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccBranch' AND FieldName='Code' AND (FieldFa<>N'کد شعبه' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccBranch' AND COLUMN_NAME='Title')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccBranch' AND FieldName='Title')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccBranch', 'Title', N'عنوان شعبه', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccBranch' AND COLUMN_NAME='Title';
  UPDATE YFG.FieldName SET FieldFa=N'عنوان شعبه', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccBranch' AND FieldName='Title' AND (FieldFa<>N'عنوان شعبه' OR Module<>N'حسابداری');
END
GO
/* --- ACC.AccFx --- */
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='ACC' AND TableName='AccFx')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  SELECT 'ACC', 'AccFx', 'AccFx', N'حسابداری', 0
  WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccFx');
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccFx' AND COLUMN_NAME='Code')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccFx' AND FieldName='Code')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccFx', 'Code', N'کد ارز', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccFx' AND COLUMN_NAME='Code';
  UPDATE YFG.FieldName SET FieldFa=N'کد ارز', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccFx' AND FieldName='Code' AND (FieldFa<>N'کد ارز' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccFx' AND COLUMN_NAME='FxId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccFx' AND FieldName='FxId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccFx', 'FxId', N'شناسهٔ ارز', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccFx' AND COLUMN_NAME='FxId';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ ارز', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccFx' AND FieldName='FxId' AND (FieldFa<>N'شناسهٔ ارز' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccFx' AND COLUMN_NAME='IsBase')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccFx' AND FieldName='IsBase')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccFx', 'IsBase', N'ارز پایه (بله/خیر)', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccFx' AND COLUMN_NAME='IsBase';
  UPDATE YFG.FieldName SET FieldFa=N'ارز پایه (بله/خیر)', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccFx' AND FieldName='IsBase' AND (FieldFa<>N'ارز پایه (بله/خیر)' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccFx' AND COLUMN_NAME='LatinTitle')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccFx' AND FieldName='LatinTitle')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccFx', 'LatinTitle', N'عنوان لاتین ارز', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccFx' AND COLUMN_NAME='LatinTitle';
  UPDATE YFG.FieldName SET FieldFa=N'عنوان لاتین ارز', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccFx' AND FieldName='LatinTitle' AND (FieldFa<>N'عنوان لاتین ارز' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccFx' AND COLUMN_NAME='Title')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccFx' AND FieldName='Title')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccFx', 'Title', N'عنوان ارز', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccFx' AND COLUMN_NAME='Title';
  UPDATE YFG.FieldName SET FieldFa=N'عنوان ارز', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccFx' AND FieldName='Title' AND (FieldFa<>N'عنوان ارز' OR Module<>N'حسابداری');
END
GO
/* --- ACC.AccGroup --- */
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='ACC' AND TableName='AccGroup')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  SELECT 'ACC', 'AccGroup', 'AccGroup', N'حسابداری', 0
  WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccGroup');
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccGroup' AND COLUMN_NAME='AccNature')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccGroup' AND FieldName='AccNature')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccGroup', 'AccNature', N'ماهیت حساب', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccGroup' AND COLUMN_NAME='AccNature';
  UPDATE YFG.FieldName SET FieldFa=N'ماهیت حساب', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccGroup' AND FieldName='AccNature' AND (FieldFa<>N'ماهیت حساب' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccGroup' AND COLUMN_NAME='Code')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccGroup' AND FieldName='Code')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccGroup', 'Code', N'کد گروه', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccGroup' AND COLUMN_NAME='Code';
  UPDATE YFG.FieldName SET FieldFa=N'کد گروه', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccGroup' AND FieldName='Code' AND (FieldFa<>N'کد گروه' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccGroup' AND COLUMN_NAME='GroupId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccGroup' AND FieldName='GroupId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccGroup', 'GroupId', N'شناسهٔ گروه', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccGroup' AND COLUMN_NAME='GroupId';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ گروه', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccGroup' AND FieldName='GroupId' AND (FieldFa<>N'شناسهٔ گروه' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccGroup' AND COLUMN_NAME='Title')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccGroup' AND FieldName='Title')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccGroup', 'Title', N'عنوان گروه', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccGroup' AND COLUMN_NAME='Title';
  UPDATE YFG.FieldName SET FieldFa=N'عنوان گروه', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccGroup' AND FieldName='Title' AND (FieldFa<>N'عنوان گروه' OR Module<>N'حسابداری');
END
GO
/* --- ACC.AccKol --- */
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='ACC' AND TableName='AccKol')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  SELECT 'ACC', 'AccKol', 'AccKol', N'حسابداری', 0
  WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccKol');
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccKol' AND COLUMN_NAME='AccNature')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccKol' AND FieldName='AccNature')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccKol', 'AccNature', N'ماهیت حساب', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccKol' AND COLUMN_NAME='AccNature';
  UPDATE YFG.FieldName SET FieldFa=N'ماهیت حساب', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccKol' AND FieldName='AccNature' AND (FieldFa<>N'ماهیت حساب' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccKol' AND COLUMN_NAME='Code')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccKol' AND FieldName='Code')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccKol', 'Code', N'کد کل', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccKol' AND COLUMN_NAME='Code';
  UPDATE YFG.FieldName SET FieldFa=N'کد کل', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccKol' AND FieldName='Code' AND (FieldFa<>N'کد کل' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccKol' AND COLUMN_NAME='GroupCode')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccKol' AND FieldName='GroupCode')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccKol', 'GroupCode', N'کد گروه', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccKol' AND COLUMN_NAME='GroupCode';
  UPDATE YFG.FieldName SET FieldFa=N'کد گروه', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccKol' AND FieldName='GroupCode' AND (FieldFa<>N'کد گروه' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccKol' AND COLUMN_NAME='KolId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccKol' AND FieldName='KolId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccKol', 'KolId', N'شناسهٔ حساب کل', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccKol' AND COLUMN_NAME='KolId';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ حساب کل', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccKol' AND FieldName='KolId' AND (FieldFa<>N'شناسهٔ حساب کل' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccKol' AND COLUMN_NAME='Title')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccKol' AND FieldName='Title')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccKol', 'Title', N'عنوان کل', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccKol' AND COLUMN_NAME='Title';
  UPDATE YFG.FieldName SET FieldFa=N'عنوان کل', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccKol' AND FieldName='Title' AND (FieldFa<>N'عنوان کل' OR Module<>N'حسابداری');
END
GO
/* --- ACC.AccMoein --- */
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='ACC' AND TableName='AccMoein')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  SELECT 'ACC', 'AccMoein', 'AccMoein', N'حسابداری', 0
  WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccMoein');
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccMoein' AND COLUMN_NAME='AccNature')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccMoein' AND FieldName='AccNature')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccMoein', 'AccNature', N'ماهیت حساب', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccMoein' AND COLUMN_NAME='AccNature';
  UPDATE YFG.FieldName SET FieldFa=N'ماهیت حساب', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccMoein' AND FieldName='AccNature' AND (FieldFa<>N'ماهیت حساب' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccMoein' AND COLUMN_NAME='Code')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccMoein' AND FieldName='Code')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccMoein', 'Code', N'کد معین', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccMoein' AND COLUMN_NAME='Code';
  UPDATE YFG.FieldName SET FieldFa=N'کد معین', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccMoein' AND FieldName='Code' AND (FieldFa<>N'کد معین' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccMoein' AND COLUMN_NAME='Countable')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccMoein' AND FieldName='Countable')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccMoein', 'Countable', N'قابل شمارش (بله/خیر)', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccMoein' AND COLUMN_NAME='Countable';
  UPDATE YFG.FieldName SET FieldFa=N'قابل شمارش (بله/خیر)', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccMoein' AND FieldName='Countable' AND (FieldFa<>N'قابل شمارش (بله/خیر)' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccMoein' AND COLUMN_NAME='FxConvertible')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccMoein' AND FieldName='FxConvertible')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccMoein', 'FxConvertible', N'قابل تبدیل ارز (بله/خیر)', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccMoein' AND COLUMN_NAME='FxConvertible';
  UPDATE YFG.FieldName SET FieldFa=N'قابل تبدیل ارز (بله/خیر)', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccMoein' AND FieldName='FxConvertible' AND (FieldFa<>N'قابل تبدیل ارز (بله/خیر)' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccMoein' AND COLUMN_NAME='IsFx')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccMoein' AND FieldName='IsFx')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccMoein', 'IsFx', N'ارزی (بله/خیر)', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccMoein' AND COLUMN_NAME='IsFx';
  UPDATE YFG.FieldName SET FieldFa=N'ارزی (بله/خیر)', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccMoein' AND FieldName='IsFx' AND (FieldFa<>N'ارزی (بله/خیر)' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccMoein' AND COLUMN_NAME='KolCode')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccMoein' AND FieldName='KolCode')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccMoein', 'KolCode', N'کد کل', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccMoein' AND COLUMN_NAME='KolCode';
  UPDATE YFG.FieldName SET FieldFa=N'کد کل', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccMoein' AND FieldName='KolCode' AND (FieldFa<>N'کد کل' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccMoein' AND COLUMN_NAME='MoeinId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccMoein' AND FieldName='MoeinId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccMoein', 'MoeinId', N'شناسهٔ حساب معین', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccMoein' AND COLUMN_NAME='MoeinId';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ حساب معین', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccMoein' AND FieldName='MoeinId' AND (FieldFa<>N'شناسهٔ حساب معین' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccMoein' AND COLUMN_NAME='Taf1TypeId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccMoein' AND FieldName='Taf1TypeId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccMoein', 'Taf1TypeId', N'نوع تفصیلی سطح ۴', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccMoein' AND COLUMN_NAME='Taf1TypeId';
  UPDATE YFG.FieldName SET FieldFa=N'نوع تفصیلی سطح ۴', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccMoein' AND FieldName='Taf1TypeId' AND (FieldFa<>N'نوع تفصیلی سطح ۴' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccMoein' AND COLUMN_NAME='Taf2TypeId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccMoein' AND FieldName='Taf2TypeId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccMoein', 'Taf2TypeId', N'نوع تفصیلی سطح ۵', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccMoein' AND COLUMN_NAME='Taf2TypeId';
  UPDATE YFG.FieldName SET FieldFa=N'نوع تفصیلی سطح ۵', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccMoein' AND FieldName='Taf2TypeId' AND (FieldFa<>N'نوع تفصیلی سطح ۵' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccMoein' AND COLUMN_NAME='Taf3TypeId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccMoein' AND FieldName='Taf3TypeId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccMoein', 'Taf3TypeId', N'نوع تفصیلی سطح ۶', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccMoein' AND COLUMN_NAME='Taf3TypeId';
  UPDATE YFG.FieldName SET FieldFa=N'نوع تفصیلی سطح ۶', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccMoein' AND FieldName='Taf3TypeId' AND (FieldFa<>N'نوع تفصیلی سطح ۶' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccMoein' AND COLUMN_NAME='Title')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccMoein' AND FieldName='Title')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccMoein', 'Title', N'عنوان معین', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccMoein' AND COLUMN_NAME='Title';
  UPDATE YFG.FieldName SET FieldFa=N'عنوان معین', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccMoein' AND FieldName='Title' AND (FieldFa<>N'عنوان معین' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccMoein' AND COLUMN_NAME='Trackable')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccMoein' AND FieldName='Trackable')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccMoein', 'Trackable', N'قابل پیگیری (بله/خیر)', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccMoein' AND COLUMN_NAME='Trackable';
  UPDATE YFG.FieldName SET FieldFa=N'قابل پیگیری (بله/خیر)', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccMoein' AND FieldName='Trackable' AND (FieldFa<>N'قابل پیگیری (بله/خیر)' OR Module<>N'حسابداری');
END
GO
/* --- ACC.AccOpeningBalance --- */
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='ACC' AND TableName='AccOpeningBalance')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  SELECT 'ACC', 'AccOpeningBalance', 'AccOpeningBalance', N'حسابداری', 0
  WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccOpeningBalance');
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccOpeningBalance' AND COLUMN_NAME='Crt')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccOpeningBalance' AND FieldName='Crt')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccOpeningBalance', 'Crt', N'بستانکار', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccOpeningBalance' AND COLUMN_NAME='Crt';
  UPDATE YFG.FieldName SET FieldFa=N'بستانکار', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccOpeningBalance' AND FieldName='Crt' AND (FieldFa<>N'بستانکار' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccOpeningBalance' AND COLUMN_NAME='Dbt')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccOpeningBalance' AND FieldName='Dbt')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccOpeningBalance', 'Dbt', N'بدهکار', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccOpeningBalance' AND COLUMN_NAME='Dbt';
  UPDATE YFG.FieldName SET FieldFa=N'بدهکار', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccOpeningBalance' AND FieldName='Dbt' AND (FieldFa<>N'بدهکار' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccOpeningBalance' AND COLUMN_NAME='KolCode')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccOpeningBalance' AND FieldName='KolCode')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccOpeningBalance', 'KolCode', N'کد کل', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccOpeningBalance' AND COLUMN_NAME='KolCode';
  UPDATE YFG.FieldName SET FieldFa=N'کد کل', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccOpeningBalance' AND FieldName='KolCode' AND (FieldFa<>N'کد کل' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccOpeningBalance' AND COLUMN_NAME='MoeinCode')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccOpeningBalance' AND FieldName='MoeinCode')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccOpeningBalance', 'MoeinCode', N'کد معین', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccOpeningBalance' AND COLUMN_NAME='MoeinCode';
  UPDATE YFG.FieldName SET FieldFa=N'کد معین', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccOpeningBalance' AND FieldName='MoeinCode' AND (FieldFa<>N'کد معین' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccOpeningBalance' AND COLUMN_NAME='ObId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccOpeningBalance' AND FieldName='ObId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccOpeningBalance', 'ObId', N'شناسهٔ ردیف', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccOpeningBalance' AND COLUMN_NAME='ObId';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ ردیف', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccOpeningBalance' AND FieldName='ObId' AND (FieldFa<>N'شناسهٔ ردیف' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccOpeningBalance' AND COLUMN_NAME='Taf1Id')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccOpeningBalance' AND FieldName='Taf1Id')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccOpeningBalance', 'Taf1Id', N'تفصیلی سطح ۴', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccOpeningBalance' AND COLUMN_NAME='Taf1Id';
  UPDATE YFG.FieldName SET FieldFa=N'تفصیلی سطح ۴', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccOpeningBalance' AND FieldName='Taf1Id' AND (FieldFa<>N'تفصیلی سطح ۴' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccOpeningBalance' AND COLUMN_NAME='Taf2Id')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccOpeningBalance' AND FieldName='Taf2Id')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccOpeningBalance', 'Taf2Id', N'تفصیلی سطح ۵', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccOpeningBalance' AND COLUMN_NAME='Taf2Id';
  UPDATE YFG.FieldName SET FieldFa=N'تفصیلی سطح ۵', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccOpeningBalance' AND FieldName='Taf2Id' AND (FieldFa<>N'تفصیلی سطح ۵' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccOpeningBalance' AND COLUMN_NAME='Taf3Id')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccOpeningBalance' AND FieldName='Taf3Id')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccOpeningBalance', 'Taf3Id', N'تفصیلی سطح ۶', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccOpeningBalance' AND COLUMN_NAME='Taf3Id';
  UPDATE YFG.FieldName SET FieldFa=N'تفصیلی سطح ۶', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccOpeningBalance' AND FieldName='Taf3Id' AND (FieldFa<>N'تفصیلی سطح ۶' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccOpeningBalance' AND COLUMN_NAME='YearId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccOpeningBalance' AND FieldName='YearId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccOpeningBalance', 'YearId', N'سال مالی', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccOpeningBalance' AND COLUMN_NAME='YearId';
  UPDATE YFG.FieldName SET FieldFa=N'سال مالی', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccOpeningBalance' AND FieldName='YearId' AND (FieldFa<>N'سال مالی' OR Module<>N'حسابداری');
END
GO
/* --- ACC.AccStdNarration --- */
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='ACC' AND TableName='AccStdNarration')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  SELECT 'ACC', 'AccStdNarration', 'AccStdNarration', N'حسابداری', 0
  WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccStdNarration');
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccStdNarration' AND COLUMN_NAME='DescText')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccStdNarration' AND FieldName='DescText')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccStdNarration', 'DescText', N'متن شرح استاندارد', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccStdNarration' AND COLUMN_NAME='DescText';
  UPDATE YFG.FieldName SET FieldFa=N'متن شرح استاندارد', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccStdNarration' AND FieldName='DescText' AND (FieldFa<>N'متن شرح استاندارد' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccStdNarration' AND COLUMN_NAME='MoeinCode')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccStdNarration' AND FieldName='MoeinCode')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccStdNarration', 'MoeinCode', N'کد معین', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccStdNarration' AND COLUMN_NAME='MoeinCode';
  UPDATE YFG.FieldName SET FieldFa=N'کد معین', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccStdNarration' AND FieldName='MoeinCode' AND (FieldFa<>N'کد معین' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccStdNarration' AND COLUMN_NAME='NarrationId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccStdNarration' AND FieldName='NarrationId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccStdNarration', 'NarrationId', N'شناسهٔ شرح', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccStdNarration' AND COLUMN_NAME='NarrationId';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ شرح', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccStdNarration' AND FieldName='NarrationId' AND (FieldFa<>N'شناسهٔ شرح' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccStdNarration' AND COLUMN_NAME='Seq')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccStdNarration' AND FieldName='Seq')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccStdNarration', 'Seq', N'ترتیب', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccStdNarration' AND COLUMN_NAME='Seq';
  UPDATE YFG.FieldName SET FieldFa=N'ترتیب', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccStdNarration' AND FieldName='Seq' AND (FieldFa<>N'ترتیب' OR Module<>N'حسابداری');
END
GO
/* --- ACC.AccTafsili --- */
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='ACC' AND TableName='AccTafsili')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  SELECT 'ACC', 'AccTafsili', 'AccTafsili', N'حسابداری', 0
  WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccTafsili');
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccTafsili' AND COLUMN_NAME='Code')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccTafsili' AND FieldName='Code')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccTafsili', 'Code', N'کد تفصیلی', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccTafsili' AND COLUMN_NAME='Code';
  UPDATE YFG.FieldName SET FieldFa=N'کد تفصیلی', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccTafsili' AND FieldName='Code' AND (FieldFa<>N'کد تفصیلی' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccTafsili' AND COLUMN_NAME='LatinTitle')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccTafsili' AND FieldName='LatinTitle')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccTafsili', 'LatinTitle', N'عنوان لاتین', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccTafsili' AND COLUMN_NAME='LatinTitle';
  UPDATE YFG.FieldName SET FieldFa=N'عنوان لاتین', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccTafsili' AND FieldName='LatinTitle' AND (FieldFa<>N'عنوان لاتین' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccTafsili' AND COLUMN_NAME='PartyRef')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccTafsili' AND FieldName='PartyRef')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccTafsili', 'PartyRef', N'مرجع شخص', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccTafsili' AND COLUMN_NAME='PartyRef';
  UPDATE YFG.FieldName SET FieldFa=N'مرجع شخص', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccTafsili' AND FieldName='PartyRef' AND (FieldFa<>N'مرجع شخص' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccTafsili' AND COLUMN_NAME='TafsiliId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccTafsili' AND FieldName='TafsiliId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccTafsili', 'TafsiliId', N'شناسهٔ تفصیلی', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccTafsili' AND COLUMN_NAME='TafsiliId';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ تفصیلی', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccTafsili' AND FieldName='TafsiliId' AND (FieldFa<>N'شناسهٔ تفصیلی' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccTafsili' AND COLUMN_NAME='TafsiliTypeId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccTafsili' AND FieldName='TafsiliTypeId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccTafsili', 'TafsiliTypeId', N'نوع تفصیلی', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccTafsili' AND COLUMN_NAME='TafsiliTypeId';
  UPDATE YFG.FieldName SET FieldFa=N'نوع تفصیلی', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccTafsili' AND FieldName='TafsiliTypeId' AND (FieldFa<>N'نوع تفصیلی' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccTafsili' AND COLUMN_NAME='Title')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccTafsili' AND FieldName='Title')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccTafsili', 'Title', N'عنوان تفصیلی', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccTafsili' AND COLUMN_NAME='Title';
  UPDATE YFG.FieldName SET FieldFa=N'عنوان تفصیلی', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccTafsili' AND FieldName='Title' AND (FieldFa<>N'عنوان تفصیلی' OR Module<>N'حسابداری');
END
GO
/* --- ACC.AccTafsiliCategory --- */
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='ACC' AND TableName='AccTafsiliCategory')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  SELECT 'ACC', 'AccTafsiliCategory', 'AccTafsiliCategory', N'حسابداری', 0
  WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccTafsiliCategory');
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccTafsiliCategory' AND COLUMN_NAME='CategoryId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccTafsiliCategory' AND FieldName='CategoryId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccTafsiliCategory', 'CategoryId', N'شناسهٔ طبقه‌بندی', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccTafsiliCategory' AND COLUMN_NAME='CategoryId';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ طبقه‌بندی', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccTafsiliCategory' AND FieldName='CategoryId' AND (FieldFa<>N'شناسهٔ طبقه‌بندی' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccTafsiliCategory' AND COLUMN_NAME='Title')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccTafsiliCategory' AND FieldName='Title')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccTafsiliCategory', 'Title', N'عنوان طبقه‌بندی', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccTafsiliCategory' AND COLUMN_NAME='Title';
  UPDATE YFG.FieldName SET FieldFa=N'عنوان طبقه‌بندی', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccTafsiliCategory' AND FieldName='Title' AND (FieldFa<>N'عنوان طبقه‌بندی' OR Module<>N'حسابداری');
END
GO
/* --- ACC.AccTafsiliCategoryLink --- */
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='ACC' AND TableName='AccTafsiliCategoryLink')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  SELECT 'ACC', 'AccTafsiliCategoryLink', 'AccTafsiliCategoryLink', N'حسابداری', 0
  WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccTafsiliCategoryLink');
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccTafsiliCategoryLink' AND COLUMN_NAME='CategoryId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccTafsiliCategoryLink' AND FieldName='CategoryId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccTafsiliCategoryLink', 'CategoryId', N'طبقه‌بندی', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccTafsiliCategoryLink' AND COLUMN_NAME='CategoryId';
  UPDATE YFG.FieldName SET FieldFa=N'طبقه‌بندی', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccTafsiliCategoryLink' AND FieldName='CategoryId' AND (FieldFa<>N'طبقه‌بندی' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccTafsiliCategoryLink' AND COLUMN_NAME='TafsiliId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccTafsiliCategoryLink' AND FieldName='TafsiliId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccTafsiliCategoryLink', 'TafsiliId', N'تفصیلی', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccTafsiliCategoryLink' AND COLUMN_NAME='TafsiliId';
  UPDATE YFG.FieldName SET FieldFa=N'تفصیلی', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccTafsiliCategoryLink' AND FieldName='TafsiliId' AND (FieldFa<>N'تفصیلی' OR Module<>N'حسابداری');
END
GO
/* --- ACC.AccTafsiliType --- */
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='ACC' AND TableName='AccTafsiliType')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  SELECT 'ACC', 'AccTafsiliType', 'AccTafsiliType', N'حسابداری', 0
  WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccTafsiliType');
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccTafsiliType' AND COLUMN_NAME='CodeListType')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccTafsiliType' AND FieldName='CodeListType')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccTafsiliType', 'CodeListType', N'نوع فهرست کد', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccTafsiliType' AND COLUMN_NAME='CodeListType';
  UPDATE YFG.FieldName SET FieldFa=N'نوع فهرست کد', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccTafsiliType' AND FieldName='CodeListType' AND (FieldFa<>N'نوع فهرست کد' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccTafsiliType' AND COLUMN_NAME='LatinTitle')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccTafsiliType' AND FieldName='LatinTitle')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccTafsiliType', 'LatinTitle', N'عنوان لاتین', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccTafsiliType' AND COLUMN_NAME='LatinTitle';
  UPDATE YFG.FieldName SET FieldFa=N'عنوان لاتین', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccTafsiliType' AND FieldName='LatinTitle' AND (FieldFa<>N'عنوان لاتین' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccTafsiliType' AND COLUMN_NAME='TafsiliTypeId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccTafsiliType' AND FieldName='TafsiliTypeId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccTafsiliType', 'TafsiliTypeId', N'شناسهٔ نوع تفصیلی', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccTafsiliType' AND COLUMN_NAME='TafsiliTypeId';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ نوع تفصیلی', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccTafsiliType' AND FieldName='TafsiliTypeId' AND (FieldFa<>N'شناسهٔ نوع تفصیلی' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccTafsiliType' AND COLUMN_NAME='Title')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccTafsiliType' AND FieldName='Title')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccTafsiliType', 'Title', N'عنوان نوع تفصیلی', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccTafsiliType' AND COLUMN_NAME='Title';
  UPDATE YFG.FieldName SET FieldFa=N'عنوان نوع تفصیلی', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccTafsiliType' AND FieldName='Title' AND (FieldFa<>N'عنوان نوع تفصیلی' OR Module<>N'حسابداری');
END
GO
/* --- ACC.AccVoucher --- */
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='ACC' AND TableName='AccVoucher')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  SELECT 'ACC', 'AccVoucher', 'AccVoucher', N'حسابداری', 0
  WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher');
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='BranchId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='BranchId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucher', 'BranchId', N'شعبه', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='BranchId';
  UPDATE YFG.FieldName SET FieldFa=N'شعبه', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='BranchId' AND (FieldFa<>N'شعبه' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='CheckedAt')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='CheckedAt')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucher', 'CheckedAt', N'تاریخ بررسی', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='CheckedAt';
  UPDATE YFG.FieldName SET FieldFa=N'تاریخ بررسی', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='CheckedAt' AND (FieldFa<>N'تاریخ بررسی' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='CheckedAtJ')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='CheckedAtJ')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucher', 'CheckedAtJ', N'تاریخ بررسی (شمسی)', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='CheckedAtJ';
  UPDATE YFG.FieldName SET FieldFa=N'تاریخ بررسی (شمسی)', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='CheckedAtJ' AND (FieldFa<>N'تاریخ بررسی (شمسی)' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='CheckedBy')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='CheckedBy')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucher', 'CheckedBy', N'بررسی‌کننده', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='CheckedBy';
  UPDATE YFG.FieldName SET FieldFa=N'بررسی‌کننده', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='CheckedBy' AND (FieldFa<>N'بررسی‌کننده' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='DayNo')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='DayNo')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucher', 'DayNo', N'شمارهٔ روزانهٔ سند', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='DayNo';
  UPDATE YFG.FieldName SET FieldFa=N'شمارهٔ روزانهٔ سند', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='DayNo' AND (FieldFa<>N'شمارهٔ روزانهٔ سند' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='Descr')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='Descr')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucher', 'Descr', N'شرح سند', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='Descr';
  UPDATE YFG.FieldName SET FieldFa=N'شرح سند', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='Descr' AND (FieldFa<>N'شرح سند' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='EditedAt')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='EditedAt')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucher', 'EditedAt', N'تاریخ ویرایش', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='EditedAt';
  UPDATE YFG.FieldName SET FieldFa=N'تاریخ ویرایش', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='EditedAt' AND (FieldFa<>N'تاریخ ویرایش' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='EditedAtJ')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='EditedAtJ')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucher', 'EditedAtJ', N'تاریخ ویرایش (شمسی)', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='EditedAtJ';
  UPDATE YFG.FieldName SET FieldFa=N'تاریخ ویرایش (شمسی)', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='EditedAtJ' AND (FieldFa<>N'تاریخ ویرایش (شمسی)' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='EditedBy')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='EditedBy')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucher', 'EditedBy', N'آخرین ویراستار', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='EditedBy';
  UPDATE YFG.FieldName SET FieldFa=N'آخرین ویراستار', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='EditedBy' AND (FieldFa<>N'آخرین ویراستار' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='FinalizedAt')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='FinalizedAt')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucher', 'FinalizedAt', N'تاریخ قطعی', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='FinalizedAt';
  UPDATE YFG.FieldName SET FieldFa=N'تاریخ قطعی', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='FinalizedAt' AND (FieldFa<>N'تاریخ قطعی' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='FinalizedAtJ')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='FinalizedAtJ')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucher', 'FinalizedAtJ', N'تاریخ قطعی (شمسی)', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='FinalizedAtJ';
  UPDATE YFG.FieldName SET FieldFa=N'تاریخ قطعی (شمسی)', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='FinalizedAtJ' AND (FieldFa<>N'تاریخ قطعی (شمسی)' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='FinalizedBy')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='FinalizedBy')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucher', 'FinalizedBy', N'قطعی‌کننده', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='FinalizedBy';
  UPDATE YFG.FieldName SET FieldFa=N'قطعی‌کننده', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='FinalizedBy' AND (FieldFa<>N'قطعی‌کننده' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='FolioNo')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='FolioNo')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucher', 'FolioNo', N'شمارهٔ عطف', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='FolioNo';
  UPDATE YFG.FieldName SET FieldFa=N'شمارهٔ عطف', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='FolioNo' AND (FieldFa<>N'شمارهٔ عطف' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='LatinDescr')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='LatinDescr')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucher', 'LatinDescr', N'شرح لاتین سند', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='LatinDescr';
  UPDATE YFG.FieldName SET FieldFa=N'شرح لاتین سند', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='LatinDescr' AND (FieldFa<>N'شرح لاتین سند' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='ReversalOf')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='ReversalOf')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucher', 'ReversalOf', N'شناسهٔ سند مبنای ابطال', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='ReversalOf';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ سند مبنای ابطال', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='ReversalOf' AND (FieldFa<>N'شناسهٔ سند مبنای ابطال' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='SourceModule')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='SourceModule')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucher', 'SourceModule', N'ماژول مبدأ', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='SourceModule';
  UPDATE YFG.FieldName SET FieldFa=N'ماژول مبدأ', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='SourceModule' AND (FieldFa<>N'ماژول مبدأ' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='State')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='State')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucher', 'State', N'وضعیت سند', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='State';
  UPDATE YFG.FieldName SET FieldFa=N'وضعیت سند', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='State' AND (FieldFa<>N'وضعیت سند' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='SubNo')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='SubNo')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucher', 'SubNo', N'شمارهٔ فرعی سند', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='SubNo';
  UPDATE YFG.FieldName SET FieldFa=N'شمارهٔ فرعی سند', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='SubNo' AND (FieldFa<>N'شمارهٔ فرعی سند' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='VchDate')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='VchDate')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucher', 'VchDate', N'تاریخ سند (جلالی)', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='VchDate';
  UPDATE YFG.FieldName SET FieldFa=N'تاریخ سند (جلالی)', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='VchDate' AND (FieldFa<>N'تاریخ سند (جلالی)' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='VchNo')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='VchNo')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucher', 'VchNo', N'شمارهٔ سند', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='VchNo';
  UPDATE YFG.FieldName SET FieldFa=N'شمارهٔ سند', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='VchNo' AND (FieldFa<>N'شمارهٔ سند' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='VoucherId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='VoucherId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucher', 'VoucherId', N'شناسهٔ سند', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='VoucherId';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ سند', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='VoucherId' AND (FieldFa<>N'شناسهٔ سند' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='VoucherTypeId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='VoucherTypeId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucher', 'VoucherTypeId', N'نوع سند', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucher' AND COLUMN_NAME='VoucherTypeId';
  UPDATE YFG.FieldName SET FieldFa=N'نوع سند', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='VoucherTypeId' AND (FieldFa<>N'نوع سند' OR Module<>N'حسابداری');
END
GO
/* --- ACC.AccVoucherFlow --- */
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='ACC' AND TableName='AccVoucherFlow')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  SELECT 'ACC', 'AccVoucherFlow', 'AccVoucherFlow', N'حسابداری', 0
  WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherFlow');
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherFlow' AND COLUMN_NAME='Action')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucherFlow' AND FieldName='Action')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucherFlow', 'Action', N'عملیات', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherFlow' AND COLUMN_NAME='Action';
  UPDATE YFG.FieldName SET FieldFa=N'عملیات', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucherFlow' AND FieldName='Action' AND (FieldFa<>N'عملیات' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherFlow' AND COLUMN_NAME='At')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucherFlow' AND FieldName='At')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucherFlow', 'At', N'زمان', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherFlow' AND COLUMN_NAME='At';
  UPDATE YFG.FieldName SET FieldFa=N'زمان', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucherFlow' AND FieldName='At' AND (FieldFa<>N'زمان' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherFlow' AND COLUMN_NAME='AtJ')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucherFlow' AND FieldName='AtJ')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucherFlow', 'AtJ', N'زمان (شمسی)', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherFlow' AND COLUMN_NAME='AtJ';
  UPDATE YFG.FieldName SET FieldFa=N'زمان (شمسی)', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucherFlow' AND FieldName='AtJ' AND (FieldFa<>N'زمان (شمسی)' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherFlow' AND COLUMN_NAME='ByUser')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucherFlow' AND FieldName='ByUser')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucherFlow', 'ByUser', N'کاربر', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherFlow' AND COLUMN_NAME='ByUser';
  UPDATE YFG.FieldName SET FieldFa=N'کاربر', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucherFlow' AND FieldName='ByUser' AND (FieldFa<>N'کاربر' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherFlow' AND COLUMN_NAME='LogId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucherFlow' AND FieldName='LogId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucherFlow', 'LogId', N'شناسهٔ ردیف جریان', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherFlow' AND COLUMN_NAME='LogId';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ ردیف جریان', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucherFlow' AND FieldName='LogId' AND (FieldFa<>N'شناسهٔ ردیف جریان' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherFlow' AND COLUMN_NAME='Note')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucherFlow' AND FieldName='Note')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucherFlow', 'Note', N'یادداشت', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherFlow' AND COLUMN_NAME='Note';
  UPDATE YFG.FieldName SET FieldFa=N'یادداشت', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucherFlow' AND FieldName='Note' AND (FieldFa<>N'یادداشت' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherFlow' AND COLUMN_NAME='VoucherId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucherFlow' AND FieldName='VoucherId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucherFlow', 'VoucherId', N'شناسهٔ سند', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherFlow' AND COLUMN_NAME='VoucherId';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ سند', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucherFlow' AND FieldName='VoucherId' AND (FieldFa<>N'شناسهٔ سند' OR Module<>N'حسابداری');
END
GO
/* --- ACC.AccVoucherItm --- */
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='ACC' AND TableName='AccVoucherItm')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  SELECT 'ACC', 'AccVoucherItm', 'AccVoucherItm', N'حسابداری', 0
  WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherItm');
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherItm' AND COLUMN_NAME='Crt')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='Crt')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucherItm', 'Crt', N'بستانکار', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherItm' AND COLUMN_NAME='Crt';
  UPDATE YFG.FieldName SET FieldFa=N'بستانکار', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='Crt' AND (FieldFa<>N'بستانکار' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherItm' AND COLUMN_NAME='Dbt')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='Dbt')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucherItm', 'Dbt', N'بدهکار', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherItm' AND COLUMN_NAME='Dbt';
  UPDATE YFG.FieldName SET FieldFa=N'بدهکار', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='Dbt' AND (FieldFa<>N'بدهکار' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherItm' AND COLUMN_NAME='Descr')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='Descr')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucherItm', 'Descr', N'شرح قلم', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherItm' AND COLUMN_NAME='Descr';
  UPDATE YFG.FieldName SET FieldFa=N'شرح قلم', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='Descr' AND (FieldFa<>N'شرح قلم' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherItm' AND COLUMN_NAME='FxAmount')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='FxAmount')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucherItm', 'FxAmount', N'مبلغ ارزی', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherItm' AND COLUMN_NAME='FxAmount';
  UPDATE YFG.FieldName SET FieldFa=N'مبلغ ارزی', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='FxAmount' AND (FieldFa<>N'مبلغ ارزی' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherItm' AND COLUMN_NAME='FxId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='FxId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucherItm', 'FxId', N'نوع ارز قلم', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherItm' AND COLUMN_NAME='FxId';
  UPDATE YFG.FieldName SET FieldFa=N'نوع ارز قلم', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='FxId' AND (FieldFa<>N'نوع ارز قلم' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherItm' AND COLUMN_NAME='FxRate')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='FxRate')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucherItm', 'FxRate', N'نرخ ارز', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherItm' AND COLUMN_NAME='FxRate';
  UPDATE YFG.FieldName SET FieldFa=N'نرخ ارز', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='FxRate' AND (FieldFa<>N'نرخ ارز' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherItm' AND COLUMN_NAME='KolCode')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='KolCode')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucherItm', 'KolCode', N'کد کل', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherItm' AND COLUMN_NAME='KolCode';
  UPDATE YFG.FieldName SET FieldFa=N'کد کل', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='KolCode' AND (FieldFa<>N'کد کل' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherItm' AND COLUMN_NAME='LatinDescr')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='LatinDescr')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucherItm', 'LatinDescr', N'شرح لاتین قلم', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherItm' AND COLUMN_NAME='LatinDescr';
  UPDATE YFG.FieldName SET FieldFa=N'شرح لاتین قلم', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='LatinDescr' AND (FieldFa<>N'شرح لاتین قلم' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherItm' AND COLUMN_NAME='LineId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='LineId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucherItm', 'LineId', N'شناسهٔ قلم', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherItm' AND COLUMN_NAME='LineId';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ قلم', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='LineId' AND (FieldFa<>N'شناسهٔ قلم' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherItm' AND COLUMN_NAME='MoeinCode')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='MoeinCode')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucherItm', 'MoeinCode', N'کد معین', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherItm' AND COLUMN_NAME='MoeinCode';
  UPDATE YFG.FieldName SET FieldFa=N'کد معین', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='MoeinCode' AND (FieldFa<>N'کد معین' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherItm' AND COLUMN_NAME='RowNo')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='RowNo')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucherItm', 'RowNo', N'ردیف قلم', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherItm' AND COLUMN_NAME='RowNo';
  UPDATE YFG.FieldName SET FieldFa=N'ردیف قلم', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='RowNo' AND (FieldFa<>N'ردیف قلم' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherItm' AND COLUMN_NAME='Taf1Id')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='Taf1Id')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucherItm', 'Taf1Id', N'تفصیلی سطح ۴', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherItm' AND COLUMN_NAME='Taf1Id';
  UPDATE YFG.FieldName SET FieldFa=N'تفصیلی سطح ۴', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='Taf1Id' AND (FieldFa<>N'تفصیلی سطح ۴' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherItm' AND COLUMN_NAME='Taf2Id')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='Taf2Id')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucherItm', 'Taf2Id', N'تفصیلی سطح ۵', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherItm' AND COLUMN_NAME='Taf2Id';
  UPDATE YFG.FieldName SET FieldFa=N'تفصیلی سطح ۵', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='Taf2Id' AND (FieldFa<>N'تفصیلی سطح ۵' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherItm' AND COLUMN_NAME='Taf3Id')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='Taf3Id')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucherItm', 'Taf3Id', N'تفصیلی سطح ۶', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherItm' AND COLUMN_NAME='Taf3Id';
  UPDATE YFG.FieldName SET FieldFa=N'تفصیلی سطح ۶', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='Taf3Id' AND (FieldFa<>N'تفصیلی سطح ۶' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherItm' AND COLUMN_NAME='TrackDate')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='TrackDate')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucherItm', 'TrackDate', N'تاریخ پیگیری (جلالی)', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherItm' AND COLUMN_NAME='TrackDate';
  UPDATE YFG.FieldName SET FieldFa=N'تاریخ پیگیری (جلالی)', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='TrackDate' AND (FieldFa<>N'تاریخ پیگیری (جلالی)' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherItm' AND COLUMN_NAME='TrackNo')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='TrackNo')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucherItm', 'TrackNo', N'شمارهٔ پیگیری', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherItm' AND COLUMN_NAME='TrackNo';
  UPDATE YFG.FieldName SET FieldFa=N'شمارهٔ پیگیری', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='TrackNo' AND (FieldFa<>N'شمارهٔ پیگیری' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherItm' AND COLUMN_NAME='VoucherId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='VoucherId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucherItm', 'VoucherId', N'شناسهٔ سند', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherItm' AND COLUMN_NAME='VoucherId';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ سند', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='VoucherId' AND (FieldFa<>N'شناسهٔ سند' OR Module<>N'حسابداری');
END
GO
/* --- ACC.AccVoucherType --- */
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='ACC' AND TableName='AccVoucherType')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  SELECT 'ACC', 'AccVoucherType', 'AccVoucherType', N'حسابداری', 0
  WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherType');
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherType' AND COLUMN_NAME='LatinTitle')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucherType' AND FieldName='LatinTitle')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucherType', 'LatinTitle', N'شرح لاتین', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherType' AND COLUMN_NAME='LatinTitle';
  UPDATE YFG.FieldName SET FieldFa=N'شرح لاتین', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucherType' AND FieldName='LatinTitle' AND (FieldFa<>N'شرح لاتین' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherType' AND COLUMN_NAME='Title')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucherType' AND FieldName='Title')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucherType', 'Title', N'عنوان نوع سند', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherType' AND COLUMN_NAME='Title';
  UPDATE YFG.FieldName SET FieldFa=N'عنوان نوع سند', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucherType' AND FieldName='Title' AND (FieldFa<>N'عنوان نوع سند' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherType' AND COLUMN_NAME='VoucherTypeId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucherType' AND FieldName='VoucherTypeId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVoucherType', 'VoucherTypeId', N'شناسهٔ نوع سند', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVoucherType' AND COLUMN_NAME='VoucherTypeId';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ نوع سند', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVoucherType' AND FieldName='VoucherTypeId' AND (FieldFa<>N'شناسهٔ نوع سند' OR Module<>N'حسابداری');
END
GO
/* --- ACC.AccVwChart --- */
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='ACC' AND TableName='AccVwChart')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  SELECT 'ACC', 'AccVwChart', 'AccVwChart', N'حسابداری', 0
  WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVwChart');
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVwChart' AND COLUMN_NAME='GroupCode')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVwChart' AND FieldName='GroupCode')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVwChart', 'GroupCode', N'کد گروه', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVwChart' AND COLUMN_NAME='GroupCode';
  UPDATE YFG.FieldName SET FieldFa=N'کد گروه', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVwChart' AND FieldName='GroupCode' AND (FieldFa<>N'کد گروه' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVwChart' AND COLUMN_NAME='GroupTitle')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVwChart' AND FieldName='GroupTitle')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVwChart', 'GroupTitle', N'عنوان گروه', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVwChart' AND COLUMN_NAME='GroupTitle';
  UPDATE YFG.FieldName SET FieldFa=N'عنوان گروه', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVwChart' AND FieldName='GroupTitle' AND (FieldFa<>N'عنوان گروه' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVwChart' AND COLUMN_NAME='KolCode')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVwChart' AND FieldName='KolCode')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVwChart', 'KolCode', N'کد کل', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVwChart' AND COLUMN_NAME='KolCode';
  UPDATE YFG.FieldName SET FieldFa=N'کد کل', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVwChart' AND FieldName='KolCode' AND (FieldFa<>N'کد کل' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVwChart' AND COLUMN_NAME='KolTitle')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVwChart' AND FieldName='KolTitle')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVwChart', 'KolTitle', N'عنوان کل', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVwChart' AND COLUMN_NAME='KolTitle';
  UPDATE YFG.FieldName SET FieldFa=N'عنوان کل', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVwChart' AND FieldName='KolTitle' AND (FieldFa<>N'عنوان کل' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVwChart' AND COLUMN_NAME='MoeinActive')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVwChart' AND FieldName='MoeinActive')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVwChart', 'MoeinActive', N'فعال (بله/خیر)', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVwChart' AND COLUMN_NAME='MoeinActive';
  UPDATE YFG.FieldName SET FieldFa=N'فعال (بله/خیر)', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVwChart' AND FieldName='MoeinActive' AND (FieldFa<>N'فعال (بله/خیر)' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVwChart' AND COLUMN_NAME='MoeinCode')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVwChart' AND FieldName='MoeinCode')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVwChart', 'MoeinCode', N'کد معین', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVwChart' AND COLUMN_NAME='MoeinCode';
  UPDATE YFG.FieldName SET FieldFa=N'کد معین', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVwChart' AND FieldName='MoeinCode' AND (FieldFa<>N'کد معین' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVwChart' AND COLUMN_NAME='MoeinTitle')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVwChart' AND FieldName='MoeinTitle')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVwChart', 'MoeinTitle', N'عنوان معین', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVwChart' AND COLUMN_NAME='MoeinTitle';
  UPDATE YFG.FieldName SET FieldFa=N'عنوان معین', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVwChart' AND FieldName='MoeinTitle' AND (FieldFa<>N'عنوان معین' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVwChart' AND COLUMN_NAME='Taf1TypeId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVwChart' AND FieldName='Taf1TypeId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVwChart', 'Taf1TypeId', N'نوع تفصیلی سطح ۴', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVwChart' AND COLUMN_NAME='Taf1TypeId';
  UPDATE YFG.FieldName SET FieldFa=N'نوع تفصیلی سطح ۴', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVwChart' AND FieldName='Taf1TypeId' AND (FieldFa<>N'نوع تفصیلی سطح ۴' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVwChart' AND COLUMN_NAME='Taf2TypeId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVwChart' AND FieldName='Taf2TypeId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVwChart', 'Taf2TypeId', N'نوع تفصیلی سطح ۵', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVwChart' AND COLUMN_NAME='Taf2TypeId';
  UPDATE YFG.FieldName SET FieldFa=N'نوع تفصیلی سطح ۵', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVwChart' AND FieldName='Taf2TypeId' AND (FieldFa<>N'نوع تفصیلی سطح ۵' OR Module<>N'حسابداری');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVwChart' AND COLUMN_NAME='Taf3TypeId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVwChart' AND FieldName='Taf3TypeId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'ACC', 'AccVwChart', 'Taf3TypeId', N'نوع تفصیلی سطح ۶', N'حسابداری', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ACC' AND TABLE_NAME='AccVwChart' AND COLUMN_NAME='Taf3TypeId';
  UPDATE YFG.FieldName SET FieldFa=N'نوع تفصیلی سطح ۶', Module=N'حسابداری'
  WHERE TableSchema='ACC' AND TableName='AccVwChart' AND FieldName='Taf3TypeId' AND (FieldFa<>N'نوع تفصیلی سطح ۶' OR Module<>N'حسابداری');
END
GO
/* --- YFG.FieldName --- */
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='YFG' AND TableName='FieldName')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  SELECT 'YFG', 'FieldName', 'FieldName', N'واژه‌نامه', 0
  WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='FieldName');
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='FieldName' AND COLUMN_NAME='DataType')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='YFG' AND TableName='FieldName' AND FieldName='DataType')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'YFG', 'FieldName', 'DataType', N'نوع داده', N'واژه‌نامه', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='FieldName' AND COLUMN_NAME='DataType';
  UPDATE YFG.FieldName SET FieldFa=N'نوع داده', Module=N'واژه‌نامه'
  WHERE TableSchema='YFG' AND TableName='FieldName' AND FieldName='DataType' AND (FieldFa<>N'نوع داده' OR Module<>N'واژه‌نامه');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='FieldName' AND COLUMN_NAME='FieldFa')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='YFG' AND TableName='FieldName' AND FieldName='FieldFa')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'YFG', 'FieldName', 'FieldFa', N'نام فارسی فیلد بر اساس نقش', N'واژه‌نامه', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='FieldName' AND COLUMN_NAME='FieldFa';
  UPDATE YFG.FieldName SET FieldFa=N'نام فارسی فیلد بر اساس نقش', Module=N'واژه‌نامه'
  WHERE TableSchema='YFG' AND TableName='FieldName' AND FieldName='FieldFa' AND (FieldFa<>N'نام فارسی فیلد بر اساس نقش' OR Module<>N'واژه‌نامه');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='FieldName' AND COLUMN_NAME='FieldId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='YFG' AND TableName='FieldName' AND FieldName='FieldId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'YFG', 'FieldName', 'FieldId', N'شناسهٔ فیلد', N'واژه‌نامه', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='FieldName' AND COLUMN_NAME='FieldId';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ فیلد', Module=N'واژه‌نامه'
  WHERE TableSchema='YFG' AND TableName='FieldName' AND FieldName='FieldId' AND (FieldFa<>N'شناسهٔ فیلد' OR Module<>N'واژه‌نامه');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='FieldName' AND COLUMN_NAME='FieldName')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='YFG' AND TableName='FieldName' AND FieldName='FieldName')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'YFG', 'FieldName', 'FieldName', N'نام فیلد (انگلیسی)', N'واژه‌نامه', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='FieldName' AND COLUMN_NAME='FieldName';
  UPDATE YFG.FieldName SET FieldFa=N'نام فیلد (انگلیسی)', Module=N'واژه‌نامه'
  WHERE TableSchema='YFG' AND TableName='FieldName' AND FieldName='FieldName' AND (FieldFa<>N'نام فیلد (انگلیسی)' OR Module<>N'واژه‌نامه');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='FieldName' AND COLUMN_NAME='Module')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='YFG' AND TableName='FieldName' AND FieldName='Module')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'YFG', 'FieldName', 'Module', N'ماژول', N'واژه‌نامه', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='FieldName' AND COLUMN_NAME='Module';
  UPDATE YFG.FieldName SET FieldFa=N'ماژول', Module=N'واژه‌نامه'
  WHERE TableSchema='YFG' AND TableName='FieldName' AND FieldName='Module' AND (FieldFa<>N'ماژول' OR Module<>N'واژه‌نامه');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='FieldName' AND COLUMN_NAME='TableName')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='YFG' AND TableName='FieldName' AND FieldName='TableName')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'YFG', 'FieldName', 'TableName', N'نام جدول', N'واژه‌نامه', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='FieldName' AND COLUMN_NAME='TableName';
  UPDATE YFG.FieldName SET FieldFa=N'نام جدول', Module=N'واژه‌نامه'
  WHERE TableSchema='YFG' AND TableName='FieldName' AND FieldName='TableName' AND (FieldFa<>N'نام جدول' OR Module<>N'واژه‌نامه');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='FieldName' AND COLUMN_NAME='TableSchema')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='YFG' AND TableName='FieldName' AND FieldName='TableSchema')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'YFG', 'FieldName', 'TableSchema', N'شمای جدول', N'واژه‌نامه', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='FieldName' AND COLUMN_NAME='TableSchema';
  UPDATE YFG.FieldName SET FieldFa=N'شمای جدول', Module=N'واژه‌نامه'
  WHERE TableSchema='YFG' AND TableName='FieldName' AND FieldName='TableSchema' AND (FieldFa<>N'شمای جدول' OR Module<>N'واژه‌نامه');
END
GO
/* --- YFG.LinkField --- */
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='YFG' AND TableName='LinkField')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  SELECT 'YFG', 'LinkField', 'LinkField', N'واژه‌نامه', 0
  WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='LinkField');
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='LinkField' AND COLUMN_NAME='FieldFa')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='YFG' AND TableName='LinkField' AND FieldName='FieldFa')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'YFG', 'LinkField', 'FieldFa', N'نام فارسی فیلد بر اساس نقش', N'واژه‌نامه', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='LinkField' AND COLUMN_NAME='FieldFa';
  UPDATE YFG.FieldName SET FieldFa=N'نام فارسی فیلد بر اساس نقش', Module=N'واژه‌نامه'
  WHERE TableSchema='YFG' AND TableName='LinkField' AND FieldName='FieldFa' AND (FieldFa<>N'نام فارسی فیلد بر اساس نقش' OR Module<>N'واژه‌نامه');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='LinkField' AND COLUMN_NAME='FieldName')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='YFG' AND TableName='LinkField' AND FieldName='FieldName')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'YFG', 'LinkField', 'FieldName', N'نام فیلد', N'واژه‌نامه', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='LinkField' AND COLUMN_NAME='FieldName';
  UPDATE YFG.FieldName SET FieldFa=N'نام فیلد', Module=N'واژه‌نامه'
  WHERE TableSchema='YFG' AND TableName='LinkField' AND FieldName='FieldName' AND (FieldFa<>N'نام فیلد' OR Module<>N'واژه‌نامه');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='LinkField' AND COLUMN_NAME='LinkFieldFa')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='YFG' AND TableName='LinkField' AND FieldName='LinkFieldFa')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'YFG', 'LinkField', 'LinkFieldFa', N'نام فارسی فیلد لینک', N'واژه‌نامه', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='LinkField' AND COLUMN_NAME='LinkFieldFa';
  UPDATE YFG.FieldName SET FieldFa=N'نام فارسی فیلد لینک', Module=N'واژه‌نامه'
  WHERE TableSchema='YFG' AND TableName='LinkField' AND FieldName='LinkFieldFa' AND (FieldFa<>N'نام فارسی فیلد لینک' OR Module<>N'واژه‌نامه');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='LinkField' AND COLUMN_NAME='LinkFieldName')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='YFG' AND TableName='LinkField' AND FieldName='LinkFieldName')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'YFG', 'LinkField', 'LinkFieldName', N'نام فیلد لینک', N'واژه‌نامه', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='LinkField' AND COLUMN_NAME='LinkFieldName';
  UPDATE YFG.FieldName SET FieldFa=N'نام فیلد لینک', Module=N'واژه‌نامه'
  WHERE TableSchema='YFG' AND TableName='LinkField' AND FieldName='LinkFieldName' AND (FieldFa<>N'نام فیلد لینک' OR Module<>N'واژه‌نامه');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='LinkField' AND COLUMN_NAME='LinkId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='YFG' AND TableName='LinkField' AND FieldName='LinkId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'YFG', 'LinkField', 'LinkId', N'شناسهٔ پیوند', N'واژه‌نامه', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='LinkField' AND COLUMN_NAME='LinkId';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ پیوند', Module=N'واژه‌نامه'
  WHERE TableSchema='YFG' AND TableName='LinkField' AND FieldName='LinkId' AND (FieldFa<>N'شناسهٔ پیوند' OR Module<>N'واژه‌نامه');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='LinkField' AND COLUMN_NAME='LinkRole')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='YFG' AND TableName='LinkField' AND FieldName='LinkRole')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'YFG', 'LinkField', 'LinkRole', N'نقش فیلد در پیوند', N'واژه‌نامه', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='LinkField' AND COLUMN_NAME='LinkRole';
  UPDATE YFG.FieldName SET FieldFa=N'نقش فیلد در پیوند', Module=N'واژه‌نامه'
  WHERE TableSchema='YFG' AND TableName='LinkField' AND FieldName='LinkRole' AND (FieldFa<>N'نقش فیلد در پیوند' OR Module<>N'واژه‌نامه');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='LinkField' AND COLUMN_NAME='LinkTableName')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='YFG' AND TableName='LinkField' AND FieldName='LinkTableName')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'YFG', 'LinkField', 'LinkTableName', N'نام جدول لینک', N'واژه‌نامه', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='LinkField' AND COLUMN_NAME='LinkTableName';
  UPDATE YFG.FieldName SET FieldFa=N'نام جدول لینک', Module=N'واژه‌نامه'
  WHERE TableSchema='YFG' AND TableName='LinkField' AND FieldName='LinkTableName' AND (FieldFa<>N'نام جدول لینک' OR Module<>N'واژه‌نامه');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='LinkField' AND COLUMN_NAME='LinkTableSchema')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='YFG' AND TableName='LinkField' AND FieldName='LinkTableSchema')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'YFG', 'LinkField', 'LinkTableSchema', N'شمای جدول لینک', N'واژه‌نامه', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='LinkField' AND COLUMN_NAME='LinkTableSchema';
  UPDATE YFG.FieldName SET FieldFa=N'شمای جدول لینک', Module=N'واژه‌نامه'
  WHERE TableSchema='YFG' AND TableName='LinkField' AND FieldName='LinkTableSchema' AND (FieldFa<>N'شمای جدول لینک' OR Module<>N'واژه‌نامه');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='LinkField' AND COLUMN_NAME='TableName')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='YFG' AND TableName='LinkField' AND FieldName='TableName')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'YFG', 'LinkField', 'TableName', N'نام جدول', N'واژه‌نامه', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='LinkField' AND COLUMN_NAME='TableName';
  UPDATE YFG.FieldName SET FieldFa=N'نام جدول', Module=N'واژه‌نامه'
  WHERE TableSchema='YFG' AND TableName='LinkField' AND FieldName='TableName' AND (FieldFa<>N'نام جدول' OR Module<>N'واژه‌نامه');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='LinkField' AND COLUMN_NAME='TableSchema')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='YFG' AND TableName='LinkField' AND FieldName='TableSchema')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'YFG', 'LinkField', 'TableSchema', N'شمای جدول', N'واژه‌نامه', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='LinkField' AND COLUMN_NAME='TableSchema';
  UPDATE YFG.FieldName SET FieldFa=N'شمای جدول', Module=N'واژه‌نامه'
  WHERE TableSchema='YFG' AND TableName='LinkField' AND FieldName='TableSchema' AND (FieldFa<>N'شمای جدول' OR Module<>N'واژه‌نامه');
END
GO
/* --- YFG.TableName --- */
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='YFG' AND TableName='TableName')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  SELECT 'YFG', 'TableName', 'TableName', N'واژه‌نامه', 0
  WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='TableName');
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='TableName' AND COLUMN_NAME='IsLookup')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='YFG' AND TableName='TableName' AND FieldName='IsLookup')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'YFG', 'TableName', 'IsLookup', N'جدول مرجع (بله/خیر)', N'واژه‌نامه', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='TableName' AND COLUMN_NAME='IsLookup';
  UPDATE YFG.FieldName SET FieldFa=N'جدول مرجع (بله/خیر)', Module=N'واژه‌نامه'
  WHERE TableSchema='YFG' AND TableName='TableName' AND FieldName='IsLookup' AND (FieldFa<>N'جدول مرجع (بله/خیر)' OR Module<>N'واژه‌نامه');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='TableName' AND COLUMN_NAME='Module')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='YFG' AND TableName='TableName' AND FieldName='Module')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'YFG', 'TableName', 'Module', N'ماژول', N'واژه‌نامه', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='TableName' AND COLUMN_NAME='Module';
  UPDATE YFG.FieldName SET FieldFa=N'ماژول', Module=N'واژه‌نامه'
  WHERE TableSchema='YFG' AND TableName='TableName' AND FieldName='Module' AND (FieldFa<>N'ماژول' OR Module<>N'واژه‌نامه');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='TableName' AND COLUMN_NAME='TableFa')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='YFG' AND TableName='TableName' AND FieldName='TableFa')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'YFG', 'TableName', 'TableFa', N'نام فارسی جدول بر اساس نقش', N'واژه‌نامه', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='TableName' AND COLUMN_NAME='TableFa';
  UPDATE YFG.FieldName SET FieldFa=N'نام فارسی جدول بر اساس نقش', Module=N'واژه‌نامه'
  WHERE TableSchema='YFG' AND TableName='TableName' AND FieldName='TableFa' AND (FieldFa<>N'نام فارسی جدول بر اساس نقش' OR Module<>N'واژه‌نامه');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='TableName' AND COLUMN_NAME='TableId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='YFG' AND TableName='TableName' AND FieldName='TableId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'YFG', 'TableName', 'TableId', N'شناسهٔ جدول', N'واژه‌نامه', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='TableName' AND COLUMN_NAME='TableId';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ جدول', Module=N'واژه‌نامه'
  WHERE TableSchema='YFG' AND TableName='TableName' AND FieldName='TableId' AND (FieldFa<>N'شناسهٔ جدول' OR Module<>N'واژه‌نامه');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='TableName' AND COLUMN_NAME='TableName')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='YFG' AND TableName='TableName' AND FieldName='TableName')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'YFG', 'TableName', 'TableName', N'نام جدول (انگلیسی)', N'واژه‌نامه', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='TableName' AND COLUMN_NAME='TableName';
  UPDATE YFG.FieldName SET FieldFa=N'نام جدول (انگلیسی)', Module=N'واژه‌نامه'
  WHERE TableSchema='YFG' AND TableName='TableName' AND FieldName='TableName' AND (FieldFa<>N'نام جدول (انگلیسی)' OR Module<>N'واژه‌نامه');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='TableName' AND COLUMN_NAME='TableSchema')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='YFG' AND TableName='TableName' AND FieldName='TableSchema')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'YFG', 'TableName', 'TableSchema', N'شمای جدول', N'واژه‌نامه', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='YFG' AND TABLE_NAME='TableName' AND COLUMN_NAME='TableSchema';
  UPDATE YFG.FieldName SET FieldFa=N'شمای جدول', Module=N'واژه‌نامه'
  WHERE TableSchema='YFG' AND TableName='TableName' AND FieldName='TableSchema' AND (FieldFa<>N'شمای جدول' OR Module<>N'واژه‌نامه');
END
GO
/* --- pob.AppSetting --- */
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='pob' AND TableName='AppSetting')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  SELECT 'pob', 'AppSetting', 'AppSetting', N'عمومی (بستر)', 0
  WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='AppSetting');
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='AppSetting' AND COLUMN_NAME='DataValue')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='AppSetting' AND FieldName='DataValue')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'AppSetting', 'DataValue', N'مقدار', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='AppSetting' AND COLUMN_NAME='DataValue';
  UPDATE YFG.FieldName SET FieldFa=N'مقدار', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='AppSetting' AND FieldName='DataValue' AND (FieldFa<>N'مقدار' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='AppSetting' AND COLUMN_NAME='Descr')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='AppSetting' AND FieldName='Descr')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'AppSetting', 'Descr', N'توضیح', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='AppSetting' AND COLUMN_NAME='Descr';
  UPDATE YFG.FieldName SET FieldFa=N'توضیح', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='AppSetting' AND FieldName='Descr' AND (FieldFa<>N'توضیح' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='AppSetting' AND COLUMN_NAME='KeyValue')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='AppSetting' AND FieldName='KeyValue')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'AppSetting', 'KeyValue', N'کلید تنظیم', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='AppSetting' AND COLUMN_NAME='KeyValue';
  UPDATE YFG.FieldName SET FieldFa=N'کلید تنظیم', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='AppSetting' AND FieldName='KeyValue' AND (FieldFa<>N'کلید تنظیم' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='AppSetting' AND COLUMN_NAME='SettingId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='AppSetting' AND FieldName='SettingId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'AppSetting', 'SettingId', N'شناسهٔ تنظیم', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='AppSetting' AND COLUMN_NAME='SettingId';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ تنظیم', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='AppSetting' AND FieldName='SettingId' AND (FieldFa<>N'شناسهٔ تنظیم' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='AppSetting' AND COLUMN_NAME='SystemName')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='AppSetting' AND FieldName='SystemName')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'AppSetting', 'SystemName', N'زیرسیستم', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='AppSetting' AND COLUMN_NAME='SystemName';
  UPDATE YFG.FieldName SET FieldFa=N'زیرسیستم', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='AppSetting' AND FieldName='SystemName' AND (FieldFa<>N'زیرسیستم' OR Module<>N'عمومی (بستر)');
END
GO
/* --- pob.AppUser --- */
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='pob' AND TableName='AppUser')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  SELECT 'pob', 'AppUser', 'AppUser', N'عمومی (بستر)', 0
  WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='AppUser');
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='AppUser' AND COLUMN_NAME='DisplayName')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='AppUser' AND FieldName='DisplayName')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'AppUser', 'DisplayName', N'نام نمایشی', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='AppUser' AND COLUMN_NAME='DisplayName';
  UPDATE YFG.FieldName SET FieldFa=N'نام نمایشی', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='AppUser' AND FieldName='DisplayName' AND (FieldFa<>N'نام نمایشی' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='AppUser' AND COLUMN_NAME='PassHash')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='AppUser' AND FieldName='PassHash')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'AppUser', 'PassHash', N'هش رمز عبور', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='AppUser' AND COLUMN_NAME='PassHash';
  UPDATE YFG.FieldName SET FieldFa=N'هش رمز عبور', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='AppUser' AND FieldName='PassHash' AND (FieldFa<>N'هش رمز عبور' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='AppUser' AND COLUMN_NAME='RoleCode')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='AppUser' AND FieldName='RoleCode')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'AppUser', 'RoleCode', N'کد نقش', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='AppUser' AND COLUMN_NAME='RoleCode';
  UPDATE YFG.FieldName SET FieldFa=N'کد نقش', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='AppUser' AND FieldName='RoleCode' AND (FieldFa<>N'کد نقش' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='AppUser' AND COLUMN_NAME='UserId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='AppUser' AND FieldName='UserId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'AppUser', 'UserId', N'شناسهٔ کاربر', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='AppUser' AND COLUMN_NAME='UserId';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ کاربر', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='AppUser' AND FieldName='UserId' AND (FieldFa<>N'شناسهٔ کاربر' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='AppUser' AND COLUMN_NAME='Username')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='AppUser' AND FieldName='Username')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'AppUser', 'Username', N'نام کاربری', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='AppUser' AND COLUMN_NAME='Username';
  UPDATE YFG.FieldName SET FieldFa=N'نام کاربری', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='AppUser' AND FieldName='Username' AND (FieldFa<>N'نام کاربری' OR Module<>N'عمومی (بستر)');
END
GO
/* --- pob.CodeList --- */
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='pob' AND TableName='CodeList')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  SELECT 'pob', 'CodeList', 'CodeList', N'عمومی (بستر)', 0
  WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='CodeList');
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='CodeList' AND COLUMN_NAME='Aux')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='CodeList' AND FieldName='Aux')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'CodeList', 'Aux', N'ستون کمکی', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='CodeList' AND COLUMN_NAME='Aux';
  UPDATE YFG.FieldName SET FieldFa=N'ستون کمکی', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='CodeList' AND FieldName='Aux' AND (FieldFa<>N'ستون کمکی' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='CodeList' AND COLUMN_NAME='Code')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='CodeList' AND FieldName='Code')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'CodeList', 'Code', N'کد', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='CodeList' AND COLUMN_NAME='Code';
  UPDATE YFG.FieldName SET FieldFa=N'کد', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='CodeList' AND FieldName='Code' AND (FieldFa<>N'کد' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='CodeList' AND COLUMN_NAME='CodeId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='CodeList' AND FieldName='CodeId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'CodeList', 'CodeId', N'شناسهٔ کد', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='CodeList' AND COLUMN_NAME='CodeId';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ کد', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='CodeList' AND FieldName='CodeId' AND (FieldFa<>N'شناسهٔ کد' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='CodeList' AND COLUMN_NAME='SystemName')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='CodeList' AND FieldName='SystemName')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'CodeList', 'SystemName', N'زیرسیستم', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='CodeList' AND COLUMN_NAME='SystemName';
  UPDATE YFG.FieldName SET FieldFa=N'زیرسیستم', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='CodeList' AND FieldName='SystemName' AND (FieldFa<>N'زیرسیستم' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='CodeList' AND COLUMN_NAME='Title')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='CodeList' AND FieldName='Title')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'CodeList', 'Title', N'عنوان', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='CodeList' AND COLUMN_NAME='Title';
  UPDATE YFG.FieldName SET FieldFa=N'عنوان', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='CodeList' AND FieldName='Title' AND (FieldFa<>N'عنوان' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='CodeList' AND COLUMN_NAME='Type')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='CodeList' AND FieldName='Type')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'CodeList', 'Type', N'نوع فهرست', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='CodeList' AND COLUMN_NAME='Type';
  UPDATE YFG.FieldName SET FieldFa=N'نوع فهرست', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='CodeList' AND FieldName='Type' AND (FieldFa<>N'نوع فهرست' OR Module<>N'عمومی (بستر)');
END
GO
/* --- pob.Companies --- */
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='pob' AND TableName='Companies')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  SELECT 'pob', 'Companies', 'Companies', N'عمومی (بستر)', 0
  WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Companies');
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Companies' AND COLUMN_NAME='CodingMode')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='Companies' AND FieldName='CodingMode')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'Companies', 'CodingMode', N'حالت کدینگ', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Companies' AND COLUMN_NAME='CodingMode';
  UPDATE YFG.FieldName SET FieldFa=N'حالت کدینگ', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='Companies' AND FieldName='CodingMode' AND (FieldFa<>N'حالت کدینگ' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Companies' AND COLUMN_NAME='CompanyCode')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='Companies' AND FieldName='CompanyCode')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'Companies', 'CompanyCode', N'کد شرکت', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Companies' AND COLUMN_NAME='CompanyCode';
  UPDATE YFG.FieldName SET FieldFa=N'کد شرکت', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='Companies' AND FieldName='CompanyCode' AND (FieldFa<>N'کد شرکت' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Companies' AND COLUMN_NAME='CompanyId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='Companies' AND FieldName='CompanyId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'Companies', 'CompanyId', N'شناسهٔ شرکت', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Companies' AND COLUMN_NAME='CompanyId';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ شرکت', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='Companies' AND FieldName='CompanyId' AND (FieldFa<>N'شناسهٔ شرکت' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Companies' AND COLUMN_NAME='EconomicCode')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='Companies' AND FieldName='EconomicCode')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'Companies', 'EconomicCode', N'کد اقتصادی', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Companies' AND COLUMN_NAME='EconomicCode';
  UPDATE YFG.FieldName SET FieldFa=N'کد اقتصادی', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='Companies' AND FieldName='EconomicCode' AND (FieldFa<>N'کد اقتصادی' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Companies' AND COLUMN_NAME='NationalId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='Companies' AND FieldName='NationalId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'Companies', 'NationalId', N'شناسهٔ ملی', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Companies' AND COLUMN_NAME='NationalId';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ ملی', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='Companies' AND FieldName='NationalId' AND (FieldFa<>N'شناسهٔ ملی' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Companies' AND COLUMN_NAME='TitleFa')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='Companies' AND FieldName='TitleFa')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'Companies', 'TitleFa', N'نام شرکت (فارسی)', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Companies' AND COLUMN_NAME='TitleFa';
  UPDATE YFG.FieldName SET FieldFa=N'نام شرکت (فارسی)', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='Companies' AND FieldName='TitleFa' AND (FieldFa<>N'نام شرکت (فارسی)' OR Module<>N'عمومی (بستر)');
END
GO
/* --- pob.FiscalPeriod --- */
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='pob' AND TableName='FiscalPeriod')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  SELECT 'pob', 'FiscalPeriod', 'FiscalPeriod', N'عمومی (بستر)', 0
  WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='FiscalPeriod');
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='FiscalPeriod' AND COLUMN_NAME='IsClosed')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='FiscalPeriod' AND FieldName='IsClosed')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'FiscalPeriod', 'IsClosed', N'بسته‌شده (بله/خیر)', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='FiscalPeriod' AND COLUMN_NAME='IsClosed';
  UPDATE YFG.FieldName SET FieldFa=N'بسته‌شده (بله/خیر)', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='FiscalPeriod' AND FieldName='IsClosed' AND (FieldFa<>N'بسته‌شده (بله/خیر)' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='FiscalPeriod' AND COLUMN_NAME='MonthNo')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='FiscalPeriod' AND FieldName='MonthNo')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'FiscalPeriod', 'MonthNo', N'شمارهٔ ماه', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='FiscalPeriod' AND COLUMN_NAME='MonthNo';
  UPDATE YFG.FieldName SET FieldFa=N'شمارهٔ ماه', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='FiscalPeriod' AND FieldName='MonthNo' AND (FieldFa<>N'شمارهٔ ماه' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='FiscalPeriod' AND COLUMN_NAME='PeriodId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='FiscalPeriod' AND FieldName='PeriodId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'FiscalPeriod', 'PeriodId', N'شناسهٔ دوره', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='FiscalPeriod' AND COLUMN_NAME='PeriodId';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ دوره', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='FiscalPeriod' AND FieldName='PeriodId' AND (FieldFa<>N'شناسهٔ دوره' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='FiscalPeriod' AND COLUMN_NAME='Title')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='FiscalPeriod' AND FieldName='Title')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'FiscalPeriod', 'Title', N'عنوان دوره', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='FiscalPeriod' AND COLUMN_NAME='Title';
  UPDATE YFG.FieldName SET FieldFa=N'عنوان دوره', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='FiscalPeriod' AND FieldName='Title' AND (FieldFa<>N'عنوان دوره' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='FiscalPeriod' AND COLUMN_NAME='YearId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='FiscalPeriod' AND FieldName='YearId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'FiscalPeriod', 'YearId', N'سال مالی', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='FiscalPeriod' AND COLUMN_NAME='YearId';
  UPDATE YFG.FieldName SET FieldFa=N'سال مالی', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='FiscalPeriod' AND FieldName='YearId' AND (FieldFa<>N'سال مالی' OR Module<>N'عمومی (بستر)');
END
GO
/* --- pob.FiscalYear --- */
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='pob' AND TableName='FiscalYear')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  SELECT 'pob', 'FiscalYear', 'FiscalYear', N'عمومی (بستر)', 0
  WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='FiscalYear');
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='FiscalYear' AND COLUMN_NAME='EndDate')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='FiscalYear' AND FieldName='EndDate')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'FiscalYear', 'EndDate', N'تاریخ پایان (جلالی)', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='FiscalYear' AND COLUMN_NAME='EndDate';
  UPDATE YFG.FieldName SET FieldFa=N'تاریخ پایان (جلالی)', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='FiscalYear' AND FieldName='EndDate' AND (FieldFa<>N'تاریخ پایان (جلالی)' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='FiscalYear' AND COLUMN_NAME='IsClosed')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='FiscalYear' AND FieldName='IsClosed')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'FiscalYear', 'IsClosed', N'بسته‌شده (بله/خیر)', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='FiscalYear' AND COLUMN_NAME='IsClosed';
  UPDATE YFG.FieldName SET FieldFa=N'بسته‌شده (بله/خیر)', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='FiscalYear' AND FieldName='IsClosed' AND (FieldFa<>N'بسته‌شده (بله/خیر)' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='FiscalYear' AND COLUMN_NAME='JalaliYear')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='FiscalYear' AND FieldName='JalaliYear')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'FiscalYear', 'JalaliYear', N'سال شمسی', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='FiscalYear' AND COLUMN_NAME='JalaliYear';
  UPDATE YFG.FieldName SET FieldFa=N'سال شمسی', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='FiscalYear' AND FieldName='JalaliYear' AND (FieldFa<>N'سال شمسی' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='FiscalYear' AND COLUMN_NAME='StartDate')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='FiscalYear' AND FieldName='StartDate')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'FiscalYear', 'StartDate', N'تاریخ شروع (جلالی)', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='FiscalYear' AND COLUMN_NAME='StartDate';
  UPDATE YFG.FieldName SET FieldFa=N'تاریخ شروع (جلالی)', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='FiscalYear' AND FieldName='StartDate' AND (FieldFa<>N'تاریخ شروع (جلالی)' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='FiscalYear' AND COLUMN_NAME='Title')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='FiscalYear' AND FieldName='Title')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'FiscalYear', 'Title', N'عنوان سال مالی', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='FiscalYear' AND COLUMN_NAME='Title';
  UPDATE YFG.FieldName SET FieldFa=N'عنوان سال مالی', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='FiscalYear' AND FieldName='Title' AND (FieldFa<>N'عنوان سال مالی' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='FiscalYear' AND COLUMN_NAME='YearId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='FiscalYear' AND FieldName='YearId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'FiscalYear', 'YearId', N'شناسهٔ سال مالی', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='FiscalYear' AND COLUMN_NAME='YearId';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ سال مالی', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='FiscalYear' AND FieldName='YearId' AND (FieldFa<>N'شناسهٔ سال مالی' OR Module<>N'عمومی (بستر)');
END
GO
/* --- pob.GeoPlace --- */
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='pob' AND TableName='GeoPlace')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  SELECT 'pob', 'GeoPlace', 'GeoPlace', N'عمومی (بستر)', 0
  WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='GeoPlace');
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='GeoPlace' AND COLUMN_NAME='GeoPlaceId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='GeoPlace' AND FieldName='GeoPlaceId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'GeoPlace', 'GeoPlaceId', N'شناسهٔ موقعیت', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='GeoPlace' AND COLUMN_NAME='GeoPlaceId';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ موقعیت', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='GeoPlace' AND FieldName='GeoPlaceId' AND (FieldFa<>N'شناسهٔ موقعیت' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='GeoPlace' AND COLUMN_NAME='GeoType')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='GeoPlace' AND FieldName='GeoType')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'GeoPlace', 'GeoType', N'نوع تقسیم', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='GeoPlace' AND COLUMN_NAME='GeoType';
  UPDATE YFG.FieldName SET FieldFa=N'نوع تقسیم', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='GeoPlace' AND FieldName='GeoType' AND (FieldFa<>N'نوع تقسیم' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='GeoPlace' AND COLUMN_NAME='LatinTitle')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='GeoPlace' AND FieldName='LatinTitle')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'GeoPlace', 'LatinTitle', N'عنوان لاتین', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='GeoPlace' AND COLUMN_NAME='LatinTitle';
  UPDATE YFG.FieldName SET FieldFa=N'عنوان لاتین', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='GeoPlace' AND FieldName='LatinTitle' AND (FieldFa<>N'عنوان لاتین' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='GeoPlace' AND COLUMN_NAME='ParentRef')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='GeoPlace' AND FieldName='ParentRef')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'GeoPlace', 'ParentRef', N'موقعیت والد', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='GeoPlace' AND COLUMN_NAME='ParentRef';
  UPDATE YFG.FieldName SET FieldFa=N'موقعیت والد', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='GeoPlace' AND FieldName='ParentRef' AND (FieldFa<>N'موقعیت والد' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='GeoPlace' AND COLUMN_NAME='Title')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='GeoPlace' AND FieldName='Title')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'GeoPlace', 'Title', N'عنوان', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='GeoPlace' AND COLUMN_NAME='Title';
  UPDATE YFG.FieldName SET FieldFa=N'عنوان', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='GeoPlace' AND FieldName='Title' AND (FieldFa<>N'عنوان' OR Module<>N'عمومی (بستر)');
END
GO
/* --- pob.Holiday --- */
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='pob' AND TableName='Holiday')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  SELECT 'pob', 'Holiday', 'Holiday', N'عمومی (بستر)', 0
  WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Holiday');
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Holiday' AND COLUMN_NAME='Descr')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='Holiday' AND FieldName='Descr')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'Holiday', 'Descr', N'توضیح', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Holiday' AND COLUMN_NAME='Descr';
  UPDATE YFG.FieldName SET FieldFa=N'توضیح', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='Holiday' AND FieldName='Descr' AND (FieldFa<>N'توضیح' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Holiday' AND COLUMN_NAME='GDate')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='Holiday' AND FieldName='GDate')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'Holiday', 'GDate', N'تاریخ (میلادی)', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Holiday' AND COLUMN_NAME='GDate';
  UPDATE YFG.FieldName SET FieldFa=N'تاریخ (میلادی)', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='Holiday' AND FieldName='GDate' AND (FieldFa<>N'تاریخ (میلادی)' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Holiday' AND COLUMN_NAME='HolidayId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='Holiday' AND FieldName='HolidayId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'Holiday', 'HolidayId', N'شناسهٔ تعطیلی', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Holiday' AND COLUMN_NAME='HolidayId';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ تعطیلی', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='Holiday' AND FieldName='HolidayId' AND (FieldFa<>N'شناسهٔ تعطیلی' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Holiday' AND COLUMN_NAME='HolidayTypeRef')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='Holiday' AND FieldName='HolidayTypeRef')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'Holiday', 'HolidayTypeRef', N'نوع تعطیلی', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Holiday' AND COLUMN_NAME='HolidayTypeRef';
  UPDATE YFG.FieldName SET FieldFa=N'نوع تعطیلی', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='Holiday' AND FieldName='HolidayTypeRef' AND (FieldFa<>N'نوع تعطیلی' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Holiday' AND COLUMN_NAME='JDate')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='Holiday' AND FieldName='JDate')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'Holiday', 'JDate', N'تاریخ (جلالی)', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Holiday' AND COLUMN_NAME='JDate';
  UPDATE YFG.FieldName SET FieldFa=N'تاریخ (جلالی)', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='Holiday' AND FieldName='JDate' AND (FieldFa<>N'تاریخ (جلالی)' OR Module<>N'عمومی (بستر)');
END
GO
/* --- pob.HolidayType --- */
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='pob' AND TableName='HolidayType')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  SELECT 'pob', 'HolidayType', 'HolidayType', N'عمومی (بستر)', 0
  WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='HolidayType');
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='HolidayType' AND COLUMN_NAME='HolidayTypeId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='HolidayType' AND FieldName='HolidayTypeId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'HolidayType', 'HolidayTypeId', N'شناسهٔ نوع تعطیلی', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='HolidayType' AND COLUMN_NAME='HolidayTypeId';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ نوع تعطیلی', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='HolidayType' AND FieldName='HolidayTypeId' AND (FieldFa<>N'شناسهٔ نوع تعطیلی' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='HolidayType' AND COLUMN_NAME='Title')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='HolidayType' AND FieldName='Title')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'HolidayType', 'Title', N'عنوان نوع تعطیلی', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='HolidayType' AND COLUMN_NAME='Title';
  UPDATE YFG.FieldName SET FieldFa=N'عنوان نوع تعطیلی', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='HolidayType' AND FieldName='Title' AND (FieldFa<>N'عنوان نوع تعطیلی' OR Module<>N'عمومی (بستر)');
END
GO
/* --- pob.IdSequence --- */
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='pob' AND TableName='IdSequence')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  SELECT 'pob', 'IdSequence', 'IdSequence', N'عمومی (بستر)', 0
  WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='IdSequence');
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='IdSequence' AND COLUMN_NAME='LastId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='IdSequence' AND FieldName='LastId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'IdSequence', 'LastId', N'آخرین شناسه', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='IdSequence' AND COLUMN_NAME='LastId';
  UPDATE YFG.FieldName SET FieldFa=N'آخرین شناسه', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='IdSequence' AND FieldName='LastId' AND (FieldFa<>N'آخرین شناسه' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='IdSequence' AND COLUMN_NAME='TableName')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='IdSequence' AND FieldName='TableName')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'IdSequence', 'TableName', N'نام جدول', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='IdSequence' AND COLUMN_NAME='TableName';
  UPDATE YFG.FieldName SET FieldFa=N'نام جدول', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='IdSequence' AND FieldName='TableName' AND (FieldFa<>N'نام جدول' OR Module<>N'عمومی (بستر)');
END
GO
/* --- pob.NonWorkingTime --- */
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='pob' AND TableName='NonWorkingTime')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  SELECT 'pob', 'NonWorkingTime', 'NonWorkingTime', N'عمومی (بستر)', 0
  WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='NonWorkingTime');
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='NonWorkingTime' AND COLUMN_NAME='Descr')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='NonWorkingTime' AND FieldName='Descr')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'NonWorkingTime', 'Descr', N'توضیح', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='NonWorkingTime' AND COLUMN_NAME='Descr';
  UPDATE YFG.FieldName SET FieldFa=N'توضیح', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='NonWorkingTime' AND FieldName='Descr' AND (FieldFa<>N'توضیح' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='NonWorkingTime' AND COLUMN_NAME='FromTime')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='NonWorkingTime' AND FieldName='FromTime')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'NonWorkingTime', 'FromTime', N'از ساعت', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='NonWorkingTime' AND COLUMN_NAME='FromTime';
  UPDATE YFG.FieldName SET FieldFa=N'از ساعت', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='NonWorkingTime' AND FieldName='FromTime' AND (FieldFa<>N'از ساعت' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='NonWorkingTime' AND COLUMN_NAME='JDate')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='NonWorkingTime' AND FieldName='JDate')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'NonWorkingTime', 'JDate', N'تاریخ (جلالی)', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='NonWorkingTime' AND COLUMN_NAME='JDate';
  UPDATE YFG.FieldName SET FieldFa=N'تاریخ (جلالی)', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='NonWorkingTime' AND FieldName='JDate' AND (FieldFa<>N'تاریخ (جلالی)' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='NonWorkingTime' AND COLUMN_NAME='NonWorkId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='NonWorkingTime' AND FieldName='NonWorkId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'NonWorkingTime', 'NonWorkId', N'شناسهٔ ردیف', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='NonWorkingTime' AND COLUMN_NAME='NonWorkId';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ ردیف', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='NonWorkingTime' AND FieldName='NonWorkId' AND (FieldFa<>N'شناسهٔ ردیف' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='NonWorkingTime' AND COLUMN_NAME='ToTime')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='NonWorkingTime' AND FieldName='ToTime')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'NonWorkingTime', 'ToTime', N'تا ساعت', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='NonWorkingTime' AND COLUMN_NAME='ToTime';
  UPDATE YFG.FieldName SET FieldFa=N'تا ساعت', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='NonWorkingTime' AND FieldName='ToTime' AND (FieldFa<>N'تا ساعت' OR Module<>N'عمومی (بستر)');
END
GO
/* --- pob.Party --- */
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='pob' AND TableName='Party')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  SELECT 'pob', 'Party', 'Party', N'عمومی (بستر)', 0
  WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Party');
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Party' AND COLUMN_NAME='CompName')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='Party' AND FieldName='CompName')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'Party', 'CompName', N'نام شرکت', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Party' AND COLUMN_NAME='CompName';
  UPDATE YFG.FieldName SET FieldFa=N'نام شرکت', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='Party' AND FieldName='CompName' AND (FieldFa<>N'نام شرکت' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Party' AND COLUMN_NAME='CompName_En')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='Party' AND FieldName='CompName_En')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'Party', 'CompName_En', N'نام شرکت لاتین', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Party' AND COLUMN_NAME='CompName_En';
  UPDATE YFG.FieldName SET FieldFa=N'نام شرکت لاتین', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='Party' AND FieldName='CompName_En' AND (FieldFa<>N'نام شرکت لاتین' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Party' AND COLUMN_NAME='EconCode')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='Party' AND FieldName='EconCode')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'Party', 'EconCode', N'کد اقتصادی', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Party' AND COLUMN_NAME='EconCode';
  UPDATE YFG.FieldName SET FieldFa=N'کد اقتصادی', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='Party' AND FieldName='EconCode' AND (FieldFa<>N'کد اقتصادی' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Party' AND COLUMN_NAME='FName')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='Party' AND FieldName='FName')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'Party', 'FName', N'نام', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Party' AND COLUMN_NAME='FName';
  UPDATE YFG.FieldName SET FieldFa=N'نام', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='Party' AND FieldName='FName' AND (FieldFa<>N'نام' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Party' AND COLUMN_NAME='FName_En')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='Party' AND FieldName='FName_En')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'Party', 'FName_En', N'نام لاتین', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Party' AND COLUMN_NAME='FName_En';
  UPDATE YFG.FieldName SET FieldFa=N'نام لاتین', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='Party' AND FieldName='FName_En' AND (FieldFa<>N'نام لاتین' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Party' AND COLUMN_NAME='FatherName')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='Party' AND FieldName='FatherName')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'Party', 'FatherName', N'نام پدر', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Party' AND COLUMN_NAME='FatherName';
  UPDATE YFG.FieldName SET FieldFa=N'نام پدر', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='Party' AND FieldName='FatherName' AND (FieldFa<>N'نام پدر' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Party' AND COLUMN_NAME='IDNo')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='Party' AND FieldName='IDNo')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'Party', 'IDNo', N'شمارهٔ شناسنامه', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Party' AND COLUMN_NAME='IDNo';
  UPDATE YFG.FieldName SET FieldFa=N'شمارهٔ شناسنامه', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='Party' AND FieldName='IDNo' AND (FieldFa<>N'شمارهٔ شناسنامه' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Party' AND COLUMN_NAME='LName')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='Party' AND FieldName='LName')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'Party', 'LName', N'نام خانوادگی', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Party' AND COLUMN_NAME='LName';
  UPDATE YFG.FieldName SET FieldFa=N'نام خانوادگی', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='Party' AND FieldName='LName' AND (FieldFa<>N'نام خانوادگی' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Party' AND COLUMN_NAME='LName_En')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='Party' AND FieldName='LName_En')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'Party', 'LName_En', N'نام خانوادگی لاتین', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Party' AND COLUMN_NAME='LName_En';
  UPDATE YFG.FieldName SET FieldFa=N'نام خانوادگی لاتین', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='Party' AND FieldName='LName_En' AND (FieldFa<>N'نام خانوادگی لاتین' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Party' AND COLUMN_NAME='MainAddrRef')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='Party' AND FieldName='MainAddrRef')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'Party', 'MainAddrRef', N'مرجع نشانی اصلی', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Party' AND COLUMN_NAME='MainAddrRef';
  UPDATE YFG.FieldName SET FieldFa=N'مرجع نشانی اصلی', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='Party' AND FieldName='MainAddrRef' AND (FieldFa<>N'مرجع نشانی اصلی' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Party' AND COLUMN_NAME='NationalCode')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='Party' AND FieldName='NationalCode')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'Party', 'NationalCode', N'کد/شناسهٔ ملی', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Party' AND COLUMN_NAME='NationalCode';
  UPDATE YFG.FieldName SET FieldFa=N'کد/شناسهٔ ملی', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='Party' AND FieldName='NationalCode' AND (FieldFa<>N'کد/شناسهٔ ملی' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Party' AND COLUMN_NAME='NickName')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='Party' AND FieldName='NickName')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'Party', 'NickName', N'لقب', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Party' AND COLUMN_NAME='NickName';
  UPDATE YFG.FieldName SET FieldFa=N'لقب', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='Party' AND FieldName='NickName' AND (FieldFa<>N'لقب' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Party' AND COLUMN_NAME='PartyKind')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='Party' AND FieldName='PartyKind')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'Party', 'PartyKind', N'نوع شخص (حقیقی/حقوقی)', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Party' AND COLUMN_NAME='PartyKind';
  UPDATE YFG.FieldName SET FieldFa=N'نوع شخص (حقیقی/حقوقی)', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='Party' AND FieldName='PartyKind' AND (FieldFa<>N'نوع شخص (حقیقی/حقوقی)' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Party' AND COLUMN_NAME='RecType')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='Party' AND FieldName='RecType')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'Party', 'RecType', N'نوع رکورد (شخص/شرکت)', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Party' AND COLUMN_NAME='RecType';
  UPDATE YFG.FieldName SET FieldFa=N'نوع رکورد (شخص/شرکت)', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='Party' AND FieldName='RecType' AND (FieldFa<>N'نوع رکورد (شخص/شرکت)' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Party' AND COLUMN_NAME='Serial')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='Party' AND FieldName='Serial')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'Party', 'Serial', N'شناسهٔ شخص', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Party' AND COLUMN_NAME='Serial';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ شخص', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='Party' AND FieldName='Serial' AND (FieldFa<>N'شناسهٔ شخص' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Party' AND COLUMN_NAME='Title')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='Party' AND FieldName='Title')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'Party', 'Title', N'عنوان شخص', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Party' AND COLUMN_NAME='Title';
  UPDATE YFG.FieldName SET FieldFa=N'عنوان شخص', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='Party' AND FieldName='Title' AND (FieldFa<>N'عنوان شخص' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Party' AND COLUMN_NAME='Title_En')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='Party' AND FieldName='Title_En')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'Party', 'Title_En', N'عنوان لاتین', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='Party' AND COLUMN_NAME='Title_En';
  UPDATE YFG.FieldName SET FieldFa=N'عنوان لاتین', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='Party' AND FieldName='Title_En' AND (FieldFa<>N'عنوان لاتین' OR Module<>N'عمومی (بستر)');
END
GO
/* --- pob.PartyAddress --- */
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='pob' AND TableName='PartyAddress')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  SELECT 'pob', 'PartyAddress', 'PartyAddress', N'عمومی (بستر)', 0
  WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyAddress');
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyAddress' AND COLUMN_NAME='Address')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='PartyAddress' AND FieldName='Address')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'PartyAddress', 'Address', N'نشانی', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyAddress' AND COLUMN_NAME='Address';
  UPDATE YFG.FieldName SET FieldFa=N'نشانی', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='PartyAddress' AND FieldName='Address' AND (FieldFa<>N'نشانی' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyAddress' AND COLUMN_NAME='Address_En')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='PartyAddress' AND FieldName='Address_En')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'PartyAddress', 'Address_En', N'نشانی لاتین', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyAddress' AND COLUMN_NAME='Address_En';
  UPDATE YFG.FieldName SET FieldFa=N'نشانی لاتین', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='PartyAddress' AND FieldName='Address_En' AND (FieldFa<>N'نشانی لاتین' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyAddress' AND COLUMN_NAME='EMail')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='PartyAddress' AND FieldName='EMail')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'PartyAddress', 'EMail', N'ایمیل', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyAddress' AND COLUMN_NAME='EMail';
  UPDATE YFG.FieldName SET FieldFa=N'ایمیل', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='PartyAddress' AND FieldName='EMail' AND (FieldFa<>N'ایمیل' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyAddress' AND COLUMN_NAME='Fax')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='PartyAddress' AND FieldName='Fax')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'PartyAddress', 'Fax', N'فکس', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyAddress' AND COLUMN_NAME='Fax';
  UPDATE YFG.FieldName SET FieldFa=N'فکس', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='PartyAddress' AND FieldName='Fax' AND (FieldFa<>N'فکس' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyAddress' AND COLUMN_NAME='GeoPlaceRef')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='PartyAddress' AND FieldName='GeoPlaceRef')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'PartyAddress', 'GeoPlaceRef', N'موقعیت جغرافیایی', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyAddress' AND COLUMN_NAME='GeoPlaceRef';
  UPDATE YFG.FieldName SET FieldFa=N'موقعیت جغرافیایی', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='PartyAddress' AND FieldName='GeoPlaceRef' AND (FieldFa<>N'موقعیت جغرافیایی' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyAddress' AND COLUMN_NAME='Mobile')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='PartyAddress' AND FieldName='Mobile')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'PartyAddress', 'Mobile', N'تلفن همراه', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyAddress' AND COLUMN_NAME='Mobile';
  UPDATE YFG.FieldName SET FieldFa=N'تلفن همراه', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='PartyAddress' AND FieldName='Mobile' AND (FieldFa<>N'تلفن همراه' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyAddress' AND COLUMN_NAME='Modem')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='PartyAddress' AND FieldName='Modem')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'PartyAddress', 'Modem', N'مودم', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyAddress' AND COLUMN_NAME='Modem';
  UPDATE YFG.FieldName SET FieldFa=N'مودم', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='PartyAddress' AND FieldName='Modem' AND (FieldFa<>N'مودم' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyAddress' AND COLUMN_NAME='PartyRef')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='PartyAddress' AND FieldName='PartyRef')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'PartyAddress', 'PartyRef', N'شناسهٔ شخص', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyAddress' AND COLUMN_NAME='PartyRef';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ شخص', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='PartyAddress' AND FieldName='PartyRef' AND (FieldFa<>N'شناسهٔ شخص' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyAddress' AND COLUMN_NAME='Phone')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='PartyAddress' AND FieldName='Phone')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'PartyAddress', 'Phone', N'تلفن', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyAddress' AND COLUMN_NAME='Phone';
  UPDATE YFG.FieldName SET FieldFa=N'تلفن', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='PartyAddress' AND FieldName='Phone' AND (FieldFa<>N'تلفن' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyAddress' AND COLUMN_NAME='PostBox')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='PartyAddress' AND FieldName='PostBox')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'PartyAddress', 'PostBox', N'صندوق پستی', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyAddress' AND COLUMN_NAME='PostBox';
  UPDATE YFG.FieldName SET FieldFa=N'صندوق پستی', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='PartyAddress' AND FieldName='PostBox' AND (FieldFa<>N'صندوق پستی' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyAddress' AND COLUMN_NAME='Serial')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='PartyAddress' AND FieldName='Serial')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'PartyAddress', 'Serial', N'شناسهٔ نشانی', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyAddress' AND COLUMN_NAME='Serial';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ نشانی', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='PartyAddress' AND FieldName='Serial' AND (FieldFa<>N'شناسهٔ نشانی' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyAddress' AND COLUMN_NAME='Title')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='PartyAddress' AND FieldName='Title')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'PartyAddress', 'Title', N'عنوان نشانی', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyAddress' AND COLUMN_NAME='Title';
  UPDATE YFG.FieldName SET FieldFa=N'عنوان نشانی', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='PartyAddress' AND FieldName='Title' AND (FieldFa<>N'عنوان نشانی' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyAddress' AND COLUMN_NAME='ZipCode')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='PartyAddress' AND FieldName='ZipCode')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'PartyAddress', 'ZipCode', N'کد پستی', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyAddress' AND COLUMN_NAME='ZipCode';
  UPDATE YFG.FieldName SET FieldFa=N'کد پستی', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='PartyAddress' AND FieldName='ZipCode' AND (FieldFa<>N'کد پستی' OR Module<>N'عمومی (بستر)');
END
GO
/* --- pob.PartyCategory --- */
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='pob' AND TableName='PartyCategory')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  SELECT 'pob', 'PartyCategory', 'PartyCategory', N'عمومی (بستر)', 0
  WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyCategory');
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyCategory' AND COLUMN_NAME='CategoryId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='PartyCategory' AND FieldName='CategoryId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'PartyCategory', 'CategoryId', N'شناسهٔ دسته‌بندی', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyCategory' AND COLUMN_NAME='CategoryId';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ دسته‌بندی', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='PartyCategory' AND FieldName='CategoryId' AND (FieldFa<>N'شناسهٔ دسته‌بندی' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyCategory' AND COLUMN_NAME='ParentRef')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='PartyCategory' AND FieldName='ParentRef')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'PartyCategory', 'ParentRef', N'دستهٔ والد', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyCategory' AND COLUMN_NAME='ParentRef';
  UPDATE YFG.FieldName SET FieldFa=N'دستهٔ والد', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='PartyCategory' AND FieldName='ParentRef' AND (FieldFa<>N'دستهٔ والد' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyCategory' AND COLUMN_NAME='Title')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='PartyCategory' AND FieldName='Title')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'PartyCategory', 'Title', N'عنوان دسته‌بندی', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyCategory' AND COLUMN_NAME='Title';
  UPDATE YFG.FieldName SET FieldFa=N'عنوان دسته‌بندی', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='PartyCategory' AND FieldName='Title' AND (FieldFa<>N'عنوان دسته‌بندی' OR Module<>N'عمومی (بستر)');
END
GO
/* --- pob.PartyCategoryLink --- */
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='pob' AND TableName='PartyCategoryLink')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  SELECT 'pob', 'PartyCategoryLink', 'PartyCategoryLink', N'عمومی (بستر)', 0
  WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyCategoryLink');
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyCategoryLink' AND COLUMN_NAME='CategoryRef')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='PartyCategoryLink' AND FieldName='CategoryRef')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'PartyCategoryLink', 'CategoryRef', N'شناسهٔ دسته‌بندی', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyCategoryLink' AND COLUMN_NAME='CategoryRef';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ دسته‌بندی', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='PartyCategoryLink' AND FieldName='CategoryRef' AND (FieldFa<>N'شناسهٔ دسته‌بندی' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyCategoryLink' AND COLUMN_NAME='PartyRef')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='PartyCategoryLink' AND FieldName='PartyRef')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'PartyCategoryLink', 'PartyRef', N'شناسهٔ شخص', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='PartyCategoryLink' AND COLUMN_NAME='PartyRef';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ شخص', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='PartyCategoryLink' AND FieldName='PartyRef' AND (FieldFa<>N'شناسهٔ شخص' OR Module<>N'عمومی (بستر)');
END
GO
/* --- pob.SubSystem --- */
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='pob' AND TableName='SubSystem')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  SELECT 'pob', 'SubSystem', 'SubSystem', N'عمومی (بستر)', 0
  WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='SubSystem');
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='SubSystem' AND COLUMN_NAME='LatinTitle')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='SubSystem' AND FieldName='LatinTitle')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'SubSystem', 'LatinTitle', N'عنوان لاتین', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='SubSystem' AND COLUMN_NAME='LatinTitle';
  UPDATE YFG.FieldName SET FieldFa=N'عنوان لاتین', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='SubSystem' AND FieldName='LatinTitle' AND (FieldFa<>N'عنوان لاتین' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='SubSystem' AND COLUMN_NAME='SystemCode')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='SubSystem' AND FieldName='SystemCode')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'SubSystem', 'SystemCode', N'کد زیرسیستم', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='SubSystem' AND COLUMN_NAME='SystemCode';
  UPDATE YFG.FieldName SET FieldFa=N'کد زیرسیستم', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='SubSystem' AND FieldName='SystemCode' AND (FieldFa<>N'کد زیرسیستم' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='SubSystem' AND COLUMN_NAME='TitleFa')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='SubSystem' AND FieldName='TitleFa')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'SubSystem', 'TitleFa', N'عنوان فارسی', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='SubSystem' AND COLUMN_NAME='TitleFa';
  UPDATE YFG.FieldName SET FieldFa=N'عنوان فارسی', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='SubSystem' AND FieldName='TitleFa' AND (FieldFa<>N'عنوان فارسی' OR Module<>N'عمومی (بستر)');
END
GO
/* --- pob.UserLog --- */
IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='pob' AND TableName='UserLog')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  SELECT 'pob', 'UserLog', 'UserLog', N'عمومی (بستر)', 0
  WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='UserLog');
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='UserLog' AND COLUMN_NAME='ActivityType')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='UserLog' AND FieldName='ActivityType')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'UserLog', 'ActivityType', N'نوع فعالیت', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='UserLog' AND COLUMN_NAME='ActivityType';
  UPDATE YFG.FieldName SET FieldFa=N'نوع فعالیت', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='UserLog' AND FieldName='ActivityType' AND (FieldFa<>N'نوع فعالیت' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='UserLog' AND COLUMN_NAME='ComputerName')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='UserLog' AND FieldName='ComputerName')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'UserLog', 'ComputerName', N'نام رایانه', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='UserLog' AND COLUMN_NAME='ComputerName';
  UPDATE YFG.FieldName SET FieldFa=N'نام رایانه', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='UserLog' AND FieldName='ComputerName' AND (FieldFa<>N'نام رایانه' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='UserLog' AND COLUMN_NAME='DocInfo')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='UserLog' AND FieldName='DocInfo')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'UserLog', 'DocInfo', N'اطلاعات سند', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='UserLog' AND COLUMN_NAME='DocInfo';
  UPDATE YFG.FieldName SET FieldFa=N'اطلاعات سند', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='UserLog' AND FieldName='DocInfo' AND (FieldFa<>N'اطلاعات سند' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='UserLog' AND COLUMN_NAME='FieldName')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='UserLog' AND FieldName='FieldName')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'UserLog', 'FieldName', N'نام فیلد', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='UserLog' AND COLUMN_NAME='FieldName';
  UPDATE YFG.FieldName SET FieldFa=N'نام فیلد', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='UserLog' AND FieldName='FieldName' AND (FieldFa<>N'نام فیلد' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='UserLog' AND COLUMN_NAME='IpAddress')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='UserLog' AND FieldName='IpAddress')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'UserLog', 'IpAddress', N'آدرس IP', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='UserLog' AND COLUMN_NAME='IpAddress';
  UPDATE YFG.FieldName SET FieldFa=N'آدرس IP', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='UserLog' AND FieldName='IpAddress' AND (FieldFa<>N'آدرس IP' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='UserLog' AND COLUMN_NAME='LogDate')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='UserLog' AND FieldName='LogDate')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'UserLog', 'LogDate', N'تاریخ (جلالی)', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='UserLog' AND COLUMN_NAME='LogDate';
  UPDATE YFG.FieldName SET FieldFa=N'تاریخ (جلالی)', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='UserLog' AND FieldName='LogDate' AND (FieldFa<>N'تاریخ (جلالی)' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='UserLog' AND COLUMN_NAME='LogTime')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='UserLog' AND FieldName='LogTime')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'UserLog', 'LogTime', N'زمان', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='UserLog' AND COLUMN_NAME='LogTime';
  UPDATE YFG.FieldName SET FieldFa=N'زمان', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='UserLog' AND FieldName='LogTime' AND (FieldFa<>N'زمان' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='UserLog' AND COLUMN_NAME='NewValue')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='UserLog' AND FieldName='NewValue')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'UserLog', 'NewValue', N'مقدار جدید', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='UserLog' AND COLUMN_NAME='NewValue';
  UPDATE YFG.FieldName SET FieldFa=N'مقدار جدید', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='UserLog' AND FieldName='NewValue' AND (FieldFa<>N'مقدار جدید' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='UserLog' AND COLUMN_NAME='OldValue')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='UserLog' AND FieldName='OldValue')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'UserLog', 'OldValue', N'مقدار قبلی', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='UserLog' AND COLUMN_NAME='OldValue';
  UPDATE YFG.FieldName SET FieldFa=N'مقدار قبلی', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='UserLog' AND FieldName='OldValue' AND (FieldFa<>N'مقدار قبلی' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='UserLog' AND COLUMN_NAME='RecId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='UserLog' AND FieldName='RecId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'UserLog', 'RecId', N'شناسهٔ رکورد', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='UserLog' AND COLUMN_NAME='RecId';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ رکورد', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='UserLog' AND FieldName='RecId' AND (FieldFa<>N'شناسهٔ رکورد' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='UserLog' AND COLUMN_NAME='SubSystem')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='UserLog' AND FieldName='SubSystem')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'UserLog', 'SubSystem', N'زیرسیستم', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='UserLog' AND COLUMN_NAME='SubSystem';
  UPDATE YFG.FieldName SET FieldFa=N'زیرسیستم', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='UserLog' AND FieldName='SubSystem' AND (FieldFa<>N'زیرسیستم' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='UserLog' AND COLUMN_NAME='TableName')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='UserLog' AND FieldName='TableName')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'UserLog', 'TableName', N'نام جدول', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='UserLog' AND COLUMN_NAME='TableName';
  UPDATE YFG.FieldName SET FieldFa=N'نام جدول', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='UserLog' AND FieldName='TableName' AND (FieldFa<>N'نام جدول' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='UserLog' AND COLUMN_NAME='UserLogId')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='UserLog' AND FieldName='UserLogId')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'UserLog', 'UserLogId', N'شناسهٔ لاگ', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='UserLog' AND COLUMN_NAME='UserLogId';
  UPDATE YFG.FieldName SET FieldFa=N'شناسهٔ لاگ', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='UserLog' AND FieldName='UserLogId' AND (FieldFa<>N'شناسهٔ لاگ' OR Module<>N'عمومی (بستر)');
END
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='UserLog' AND COLUMN_NAME='UserName')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='UserLog' AND FieldName='UserName')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT 'pob', 'UserLog', 'UserName', N'کاربر', N'عمومی (بستر)', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='pob' AND TABLE_NAME='UserLog' AND COLUMN_NAME='UserName';
  UPDATE YFG.FieldName SET FieldFa=N'کاربر', Module=N'عمومی (بستر)'
  WHERE TableSchema='pob' AND TableName='UserLog' AND FieldName='UserName' AND (FieldFa<>N'کاربر' OR Module<>N'عمومی (بستر)');
END
GO
/* ---------- بخش ۷: هم‌گام‌سازی خودکار با INFORMATION_SCHEMA (جدول/ستون‌های تازه) ---------- */
INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
SELECT c.TABLE_SCHEMA, c.TABLE_NAME, c.TABLE_NAME,
       CASE c.TABLE_SCHEMA WHEN N'ACC' THEN N'حسابداری' WHEN N'YFG' THEN N'واژه‌نامه' ELSE N'عمومی (بستر)' END, 0
FROM (SELECT DISTINCT TABLE_SCHEMA, TABLE_NAME FROM INFORMATION_SCHEMA.TABLES
      WHERE TABLE_SCHEMA IN ('ACC','pob','YFG') AND TABLE_TYPE='BASE TABLE') c
WHERE NOT EXISTS (SELECT 1 FROM YFG.TableName e WHERE e.TableSchema=c.TABLE_SCHEMA AND e.TableName=c.TABLE_NAME);

INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
SELECT c.TABLE_SCHEMA, c.TABLE_NAME, c.COLUMN_NAME, c.COLUMN_NAME,
       CASE c.TABLE_SCHEMA WHEN N'ACC' THEN N'حسابداری' WHEN N'YFG' THEN N'واژه‌نامه' ELSE N'عمومی (بستر)' END, c.DATA_TYPE
FROM (SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS
      WHERE TABLE_SCHEMA IN ('ACC','pob','YFG')) c
WHERE NOT EXISTS (SELECT 1 FROM YFG.FieldName e
                  WHERE e.TableSchema=c.TABLE_SCHEMA AND e.TableName=c.TABLE_NAME AND e.FieldName=c.COLUMN_NAME);
GO

/* ---------- بخش ۸: پیوندها (YFG.LinkField) ---------- */
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='ACC' AND TableName='AccFx' AND FieldName='CompanyId'
                      AND LinkTableSchema='pob' AND LinkTableName='Companies' AND LinkFieldName='CompanyId')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'ACC', 'AccFx', 'CompanyId', N'کد شرکت', 'pob', 'Companies', 'CompanyId', N'شناسهٔ شرکت', N'مرجع شرکت مالک ارز'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccFx' AND FieldName='CompanyId');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='ACC' AND TableName='AccBranch' AND FieldName='CompanyId'
                      AND LinkTableSchema='pob' AND LinkTableName='Companies' AND LinkFieldName='CompanyId')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'ACC', 'AccBranch', 'CompanyId', N'کد شرکت', 'pob', 'Companies', 'CompanyId', N'شناسهٔ شرکت', N'مرجع شرکت مالک شعبه'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccBranch' AND FieldName='CompanyId');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='ACC' AND TableName='AccGroup' AND FieldName='CompanyId'
                      AND LinkTableSchema='pob' AND LinkTableName='Companies' AND LinkFieldName='CompanyId')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'ACC', 'AccGroup', 'CompanyId', N'کد شرکت', 'pob', 'Companies', 'CompanyId', N'شناسهٔ شرکت', N'مرجع شرکت مالک گروه'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccGroup' AND FieldName='CompanyId');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='ACC' AND TableName='AccKol' AND FieldName='CompanyId'
                      AND LinkTableSchema='pob' AND LinkTableName='Companies' AND LinkFieldName='CompanyId')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'ACC', 'AccKol', 'CompanyId', N'کد شرکت', 'pob', 'Companies', 'CompanyId', N'شناسهٔ شرکت', N'مرجع شرکت مالک کل'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccKol' AND FieldName='CompanyId');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='ACC' AND TableName='AccKol' AND FieldName='GroupCode'
                      AND LinkTableSchema='ACC' AND LinkTableName='AccGroup' AND LinkFieldName='Code')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'ACC', 'AccKol', 'GroupCode', N'کد گروه', 'ACC', 'AccGroup', 'Code', N'کد گروه', N'کد گروهِ حساب کل'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccKol' AND FieldName='GroupCode');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='ACC' AND TableName='AccMoein' AND FieldName='CompanyId'
                      AND LinkTableSchema='pob' AND LinkTableName='Companies' AND LinkFieldName='CompanyId')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'ACC', 'AccMoein', 'CompanyId', N'کد شرکت', 'pob', 'Companies', 'CompanyId', N'شناسهٔ شرکت', N'مرجع شرکت مالک معین'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccMoein' AND FieldName='CompanyId');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='ACC' AND TableName='AccMoein' AND FieldName='KolCode'
                      AND LinkTableSchema='ACC' AND LinkTableName='AccKol' AND LinkFieldName='Code')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'ACC', 'AccMoein', 'KolCode', N'کد کل', 'ACC', 'AccKol', 'Code', N'کد کل', N'حساب کلِ معین'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccMoein' AND FieldName='KolCode');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='ACC' AND TableName='AccMoein' AND FieldName='Taf1TypeId'
                      AND LinkTableSchema='ACC' AND LinkTableName='AccTafsiliType' AND LinkFieldName='TafsiliTypeId')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'ACC', 'AccMoein', 'Taf1TypeId', N'نوع تفصیلی سطح ۴', 'ACC', 'AccTafsiliType', 'TafsiliTypeId', N'شناسهٔ نوع تفصیلی', N'نوع تفصیلی سطح چهارم معین'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccMoein' AND FieldName='Taf1TypeId');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='ACC' AND TableName='AccMoein' AND FieldName='Taf2TypeId'
                      AND LinkTableSchema='ACC' AND LinkTableName='AccTafsiliType' AND LinkFieldName='TafsiliTypeId')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'ACC', 'AccMoein', 'Taf2TypeId', N'نوع تفصیلی سطح ۵', 'ACC', 'AccTafsiliType', 'TafsiliTypeId', N'شناسهٔ نوع تفصیلی', N'نوع تفصیلی سطح پنجم معین'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccMoein' AND FieldName='Taf2TypeId');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='ACC' AND TableName='AccMoein' AND FieldName='Taf3TypeId'
                      AND LinkTableSchema='ACC' AND LinkTableName='AccTafsiliType' AND LinkFieldName='TafsiliTypeId')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'ACC', 'AccMoein', 'Taf3TypeId', N'نوع تفصیلی سطح ۶', 'ACC', 'AccTafsiliType', 'TafsiliTypeId', N'شناسهٔ نوع تفصیلی', N'نوع تفصیلی سطح ششم معین'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccMoein' AND FieldName='Taf3TypeId');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='ACC' AND TableName='AccTafsili' AND FieldName='CompanyId'
                      AND LinkTableSchema='pob' AND LinkTableName='Companies' AND LinkFieldName='CompanyId')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'ACC', 'AccTafsili', 'CompanyId', N'کد شرکت', 'pob', 'Companies', 'CompanyId', N'شناسهٔ شرکت', N'مرجع شرکت مالک تفصیلی'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccTafsili' AND FieldName='CompanyId');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='ACC' AND TableName='AccTafsili' AND FieldName='TafsiliTypeId'
                      AND LinkTableSchema='ACC' AND LinkTableName='AccTafsiliType' AND LinkFieldName='TafsiliTypeId')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'ACC', 'AccTafsili', 'TafsiliTypeId', N'نوع تفصیلی', 'ACC', 'AccTafsiliType', 'TafsiliTypeId', N'شناسهٔ نوع تفصیلی', N'نوعِ تفصیلی'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccTafsili' AND FieldName='TafsiliTypeId');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='ACC' AND TableName='AccTafsili' AND FieldName='PartyRef'
                      AND LinkTableSchema='pob' AND LinkTableName='Party' AND LinkFieldName='Serial')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'ACC', 'AccTafsili', 'PartyRef', N'مرجع شخص', 'pob', 'Party', 'Serial', N'شناسهٔ شخص', N'شخص متناظر با تفصیلی'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccTafsili' AND FieldName='PartyRef');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='ACC' AND TableName='AccTafsiliCategoryLink' AND FieldName='CategoryId'
                      AND LinkTableSchema='ACC' AND LinkTableName='AccTafsiliCategory' AND LinkFieldName='CategoryId')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'ACC', 'AccTafsiliCategoryLink', 'CategoryId', N'طبقه‌بندی', 'ACC', 'AccTafsiliCategory', 'CategoryId', N'شناسهٔ طبقه‌بندی', N'طبقه‌بندیِ پیوند'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccTafsiliCategoryLink' AND FieldName='CategoryId');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='ACC' AND TableName='AccTafsiliCategoryLink' AND FieldName='TafsiliId'
                      AND LinkTableSchema='ACC' AND LinkTableName='AccTafsili' AND LinkFieldName='TafsiliId')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'ACC', 'AccTafsiliCategoryLink', 'TafsiliId', N'تفصیلی', 'ACC', 'AccTafsili', 'TafsiliId', N'شناسهٔ تفصیلی', N'تفصیلیِ پیوند'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccTafsiliCategoryLink' AND FieldName='TafsiliId');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='ACC' AND TableName='AccOpeningBalance' AND FieldName='CompanyId'
                      AND LinkTableSchema='pob' AND LinkTableName='Companies' AND LinkFieldName='CompanyId')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'ACC', 'AccOpeningBalance', 'CompanyId', N'کد شرکت', 'pob', 'Companies', 'CompanyId', N'شناسهٔ شرکت', N'مرجع شرکت ماندهٔ افتتاحیه'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccOpeningBalance' AND FieldName='CompanyId');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='ACC' AND TableName='AccOpeningBalance' AND FieldName='YearId'
                      AND LinkTableSchema='pob' AND LinkTableName='FiscalYear' AND LinkFieldName='YearId')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'ACC', 'AccOpeningBalance', 'YearId', N'سال مالی', 'pob', 'FiscalYear', 'YearId', N'شناسهٔ سال مالی', N'سال مالی ماندهٔ افتتاحیه'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccOpeningBalance' AND FieldName='YearId');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='ACC' AND TableName='AccOpeningBalance' AND FieldName='KolCode'
                      AND LinkTableSchema='ACC' AND LinkTableName='AccKol' AND LinkFieldName='Code')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'ACC', 'AccOpeningBalance', 'KolCode', N'کد کل', 'ACC', 'AccKol', 'Code', N'کد کل', N'کد کل ماندهٔ افتتاحیه'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccOpeningBalance' AND FieldName='KolCode');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='ACC' AND TableName='AccOpeningBalance' AND FieldName='MoeinCode'
                      AND LinkTableSchema='ACC' AND LinkTableName='AccMoein' AND LinkFieldName='Code')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'ACC', 'AccOpeningBalance', 'MoeinCode', N'کد معین', 'ACC', 'AccMoein', 'Code', N'کد معین', N'کد معین ماندهٔ افتتاحیه'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccOpeningBalance' AND FieldName='MoeinCode');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='ACC' AND TableName='AccOpeningBalance' AND FieldName='Taf1Id'
                      AND LinkTableSchema='ACC' AND LinkTableName='AccTafsili' AND LinkFieldName='TafsiliId')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'ACC', 'AccOpeningBalance', 'Taf1Id', N'تفصیلی سطح ۴', 'ACC', 'AccTafsili', 'TafsiliId', N'شناسهٔ تفصیلی', N'تفصیلی سطح چهارم ماندهٔ افتتاحیه'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccOpeningBalance' AND FieldName='Taf1Id');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='ACC' AND TableName='AccOpeningBalance' AND FieldName='Taf2Id'
                      AND LinkTableSchema='ACC' AND LinkTableName='AccTafsili' AND LinkFieldName='TafsiliId')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'ACC', 'AccOpeningBalance', 'Taf2Id', N'تفصیلی سطح ۵', 'ACC', 'AccTafsili', 'TafsiliId', N'شناسهٔ تفصیلی', N'تفصیلی سطح پنجم ماندهٔ افتتاحیه'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccOpeningBalance' AND FieldName='Taf2Id');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='ACC' AND TableName='AccOpeningBalance' AND FieldName='Taf3Id'
                      AND LinkTableSchema='ACC' AND LinkTableName='AccTafsili' AND LinkFieldName='TafsiliId')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'ACC', 'AccOpeningBalance', 'Taf3Id', N'تفصیلی سطح ۶', 'ACC', 'AccTafsili', 'TafsiliId', N'شناسهٔ تفصیلی', N'تفصیلی سطح ششم ماندهٔ افتتاحیه'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccOpeningBalance' AND FieldName='Taf3Id');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='ACC' AND TableName='AccStdNarration' AND FieldName='CompanyId'
                      AND LinkTableSchema='pob' AND LinkTableName='Companies' AND LinkFieldName='CompanyId')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'ACC', 'AccStdNarration', 'CompanyId', N'کد شرکت', 'pob', 'Companies', 'CompanyId', N'شناسهٔ شرکت', N'مرجع شرکت شرح استاندارد'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccStdNarration' AND FieldName='CompanyId');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='ACC' AND TableName='AccStdNarration' AND FieldName='MoeinCode'
                      AND LinkTableSchema='ACC' AND LinkTableName='AccMoein' AND LinkFieldName='Code')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'ACC', 'AccStdNarration', 'MoeinCode', N'کد معین', 'ACC', 'AccMoein', 'Code', N'کد معین', N'کد معینِ شرح استاندارد'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccStdNarration' AND FieldName='MoeinCode');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='CompanyId'
                      AND LinkTableSchema='pob' AND LinkTableName='Companies' AND LinkFieldName='CompanyId')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'ACC', 'AccVoucher', 'CompanyId', N'کد شرکت', 'pob', 'Companies', 'CompanyId', N'شناسهٔ شرکت', N'شرکت مالک سند'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='CompanyId');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='YearId'
                      AND LinkTableSchema='pob' AND LinkTableName='FiscalYear' AND LinkFieldName='YearId')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'ACC', 'AccVoucher', 'YearId', N'YearId', 'pob', 'FiscalYear', 'YearId', N'شناسهٔ سال مالی', N'سال مالی سند'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='YearId');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='VoucherTypeId'
                      AND LinkTableSchema='ACC' AND LinkTableName='AccVoucherType' AND LinkFieldName='VoucherTypeId')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'ACC', 'AccVoucher', 'VoucherTypeId', N'نوع سند', 'ACC', 'AccVoucherType', 'VoucherTypeId', N'شناسهٔ نوع سند', N'نوع سند'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='VoucherTypeId');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='BranchId'
                      AND LinkTableSchema='ACC' AND LinkTableName='AccBranch' AND LinkFieldName='BranchId')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'ACC', 'AccVoucher', 'BranchId', N'شعبه', 'ACC', 'AccBranch', 'BranchId', N'شناسهٔ شعبه', N'شعبهٔ سند'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='BranchId');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='ReversalOf'
                      AND LinkTableSchema='ACC' AND LinkTableName='AccVoucher' AND LinkFieldName='VoucherId')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'ACC', 'AccVoucher', 'ReversalOf', N'شناسهٔ سند مبنای ابطال', 'ACC', 'AccVoucher', 'VoucherId', N'شناسهٔ سند', N'سند مبنای ابطال/برگشت'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucher' AND FieldName='ReversalOf');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='ACC' AND TableName='AccVoucherFlow' AND FieldName='VoucherId'
                      AND LinkTableSchema='ACC' AND LinkTableName='AccVoucher' AND LinkFieldName='VoucherId')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'ACC', 'AccVoucherFlow', 'VoucherId', N'شناسهٔ سند', 'ACC', 'AccVoucher', 'VoucherId', N'شناسهٔ سند', N'سند مالک ردیف جریان'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucherFlow' AND FieldName='VoucherId');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='VoucherId'
                      AND LinkTableSchema='ACC' AND LinkTableName='AccVoucher' AND LinkFieldName='VoucherId')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'ACC', 'AccVoucherItm', 'VoucherId', N'شناسهٔ سند', 'ACC', 'AccVoucher', 'VoucherId', N'شناسهٔ سند', N'سند مالک قلم'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='VoucherId');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='KolCode'
                      AND LinkTableSchema='ACC' AND LinkTableName='AccKol' AND LinkFieldName='Code')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'ACC', 'AccVoucherItm', 'KolCode', N'کد کل', 'ACC', 'AccKol', 'Code', N'کد کل', N'کد کل قلم'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='KolCode');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='MoeinCode'
                      AND LinkTableSchema='ACC' AND LinkTableName='AccMoein' AND LinkFieldName='Code')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'ACC', 'AccVoucherItm', 'MoeinCode', N'کد معین', 'ACC', 'AccMoein', 'Code', N'کد معین', N'کد معین قلم'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='MoeinCode');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='Taf1Id'
                      AND LinkTableSchema='ACC' AND LinkTableName='AccTafsili' AND LinkFieldName='TafsiliId')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'ACC', 'AccVoucherItm', 'Taf1Id', N'تفصیلی سطح ۴', 'ACC', 'AccTafsili', 'TafsiliId', N'شناسهٔ تفصیلی', N'تفصیلی سطح چهارم قلم'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='Taf1Id');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='Taf2Id'
                      AND LinkTableSchema='ACC' AND LinkTableName='AccTafsili' AND LinkFieldName='TafsiliId')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'ACC', 'AccVoucherItm', 'Taf2Id', N'تفصیلی سطح ۵', 'ACC', 'AccTafsili', 'TafsiliId', N'شناسهٔ تفصیلی', N'تفصیلی سطح پنجم قلم'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='Taf2Id');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='Taf3Id'
                      AND LinkTableSchema='ACC' AND LinkTableName='AccTafsili' AND LinkFieldName='TafsiliId')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'ACC', 'AccVoucherItm', 'Taf3Id', N'تفصیلی سطح ۶', 'ACC', 'AccTafsili', 'TafsiliId', N'شناسهٔ تفصیلی', N'تفصیلی سطح ششم قلم'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='Taf3Id');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='FxId'
                      AND LinkTableSchema='ACC' AND LinkTableName='AccFx' AND LinkFieldName='FxId')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'ACC', 'AccVoucherItm', 'FxId', N'نوع ارز قلم', 'ACC', 'AccFx', 'FxId', N'شناسهٔ ارز', N'ارز قلم سند'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='ACC' AND TableName='AccVoucherItm' AND FieldName='FxId');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='pob' AND TableName='FiscalYear' AND FieldName='CompanyId'
                      AND LinkTableSchema='pob' AND LinkTableName='Companies' AND LinkFieldName='CompanyId')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'pob', 'FiscalYear', 'CompanyId', N'کد شرکت', 'pob', 'Companies', 'CompanyId', N'شناسهٔ شرکت', N'شرکت مالک سال مالی'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='FiscalYear' AND FieldName='CompanyId');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='pob' AND TableName='FiscalPeriod' AND FieldName='YearId'
                      AND LinkTableSchema='pob' AND LinkTableName='FiscalYear' AND LinkFieldName='YearId')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'pob', 'FiscalPeriod', 'YearId', N'سال مالی', 'pob', 'FiscalYear', 'YearId', N'شناسهٔ سال مالی', N'سال مالیِ دوره'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='FiscalPeriod' AND FieldName='YearId');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='pob' AND TableName='Holiday' AND FieldName='HolidayTypeRef'
                      AND LinkTableSchema='pob' AND LinkTableName='HolidayType' AND LinkFieldName='HolidayTypeId')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'pob', 'Holiday', 'HolidayTypeRef', N'نوع تعطیلی', 'pob', 'HolidayType', 'HolidayTypeId', N'شناسهٔ نوع تعطیلی', N'نوع تعطیلی'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='Holiday' AND FieldName='HolidayTypeRef');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='pob' AND TableName='PartyAddress' AND FieldName='PartyRef'
                      AND LinkTableSchema='pob' AND LinkTableName='Party' AND LinkFieldName='Serial')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'pob', 'PartyAddress', 'PartyRef', N'شناسهٔ شخص', 'pob', 'Party', 'Serial', N'شناسهٔ شخص', N'شخصِ نشانی'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='PartyAddress' AND FieldName='PartyRef');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='pob' AND TableName='PartyAddress' AND FieldName='GeoPlaceRef'
                      AND LinkTableSchema='pob' AND LinkTableName='GeoPlace' AND LinkFieldName='GeoPlaceId')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'pob', 'PartyAddress', 'GeoPlaceRef', N'موقعیت جغرافیایی', 'pob', 'GeoPlace', 'GeoPlaceId', N'شناسهٔ موقعیت', N'موقعیت جغرافیایی نشانی'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='PartyAddress' AND FieldName='GeoPlaceRef');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='pob' AND TableName='PartyCategoryLink' AND FieldName='PartyRef'
                      AND LinkTableSchema='pob' AND LinkTableName='Party' AND LinkFieldName='Serial')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'pob', 'PartyCategoryLink', 'PartyRef', N'شناسهٔ شخص', 'pob', 'Party', 'Serial', N'شناسهٔ شخص', N'شخصِ پیوند'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='PartyCategoryLink' AND FieldName='PartyRef');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='pob' AND TableName='PartyCategoryLink' AND FieldName='CategoryRef'
                      AND LinkTableSchema='pob' AND LinkTableName='PartyCategory' AND LinkFieldName='CategoryId')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'pob', 'PartyCategoryLink', 'CategoryRef', N'شناسهٔ دسته‌بندی', 'pob', 'PartyCategory', 'CategoryId', N'شناسهٔ دسته‌بندی', N'دسته‌بندیِ پیوند'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='PartyCategoryLink' AND FieldName='CategoryRef');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='pob' AND TableName='PartyCategory' AND FieldName='ParentRef'
                      AND LinkTableSchema='pob' AND LinkTableName='PartyCategory' AND LinkFieldName='CategoryId')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'pob', 'PartyCategory', 'ParentRef', N'دستهٔ والد', 'pob', 'PartyCategory', 'CategoryId', N'شناسهٔ دسته‌بندی', N'دستهٔ والد'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='PartyCategory' AND FieldName='ParentRef');
GO
IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='pob' AND TableName='GeoPlace' AND FieldName='ParentRef'
                      AND LinkTableSchema='pob' AND LinkTableName='GeoPlace' AND LinkFieldName='GeoPlaceId')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT 'pob', 'GeoPlace', 'ParentRef', N'موقعیت والد', 'pob', 'GeoPlace', 'GeoPlaceId', N'شناسهٔ موقعیت', N'موقعیت والد'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='pob' AND TableName='GeoPlace' AND FieldName='ParentRef');
GO
/* ---------- بخش ۹: تریگرهای ممیزی UserLog برای سه جدول واژه‌نامه ---------- */
CREATE OR ALTER TRIGGER YFG.Tr_YFG_TableName_Audit ON YFG.TableName
AFTER INSERT, UPDATE, DELETE AS
BEGIN
  SET NOCOUNT ON;
  IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 1, N'YFG', N'YFG.TableName', i.TableId, i.TableFa + N' (' + i.TableSchema + N'.' + i.TableName + N')'
    FROM inserted i;
  IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
  BEGIN
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'YFG', N'YFG.TableName', i.TableId, i.TableFa, N'TableFa', d.TableFa, i.TableFa
    FROM inserted i JOIN deleted d ON d.TableId = i.TableId WHERE EXISTS (SELECT i.TableFa EXCEPT SELECT d.TableFa);
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'YFG', N'YFG.TableName', i.TableId, i.TableFa, N'Module', d.Module, i.Module
    FROM inserted i JOIN deleted d ON d.TableId = i.TableId WHERE EXISTS (SELECT i.Module EXCEPT SELECT d.Module);
  END
  IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 3, N'YFG', N'YFG.TableName', NULL, d.TableFa + N' (' + d.TableSchema + N'.' + d.TableName + N')'
    FROM deleted d;
END
GO

CREATE OR ALTER TRIGGER YFG.Tr_YFG_FieldName_Audit ON YFG.FieldName
AFTER INSERT, UPDATE, DELETE AS
BEGIN
  SET NOCOUNT ON;
  IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 1, N'YFG', N'YFG.FieldName', i.FieldId, i.TableSchema + N'.' + i.TableName + N'.' + i.FieldName + N' = ' + i.FieldFa
    FROM inserted i;
  IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'YFG', N'YFG.FieldName', i.FieldId, i.TableSchema + N'.' + i.TableName + N'.' + i.FieldName, N'FieldFa', d.FieldFa, i.FieldFa
    FROM inserted i JOIN deleted d ON d.FieldId = i.FieldId WHERE EXISTS (SELECT i.FieldFa EXCEPT SELECT d.FieldFa);
  IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 3, N'YFG', N'YFG.FieldName', NULL, d.TableSchema + N'.' + d.TableName + N'.' + d.FieldName + N' = ' + d.FieldFa
    FROM deleted d;
END
GO

CREATE OR ALTER TRIGGER YFG.Tr_YFG_LinkField_Audit ON YFG.LinkField
AFTER INSERT, UPDATE, DELETE AS
BEGIN
  SET NOCOUNT ON;
  IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 1, N'YFG', N'YFG.LinkField', i.LinkId,
           i.TableSchema + N'.' + i.TableName + N'.' + i.FieldName + N' → ' + i.LinkTableSchema + N'.' + i.LinkTableName + N'.' + i.LinkFieldName
    FROM inserted i;
  IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 3, N'YFG', N'YFG.LinkField', NULL,
           d.TableSchema + N'.' + d.TableName + N'.' + d.FieldName + N' → ' + d.LinkTableSchema + N'.' + d.LinkTableName + N'.' + d.LinkFieldName
    FROM deleted d;
END
GO

/* ---------- بخش ۱۰: راستی‌آزمایی ---------- */
PRINT '--- وضعیت واژه‌نامهٔ داده ---';
SELECT 'YFG.TableName' Tbl, COUNT(*) Cnt FROM YFG.TableName
UNION ALL SELECT 'YFG.FieldName', COUNT(*) FROM YFG.FieldName
UNION ALL SELECT 'YFG.LinkField', COUNT(*) FROM YFG.LinkField;
/* جدول‌های دیتابیس که هنوز در واژه‌نامه نیستند — باید صفر باشد */
SELECT COUNT(*) MissingTables FROM INFORMATION_SCHEMA.TABLES t
WHERE t.TABLE_SCHEMA IN ('ACC','pob','YFG') AND t.TABLE_TYPE='BASE TABLE'
  AND NOT EXISTS (SELECT 1 FROM YFG.TableName e WHERE e.TableSchema=t.TABLE_SCHEMA AND e.TableName=t.TABLE_NAME);
SELECT COUNT(*) MissingColumns FROM INFORMATION_SCHEMA.COLUMNS c
WHERE c.TABLE_SCHEMA IN ('ACC','pob','YFG')
  AND NOT EXISTS (SELECT 1 FROM YFG.FieldName e WHERE e.TableSchema=c.TABLE_SCHEMA AND e.TableName=c.TABLE_NAME AND e.FieldName=c.COLUMN_NAME);
PRINT '=== 06_meta_dictionary done ===';
GO
