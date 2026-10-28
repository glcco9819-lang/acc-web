/* ============================================================================
   YFG ACC-WEB — دیتابیس acc — نسخهٔ ۱.۲.۰
   همتاسازی ماژول حسابداری فایل‌های اصلی (acCDef.bpl / acVchDef / acGenVch /
   acGLVch / AcVwDef) با نام‌گذاری نقش‌محور و پیشوند YFG (رعایت حق مؤلف —
   نام‌ها عیناً کپی نمی‌شود؛ معادل‌ها در sql/10_migration_v1.2.0_yfg_rename.sql).
   شِما: YfgPrm (پایه) / YfgAcc (حساب‌ها) / YfgVch (اسناد)
   Idempotent — قابل اجرای مکرر.
   ============================================================================ */

/* ---------- اسکیماها ---------- */
IF SCHEMA_ID('YfgPrm') IS NULL EXEC('CREATE SCHEMA YfgPrm');
IF SCHEMA_ID('YfgAcc') IS NULL EXEC('CREATE SCHEMA YfgAcc');
IF SCHEMA_ID('YfgVch') IS NULL EXEC('CREATE SCHEMA YfgVch');
GO

/* ============================================================
   YfgPrm — پایه: شرکت، کاربر، سال و دورهٔ مالی
   ============================================================ */
IF OBJECT_ID('YfgPrm.Company') IS NULL
CREATE TABLE YfgPrm.Company (
  CompanyId     smallint      IDENTITY(1,1) NOT NULL CONSTRAINT PK_Company PRIMARY KEY,
  CompanyCode   varchar(10)   NOT NULL CONSTRAINT UQ_Company_Code UNIQUE,
  TitleFa       nvarchar(200) NOT NULL,
  NationalId    varchar(15)   NULL,
  EconomicCode  varchar(15)   NULL,
  CodingMode    tinyint       NOT NULL CONSTRAINT DF_Company_Mode DEFAULT(2), /* 1=پلکانی 2=کدینگ مطابق accdef */
  IsActive      bit           NOT NULL CONSTRAINT DF_Company_Act DEFAULT(1),
  CreatedAt     datetime2(0)  NOT NULL CONSTRAINT DF_Company_Cr DEFAULT(SYSUTCDATETIME())
);
GO

IF OBJECT_ID('YfgPrm.AppUser') IS NULL
CREATE TABLE YfgPrm.AppUser (
  UserId      smallint     IDENTITY(1,1) NOT NULL CONSTRAINT PK_AppUser PRIMARY KEY,
  Username    varchar(50)  NOT NULL CONSTRAINT UQ_AppUser_Username UNIQUE,
  DisplayName nvarchar(100) NOT NULL,
  RoleCode    varchar(20)  NOT NULL, /* admin | registrar(ثبت‌کننده) | checker(بررسی‌کننده/قطعی‌کننده) */
  PassHash    varchar(200) NOT NULL,
  IsActive    bit          NOT NULL CONSTRAINT DF_AppUser_Act DEFAULT(1),
  CreatedAt   datetime2(0) NOT NULL CONSTRAINT DF_AppUser_Cr DEFAULT(SYSUTCDATETIME())
);
GO

IF OBJECT_ID('YfgPrm.FiscalYear') IS NULL
CREATE TABLE YfgPrm.FiscalYear (
  YearId    smallint     IDENTITY(1,1) NOT NULL CONSTRAINT PK_FiscalYear PRIMARY KEY,
  CompanyId smallint     NOT NULL CONSTRAINT FK_Year_Company REFERENCES YfgPrm.Company(CompanyId),
  JalaliYear smallint    NOT NULL,
  Title     nvarchar(50) NOT NULL,
  StartDate char(10)     NOT NULL, /* جلالی YYYY/MM/DD */
  EndDate   char(10)     NOT NULL,
  IsClosed  bit          NOT NULL CONSTRAINT DF_Year_Closed DEFAULT(0),
  CreatedAt datetime2(0) NOT NULL CONSTRAINT DF_Year_Cr DEFAULT(SYSUTCDATETIME()),
  CONSTRAINT UQ_Year UNIQUE(CompanyId, JalaliYear)
);
GO

