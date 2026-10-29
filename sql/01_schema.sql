/* ============================================================================
   YFG ACC-WEB — دیتابیس acc — نسخهٔ ۱.۳.۰
   همتاسازی ماژول حسابداری فایل‌های اصلی (acCDef.bpl / acVchDef / acGenVch /
   acGLVch / AcVwDef) با نام‌گذاری استاندارد v1.3.0 (رعایت حق مؤلف —
   نام‌ها عیناً کپی نمی‌شود).
   شِما: ACC (حسابداری — جدول‌ها با پیشوند Acc) / pob (مشترک بین ماژول‌ها)
   Idempotent — قابل اجرای مکرر.
   ============================================================================ */

/* ---------- اسکیماها ---------- */
IF SCHEMA_ID('pob') IS NULL EXEC('CREATE SCHEMA pob');
IF SCHEMA_ID('ACC') IS NULL EXEC('CREATE SCHEMA ACC');
GO

/* ============================================================
   pob — مشترک: شرکت، کاربر، سال و دورهٔ مالی
   ============================================================ */
IF OBJECT_ID('pob.Companies') IS NULL
CREATE TABLE pob.Companies (
  CompanyId     smallint      IDENTITY(1,1) NOT NULL CONSTRAINT PK_Companies PRIMARY KEY,
  CompanyCode   varchar(10)   NOT NULL CONSTRAINT UQ_Companies_Code UNIQUE,
  TitleFa       nvarchar(200) NOT NULL,
  NationalId    varchar(15)   NULL,
  EconomicCode  varchar(15)   NULL,
  CodingMode    tinyint       NOT NULL CONSTRAINT DF_Companies_Mode DEFAULT(2), /* 1=پلکانی 2=کدینگ مطابق accdef */
  IsActive      bit           NOT NULL CONSTRAINT DF_Companies_Act DEFAULT(1),
  CreatedAt     datetime2(0)  NOT NULL CONSTRAINT DF_Companies_Cr DEFAULT(SYSUTCDATETIME())
);
GO

IF OBJECT_ID('pob.AppUser') IS NULL
CREATE TABLE pob.AppUser (
  UserId      smallint     IDENTITY(1,1) NOT NULL CONSTRAINT PK_AppUser PRIMARY KEY,
  Username    varchar(50)  NOT NULL CONSTRAINT UQ_AppUser_Username UNIQUE,
  DisplayName nvarchar(100) NOT NULL,
  RoleCode    varchar(20)  NOT NULL, /* admin | registrar(ثبت‌کننده) | checker(بررسی‌کننده/قطعی‌کننده) */
  PassHash    varchar(200) NOT NULL,
  IsActive    bit          NOT NULL CONSTRAINT DF_AppUser_Act DEFAULT(1),
  CreatedAt   datetime2(0) NOT NULL CONSTRAINT DF_AppUser_Cr DEFAULT(SYSUTCDATETIME())
);
GO

IF OBJECT_ID('pob.FiscalYear') IS NULL
CREATE TABLE pob.FiscalYear (
  YearId    smallint     IDENTITY(1,1) NOT NULL CONSTRAINT PK_FiscalYear PRIMARY KEY,
  CompanyId smallint     NOT NULL CONSTRAINT FK_Year_Company REFERENCES pob.Companies(CompanyId),
  JalaliYear smallint    NOT NULL,
  Title     nvarchar(50) NOT NULL,
  StartDate char(10)     NOT NULL, /* جلالی YYYY/MM/DD */
  EndDate   char(10)     NOT NULL,
  IsClosed  bit          NOT NULL CONSTRAINT DF_Year_Closed DEFAULT(0),
  CreatedAt datetime2(0) NOT NULL CONSTRAINT DF_Year_Cr DEFAULT(SYSUTCDATETIME()),
  CONSTRAINT UQ_FiscalYear UNIQUE(CompanyId, JalaliYear)
);
GO

IF OBJECT_ID('pob.FiscalPeriod') IS NULL
CREATE TABLE pob.FiscalPeriod (
  PeriodId smallint     IDENTITY(1,1) NOT NULL CONSTRAINT PK_FiscalPeriod PRIMARY KEY,
  YearId   smallint     NOT NULL CONSTRAINT FK_Period_Year REFERENCES pob.FiscalYear(YearId),
  MonthNo  tinyint      NOT NULL,
  Title    nvarchar(20) NOT NULL,
  IsClosed bit          NOT NULL CONSTRAINT DF_Period_Closed DEFAULT(0),
  CONSTRAINT UQ_FiscalPeriod UNIQUE(YearId, MonthNo)
);
GO

