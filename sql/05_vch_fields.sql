/* ============================================================
   YFG ACC-WEB — دیتابیس acc — ۰۵: فیلدهای ناقص سند (G-C2 گپ‌آنالیز)
   مطابق فرم اصلی:
     صدور سند حسابداري (acVchDef): شعبه، ش روزانه، ش فرعي، لاتين
     ارز (accCurrency): مبلغ ارزي، نوع ارز، نرخ ارز — در سطح قلم
     پیگیری (تغيير شماره و تاريخ پيگيري): شماره + تاريخ — در سطح قلم
   استانداردها: جلالی · بله/خیر bit · ستون‌های ممیزی کامل · SourceSystem
   همهٔ تغییرها افزایشی است (ADD COLUMN NULL / جدول جدید) — داده‌ای دست نمی‌خورد
   ============================================================ */

/* ---------- بخش ۱: تعریف ارزها [فرم: اطلاعات ارزها — accCurrency] ---------- */
IF OBJECT_ID('ACC.AccFx') IS NULL
CREATE TABLE ACC.AccFx (
  FxId       smallint      IDENTITY(1,1) NOT NULL CONSTRAINT PK_AccFx PRIMARY KEY,
  CompanyId  smallint      NOT NULL CONSTRAINT FK_Fx_Company REFERENCES pob.Companies(CompanyId),
  Code       varchar(10)   NOT NULL,           /* کد ارز: IRR، USD، AED … */
  Title      nvarchar(100) NOT NULL,           /* عنوان فارسی */
  LatinTitle varchar(100)  NULL,
  IsBase     bit           NOT NULL CONSTRAINT DF_AccFx_IsBase DEFAULT(0), /* ارز پایه — بله/خیر */
  IsActive   bit           NOT NULL CONSTRAINT DF_AccFx_Act DEFAULT(1),
  CreatedBy  varchar(50)   NOT NULL CONSTRAINT DF_AccFx_CreatedBy DEFAULT('system'),
  CreatedAt  datetime2(0)  NOT NULL CONSTRAINT DF_AccFx_CreatedAt DEFAULT(SYSDATETIME()),
  UpdatedBy  varchar(50)   NULL,
  UpdatedAt  datetime2(0)  NULL,
  SourceSystem varchar(20) NOT NULL CONSTRAINT DF_AccFx_SourceSystem DEFAULT('ACCWEB'),
  CreatedAtJ AS pob.GrgToJalali(CreatedAt),
  UpdatedAtJ AS pob.GrgToJalali(UpdatedAt),
  CONSTRAINT UQ_AccFx UNIQUE(CompanyId, Code)
);
GO

/* ---------- بخش ۲: تعریف شعبه [فرم: تعريف شعبه — acVchDef] ---------- */
IF OBJECT_ID('ACC.AccBranch') IS NULL
CREATE TABLE ACC.AccBranch (
  BranchId   smallint      IDENTITY(1,1) NOT NULL CONSTRAINT PK_AccBranch PRIMARY KEY,
  CompanyId  smallint      NOT NULL CONSTRAINT FK_Branch_Company REFERENCES pob.Companies(CompanyId),
  Code       varchar(10)   NOT NULL,           /* کد شعبه */
  Title      nvarchar(150) NOT NULL,
  IsActive   bit           NOT NULL CONSTRAINT DF_AccBranch_Act DEFAULT(1),
  CreatedBy  varchar(50)   NOT NULL CONSTRAINT DF_AccBranch_CreatedBy DEFAULT('system'),
  CreatedAt  datetime2(0)  NOT NULL CONSTRAINT DF_AccBranch_CreatedAt DEFAULT(SYSDATETIME()),
  UpdatedBy  varchar(50)   NULL,
  UpdatedAt  datetime2(0)  NULL,
  SourceSystem varchar(20) NOT NULL CONSTRAINT DF_AccBranch_SourceSystem DEFAULT('ACCWEB'),
  CreatedAtJ AS pob.GrgToJalali(CreatedAt),
  UpdatedAtJ AS pob.GrgToJalali(UpdatedAt),
  CONSTRAINT UQ_AccBranch UNIQUE(CompanyId, Code)
);
GO