IF OBJECT_ID('YfgPrm.FiscalPeriod') IS NULL
CREATE TABLE YfgPrm.FiscalPeriod (
  PeriodId smallint     IDENTITY(1,1) NOT NULL CONSTRAINT PK_FiscalPeriod PRIMARY KEY,
  YearId   smallint     NOT NULL CONSTRAINT FK_Period_Year REFERENCES YfgPrm.FiscalYear(YearId),
  MonthNo  tinyint      NOT NULL,
  Title    nvarchar(20) NOT NULL,
  IsClosed bit          NOT NULL CONSTRAINT DF_Period_Closed DEFAULT(0),
  CONSTRAINT UQ_Period UNIQUE(YearId, MonthNo)
);
GO

/* ============================================================
   YfgAcc — حساب‌ها (مطابق acCDef.bpl)
   ============================================================ */
/* انواع تفصیل [فرم: انواع تفصيل — نوع تفصيل، شرح لاتين] */
IF OBJECT_ID('YfgAcc.TafsiliType') IS NULL
CREATE TABLE YfgAcc.TafsiliType (
  TafsiliTypeId   smallint      IDENTITY(1,1) NOT NULL CONSTRAINT PK_TafsiliType PRIMARY KEY,
  CompanyId  smallint      NOT NULL CONSTRAINT FK_TafsiliType_Company REFERENCES YfgPrm.Company(CompanyId),
  Title      nvarchar(100) NOT NULL,
  LatinTitle varchar(100)  NULL,
  CreatedAt  datetime2(0)  NOT NULL CONSTRAINT DF_TafsiliType_Cr DEFAULT(SYSUTCDATETIME()),
  CONSTRAINT UQ_TafsiliType UNIQUE(CompanyId, Title)
);
GO

/* حساب‌های تفصیلی [فرم: معرفي حسابهاي تفصيل — كد، عنوان، نوع تفصيل، عنوان لاتين، وضعيت حساب فعال/غيرفعال]
   کد تفصیلی ۸ رقم؛ تفصیلی والد ندارد (اصل تأییدشده) */
IF OBJECT_ID('YfgAcc.Tafsili') IS NULL
CREATE TABLE YfgAcc.Tafsili (
  TafsiliId       int           IDENTITY(1,1) NOT NULL CONSTRAINT PK_Tafsili PRIMARY KEY,
  CompanyId  smallint      NOT NULL CONSTRAINT FK_Tafsili_Company REFERENCES YfgPrm.Company(CompanyId),
  TafsiliTypeId   smallint      NOT NULL CONSTRAINT FK_Tafsili_Type REFERENCES YfgAcc.TafsiliType(TafsiliTypeId),
  Code       char(8)       NOT NULL,
  Title      nvarchar(200) NOT NULL,
  LatinTitle varchar(200)  NULL,
  IsActive   bit           NOT NULL CONSTRAINT DF_Tafsili_Act DEFAULT(1),
  CreatedAt  datetime2(0)  NOT NULL CONSTRAINT DF_Tafsili_Cr DEFAULT(SYSUTCDATETIME()),
  CONSTRAINT UQ_Tafsili_Code UNIQUE(CompanyId, Code)
);
GO

