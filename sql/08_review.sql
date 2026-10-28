/* ============================================================
   YFG ACC-WEB — دیتابیس acc — ۰۸: زیرسیستم مرور حساب‌ها (AcVwDef)
   مطابق BPL اصلی:
     - TFrRemRep «مرور حسابها» + آناليز حسابها + تراز حساب + گردش ارز
     - صدور اعلاميه / نمايش اعلاميه ها / جزئيات اعلاميه (AccNote*)
   محتوا:
     ۱) ACC.AccNoteHdr  — سربرگ اعلاميه
     ۲) ACC.AccNoteItm  — اقلام اعلاميه (عکس فوری از ردیف سند هنگام صدور)
     ۳) تریگر لاگ اعلاميه (pob.UserLog — ایجاد/حذف)
     ۴) ایندکس‌های پرس‌وجوی مرور (کدینگ/تفصیلی/ارز)
   همهٔ دستورها Idempotent — اجرای تکراری بی‌ضرر.
   ============================================================ */

/* ---------- ۱) سربرگ اعلاميه [فرم: صدور اعلاميه] ---------- */
IF OBJECT_ID('ACC.AccNoteHdr') IS NULL
CREATE TABLE ACC.AccNoteHdr (
  NoteId    int            IDENTITY(1,1) NOT NULL CONSTRAINT PK_AccNoteHdr PRIMARY KEY,
  CompanyId smallint       NOT NULL CONSTRAINT FK_NoteHdr_Company REFERENCES pob.Companies(CompanyId),
  YearId    smallint       NOT NULL CONSTRAINT FK_NoteHdr_Year REFERENCES pob.FiscalYear(YearId),
  NoteNo    int            NOT NULL,                    /* شماره اعلاميه — خودکار در هر سال */
  NoteDate  char(10)       NOT NULL,                    /* تاریخ اعلاميه (جلالی) */
  Title     nvarchar(300)  NULL,                        /* شرح اعلاميه */
  MoeinCode char(6)        NULL,                        /* حساب معين منشأ اقلام */
  CreatedBy varchar(50)    NOT NULL,
  CreatedAt datetime2(0)   NOT NULL CONSTRAINT DF_AccNoteHdr_Cr DEFAULT(SYSUTCDATETIME()),
  CONSTRAINT UQ_AccNoteHdr_No UNIQUE(CompanyId, YearId, NoteNo)
);
GO

/* ---------- ۲) اقلام اعلاميه [فرم: انتخاب اقلام اعلاميه + جزئيات اعلاميه] ---------- */
IF OBJECT_ID('ACC.AccNoteItm') IS NULL
CREATE TABLE ACC.AccNoteItm (
  NoteId      int            NOT NULL CONSTRAINT FK_NoteItm_Hdr REFERENCES ACC.AccNoteHdr(NoteId),
  NoteLineNo  smallint       NOT NULL,
  VoucherId   int            NOT NULL,
  LineId      int            NOT NULL,                  /* ردیف سند مبدأ — برای وصل به سند */
  VchNo       int            NOT NULL,
  VchDate     char(10)       NOT NULL,
  KolCode     char(4)        NOT NULL,
  MoeinCode   char(6)        NOT NULL,
  Taf1Id      int            NULL,
  Taf2Id      int            NULL,
  Taf3Id      int            NULL,
  Descr       nvarchar(500)  NULL,
  Dbt         decimal(18,0)  NOT NULL CONSTRAINT DF_NoteItm_Dbt DEFAULT(0),
  Crt         decimal(18,0)  NOT NULL CONSTRAINT DF_NoteItm_Crt DEFAULT(0),
  CONSTRAINT PK_AccNoteItm PRIMARY KEY(NoteId, NoteLineNo),
  CONSTRAINT CK_NoteItm_Amount CHECK (Dbt >= 0 AND Crt >= 0 AND (Dbt = 0 OR Crt = 0))
);
GO

/* ---------- ۳) لاگ اعلاميه در pob.UserLog (الگوی ۰۴) ---------- */
CREATE OR ALTER TRIGGER ACC.Tr_ACC_AccNoteHdr_Audit ON ACC.AccNoteHdr
AFTER INSERT, UPDATE, DELETE AS
BEGIN
  SET NOCOUNT ON;
  IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 1, N'ACC', N'AccNoteHdr', i.NoteId, N'اعلاميه شمارهٔ ' + CONVERT(nvarchar(10), i.NoteNo) + N' — ' + i.NoteDate
    FROM inserted i;
  IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccNoteHdr', i.NoteId, N'اعلاميه شمارهٔ ' + CONVERT(nvarchar(10), i.NoteNo) + N' — ' + i.NoteDate, N'Title', LEFT(CONVERT(nvarchar(2000), d.Title), 2000), LEFT(CONVERT(nvarchar(2000), i.Title), 2000)
    FROM inserted i JOIN deleted d ON d.NoteId = i.NoteId
    WHERE EXISTS (SELECT i.Title EXCEPT SELECT d.Title);
  IF NOT EXISTS (SELECT 1 FROM inserted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 3, N'ACC', N'AccNoteHdr', d.NoteId, N'اعلاميه شمارهٔ ' + CONVERT(nvarchar(10), d.NoteNo) + N' — ' + d.NoteDate, NULL, NULL, NULL
    FROM deleted d;
END
GO

/* ---------- ۴) ایندکس‌های پرس‌وجوی مرور حساب‌ها ---------- */
/* گردش معین */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_AccVoucherItm_Moein')
  CREATE INDEX IX_AccVoucherItm_Moein ON ACC.AccVoucherItm (MoeinCode) INCLUDE (VoucherId, KolCode, Taf1Id, Taf2Id, Taf3Id, Dbt, Crt);
/* گردش کل */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_AccVoucherItm_Kol')
  CREATE INDEX IX_AccVoucherItm_Kol ON ACC.AccVoucherItm (KolCode) INCLUDE (VoucherId, MoeinCode, Dbt, Crt);
/* آناليز تفصيلي */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_AccVoucherItm_Taf1')
  CREATE INDEX IX_AccVoucherItm_Taf1 ON ACC.AccVoucherItm (Taf1Id) INCLUDE (VoucherId, MoeinCode, Dbt, Crt);
/* گردش ارز */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_AccVoucherItm_Fx')
  CREATE INDEX IX_AccVoucherItm_Fx ON ACC.AccVoucherItm (FxId) INCLUDE (VoucherId, MoeinCode, FxAmount, Dbt, Crt);
/* بازهٔ تاریخ سرسند */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_AccVoucher_Date')
  CREATE INDEX IX_AccVoucher_Date ON ACC.AccVoucher (CompanyId, YearId, State, VchDate) INCLUDE (VchNo, VoucherTypeId);
GO