/* ---------- بخش ۳: سرسند — ستون‌های فرم صدور سند حسابداري ---------- */
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccVoucher') AND name='BranchId')
  ALTER TABLE ACC.AccVoucher ADD BranchId smallint NULL; /* شعبه */
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccVoucher') AND name='DayNo')
  ALTER TABLE ACC.AccVoucher ADD DayNo int NULL; /* ش روزانه — شماره‌گذاری روزانهٔ سند */
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccVoucher') AND name='SubNo')
  ALTER TABLE ACC.AccVoucher ADD SubNo smallint NOT NULL CONSTRAINT DF_AccVoucher_SubNo DEFAULT(0); /* ش فرعي */
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccVoucher') AND name='LatinDescr')
  ALTER TABLE ACC.AccVoucher ADD LatinDescr varchar(500) NULL; /* لاتين — شرح لاتین سند */
GO
/* کلید خارجی شعبه (بعد از ساخت جدول) */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_Voucher_Branch')
  ALTER TABLE ACC.AccVoucher ADD CONSTRAINT FK_Voucher_Branch
    FOREIGN KEY (BranchId) REFERENCES ACC.AccBranch(BranchId);
GO
/* یکتایی شمارهٔ سند با در نظر گرفتن شمارهٔ فرعی — تعویض قید (داده حفظ می‌شود؛ SubNo=0 پیش‌فرض) */
IF EXISTS (SELECT 1 FROM sys.key_constraints WHERE name='UQ_AccVoucher_VchNo')
   AND NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE name='UQ_AccVoucher_VchNoSub')
BEGIN
  ALTER TABLE ACC.AccVoucher DROP CONSTRAINT UQ_AccVoucher_VchNo;
  ALTER TABLE ACC.AccVoucher ADD CONSTRAINT UQ_AccVoucher_VchNoSub UNIQUE(CompanyId, YearId, VchNo, SubNo);
END
GO

/* ---------- بخش ۴: قلم سند — ارز/نرخ/پیگیری/لاتین [accCurrency + تغيير شماره و تاريخ پيگيري] ---------- */
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccVoucherItm') AND name='FxId')
  ALTER TABLE ACC.AccVoucherItm ADD FxId smallint NULL; /* نوع ارز قلم */
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccVoucherItm') AND name='FxAmount')
  ALTER TABLE ACC.AccVoucherItm ADD FxAmount decimal(18,3) NULL; /* مبلغ ارزي */
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccVoucherItm') AND name='FxRate')
  ALTER TABLE ACC.AccVoucherItm ADD FxRate decimal(18,4) NULL; /* نرخ ارز */
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccVoucherItm') AND name='TrackNo')
  ALTER TABLE ACC.AccVoucherItm ADD TrackNo varchar(50) NULL; /* شماره پيگيري */
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccVoucherItm') AND name='TrackDate')
  ALTER TABLE ACC.AccVoucherItm ADD TrackDate char(10) NULL; /* تاريخ پيگيري — جلالی */
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccVoucherItm') AND name='LatinDescr')
  ALTER TABLE ACC.AccVoucherItm ADD LatinDescr varchar(500) NULL; /* شرح لاتین قلم */
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_Line_Fx')
  ALTER TABLE ACC.AccVoucherItm ADD CONSTRAINT FK_Line_Fx
    FOREIGN KEY (FxId) REFERENCES ACC.AccFx(FxId);
GO
/* سه‌تایی ارز (نوع/مبلغ/نرخ) همیشه کامل یا اصلاً — نرخ مثبت */
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name='CK_Line_Fx')
  ALTER TABLE ACC.AccVoucherItm ADD CONSTRAINT CK_Line_Fx CHECK (
    (FxId IS NULL AND FxAmount IS NULL AND FxRate IS NULL)
    OR (FxId IS NOT NULL AND FxAmount IS NOT NULL AND FxRate IS NOT NULL AND FxRate > 0)
  );
GO

/* ---------- بخش ۵: ارز پایهٔ ریال برای همهٔ شرکت‌ها ---------- */
INSERT INTO ACC.AccFx (CompanyId, Code, Title, LatinTitle, IsBase)
SELECT c.CompanyId, 'IRR', N'ریال ایران', 'Iranian Rial', 1
FROM pob.Companies c
WHERE NOT EXISTS (SELECT 1 FROM ACC.AccFx f WHERE f.CompanyId = c.CompanyId AND f.Code = 'IRR');
GO

/* ---------- بخش ۶: تریگرهای ممیزی UserLog ---------- */
/* ۶-۱: جدول‌های جدید AccFx و AccBranch + توسعهٔ تریگرهای سند و قلم (فیلدهای جدید) */
PRINT '=== 05_vch_fields: بخش ۶ (تریگرها) ===';
GO

