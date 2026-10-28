/* ============================================================================
   YFG ACC-WEB SAMPLE — دیتابیس acc
   بازسازی وفادار ماژول حسابداری مطابق فایل‌های اصلی (acCDef.bpl / acVchDef /
   acGenVch / acGLVch / AcVwDef) — فیلدها از کپشن‌های واقعی فرم‌ها استخراج شده.
   اسکیما: Prm (پایه) / Acc (حساب‌ها) / Vch (اسناد)
   Idempotent — قابل اجرای مکرر.
   ============================================================================ */

/* ---------- اسکیماها ---------- */
IF SCHEMA_ID('Prm') IS NULL EXEC('CREATE SCHEMA Prm');
IF SCHEMA_ID('Acc') IS NULL EXEC('CREATE SCHEMA Acc');
IF SCHEMA_ID('Vch') IS NULL EXEC('CREATE SCHEMA Vch');
GO

/* ============================================================
   Prm — پایه: شرکت، کاربر، سال و دورهٔ مالی
   ============================================================ */
IF OBJECT_ID('Prm.Company') IS NULL
CREATE TABLE Prm.Company (
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

IF OBJECT_ID('Prm.AppUser') IS NULL
CREATE TABLE Prm.AppUser (
  UserId      smallint     IDENTITY(1,1) NOT NULL CONSTRAINT PK_AppUser PRIMARY KEY,
  Username    varchar(50)  NOT NULL CONSTRAINT UQ_AppUser_Username UNIQUE,
  DisplayName nvarchar(100) NOT NULL,
  RoleCode    varchar(20)  NOT NULL, /* admin | registrar(ثبت‌کننده) | checker(بررسی‌کننده/قطعی‌کننده) */
  PassHash    varchar(200) NOT NULL,
  IsActive    bit          NOT NULL CONSTRAINT DF_AppUser_Act DEFAULT(1),
  CreatedAt   datetime2(0) NOT NULL CONSTRAINT DF_AppUser_Cr DEFAULT(SYSUTCDATETIME())
);
GO

IF OBJECT_ID('Prm.FiscalYear') IS NULL
CREATE TABLE Prm.FiscalYear (
  YearId    smallint     IDENTITY(1,1) NOT NULL CONSTRAINT PK_FiscalYear PRIMARY KEY,
  CompanyId smallint     NOT NULL CONSTRAINT FK_Year_Company REFERENCES Prm.Company(CompanyId),
  JalaliYear smallint    NOT NULL,
  Title     nvarchar(50) NOT NULL,
  StartDate char(10)     NOT NULL, /* جلالی YYYY/MM/DD */
  EndDate   char(10)     NOT NULL,
  IsClosed  bit          NOT NULL CONSTRAINT DF_Year_Closed DEFAULT(0),
  CreatedAt datetime2(0) NOT NULL CONSTRAINT DF_Year_Cr DEFAULT(SYSUTCDATETIME()),
  CONSTRAINT UQ_Year UNIQUE(CompanyId, JalaliYear)
);
GO

IF OBJECT_ID('Prm.FiscalPeriod') IS NULL
CREATE TABLE Prm.FiscalPeriod (
  PeriodId smallint     IDENTITY(1,1) NOT NULL CONSTRAINT PK_FiscalPeriod PRIMARY KEY,
  YearId   smallint     NOT NULL CONSTRAINT FK_Period_Year REFERENCES Prm.FiscalYear(YearId),
  MonthNo  tinyint      NOT NULL,
  Title    nvarchar(20) NOT NULL,
  IsClosed bit          NOT NULL CONSTRAINT DF_Period_Closed DEFAULT(0),
  CONSTRAINT UQ_Period UNIQUE(YearId, MonthNo)
);
GO

/* ============================================================
   Acc — حساب‌ها (مطابق acCDef.bpl)
   ============================================================ */
/* انواع تفصیل [فرم: انواع تفصيل — نوع تفصيل، شرح لاتين] */
IF OBJECT_ID('Acc.DlType') IS NULL
CREATE TABLE Acc.DlType (
  DlTypeId   smallint      IDENTITY(1,1) NOT NULL CONSTRAINT PK_DlType PRIMARY KEY,
  CompanyId  smallint      NOT NULL CONSTRAINT FK_DlType_Company REFERENCES Prm.Company(CompanyId),
  Title      nvarchar(100) NOT NULL,
  LatinTitle varchar(100)  NULL,
  CreatedAt  datetime2(0)  NOT NULL CONSTRAINT DF_DlType_Cr DEFAULT(SYSUTCDATETIME()),
  CONSTRAINT UQ_DlType UNIQUE(CompanyId, Title)
);
GO

/* حساب‌های تفصیلی [فرم: معرفي حسابهاي تفصيل — كد، عنوان، نوع تفصيل، عنوان لاتين، وضعيت حساب فعال/غيرفعال]
   کد تفصیلی ۸ رقم؛ تفصیلی والد ندارد (اصل تأییدشده) */
IF OBJECT_ID('Acc.DL') IS NULL
CREATE TABLE Acc.DL (
  DlId       int           IDENTITY(1,1) NOT NULL CONSTRAINT PK_DL PRIMARY KEY,
  CompanyId  smallint      NOT NULL CONSTRAINT FK_DL_Company REFERENCES Prm.Company(CompanyId),
  DlTypeId   smallint      NOT NULL CONSTRAINT FK_DL_Type REFERENCES Acc.DlType(DlTypeId),
  Code       char(8)       NOT NULL,
  Title      nvarchar(200) NOT NULL,
  LatinTitle varchar(200)  NULL,
  IsActive   bit           NOT NULL CONSTRAINT DF_DL_Act DEFAULT(1),
  CreatedAt  datetime2(0)  NOT NULL CONSTRAINT DF_DL_Cr DEFAULT(SYSUTCDATETIME()),
  CONSTRAINT UQ_DL_Code UNIQUE(CompanyId, Code)
);
GO

/* طبقه‌بندی تفصیلی [فرم: طبقه بندي تفصيلي — طبقات + تفصيليهاي طبقهٔ انتخاب‌شده] */
IF OBJECT_ID('Acc.DlCtgry') IS NULL
CREATE TABLE Acc.DlCtgry (
  CtgryId   smallint      IDENTITY(1,1) NOT NULL CONSTRAINT PK_DlCtgry PRIMARY KEY,
  CompanyId smallint      NOT NULL CONSTRAINT FK_DlCtgry_Company REFERENCES Prm.Company(CompanyId),
  Title     nvarchar(100) NOT NULL,
  CONSTRAINT UQ_DlCtgry UNIQUE(CompanyId, Title)
);
GO
IF OBJECT_ID('Acc.DlCtgryLink') IS NULL
CREATE TABLE Acc.DlCtgryLink (
  CtgryId smallint NOT NULL CONSTRAINT FK_DlCL_Ctgry REFERENCES Acc.DlCtgry(CtgryId),
  DlId    int      NOT NULL CONSTRAINT FK_DlCL_DL REFERENCES Acc.DL(DlId),
  CONSTRAINT PK_DlCtgryLink PRIMARY KEY(CtgryId, DlId)
);
GO

/* گروه حساب [فرم: معرفي گروه حساب — كد(۲رقم)، عنوان، نوع حساب] */
IF OBJECT_ID('Acc.[Group]') IS NULL
CREATE TABLE Acc.[Group] (
  GroupId   smallint      IDENTITY(1,1) NOT NULL CONSTRAINT PK_Group PRIMARY KEY,
  CompanyId smallint      NOT NULL CONSTRAINT FK_Group_Company REFERENCES Prm.Company(CompanyId),
  Code      char(2)       NOT NULL,
  Title     nvarchar(200) NOT NULL,
  AccNature tinyint       NOT NULL CONSTRAINT DF_Group_Nat DEFAULT(3), /* 1=بدهکار 2=بستانکار 3=دوطرفه */
  CONSTRAINT UQ_Group_Code UNIQUE(CompanyId, Code)
);
GO

/* حساب‌های کل [فرم: معرفي حسابهاي كل — گروه حساب، كد(۴رقم)، عنوان، ماهيت حساب] */
IF OBJECT_ID('Acc.Kol') IS NULL
CREATE TABLE Acc.Kol (
  KolId     smallint      IDENTITY(1,1) NOT NULL CONSTRAINT PK_Kol PRIMARY KEY,
  CompanyId smallint      NOT NULL CONSTRAINT FK_Kol_Company REFERENCES Prm.Company(CompanyId),
  Code      char(4)       NOT NULL,
  GroupCode char(2)       NULL, /* حالت ۲: الزامی — دو رقم اول؛ حالت ۱: NULL */
  Title     nvarchar(200) NOT NULL,
  AccNature tinyint       NOT NULL CONSTRAINT DF_Kol_Nat DEFAULT(3),
  CONSTRAINT UQ_Kol_Code UNIQUE(CompanyId, Code),
  CONSTRAINT FK_Kol_Group FOREIGN KEY(CompanyId, GroupCode) REFERENCES Acc.[Group](CompanyId, Code)
);
GO

/* حساب‌های معین [فرم: معرفي حسابهاي معين — حساب كل، كد(۶رقم)، ارتباط معين با سطوح تفصيلي چهارم/پنجم/ششم،
   ماهيت حساب، ويژگيها (پيگيري/تعدادي/نوع ارز/ارزي/تسعيرپذير)، وضعيت حساب] */
IF OBJECT_ID('Acc.Moein') IS NULL
CREATE TABLE Acc.Moein (
  MoeinId       int           IDENTITY(1,1) NOT NULL CONSTRAINT PK_Moein PRIMARY KEY,
  CompanyId     smallint      NOT NULL CONSTRAINT FK_Moein_Company REFERENCES Prm.Company(CompanyId),
  Code          char(6)       NOT NULL,
  KolCode       char(4)       NOT NULL,
  Title         nvarchar(200) NOT NULL,
  AccNature     tinyint       NOT NULL CONSTRAINT DF_Moein_Nat DEFAULT(3),
  Dl1TypeId     smallint      NULL CONSTRAINT FK_Moein_Dl1 REFERENCES Acc.DlType(DlTypeId), /* سطح چهارم */
  Dl2TypeId     smallint      NULL CONSTRAINT FK_Moein_Dl2 REFERENCES Acc.DlType(DlTypeId), /* سطح پنجم */
  Dl3TypeId     smallint      NULL CONSTRAINT FK_Moein_Dl3 REFERENCES Acc.DlType(DlTypeId), /* سطح ششم */
  Trackable     bit           NOT NULL CONSTRAINT DF_Moein_Trk DEFAULT(0), /* پيگيري */
  Countable     bit           NOT NULL CONSTRAINT DF_Moein_Cnt DEFAULT(0), /* تعدادي */
  IsFx          bit           NOT NULL CONSTRAINT DF_Moein_Fx  DEFAULT(0), /* ارزي */
  FxConvertible bit           NOT NULL CONSTRAINT DF_Moein_FxC DEFAULT(0), /* تسعيرپذير */
  IsActive      bit           NOT NULL CONSTRAINT DF_Moein_Act DEFAULT(1),
  CONSTRAINT UQ_Moein_Code UNIQUE(CompanyId, Code),
  CONSTRAINT FK_Moein_Kol FOREIGN KEY(CompanyId, KolCode) REFERENCES Acc.Kol(CompanyId, Code)
);
GO

/* شرح‌های استاندارد [فرم: شرحهاي استاندارد] */
IF OBJECT_ID('Acc.StdDesc') IS NULL
CREATE TABLE Acc.StdDesc (
  StdDescId int           IDENTITY(1,1) NOT NULL CONSTRAINT PK_StdDesc PRIMARY KEY,
  CompanyId smallint      NOT NULL,
  MoeinCode char(6)       NOT NULL,
  Seq       smallint      NOT NULL,
  DescText  nvarchar(300) NOT NULL,
  CONSTRAINT FK_StdDesc_Moein FOREIGN KEY(CompanyId, MoeinCode) REFERENCES Acc.Moein(CompanyId, Code),
  CONSTRAINT UQ_StdDesc UNIQUE(CompanyId, MoeinCode, Seq)
);
GO

/* ماندهٔ ابتدای دوره (مبنای سند افتتاحیه AC0540 و دفاتر) */
IF OBJECT_ID('Acc.OpeningBalance') IS NULL
CREATE TABLE Acc.OpeningBalance (
  ObId      int           IDENTITY(1,1) NOT NULL CONSTRAINT PK_OB PRIMARY KEY,
  CompanyId smallint      NOT NULL,
  YearId    smallint      NOT NULL CONSTRAINT FK_OB_Year REFERENCES Prm.FiscalYear(YearId),
  KolCode   char(4)       NOT NULL,
  MoeinCode char(6)       NOT NULL,
  Dl1Id     int           NULL CONSTRAINT FK_OB_Dl1 REFERENCES Acc.DL(DlId),
  Dl2Id     int           NULL CONSTRAINT FK_OB_Dl2 REFERENCES Acc.DL(DlId),
  Dl3Id     int           NULL CONSTRAINT FK_OB_Dl3 REFERENCES Acc.DL(DlId),
  Dbt       decimal(18,0) NOT NULL CONSTRAINT DF_OB_Dbt DEFAULT(0),
  Crt       decimal(18,0) NOT NULL CONSTRAINT DF_OB_Crt DEFAULT(0),
  CONSTRAINT FK_OB_Moein FOREIGN KEY(CompanyId, MoeinCode) REFERENCES Acc.Moein(CompanyId, Code),
  CONSTRAINT CK_OB_Amount CHECK (Dbt >= 0 AND Crt >= 0 AND (Dbt = 0 OR Crt = 0))
);
GO

/* ============================================================
   Vch — اسناد (مطابق acVchDef/acGenVch/acGLVch)
   ============================================================ */
/* تعريف انواع سند [فرم: تعريف انواع سند — نوع سند، شرح لاتین] */
IF OBJECT_ID('Vch.[Type]') IS NULL
CREATE TABLE Vch.[Type] (
  TypeId     smallint      IDENTITY(1,1) NOT NULL CONSTRAINT PK_VchType PRIMARY KEY,
  CompanyId  smallint      NOT NULL CONSTRAINT FK_VchType_Company REFERENCES Prm.Company(CompanyId),
  Title      nvarchar(100) NOT NULL,
  LatinTitle varchar(100)  NULL,
  CONSTRAINT UQ_VchType UNIQUE(CompanyId, Title)
);
GO

/* سرسند [فرم: صدور سند حسابداري]
   State: 1=موقت (صدور) 2=بررسی‌شده 3=قطعی — فرایند: صدور→بررسی→قطعی */
IF OBJECT_ID('Vch.Hdr') IS NULL
CREATE TABLE Vch.Hdr (
  HdrId        int            IDENTITY(1,1) NOT NULL CONSTRAINT PK_VchHdr PRIMARY KEY,
  CompanyId    smallint       NOT NULL CONSTRAINT FK_Hdr_Company REFERENCES Prm.Company(CompanyId),
  YearId       smallint       NOT NULL CONSTRAINT FK_Hdr_Year REFERENCES Prm.FiscalYear(YearId),
  FolioNo      int            NOT NULL, /* شماره عطف */
  VchNo        int            NOT NULL, /* شماره سند */
  TypeId       smallint       NOT NULL CONSTRAINT FK_Hdr_Type REFERENCES Vch.[Type](TypeId),
  VchDate      char(10)       NOT NULL, /* جلالی */
  Descr        nvarchar(500)  NULL,
  State        tinyint        NOT NULL CONSTRAINT DF_Hdr_State DEFAULT(1),
  ReversalOf   int            NULL CONSTRAINT FK_Hdr_Rev REFERENCES Vch.Hdr(HdrId), /* سند برگشتی */
  SourceModule varchar(10)    NOT NULL CONSTRAINT DF_Hdr_Src DEFAULT('ACC'), /* مبدأ سند: حسابداری یا ماژول دیگر (اصل کارفرما) */
  CreatedBy    varchar(50)    NOT NULL,
  CreatedAt    datetime2(0)   NOT NULL CONSTRAINT DF_Hdr_Cr DEFAULT(SYSUTCDATETIME()),
  CheckedBy    varchar(50)    NULL,
  CheckedAt    datetime2(0)   NULL,
  FinalizedBy  varchar(50)    NULL,
  FinalizedAt  datetime2(0)   NULL,
  CONSTRAINT UQ_Hdr_Folio UNIQUE(CompanyId, YearId, FolioNo),
  CONSTRAINT UQ_Hdr_VchNo UNIQUE(CompanyId, YearId, VchNo)
);
GO

/* ردیف سند [ستون‌های فرم بررسي اسناد: حساب كل، حساب معين، تفصيلي، سطح پنجم، سطح ششم] */
IF OBJECT_ID('Vch.Itm') IS NULL
CREATE TABLE Vch.Itm (
  ItmId     int            IDENTITY(1,1) NOT NULL CONSTRAINT PK_VchItm PRIMARY KEY,
  HdrId     int            NOT NULL CONSTRAINT FK_Itm_Hdr REFERENCES Vch.Hdr(HdrId),
  RowNo     smallint       NOT NULL,
  KolCode   char(4)        NOT NULL,
  MoeinCode char(6)        NOT NULL,
  Dl1Id     int            NULL CONSTRAINT FK_Itm_Dl1 REFERENCES Acc.DL(DlId),
  Dl2Id     int            NULL CONSTRAINT FK_Itm_Dl2 REFERENCES Acc.DL(DlId),
  Dl3Id     int            NULL CONSTRAINT FK_Itm_Dl3 REFERENCES Acc.DL(DlId),
  Descr     nvarchar(500)  NULL,
  Dbt       decimal(18,0)  NOT NULL CONSTRAINT DF_Itm_Dbt DEFAULT(0),
  Crt       decimal(18,0)  NOT NULL CONSTRAINT DF_Itm_Crt DEFAULT(0),
  CONSTRAINT CK_Itm_Amount CHECK (Dbt >= 0 AND Crt >= 0 AND (Dbt = 0 OR Crt = 0))
);
GO

/* ردپای کامل عملیات سند */
IF OBJECT_ID('Vch.WfLog') IS NULL
CREATE TABLE Vch.WfLog (
  LogId   int           IDENTITY(1,1) NOT NULL CONSTRAINT PK_WfLog PRIMARY KEY,
  HdrId   int           NOT NULL CONSTRAINT FK_Log_Hdr REFERENCES Vch.Hdr(HdrId),
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
IF OBJECT_ID('Vch.TrAccWeb_Hdr_NoDeleteFinal') IS NULL
EXEC('CREATE TRIGGER Vch.TrAccWeb_Hdr_NoDeleteFinal ON Vch.Hdr INSTEAD OF DELETE AS
BEGIN
  SET NOCOUNT ON;
  IF EXISTS (SELECT 1 FROM deleted WHERE State = 3)
  BEGIN
    RAISERROR(N''سند قطعی‌شده حذف‌شدنی نیست — فقط با سند برگشتی'', 16, 1); ROLLBACK; RETURN;
  END
  DELETE h FROM Vch.Hdr h JOIN deleted d ON d.HdrId = h.HdrId;
END');
GO
/* ۲) سند قطعی ویرایش‌ناپذیر؛ گذار وضعیت فقط رو به جلو */
IF OBJECT_ID('Vch.TrAccWeb_Hdr_StateGuard') IS NULL
EXEC('CREATE TRIGGER Vch.TrAccWeb_Hdr_StateGuard ON Vch.Hdr FOR UPDATE AS
BEGIN
  SET NOCOUNT ON;
  IF EXISTS (SELECT 1 FROM deleted d JOIN inserted i ON i.HdrId = d.HdrId
             WHERE d.State = 3 AND (i.State <> 3 OR i.VchNo <> d.VchNo OR i.VchDate <> d.VchDate
                   OR ISNULL(i.ReversalOf,0) <> ISNULL(d.ReversalOf,0)))
  BEGIN
    RAISERROR(N''سند قطعی‌شده ویرایش‌ناپذیر است'', 16, 1); ROLLBACK; RETURN;
  END
  IF EXISTS (SELECT 1 FROM deleted d JOIN inserted i ON i.HdrId = d.HdrId
             WHERE i.State < d.State OR (d.State = 1 AND i.State = 3))
  BEGIN
    RAISERROR(N''گذار وضعیت نامعتبر: موقت←بررسی‌شده←قطعی'', 16, 1); ROLLBACK; RETURN;
  END
END');
GO
/* ۳) ردیف سند بررسی‌شده/قطعی ویرایش‌ناپذیر */
IF OBJECT_ID('Vch.TrAccWeb_Itm_EditGuard') IS NULL
EXEC('CREATE TRIGGER Vch.TrAccWeb_Itm_EditGuard ON Vch.Itm FOR UPDATE, DELETE AS
BEGIN
  SET NOCOUNT ON;
  IF EXISTS (SELECT 1 FROM deleted d JOIN Vch.Hdr h ON h.HdrId = d.HdrId WHERE h.State >= 2)
  BEGIN
    RAISERROR(N''ردیف سند بررسی‌شده/قطعی ویرایش‌ناپذیر است'', 16, 1); ROLLBACK; RETURN;
  END
END');
GO
/* ۴) اعتبار کدینگ مطابق accdef (حالت ۲): دو رقم اول کل=گروه؛ چهار رقم اول معین=کل */
IF OBJECT_ID('Acc.TrAccWeb_Kol_Prefix') IS NULL
EXEC('CREATE TRIGGER Acc.TrAccWeb_Kol_Prefix ON Acc.Kol FOR INSERT, UPDATE AS
BEGIN
  SET NOCOUNT ON;
  IF EXISTS (SELECT 1 FROM inserted i JOIN Prm.Company c ON c.CompanyId = i.CompanyId
             WHERE c.CodingMode = 2 AND (i.GroupCode IS NULL OR LEFT(i.Code,2) <> i.GroupCode))
  BEGIN
    RAISERROR(N''در کدینگ accdef، کل باید با کد گروه (۲ رقم) شروع شود'', 16, 1); ROLLBACK; RETURN;
  END
END');
GO
IF OBJECT_ID('Acc.TrAccWeb_Moein_Prefix') IS NULL
EXEC('CREATE TRIGGER Acc.TrAccWeb_Moein_Prefix ON Acc.Moein FOR INSERT, UPDATE AS
BEGIN
  SET NOCOUNT ON;
  IF EXISTS (SELECT 1 FROM inserted i JOIN Prm.Company c ON c.CompanyId = i.CompanyId
             WHERE c.CodingMode = 2 AND LEFT(i.Code,4) <> i.KolCode)
  BEGIN
    RAISERROR(N''در کدینگ accdef، معین باید با کد کل (۴ رقم) شروع شود'', 16, 1); ROLLBACK; RETURN;
  END
  IF EXISTS (SELECT 1 FROM inserted i JOIN Acc.Kol k ON k.CompanyId = i.CompanyId AND k.Code = i.KolCode
             JOIN Prm.Company c ON c.CompanyId = i.CompanyId
             WHERE c.CodingMode = 1 AND LEFT(i.Code,2) <> i.KolCode)
  BEGIN
    RAISERROR(N''در کدینگ پلکانی، معین باید با کد کل (۲ رقم) شروع شود'', 16, 1); ROLLBACK; RETURN;
  END
END');
GO

/* نمای شجرهٔ حساب‌ها [گزارش مجموعه حسابها — بر اساس ارتباط حسابها] */
IF OBJECT_ID('Acc.VwChart') IS NULL
EXEC('CREATE VIEW Acc.VwChart AS
SELECT g.CompanyId, g.Code AS GroupCode, g.Title AS GroupTitle, g.AccNature,
       k.Code AS KolCode, k.Title AS KolTitle,
       m.Code AS MoeinCode, m.Title AS MoeinTitle, m.IsActive AS MoeinActive,
       m.Dl1TypeId, m.Dl2TypeId, m.Dl3TypeId
FROM Acc.[Group] g
LEFT JOIN Acc.Kol k   ON k.CompanyId = g.CompanyId AND k.GroupCode = g.Code
LEFT JOIN Acc.Moein m ON m.CompanyId = k.CompanyId AND m.KolCode = k.Code');
GO