/* ============================================================
   ACC — حساب‌ها (مطابق acCDef.bpl)
   ============================================================ */
/* انواع تفصیل [فرم: انواع تفصيل — نوع تفصيل، شرح لاتين] */
IF OBJECT_ID('ACC.AccTafsiliType') IS NULL
CREATE TABLE ACC.AccTafsiliType (
  TafsiliTypeId   smallint      IDENTITY(1,1) NOT NULL CONSTRAINT PK_AccTafsiliType PRIMARY KEY,
  CompanyId  smallint      NOT NULL CONSTRAINT FK_TafsiliType_Company REFERENCES pob.Companies(CompanyId),
  Title      nvarchar(100) NOT NULL,
  LatinTitle varchar(100)  NULL,
  /* v2.4.3 — فهرست مبدأ نوع (PARTY/BANK/BRANCH/PROJECT/CASH/COSTCENTER/EMPLOYEE/GOODS/CHECK/LC یا خالی=آزاد) */
  CodeListType varchar(40) NULL,
  CreatedAt  datetime2(0)  NOT NULL CONSTRAINT DF_AccTafsiliType_Cr DEFAULT(SYSUTCDATETIME()),
  CONSTRAINT UQ_AccTafsiliType UNIQUE(CompanyId, Title)
);
GO

/* حساب‌های تفصیلی [فرم: معرفي حسابهاي تفصيل — كد، عنوان، نوع تفصيل، عنوان لاتين، وضعيت حساب فعال/غيرفعال]
   کد تفصیلی ۸ رقم؛ تفصیلی والد ندارد (اصل تأییدشده) */
IF OBJECT_ID('ACC.AccTafsili') IS NULL
CREATE TABLE ACC.AccTafsili (
  TafsiliId       int           IDENTITY(1,1) NOT NULL CONSTRAINT PK_AccTafsili PRIMARY KEY,
  CompanyId  smallint      NOT NULL CONSTRAINT FK_Tafsili_Company REFERENCES pob.Companies(CompanyId),
  TafsiliTypeId   smallint      NOT NULL CONSTRAINT FK_Tafsili_Type REFERENCES ACC.AccTafsiliType(TafsiliTypeId),
  Code       char(8)       NOT NULL,
  Title      nvarchar(200) NOT NULL,
  LatinTitle varchar(200)  NULL,
  IsActive   bit           NOT NULL CONSTRAINT DF_AccTafsili_Act DEFAULT(1),
  CreatedAt  datetime2(0)  NOT NULL CONSTRAINT DF_AccTafsili_Cr DEFAULT(SYSUTCDATETIME()),
  /* v2.4.3 — مرجع مبدأ: اشخاص → pob.Party / شعبه → ACC.AccBranch / سایر انواع → pob.CodeList */
  PartyRef   bigint        NULL,
  BranchRef  int           NULL,
  ListRef    bigint        NULL,
  CONSTRAINT UQ_AccTafsili_Code UNIQUE(CompanyId, Code)
);
GO

/* طبقه‌بندی تفصیلی [فرم: طبقه بندي تفصيلي — طبقات + تفصيليهاي طبقهٔ انتخاب‌شده] */
IF OBJECT_ID('ACC.AccTafsiliCategory') IS NULL
CREATE TABLE ACC.AccTafsiliCategory (
  CategoryId   smallint      IDENTITY(1,1) NOT NULL CONSTRAINT PK_AccTafsiliCategory PRIMARY KEY,
  CompanyId smallint      NOT NULL CONSTRAINT FK_TafsiliCategory_Company REFERENCES pob.Companies(CompanyId),
  Title     nvarchar(100) NOT NULL,
  CONSTRAINT UQ_AccTafsiliCategory UNIQUE(CompanyId, Title)
);
GO
IF OBJECT_ID('ACC.AccTafsiliCategoryLink') IS NULL
CREATE TABLE ACC.AccTafsiliCategoryLink (
  CategoryId smallint NOT NULL CONSTRAINT FK_DlCL_Ctgry REFERENCES ACC.AccTafsiliCategory(CategoryId),
  TafsiliId    int      NOT NULL CONSTRAINT FK_DlCL_Tafsili REFERENCES ACC.AccTafsili(TafsiliId),
  CONSTRAINT PK_AccTafsiliCategoryLink PRIMARY KEY(CategoryId, TafsiliId)
);
GO