/* طبقه‌بندی تفصیلی [فرم: طبقه بندي تفصيلي — طبقات + تفصيليهاي طبقهٔ انتخاب‌شده] */
IF OBJECT_ID('YfgAcc.TafsiliCategory') IS NULL
CREATE TABLE YfgAcc.TafsiliCategory (
  CategoryId   smallint      IDENTITY(1,1) NOT NULL CONSTRAINT PK_TafsiliCategory PRIMARY KEY,
  CompanyId smallint      NOT NULL CONSTRAINT FK_TafsiliCategory_Company REFERENCES YfgPrm.Company(CompanyId),
  Title     nvarchar(100) NOT NULL,
  CONSTRAINT UQ_TafsiliCategory UNIQUE(CompanyId, Title)
);
GO
IF OBJECT_ID('YfgAcc.TafsiliCategoryLink') IS NULL
CREATE TABLE YfgAcc.TafsiliCategoryLink (
  CategoryId smallint NOT NULL CONSTRAINT FK_DlCL_Ctgry REFERENCES YfgAcc.TafsiliCategory(CategoryId),
  TafsiliId    int      NOT NULL CONSTRAINT FK_DlCL_Tafsili REFERENCES YfgAcc.Tafsili(TafsiliId),
  CONSTRAINT PK_TafsiliCategoryLink PRIMARY KEY(CategoryId, TafsiliId)
);
GO

/* گروه حساب [فرم: معرفي گروه حساب — كد(۲رقم)، عنوان، نوع حساب] */
IF OBJECT_ID('YfgAcc.AccGroup') IS NULL
CREATE TABLE YfgAcc.AccGroup (
  GroupId   smallint      IDENTITY(1,1) NOT NULL CONSTRAINT PK_Group PRIMARY KEY,
  CompanyId smallint      NOT NULL CONSTRAINT FK_Group_Company REFERENCES YfgPrm.Company(CompanyId),
  Code      char(2)       NOT NULL,
  Title     nvarchar(200) NOT NULL,
  AccNature tinyint       NOT NULL CONSTRAINT DF_Group_Nat DEFAULT(3), /* 1=بدهکار 2=بستانکار 3=دوطرفه */
  CONSTRAINT UQ_Group_Code UNIQUE(CompanyId, Code)
);
GO

/* حساب‌های کل [فرم: معرفي حسابهاي كل — گروه حساب، كد(۴رقم)، عنوان، ماهيت حساب] */
IF OBJECT_ID('YfgAcc.Kol') IS NULL
CREATE TABLE YfgAcc.Kol (
  KolId     smallint      IDENTITY(1,1) NOT NULL CONSTRAINT PK_Kol PRIMARY KEY,
  CompanyId smallint      NOT NULL CONSTRAINT FK_Kol_Company REFERENCES YfgPrm.Company(CompanyId),
  Code      char(4)       NOT NULL,
  GroupCode char(2)       NULL, /* حالت ۲: الزامی — دو رقم اول؛ حالت ۱: NULL */
  Title     nvarchar(200) NOT NULL,
  AccNature tinyint       NOT NULL CONSTRAINT DF_Kol_Nat DEFAULT(3),
  CONSTRAINT UQ_Kol_Code UNIQUE(CompanyId, Code),
  CONSTRAINT FK_Kol_Group FOREIGN KEY(CompanyId, GroupCode) REFERENCES YfgAcc.AccGroup(CompanyId, Code)
);
GO

/* حساب‌های معین [فرم: معرفي حسابهاي معين — حساب كل، كد(۶رقم)، ارتباط معين با سطوح تفصيلي چهارم/پنجم/ششم،
   ماهيت حساب، ويژگيها (پيگيري/تعدادي/نوع ارز/ارزي/تسعيرپذير)، وضعيت حساب] */