/* تریگر لاگ: AccFx */
CREATE OR ALTER TRIGGER ACC.Tr_ACC_AccFx_Audit ON ACC.AccFx
AFTER INSERT, UPDATE, DELETE AS
BEGIN
  SET NOCOUNT ON;
  /* ایجاد — یک سطر برای هر رکورد */
  IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 1, N'ACC', N'AccFx', i.FxId, i.Title
    FROM inserted i;
  /* ویرایش — یک سطر برای هر فیلد تغییر یافته */
  IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
  BEGIN
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccFx', i.FxId, i.Title, N'CompanyId', LEFT(CONVERT(nvarchar(2000), d.CompanyId), 2000), LEFT(CONVERT(nvarchar(2000), i.CompanyId), 2000)
    FROM inserted i JOIN deleted d ON d.FxId = i.FxId
    WHERE EXISTS (SELECT i.CompanyId EXCEPT SELECT d.CompanyId);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccFx', i.FxId, i.Title, N'Code', LEFT(CONVERT(nvarchar(2000), d.Code), 2000), LEFT(CONVERT(nvarchar(2000), i.Code), 2000)
    FROM inserted i JOIN deleted d ON d.FxId = i.FxId
    WHERE EXISTS (SELECT i.Code EXCEPT SELECT d.Code);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccFx', i.FxId, i.Title, N'Title', LEFT(CONVERT(nvarchar(2000), d.Title), 2000), LEFT(CONVERT(nvarchar(2000), i.Title), 2000)
    FROM inserted i JOIN deleted d ON d.FxId = i.FxId
    WHERE EXISTS (SELECT i.Title EXCEPT SELECT d.Title);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccFx', i.FxId, i.Title, N'LatinTitle', LEFT(CONVERT(nvarchar(2000), d.LatinTitle), 2000), LEFT(CONVERT(nvarchar(2000), i.LatinTitle), 2000)
    FROM inserted i JOIN deleted d ON d.FxId = i.FxId
    WHERE EXISTS (SELECT i.LatinTitle EXCEPT SELECT d.LatinTitle);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccFx', i.FxId, i.Title, N'IsBase', LEFT(CONVERT(nvarchar(2000), d.IsBase), 2000), LEFT(CONVERT(nvarchar(2000), i.IsBase), 2000)
    FROM inserted i JOIN deleted d ON d.FxId = i.FxId
    WHERE EXISTS (SELECT i.IsBase EXCEPT SELECT d.IsBase);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccFx', i.FxId, i.Title, N'IsActive', LEFT(CONVERT(nvarchar(2000), d.IsActive), 2000), LEFT(CONVERT(nvarchar(2000), i.IsActive), 2000)
    FROM inserted i JOIN deleted d ON d.FxId = i.FxId
    WHERE EXISTS (SELECT i.IsActive EXCEPT SELECT d.IsActive);
  END
  /* حذف — یک سطر برای هر رکورد */
  IF NOT EXISTS (SELECT 1 FROM inserted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 3, N'ACC', N'AccFx', d.FxId, d.Title, NULL, NULL, NULL
    FROM deleted d;
END
GO

/* تریگر لاگ: AccBranch */
CREATE OR ALTER TRIGGER ACC.Tr_ACC_AccBranch_Audit ON ACC.AccBranch
AFTER INSERT, UPDATE, DELETE AS
BEGIN
  SET NOCOUNT ON;
  /* ایجاد — یک سطر برای هر رکورد */
  IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 1, N'ACC', N'AccBranch', i.BranchId, i.Title
    FROM inserted i;
  /* ویرایش — یک سطر برای هر فیلد تغییر یافته */
  IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
  BEGIN
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccBranch', i.BranchId, i.Title, N'CompanyId', LEFT(CONVERT(nvarchar(2000), d.CompanyId), 2000), LEFT(CONVERT(nvarchar(2000), i.CompanyId), 2000)
    FROM inserted i JOIN deleted d ON d.BranchId = i.BranchId
    WHERE EXISTS (SELECT i.CompanyId EXCEPT SELECT d.CompanyId);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccBranch', i.BranchId, i.Title, N'Code', LEFT(CONVERT(nvarchar(2000), d.Code), 2000), LEFT(CONVERT(nvarchar(2000), i.Code), 2000)
    FROM inserted i JOIN deleted d ON d.BranchId = i.BranchId
    WHERE EXISTS (SELECT i.Code EXCEPT SELECT d.Code);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccBranch', i.BranchId, i.Title, N'Title', LEFT(CONVERT(nvarchar(2000), d.Title), 2000), LEFT(CONVERT(nvarchar(2000), i.Title), 2000)
    FROM inserted i JOIN deleted d ON d.BranchId = i.BranchId
    WHERE EXISTS (SELECT i.Title EXCEPT SELECT d.Title);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccBranch', i.BranchId, i.Title, N'IsActive', LEFT(CONVERT(nvarchar(2000), d.IsActive), 2000), LEFT(CONVERT(nvarchar(2000), i.IsActive), 2000)
    FROM inserted i JOIN deleted d ON d.BranchId = i.BranchId
    WHERE EXISTS (SELECT i.IsActive EXCEPT SELECT d.IsActive);
  END
  /* حذف — یک سطر برای هر رکورد */
  IF NOT EXISTS (SELECT 1 FROM inserted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 3, N'ACC', N'AccBranch', d.BranchId, d.Title, NULL, NULL, NULL
    FROM deleted d;
END
GO

/* ۶-۲: تریگر توسعه‌یافتهٔ AccVoucher — ستون‌های جدید هم لاگ می‌شوند */
CREATE OR ALTER TRIGGER ACC.Tr_ACC_AccVoucher_Audit ON ACC.AccVoucher
AFTER INSERT, UPDATE, DELETE AS
BEGIN
  SET NOCOUNT ON;
  /* ایجاد — یک سطر برای هر رکورد */
  IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 1, N'ACC', N'AccVoucher', i.VoucherId, N'سند شمارهٔ ' + CONVERT(nvarchar(10), i.VchNo) + N' — ' + i.VchDate
    FROM inserted i;
  /* ویرایش — یک سطر برای هر فیلد تغییر یافته */
  IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
  BEGIN
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccVoucher', i.VoucherId, N'سند شمارهٔ ' + CONVERT(nvarchar(10), i.VchNo) + N' — ' + i.VchDate, N'CompanyId', LEFT(CONVERT(nvarchar(2000), d.CompanyId), 2000), LEFT(CONVERT(nvarchar(2000), i.CompanyId), 2000)
    FROM inserted i JOIN deleted d ON d.VoucherId = i.VoucherId
    WHERE EXISTS (SELECT i.CompanyId EXCEPT SELECT d.CompanyId);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccVoucher', i.VoucherId, N'سند شمارهٔ ' + CONVERT(nvarchar(10), i.VchNo) + N' — ' + i.VchDate, N'YearId', LEFT(CONVERT(nvarchar(2000), d.YearId), 2000), LEFT(CONVERT(nvarchar(2000), i.YearId), 2000)
    FROM inserted i JOIN deleted d ON d.VoucherId = i.VoucherId
    WHERE EXISTS (SELECT i.YearId EXCEPT SELECT d.YearId);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccVoucher', i.VoucherId, N'سند شمارهٔ ' + CONVERT(nvarchar(10), i.VchNo) + N' — ' + i.VchDate, N'FolioNo', LEFT(CONVERT(nvarchar(2000), d.FolioNo), 2000), LEFT(CONVERT(nvarchar(2000), i.FolioNo), 2000)
    FROM inserted i JOIN deleted d ON d.VoucherId = i.VoucherId
    WHERE EXISTS (SELECT i.FolioNo EXCEPT SELECT d.FolioNo);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccVoucher', i.VoucherId, N'سند شمارهٔ ' + CONVERT(nvarchar(10), i.VchNo) + N' — ' + i.VchDate, N'VchNo', LEFT(CONVERT(nvarchar(2000), d.VchNo), 2000), LEFT(CONVERT(nvarchar(2000), i.VchNo), 2000)
    FROM inserted i JOIN deleted d ON d.VoucherId = i.VoucherId
    WHERE EXISTS (SELECT i.VchNo EXCEPT SELECT d.VchNo);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccVoucher', i.VoucherId, N'سند شمارهٔ ' + CONVERT(nvarchar(10), i.VchNo) + N' — ' + i.VchDate, N'VoucherTypeId', LEFT(CONVERT(nvarchar(2000), d.VoucherTypeId), 2000), LEFT(CONVERT(nvarchar(2000), i.VoucherTypeId), 2000)
    FROM inserted i JOIN deleted d ON d.VoucherId = i.VoucherId
    WHERE EXISTS (SELECT i.VoucherTypeId EXCEPT SELECT d.VoucherTypeId);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccVoucher', i.VoucherId, N'سند شمارهٔ ' + CONVERT(nvarchar(10), i.VchNo) + N' — ' + i.VchDate, N'VchDate', LEFT(CONVERT(nvarchar(2000), d.VchDate), 2000), LEFT(CONVERT(nvarchar(2000), i.VchDate), 2000)
    FROM inserted i JOIN deleted d ON d.VoucherId = i.VoucherId
    WHERE EXISTS (SELECT i.VchDate EXCEPT SELECT d.VchDate);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccVoucher', i.VoucherId, N'سند شمارهٔ ' + CONVERT(nvarchar(10), i.VchNo) + N' — ' + i.VchDate, N'Descr', LEFT(CONVERT(nvarchar(2000), d.Descr), 2000), LEFT(CONVERT(nvarchar(2000), i.Descr), 2000)
    FROM inserted i JOIN deleted d ON d.VoucherId = i.VoucherId
    WHERE EXISTS (SELECT i.Descr EXCEPT SELECT d.Descr);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccVoucher', i.VoucherId, N'سند شمارهٔ ' + CONVERT(nvarchar(10), i.VchNo) + N' — ' + i.VchDate, N'State', LEFT(CONVERT(nvarchar(2000), d.State), 2000), LEFT(CONVERT(nvarchar(2000), i.State), 2000)
    FROM inserted i JOIN deleted d ON d.VoucherId = i.VoucherId
    WHERE EXISTS (SELECT i.State EXCEPT SELECT d.State);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccVoucher', i.VoucherId, N'سند شمارهٔ ' + CONVERT(nvarchar(10), i.VchNo) + N' — ' + i.VchDate, N'ReversalOf', LEFT(CONVERT(nvarchar(2000), d.ReversalOf), 2000), LEFT(CONVERT(nvarchar(2000), i.ReversalOf), 2000)
    FROM inserted i JOIN deleted d ON d.VoucherId = i.VoucherId
    WHERE EXISTS (SELECT i.ReversalOf EXCEPT SELECT d.ReversalOf);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccVoucher', i.VoucherId, N'سند شمارهٔ ' + CONVERT(nvarchar(10), i.VchNo) + N' — ' + i.VchDate, N'SourceModule', LEFT(CONVERT(nvarchar(2000), d.SourceModule), 2000), LEFT(CONVERT(nvarchar(2000), i.SourceModule), 2000)
    FROM inserted i JOIN deleted d ON d.VoucherId = i.VoucherId
    WHERE EXISTS (SELECT i.SourceModule EXCEPT SELECT d.SourceModule);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccVoucher', i.VoucherId, N'سند شمارهٔ ' + CONVERT(nvarchar(10), i.VchNo) + N' — ' + i.VchDate, N'BranchId', LEFT(CONVERT(nvarchar(2000), d.BranchId), 2000), LEFT(CONVERT(nvarchar(2000), i.BranchId), 2000)
    FROM inserted i JOIN deleted d ON d.VoucherId = i.VoucherId
    WHERE EXISTS (SELECT i.BranchId EXCEPT SELECT d.BranchId);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccVoucher', i.VoucherId, N'سند شمارهٔ ' + CONVERT(nvarchar(10), i.VchNo) + N' — ' + i.VchDate, N'DayNo', LEFT(CONVERT(nvarchar(2000), d.DayNo), 2000), LEFT(CONVERT(nvarchar(2000), i.DayNo), 2000)
    FROM inserted i JOIN deleted d ON d.VoucherId = i.VoucherId
    WHERE EXISTS (SELECT i.DayNo EXCEPT SELECT d.DayNo);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccVoucher', i.VoucherId, N'سند شمارهٔ ' + CONVERT(nvarchar(10), i.VchNo) + N' — ' + i.VchDate, N'SubNo', LEFT(CONVERT(nvarchar(2000), d.SubNo), 2000), LEFT(CONVERT(nvarchar(2000), i.SubNo), 2000)
    FROM inserted i JOIN deleted d ON d.VoucherId = i.VoucherId
    WHERE EXISTS (SELECT i.SubNo EXCEPT SELECT d.SubNo);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccVoucher', i.VoucherId, N'سند شمارهٔ ' + CONVERT(nvarchar(10), i.VchNo) + N' — ' + i.VchDate, N'LatinDescr', LEFT(CONVERT(nvarchar(2000), d.LatinDescr), 2000), LEFT(CONVERT(nvarchar(2000), i.LatinDescr), 2000)
    FROM inserted i JOIN deleted d ON d.VoucherId = i.VoucherId
    WHERE EXISTS (SELECT i.LatinDescr EXCEPT SELECT d.LatinDescr);
  END
  /* حذف — یک سطر برای هر رکورد */
  IF NOT EXISTS (SELECT 1 FROM inserted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 3, N'ACC', N'AccVoucher', d.VoucherId, N'سند شمارهٔ ' + CONVERT(nvarchar(10), d.VchNo) + N' — ' + d.VchDate, NULL, NULL, NULL
    FROM deleted d;
END
GO

/* ۶-۲: تریگر توسعه‌یافتهٔ AccVoucherItm — ستون‌های جدید هم لاگ می‌شوند */
CREATE OR ALTER TRIGGER ACC.Tr_ACC_AccVoucherItm_Audit ON ACC.AccVoucherItm
AFTER INSERT, UPDATE, DELETE AS
BEGIN
  SET NOCOUNT ON;
  /* ایجاد — یک سطر برای کل سند (تعداد ردیف) */
  IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 1, N'ACC', N'AccVoucherItm', NULL, N'سند شمارهٔ ' + CONVERT(nvarchar(10), MIN(h.VchNo)) + N' — ' + CONVERT(nvarchar(10), COUNT(*)) + N' ردیف'
    FROM inserted i JOIN ACC.AccVoucher h ON h.VoucherId = i.VoucherId
    GROUP BY i.VoucherId;
  /* ویرایش — یک سطر برای هر فیلد تغییر یافته */
  IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
  BEGIN
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccVoucherItm', i.LineId, N'سند شمارهٔ ' + CONVERT(nvarchar(10), h.VchNo) + N' — ردیف ' + CONVERT(nvarchar(10), i.RowNo), N'VoucherId', LEFT(CONVERT(nvarchar(2000), d.VoucherId), 2000), LEFT(CONVERT(nvarchar(2000), i.VoucherId), 2000)
    FROM inserted i JOIN deleted d ON d.LineId = i.LineId
    JOIN ACC.AccVoucher h ON h.VoucherId = i.VoucherId
    WHERE EXISTS (SELECT i.VoucherId EXCEPT SELECT d.VoucherId);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccVoucherItm', i.LineId, N'سند شمارهٔ ' + CONVERT(nvarchar(10), h.VchNo) + N' — ردیف ' + CONVERT(nvarchar(10), i.RowNo), N'RowNo', LEFT(CONVERT(nvarchar(2000), d.RowNo), 2000), LEFT(CONVERT(nvarchar(2000), i.RowNo), 2000)
    FROM inserted i JOIN deleted d ON d.LineId = i.LineId
    JOIN ACC.AccVoucher h ON h.VoucherId = i.VoucherId
    WHERE EXISTS (SELECT i.RowNo EXCEPT SELECT d.RowNo);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccVoucherItm', i.LineId, N'سند شمارهٔ ' + CONVERT(nvarchar(10), h.VchNo) + N' — ردیف ' + CONVERT(nvarchar(10), i.RowNo), N'KolCode', LEFT(CONVERT(nvarchar(2000), d.KolCode), 2000), LEFT(CONVERT(nvarchar(2000), i.KolCode), 2000)
    FROM inserted i JOIN deleted d ON d.LineId = i.LineId
    JOIN ACC.AccVoucher h ON h.VoucherId = i.VoucherId
    WHERE EXISTS (SELECT i.KolCode EXCEPT SELECT d.KolCode);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccVoucherItm', i.LineId, N'سند شمارهٔ ' + CONVERT(nvarchar(10), h.VchNo) + N' — ردیف ' + CONVERT(nvarchar(10), i.RowNo), N'MoeinCode', LEFT(CONVERT(nvarchar(2000), d.MoeinCode), 2000), LEFT(CONVERT(nvarchar(2000), i.MoeinCode), 2000)
    FROM inserted i JOIN deleted d ON d.LineId = i.LineId
    JOIN ACC.AccVoucher h ON h.VoucherId = i.VoucherId
    WHERE EXISTS (SELECT i.MoeinCode EXCEPT SELECT d.MoeinCode);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccVoucherItm', i.LineId, N'سند شمارهٔ ' + CONVERT(nvarchar(10), h.VchNo) + N' — ردیف ' + CONVERT(nvarchar(10), i.RowNo), N'Taf1Id', LEFT(CONVERT(nvarchar(2000), d.Taf1Id), 2000), LEFT(CONVERT(nvarchar(2000), i.Taf1Id), 2000)
    FROM inserted i JOIN deleted d ON d.LineId = i.LineId
    JOIN ACC.AccVoucher h ON h.VoucherId = i.VoucherId
    WHERE EXISTS (SELECT i.Taf1Id EXCEPT SELECT d.Taf1Id);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccVoucherItm', i.LineId, N'سند شمارهٔ ' + CONVERT(nvarchar(10), h.VchNo) + N' — ردیف ' + CONVERT(nvarchar(10), i.RowNo), N'Taf2Id', LEFT(CONVERT(nvarchar(2000), d.Taf2Id), 2000), LEFT(CONVERT(nvarchar(2000), i.Taf2Id), 2000)
    FROM inserted i JOIN deleted d ON d.LineId = i.LineId
    JOIN ACC.AccVoucher h ON h.VoucherId = i.VoucherId
    WHERE EXISTS (SELECT i.Taf2Id EXCEPT SELECT d.Taf2Id);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccVoucherItm', i.LineId, N'سند شمارهٔ ' + CONVERT(nvarchar(10), h.VchNo) + N' — ردیف ' + CONVERT(nvarchar(10), i.RowNo), N'Taf3Id', LEFT(CONVERT(nvarchar(2000), d.Taf3Id), 2000), LEFT(CONVERT(nvarchar(2000), i.Taf3Id), 2000)
    FROM inserted i JOIN deleted d ON d.LineId = i.LineId
    JOIN ACC.AccVoucher h ON h.VoucherId = i.VoucherId
    WHERE EXISTS (SELECT i.Taf3Id EXCEPT SELECT d.Taf3Id);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccVoucherItm', i.LineId, N'سند شمارهٔ ' + CONVERT(nvarchar(10), h.VchNo) + N' — ردیف ' + CONVERT(nvarchar(10), i.RowNo), N'Descr', LEFT(CONVERT(nvarchar(2000), d.Descr), 2000), LEFT(CONVERT(nvarchar(2000), i.Descr), 2000)
    FROM inserted i JOIN deleted d ON d.LineId = i.LineId
    JOIN ACC.AccVoucher h ON h.VoucherId = i.VoucherId
    WHERE EXISTS (SELECT i.Descr EXCEPT SELECT d.Descr);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccVoucherItm', i.LineId, N'سند شمارهٔ ' + CONVERT(nvarchar(10), h.VchNo) + N' — ردیف ' + CONVERT(nvarchar(10), i.RowNo), N'Dbt', LEFT(CONVERT(nvarchar(2000), d.Dbt), 2000), LEFT(CONVERT(nvarchar(2000), i.Dbt), 2000)
    FROM inserted i JOIN deleted d ON d.LineId = i.LineId
    JOIN ACC.AccVoucher h ON h.VoucherId = i.VoucherId
    WHERE EXISTS (SELECT i.Dbt EXCEPT SELECT d.Dbt);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccVoucherItm', i.LineId, N'سند شمارهٔ ' + CONVERT(nvarchar(10), h.VchNo) + N' — ردیف ' + CONVERT(nvarchar(10), i.RowNo), N'Crt', LEFT(CONVERT(nvarchar(2000), d.Crt), 2000), LEFT(CONVERT(nvarchar(2000), i.Crt), 2000)
    FROM inserted i JOIN deleted d ON d.LineId = i.LineId
    JOIN ACC.AccVoucher h ON h.VoucherId = i.VoucherId
    WHERE EXISTS (SELECT i.Crt EXCEPT SELECT d.Crt);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccVoucherItm', i.LineId, N'سند شمارهٔ ' + CONVERT(nvarchar(10), h.VchNo) + N' — ردیف ' + CONVERT(nvarchar(10), i.RowNo), N'FxId', LEFT(CONVERT(nvarchar(2000), d.FxId), 2000), LEFT(CONVERT(nvarchar(2000), i.FxId), 2000)
    FROM inserted i JOIN deleted d ON d.LineId = i.LineId
    JOIN ACC.AccVoucher h ON h.VoucherId = i.VoucherId
    WHERE EXISTS (SELECT i.FxId EXCEPT SELECT d.FxId);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccVoucherItm', i.LineId, N'سند شمارهٔ ' + CONVERT(nvarchar(10), h.VchNo) + N' — ردیف ' + CONVERT(nvarchar(10), i.RowNo), N'FxAmount', LEFT(CONVERT(nvarchar(2000), d.FxAmount), 2000), LEFT(CONVERT(nvarchar(2000), i.FxAmount), 2000)
    FROM inserted i JOIN deleted d ON d.LineId = i.LineId
    JOIN ACC.AccVoucher h ON h.VoucherId = i.VoucherId
    WHERE EXISTS (SELECT i.FxAmount EXCEPT SELECT d.FxAmount);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccVoucherItm', i.LineId, N'سند شمارهٔ ' + CONVERT(nvarchar(10), h.VchNo) + N' — ردیف ' + CONVERT(nvarchar(10), i.RowNo), N'FxRate', LEFT(CONVERT(nvarchar(2000), d.FxRate), 2000), LEFT(CONVERT(nvarchar(2000), i.FxRate), 2000)
    FROM inserted i JOIN deleted d ON d.LineId = i.LineId
    JOIN ACC.AccVoucher h ON h.VoucherId = i.VoucherId
    WHERE EXISTS (SELECT i.FxRate EXCEPT SELECT d.FxRate);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccVoucherItm', i.LineId, N'سند شمارهٔ ' + CONVERT(nvarchar(10), h.VchNo) + N' — ردیف ' + CONVERT(nvarchar(10), i.RowNo), N'TrackNo', LEFT(CONVERT(nvarchar(2000), d.TrackNo), 2000), LEFT(CONVERT(nvarchar(2000), i.TrackNo), 2000)
    FROM inserted i JOIN deleted d ON d.LineId = i.LineId
    JOIN ACC.AccVoucher h ON h.VoucherId = i.VoucherId
    WHERE EXISTS (SELECT i.TrackNo EXCEPT SELECT d.TrackNo);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccVoucherItm', i.LineId, N'سند شمارهٔ ' + CONVERT(nvarchar(10), h.VchNo) + N' — ردیف ' + CONVERT(nvarchar(10), i.RowNo), N'TrackDate', LEFT(CONVERT(nvarchar(2000), d.TrackDate), 2000), LEFT(CONVERT(nvarchar(2000), i.TrackDate), 2000)
    FROM inserted i JOIN deleted d ON d.LineId = i.LineId
    JOIN ACC.AccVoucher h ON h.VoucherId = i.VoucherId
    WHERE EXISTS (SELECT i.TrackDate EXCEPT SELECT d.TrackDate);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccVoucherItm', i.LineId, N'سند شمارهٔ ' + CONVERT(nvarchar(10), h.VchNo) + N' — ردیف ' + CONVERT(nvarchar(10), i.RowNo), N'LatinDescr', LEFT(CONVERT(nvarchar(2000), d.LatinDescr), 2000), LEFT(CONVERT(nvarchar(2000), i.LatinDescr), 2000)
    FROM inserted i JOIN deleted d ON d.LineId = i.LineId
    JOIN ACC.AccVoucher h ON h.VoucherId = i.VoucherId
    WHERE EXISTS (SELECT i.LatinDescr EXCEPT SELECT d.LatinDescr);
  END
  /* حذف — یک سطر برای کل سند (تعداد ردیف) */
  IF NOT EXISTS (SELECT 1 FROM inserted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 3, N'ACC', N'AccVoucherItm', NULL, N'سند شمارهٔ ' + CONVERT(nvarchar(10), MIN(h.VchNo)) + N' — ' + CONVERT(nvarchar(10), COUNT(*)) + N' ردیف', NULL, NULL, NULL
    FROM deleted d JOIN ACC.AccVoucher h ON h.VoucherId = d.VoucherId
    GROUP BY d.VoucherId;
END
GO


/* ---------- بخش ۷: راستی‌آزمایی ---------- */
PRINT '--- وضعیت پس از مهاجرت ---';
SELECT 'AccFx' Tbl, COUNT(*) Cnt FROM ACC.AccFx
UNION ALL SELECT 'AccBranch', COUNT(*) FROM ACC.AccBranch
UNION ALL SELECT 'AccVoucher.NewCols',
  (SELECT COUNT(*) FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccVoucher')
     AND name IN ('BranchId','DayNo','SubNo','LatinDescr'))
UNION ALL SELECT 'AccVoucherItm.NewCols',
  (SELECT COUNT(*) FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccVoucherItm')
     AND name IN ('FxId','FxAmount','FxRate','TrackNo','TrackDate','LatinDescr'));
SELECT name FROM sys.key_constraints WHERE name IN ('UQ_AccVoucher_VchNoSub');
SELECT name FROM sys.check_constraints WHERE name = 'CK_Line_Fx';
SELECT name FROM sys.foreign_keys WHERE name IN ('FK_Voucher_Branch','FK_Line_Fx','FK_Fx_Company','FK_Branch_Company');
SELECT name FROM sys.triggers WHERE parent_id = OBJECT_ID('ACC.AccFx')
UNION ALL SELECT name FROM sys.triggers WHERE parent_id = OBJECT_ID('ACC.AccBranch');
PRINT '=== 05_vch_fields done ===';
GO