/* گروه حساب [فرم: معرفي گروه حساب — كد(۲رقم)، عنوان، نوع حساب] */
IF OBJECT_ID('ACC.AccGroup') IS NULL
CREATE TABLE ACC.AccGroup (
  GroupId   smallint      IDENTITY(1,1) NOT NULL CONSTRAINT PK_AccGroup PRIMARY KEY,
  CompanyId smallint      NOT NULL CONSTRAINT FK_Group_Company REFERENCES pob.Companies(CompanyId),
  Code      char(2)       NOT NULL,
  Title     nvarchar(200) NOT NULL,
  AccNature tinyint       NOT NULL CONSTRAINT DF_Group_Nat DEFAULT(3), /* 1=بدهکار 2=بستانکار 3=دوطرفه */
  CONSTRAINT UQ_AccGroup_Code UNIQUE(CompanyId, Code)
);
GO

/* حساب‌های کل [فرم: معرفي حسابهاي كل — گروه حساب، كد(۴رقم)، عنوان، ماهيت حساب] */
IF OBJECT_ID('ACC.AccKol') IS NULL
CREATE TABLE ACC.AccKol (
  KolId     smallint      IDENTITY(1,1) NOT NULL CONSTRAINT PK_AccKol PRIMARY KEY,
  CompanyId smallint      NOT NULL CONSTRAINT FK_Kol_Company REFERENCES pob.Companies(CompanyId),
  Code      char(4)       NOT NULL,
  GroupCode char(2)       NULL, /* حالت ۲: الزامی — دو رقم اول؛ حالت ۱: NULL */
  Title     nvarchar(200) NOT NULL,
  AccNature tinyint       NOT NULL CONSTRAINT DF_AccKol_Nat DEFAULT(3),
  CONSTRAINT UQ_AccKol_Code UNIQUE(CompanyId, Code),
  CONSTRAINT FK_Kol_Group FOREIGN KEY(CompanyId, GroupCode) REFERENCES ACC.AccGroup(CompanyId, Code)
);
GO

/* حساب‌های معین [فرم: معرفي حسابهاي معين — حساب كل، كد(۶رقم)، ارتباط معين با سطوح تفصيلي چهارم/پنجم/ششم،
   ماهيت حساب، ويژگيها (پيگيري/تعدادي/نوع ارز/ارزي/تسعيرپذير)، وضعيت حساب] */
IF OBJECT_ID('ACC.AccMoein') IS NULL
CREATE TABLE ACC.AccMoein (
  MoeinId       int           IDENTITY(1,1) NOT NULL CONSTRAINT PK_AccMoein PRIMARY KEY,
  CompanyId     smallint      NOT NULL CONSTRAINT FK_Moein_Company REFERENCES pob.Companies(CompanyId),
  Code          char(6)       NOT NULL,
  KolCode       char(4)       NOT NULL,
  Title         nvarchar(200) NOT NULL,
  AccNature     tinyint       NOT NULL CONSTRAINT DF_AccMoein_Nat DEFAULT(3),
  Taf1TypeId     smallint      NULL CONSTRAINT FK_Moein_Dl1 REFERENCES ACC.AccTafsiliType(TafsiliTypeId), /* سطح چهارم */
  Taf2TypeId     smallint      NULL CONSTRAINT FK_Moein_Dl2 REFERENCES ACC.AccTafsiliType(TafsiliTypeId), /* سطح پنجم */
  Taf3TypeId     smallint      NULL CONSTRAINT FK_Moein_Dl3 REFERENCES ACC.AccTafsiliType(TafsiliTypeId), /* سطح ششم */
  Trackable     bit           NOT NULL CONSTRAINT DF_AccMoein_Trk DEFAULT(0), /* پيگيري */
  Countable     bit           NOT NULL CONSTRAINT DF_AccMoein_Cnt DEFAULT(0), /* تعدادي */
  IsFx          bit           NOT NULL CONSTRAINT DF_AccMoein_Fx  DEFAULT(0), /* ارزي */
  FxConvertible bit           NOT NULL CONSTRAINT DF_AccMoein_FxC DEFAULT(0), /* تسعيرپذير */
  IsActive      bit           NOT NULL CONSTRAINT DF_AccMoein_Act DEFAULT(1),
  CONSTRAINT UQ_AccMoein_Code UNIQUE(CompanyId, Code),
  CONSTRAINT FK_Moein_Kol FOREIGN KEY(CompanyId, KolCode) REFERENCES ACC.AccKol(CompanyId, Code)
);
GO