IF OBJECT_ID('YfgAcc.Moein') IS NULL
CREATE TABLE YfgAcc.Moein (
  MoeinId       int           IDENTITY(1,1) NOT NULL CONSTRAINT PK_Moein PRIMARY KEY,
  CompanyId     smallint      NOT NULL CONSTRAINT FK_Moein_Company REFERENCES YfgPrm.Company(CompanyId),
  Code          char(6)       NOT NULL,
  KolCode       char(4)       NOT NULL,
  Title         nvarchar(200) NOT NULL,
  AccNature     tinyint       NOT NULL CONSTRAINT DF_Moein_Nat DEFAULT(3),
  Taf1TypeId     smallint      NULL CONSTRAINT FK_Moein_Dl1 REFERENCES YfgAcc.TafsiliType(TafsiliTypeId), /* سطح چهارم */
  Taf2TypeId     smallint      NULL CONSTRAINT FK_Moein_Dl2 REFERENCES YfgAcc.TafsiliType(TafsiliTypeId), /* سطح پنجم */
  Taf3TypeId     smallint      NULL CONSTRAINT FK_Moein_Dl3 REFERENCES YfgAcc.TafsiliType(TafsiliTypeId), /* سطح ششم */
  Trackable     bit           NOT NULL CONSTRAINT DF_Moein_Trk DEFAULT(0), /* پيگيري */
  Countable     bit           NOT NULL CONSTRAINT DF_Moein_Cnt DEFAULT(0), /* تعدادي */
  IsFx          bit           NOT NULL CONSTRAINT DF_Moein_Fx  DEFAULT(0), /* ارزي */
  FxConvertible bit           NOT NULL CONSTRAINT DF_Moein_FxC DEFAULT(0), /* تسعيرپذير */
  IsActive      bit           NOT NULL CONSTRAINT DF_Moein_Act DEFAULT(1),
  CONSTRAINT UQ_Moein_Code UNIQUE(CompanyId, Code),
  CONSTRAINT FK_Moein_Kol FOREIGN KEY(CompanyId, KolCode) REFERENCES YfgAcc.Kol(CompanyId, Code)
);
GO

/* شرح‌های استاندارد [فرم: شرحهاي استاندارد] */
IF OBJECT_ID('YfgAcc.StdNarration') IS NULL
CREATE TABLE YfgAcc.StdNarration (
  NarrationId int           IDENTITY(1,1) NOT NULL CONSTRAINT PK_StdNarration PRIMARY KEY,
  CompanyId smallint      NOT NULL,
  MoeinCode char(6)       NOT NULL,
  Seq       smallint      NOT NULL,
  DescText  nvarchar(300) NOT NULL,
  CONSTRAINT FK_StdNarration_Moein FOREIGN KEY(CompanyId, MoeinCode) REFERENCES YfgAcc.Moein(CompanyId, Code),
  CONSTRAINT UQ_StdNarration UNIQUE(CompanyId, MoeinCode, Seq)
);
GO

/* ماندهٔ ابتدای دوره (مبنای سند افتتاحیه AC0540 و دفاتر) */
IF OBJECT_ID('YfgAcc.OpeningBalance') IS NULL
CREATE TABLE YfgAcc.OpeningBalance (
  ObId      int           IDENTITY(1,1) NOT NULL CONSTRAINT PK_OB PRIMARY KEY,
  CompanyId smallint      NOT NULL,
  YearId    smallint      NOT NULL CONSTRAINT FK_OB_Year REFERENCES YfgPrm.FiscalYear(YearId),
  KolCode   char(4)       NOT NULL,
  MoeinCode char(6)       NOT NULL,
  Taf1Id     int           NULL CONSTRAINT FK_OB_Dl1 REFERENCES YfgAcc.Tafsili(TafsiliId),
  Taf2Id     int           NULL CONSTRAINT FK_OB_Dl2 REFERENCES YfgAcc.Tafsili(TafsiliId),
  Taf3Id     int           NULL CONSTRAINT FK_OB_Dl3 REFERENCES YfgAcc.Tafsili(TafsiliId),
  Dbt       decimal(18,0) NOT NULL CONSTRAINT DF_OB_Dbt DEFAULT(0),
  Crt       decimal(18,0) NOT NULL CONSTRAINT DF_OB_Crt DEFAULT(0),
  CONSTRAINT FK_OB_Moein FOREIGN KEY(CompanyId, MoeinCode) REFERENCES YfgAcc.Moein(CompanyId, Code),
  CONSTRAINT CK_OB_Amount CHECK (Dbt >= 0 AND Crt >= 0 AND (Dbt = 0 OR Crt = 0))
);
GO

/* ============================================================
   YfgVch — اسناد (مطابق acVchDef/acGenVch/acGLVch)
   ============================================================ */