/* شرح‌های استاندارد [فرم: شرحهاي استاندارد] */
IF OBJECT_ID('ACC.AccStdNarration') IS NULL
CREATE TABLE ACC.AccStdNarration (
  NarrationId int           IDENTITY(1,1) NOT NULL CONSTRAINT PK_AccStdNarration PRIMARY KEY,
  CompanyId smallint      NOT NULL,
  MoeinCode char(6)       NOT NULL,
  Seq       smallint      NOT NULL,
  DescText  nvarchar(300) NOT NULL,
  CONSTRAINT FK_StdNarration_Moein FOREIGN KEY(CompanyId, MoeinCode) REFERENCES ACC.AccMoein(CompanyId, Code),
  CONSTRAINT UQ_AccStdNarration UNIQUE(CompanyId, MoeinCode, Seq)
);
GO

/* ماندهٔ ابتدای دوره (مبنای سند افتتاحیه AC0540 و دفاتر) */
IF OBJECT_ID('ACC.AccOpeningBalance') IS NULL
CREATE TABLE ACC.AccOpeningBalance (
  ObId      int           IDENTITY(1,1) NOT NULL CONSTRAINT PK_AccOpeningBalance PRIMARY KEY,
  CompanyId smallint      NOT NULL,
  YearId    smallint      NOT NULL CONSTRAINT FK_OB_Year REFERENCES pob.FiscalYear(YearId),
  KolCode   char(4)       NOT NULL,
  MoeinCode char(6)       NOT NULL,
  Taf1Id     int           NULL CONSTRAINT FK_OB_Dl1 REFERENCES ACC.AccTafsili(TafsiliId),
  Taf2Id     int           NULL CONSTRAINT FK_OB_Dl2 REFERENCES ACC.AccTafsili(TafsiliId),
  Taf3Id     int           NULL CONSTRAINT FK_OB_Dl3 REFERENCES ACC.AccTafsili(TafsiliId),
  Dbt       decimal(18,0) NOT NULL CONSTRAINT DF_OB_Dbt DEFAULT(0),
  Crt       decimal(18,0) NOT NULL CONSTRAINT DF_OB_Crt DEFAULT(0),
  CONSTRAINT FK_OB_Moein FOREIGN KEY(CompanyId, MoeinCode) REFERENCES ACC.AccMoein(CompanyId, Code),
  CONSTRAINT CK_OB_Amount CHECK (Dbt >= 0 AND Crt >= 0 AND (Dbt = 0 OR Crt = 0))
);
GO

/* ============================================================
   ACC — اسناد (مطابق acVchDef/acGenVch/acGLVch)
   ============================================================ */
/* تعريف انواع سند [فرم: تعريف انواع سند — نوع سند، شرح لاتین] */
IF OBJECT_ID('ACC.AccVoucherType') IS NULL
CREATE TABLE ACC.AccVoucherType (
  VoucherTypeId     smallint      IDENTITY(1,1) NOT NULL CONSTRAINT PK_AccVoucherType PRIMARY KEY,
  CompanyId  smallint      NOT NULL CONSTRAINT FK_VoucherType_Company REFERENCES pob.Companies(CompanyId),
  Title      nvarchar(100) NOT NULL,
  LatinTitle varchar(100)  NULL,
  CONSTRAINT UQ_AccVoucherType UNIQUE(CompanyId, Title)
);
GO

/* سرسند [فرم: صدور سند حسابداري]
   State: 1=موقت (صدور) 2=بررسی‌شده 3=قطعی — فرایند: صدور→بررسی→قطعی */
IF OBJECT_ID('ACC.AccVoucher') IS NULL
CREATE TABLE ACC.AccVoucher (
  VoucherId        int            IDENTITY(1,1) NOT NULL CONSTRAINT PK_AccVoucher PRIMARY KEY,
  CompanyId    smallint       NOT NULL CONSTRAINT FK_Voucher_Company REFERENCES pob.Companies(CompanyId),
  YearId       smallint       NOT NULL CONSTRAINT FK_Voucher_Year REFERENCES pob.FiscalYear(YearId),
  FolioNo      int            NOT NULL, /* شماره عطف */
  VchNo        int            NOT NULL, /* شماره سند */
  VoucherTypeId       smallint       NOT NULL CONSTRAINT FK_Voucher_Type REFERENCES ACC.AccVoucherType(VoucherTypeId),
  VchDate      char(10)       NOT NULL, /* جلالی */
  Descr        nvarchar(500)  NULL,
  State        tinyint        NOT NULL CONSTRAINT DF_AccVoucher_State DEFAULT(1),
  ReversalOf   int            NULL CONSTRAINT FK_Voucher_Rev REFERENCES ACC.AccVoucher(VoucherId), /* سند برگشتی */
  SourceModule varchar(10)    NOT NULL CONSTRAINT DF_AccVoucher_Src DEFAULT('ACC'), /* مبدأ سند: حسابداری یا ماژول دیگر (اصل کارفرما) */
  CreatedBy    varchar(50)    NOT NULL,
  CreatedAt    datetime2(0)   NOT NULL CONSTRAINT DF_AccVoucher_Cr DEFAULT(SYSUTCDATETIME()),
  CheckedBy    varchar(50)    NULL,
  CheckedAt    datetime2(0)   NULL,
  FinalizedBy  varchar(50)    NULL,
  FinalizedAt  datetime2(0)   NULL,
  CONSTRAINT UQ_AccVoucher_Folio UNIQUE(CompanyId, YearId, FolioNo),
  CONSTRAINT UQ_AccVoucher_VchNo UNIQUE(CompanyId, YearId, VchNo)
);
GO

/* ردیف سند [ستون‌های فرم بررسي اسناد: حساب كل، حساب معين، تفصيلي، سطح پنجم، سطح ششم] */
IF OBJECT_ID('ACC.AccVoucherItm') IS NULL
CREATE TABLE ACC.AccVoucherItm (
  LineId     int            IDENTITY(1,1) NOT NULL CONSTRAINT PK_AccVoucherItm PRIMARY KEY,
  VoucherId     int            NOT NULL CONSTRAINT FK_Line_Voucher REFERENCES ACC.AccVoucher(VoucherId),
  RowNo     smallint       NOT NULL,
  KolCode   char(4)        NOT NULL,
  MoeinCode char(6)        NOT NULL,
  Taf1Id     int            NULL CONSTRAINT FK_Line_Dl1 REFERENCES ACC.AccTafsili(TafsiliId),
  Taf2Id     int            NULL CONSTRAINT FK_Line_Dl2 REFERENCES ACC.AccTafsili(TafsiliId),
  Taf3Id     int            NULL CONSTRAINT FK_Line_Dl3 REFERENCES ACC.AccTafsili(TafsiliId),
  Descr     nvarchar(500)  NULL,
  Dbt       decimal(18,0)  NOT NULL CONSTRAINT DF_Line_Dbt DEFAULT(0),
  Crt       decimal(18,0)  NOT NULL CONSTRAINT DF_Line_Crt DEFAULT(0),
  CONSTRAINT CK_Line_Amount CHECK (Dbt >= 0 AND Crt >= 0 AND (Dbt = 0 OR Crt = 0))
);
GO