/* تعريف انواع سند [فرم: تعريف انواع سند — نوع سند، شرح لاتین] */
IF OBJECT_ID('YfgVch.VoucherType') IS NULL
CREATE TABLE YfgVch.VoucherType (
  VoucherTypeId     smallint      IDENTITY(1,1) NOT NULL CONSTRAINT PK_VoucherType PRIMARY KEY,
  CompanyId  smallint      NOT NULL CONSTRAINT FK_VoucherType_Company REFERENCES YfgPrm.Company(CompanyId),
  Title      nvarchar(100) NOT NULL,
  LatinTitle varchar(100)  NULL,
  CONSTRAINT UQ_VoucherType UNIQUE(CompanyId, Title)
);
GO

/* سرسند [فرم: صدور سند حسابداري]
   State: 1=موقت (صدور) 2=بررسی‌شده 3=قطعی — فرایند: صدور→بررسی→قطعی */
IF OBJECT_ID('YfgVch.Voucher') IS NULL
CREATE TABLE YfgVch.Voucher (
  VoucherId        int            IDENTITY(1,1) NOT NULL CONSTRAINT PK_VchHdr PRIMARY KEY,
  CompanyId    smallint       NOT NULL CONSTRAINT FK_Voucher_Company REFERENCES YfgPrm.Company(CompanyId),
  YearId       smallint       NOT NULL CONSTRAINT FK_Voucher_Year REFERENCES YfgPrm.FiscalYear(YearId),
  FolioNo      int            NOT NULL, /* شماره عطف */
  VchNo        int            NOT NULL, /* شماره سند */
  VoucherTypeId       smallint       NOT NULL CONSTRAINT FK_Voucher_Type REFERENCES YfgVch.VoucherType(VoucherTypeId),
  VchDate      char(10)       NOT NULL, /* جلالی */
  Descr        nvarchar(500)  NULL,
  State        tinyint        NOT NULL CONSTRAINT DF_Voucher_State DEFAULT(1),
  ReversalOf   int            NULL CONSTRAINT FK_Voucher_Rev REFERENCES YfgVch.Voucher(VoucherId), /* سند برگشتی */
  SourceModule varchar(10)    NOT NULL CONSTRAINT DF_Voucher_Src DEFAULT('ACC'), /* مبدأ سند: حسابداری یا ماژول دیگر (اصل کارفرما) */
  CreatedBy    varchar(50)    NOT NULL,
  CreatedAt    datetime2(0)   NOT NULL CONSTRAINT DF_Voucher_Cr DEFAULT(SYSUTCDATETIME()),
  CheckedBy    varchar(50)    NULL,
  CheckedAt    datetime2(0)   NULL,
  FinalizedBy  varchar(50)    NULL,
  FinalizedAt  datetime2(0)   NULL,
  CONSTRAINT UQ_Voucher_Folio UNIQUE(CompanyId, YearId, FolioNo),
  CONSTRAINT UQ_Voucher_VchNo UNIQUE(CompanyId, YearId, VchNo)
);
GO

/* ردیف سند [ستون‌های فرم بررسي اسناد: حساب كل، حساب معين، تفصيلي، سطح پنجم، سطح ششم] */
IF OBJECT_ID('YfgVch.VoucherLine') IS NULL
CREATE TABLE YfgVch.VoucherLine (
  LineId     int            IDENTITY(1,1) NOT NULL CONSTRAINT PK_VchItm PRIMARY KEY,
  VoucherId     int            NOT NULL CONSTRAINT FK_Line_Voucher REFERENCES YfgVch.Voucher(VoucherId),
  RowNo     smallint       NOT NULL,
  KolCode   char(4)        NOT NULL,
  MoeinCode char(6)        NOT NULL,
  Taf1Id     int            NULL CONSTRAINT FK_Line_Dl1 REFERENCES YfgAcc.Tafsili(TafsiliId),
  Taf2Id     int            NULL CONSTRAINT FK_Line_Dl2 REFERENCES YfgAcc.Tafsili(TafsiliId),
  Taf3Id     int            NULL CONSTRAINT FK_Line_Dl3 REFERENCES YfgAcc.Tafsili(TafsiliId),
  Descr     nvarchar(500)  NULL,
  Dbt       decimal(18,0)  NOT NULL CONSTRAINT DF_Line_Dbt DEFAULT(0),
  Crt       decimal(18,0)  NOT NULL CONSTRAINT DF_Line_Crt DEFAULT(0),
  CONSTRAINT CK_Line_Amount CHECK (Dbt >= 0 AND Crt >= 0 AND (Dbt = 0 OR Crt = 0))
);
GO