/* ردپای کامل عملیات سند */
IF OBJECT_ID('ACC.AccVoucherFlow') IS NULL
CREATE TABLE ACC.AccVoucherFlow (
  LogId   int           IDENTITY(1,1) NOT NULL CONSTRAINT PK_AccVoucherFlow PRIMARY KEY,
  VoucherId   int           NOT NULL CONSTRAINT FK_Log_Voucher REFERENCES ACC.AccVoucher(VoucherId),
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
IF OBJECT_ID('ACC.Tr_ACC_AccVoucher_NoDeleteFinal') IS NULL
EXEC('CREATE TRIGGER ACC.Tr_ACC_AccVoucher_NoDeleteFinal ON ACC.AccVoucher INSTEAD OF DELETE AS
BEGIN
  SET NOCOUNT ON;
  IF EXISTS (SELECT 1 FROM deleted WHERE State = 3)
  BEGIN
    RAISERROR(N''سند قطعی‌شده حذف‌شدنی نیست — فقط با سند برگشتی'', 16, 1); ROLLBACK; RETURN;
  END
  DELETE h FROM ACC.AccVoucher h JOIN deleted d ON d.VoucherId = h.VoucherId;
END');
GO
/* ۲) سند قطعی ویرایش‌ناپذیر؛ گذار وضعیت فقط رو به جلو */
IF OBJECT_ID('ACC.Tr_ACC_AccVoucher_StateGuard') IS NULL
EXEC('CREATE TRIGGER ACC.Tr_ACC_AccVoucher_StateGuard ON ACC.AccVoucher FOR UPDATE AS
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
IF OBJECT_ID('ACC.Tr_ACC_AccVoucherItm_EditGuard') IS NULL
EXEC('CREATE TRIGGER ACC.Tr_ACC_AccVoucherItm_EditGuard ON ACC.AccVoucherItm FOR UPDATE, DELETE AS
BEGIN
  SET NOCOUNT ON;
  IF EXISTS (SELECT 1 FROM deleted d JOIN ACC.AccVoucher h ON h.VoucherId = d.VoucherId WHERE h.State >= 2)
  BEGIN
    RAISERROR(N''ردیف سند بررسی‌شده/قطعی ویرایش‌ناپذیر است'', 16, 1); ROLLBACK; RETURN;
  END
END');
GO
/* ۴) اعتبار کدینگ مطابق accdef (حالت ۲): دو رقم اول کل=گروه؛ چهار رقم اول معین=کل */
IF OBJECT_ID('ACC.Tr_ACC_AccKol_Prefix') IS NULL
EXEC('CREATE TRIGGER ACC.Tr_ACC_AccKol_Prefix ON ACC.AccKol FOR INSERT, UPDATE AS
BEGIN
  SET NOCOUNT ON;
  IF EXISTS (SELECT 1 FROM inserted i JOIN pob.Companies c ON c.CompanyId = i.CompanyId
             WHERE c.CodingMode = 2 AND (i.GroupCode IS NULL OR LEFT(i.Code,2) <> i.GroupCode))
  BEGIN
    RAISERROR(N''در کدینگ accdef، کل باید با کد گروه (۲ رقم) شروع شود'', 16, 1); ROLLBACK; RETURN;
  END
END');
GO
IF OBJECT_ID('ACC.Tr_ACC_AccMoein_Prefix') IS NULL
EXEC('CREATE TRIGGER ACC.Tr_ACC_AccMoein_Prefix ON ACC.AccMoein FOR INSERT, UPDATE AS
BEGIN
  SET NOCOUNT ON;
  IF EXISTS (SELECT 1 FROM inserted i JOIN pob.Companies c ON c.CompanyId = i.CompanyId
             WHERE c.CodingMode = 2 AND LEFT(i.Code,4) <> i.KolCode)
  BEGIN
    RAISERROR(N''در کدینگ accdef، معین باید با کد کل (۴ رقم) شروع شود'', 16, 1); ROLLBACK; RETURN;
  END
  IF EXISTS (SELECT 1 FROM inserted i JOIN ACC.AccKol k ON k.CompanyId = i.CompanyId AND k.Code = i.KolCode
             JOIN pob.Companies c ON c.CompanyId = i.CompanyId
             WHERE c.CodingMode = 1 AND LEFT(i.Code,2) <> i.KolCode)
  BEGIN
    RAISERROR(N''در کدینگ پلکانی، معین باید با کد کل (۲ رقم) شروع شود'', 16, 1); ROLLBACK; RETURN;
  END
END');
GO

/* نمای شجرهٔ حساب‌ها [گزارش مجموعه حسابها — بر اساس ارتباط حسابها] */
IF OBJECT_ID('ACC.AccVwChart') IS NULL
EXEC('CREATE VIEW ACC.AccVwChart AS
SELECT g.CompanyId, g.Code AS GroupCode, g.Title AS GroupTitle, g.AccNature,
       k.Code AS KolCode, k.Title AS KolTitle,
       m.Code AS MoeinCode, m.Title AS MoeinTitle, m.IsActive AS MoeinActive,
       m.Taf1TypeId, m.Taf2TypeId, m.Taf3TypeId
FROM ACC.AccGroup g
LEFT JOIN ACC.AccKol k   ON k.CompanyId = g.CompanyId AND k.GroupCode = g.Code
LEFT JOIN ACC.AccMoein m ON m.CompanyId = k.CompanyId AND m.KolCode = k.Code');
GO