/* ردپای کامل عملیات سند */
IF OBJECT_ID('YfgVch.VoucherFlow') IS NULL
CREATE TABLE YfgVch.VoucherFlow (
  LogId   int           IDENTITY(1,1) NOT NULL CONSTRAINT PK_VoucherFlow PRIMARY KEY,
  VoucherId   int           NOT NULL CONSTRAINT FK_Log_Voucher REFERENCES YfgVch.Voucher(VoucherId),
  Action  tinyint       NOT NULL, /* 1=صدور 2=بررسی 3=لغو بررسی 4=قطعی 5=لغو قطعی 6=برگشت */
  ByUser  varchar(50)   NOT NULL,
  At      datetime2(0)  NOT NULL CONSTRAINT DF_Log_At DEFAULT(SYSUTCDATETIME()),
  Note    nvarchar(300) NULL
);
GO

/* ============================================================
   گاردهای دیتابیسی — قوانین کدینگ و فرایند سند
   ============================================================ */
/* ۱) سند قطعی حذف‌ناپذیر */
IF OBJECT_ID('YfgVch.Tr_YfgVch_Voucher_NoDeleteFinal') IS NULL
EXEC('CREATE TRIGGER YfgVch.Tr_YfgVch_Voucher_NoDeleteFinal ON YfgVch.Voucher INSTEAD OF DELETE AS
BEGIN
  SET NOCOUNT ON;
  IF EXISTS (SELECT 1 FROM deleted WHERE State = 3)
  BEGIN
    RAISERROR(N''سند قطعی‌شده حذف‌شدنی نیست — فقط با سند برگشتی'', 16, 1); ROLLBACK; RETURN;
  END
  DELETE h FROM YfgVch.Voucher h JOIN deleted d ON d.VoucherId = h.VoucherId;
END');
GO
/* ۲) سند قطعی ویرایش‌ناپذیر؛ گذار وضعیت فقط رو به جلو */
IF OBJECT_ID('YfgVch.Tr_YfgVch_Voucher_StateGuard') IS NULL
EXEC('CREATE TRIGGER YfgVch.Tr_YfgVch_Voucher_StateGuard ON YfgVch.Voucher FOR UPDATE AS
BEGIN
  SET NOCOUNT ON;
  IF EXISTS (SELECT 1 FROM deleted d JOIN inserted i ON i.VoucherId = d.VoucherId
             WHERE d.State = 3 AND (i.State <> 3 OR i.VchNo <> d.VchNo OR i.VchDate <> d.VchDate
                   OR ISNULL(i.ReversalOf,0) <> ISNULL(d.ReversalOf,0)))
  BEGIN
    RAISERROR(N''سند قطعی‌شده ویرایش‌ناپذیر است'', 16, 1); ROLLBACK; RETURN;
  END
  IF EXISTS (SELECT 1 FROM deleted d JOIN inserted i ON i.VoucherId = d.VoucherId
             WHERE i.State < d.State OR (d.State = 1 AND i.State = 3))
  BEGIN
    RAISERROR(N''گذار وضعیت نامعتبر: موقت←بررسی‌شده←قطعی'', 16, 1); ROLLBACK; RETURN;
  END
END');
GO
/* ۳) ردیف سند بررسی‌شده/قطعی ویرایش‌ناپذیر */
IF OBJECT_ID('YfgVch.Tr_YfgVch_VoucherLine_EditGuard') IS NULL
EXEC('CREATE TRIGGER YfgVch.Tr_YfgVch_VoucherLine_EditGuard ON YfgVch.VoucherLine FOR UPDATE, DELETE AS
BEGIN
  SET NOCOUNT ON;
  IF EXISTS (SELECT 1 FROM deleted d JOIN YfgVch.Voucher h ON h.VoucherId = d.VoucherId WHERE h.State >= 2)
  BEGIN
    RAISERROR(N''ردیف سند بررسی‌شده/قطعی ویرایش‌ناپذیر است'', 16, 1); ROLLBACK; RETURN;
  END
END');
GO
/* ۴) اعتبار کدینگ مطابق accdef (حالت ۲): دو رقم اول کل=گروه؛ چهار رقم اول معین=کل */
IF OBJECT_ID('YfgAcc.Tr_YfgAcc_Kol_Prefix') IS NULL
EXEC('CREATE TRIGGER YfgAcc.Tr_YfgAcc_Kol_Prefix ON YfgAcc.Kol FOR INSERT, UPDATE AS
BEGIN
  SET NOCOUNT ON;
  IF EXISTS (SELECT 1 FROM inserted i JOIN YfgPrm.Company c ON c.CompanyId = i.CompanyId
             WHERE c.CodingMode = 2 AND (i.GroupCode IS NULL OR LEFT(i.Code,2) <> i.GroupCode))
  BEGIN
    RAISERROR(N''در کدینگ accdef، کل باید با کد گروه (۲ رقم) شروع شود'', 16, 1); ROLLBACK; RETURN;
  END
END');
GO
IF OBJECT_ID('YfgAcc.Tr_YfgAcc_Moein_Prefix') IS NULL
EXEC('CREATE TRIGGER YfgAcc.Tr_YfgAcc_Moein_Prefix ON YfgAcc.Moein FOR INSERT, UPDATE AS
BEGIN
  SET NOCOUNT ON;
  IF EXISTS (SELECT 1 FROM inserted i JOIN YfgPrm.Company c ON c.CompanyId = i.CompanyId
             WHERE c.CodingMode = 2 AND LEFT(i.Code,4) <> i.KolCode)
  BEGIN
    RAISERROR(N''در کدینگ accdef، معین باید با کد کل (۴ رقم) شروع شود'', 16, 1); ROLLBACK; RETURN;
  END
  IF EXISTS (SELECT 1 FROM inserted i JOIN YfgAcc.Kol k ON k.CompanyId = i.CompanyId AND k.Code = i.KolCode
             JOIN YfgPrm.Company c ON c.CompanyId = i.CompanyId
             WHERE c.CodingMode = 1 AND LEFT(i.Code,2) <> i.KolCode)
  BEGIN
    RAISERROR(N''در کدینگ پلکانی، معین باید با کد کل (۲ رقم) شروع شود'', 16, 1); ROLLBACK; RETURN;
  END
END');
GO

/* نمای شجرهٔ حساب‌ها [گزارش مجموعه حسابها — بر اساس ارتباط حسابها] */
IF OBJECT_ID('YfgAcc.VwChart') IS NULL
EXEC('CREATE VIEW YfgAcc.VwChart AS
SELECT g.CompanyId, g.Code AS GroupCode, g.Title AS GroupTitle, g.AccNature,
       k.Code AS KolCode, k.Title AS KolTitle,
       m.Code AS MoeinCode, m.Title AS MoeinTitle, m.IsActive AS MoeinActive,
       m.Taf1TypeId, m.Taf2TypeId, m.Taf3TypeId
FROM YfgAcc.AccGroup g
LEFT JOIN YfgAcc.Kol k   ON k.CompanyId = g.CompanyId AND k.GroupCode = g.Code
LEFT JOIN YfgAcc.Moein m ON m.CompanyId = k.CompanyId AND m.KolCode = k.Code');
GO
