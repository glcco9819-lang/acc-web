/* ============================================================
   YFG ACC-WEB — دیتابیس acc — ۰۴: لاگ فعالیت کاربران (UserLog)
   طبق دستور کارفرما: ثبت لاگ در پیش‌زمینهٔ دیتابیس (تریگر) —
   نرم‌افزار فقط پنجرهٔ نمایش دارد.
   انواع فعالیت: 1=ایجاد 2=ویرایش 3=حذف 4=ورود 5=خروج
   ویرایش: یک سطر برای هر فیلدِ تغییر یافته (چه فیلدی)
   ایجاد/حذف: یک سطر برای هر سند/رکورد
   دسترسی مستقیم به دیتابیس: نام لاگین SQL ثبت می‌شود
   ============================================================ */

IF OBJECT_ID('pob.UserLog') IS NULL
BEGIN
  CREATE TABLE pob.UserLog (
    UserLogId    bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_UserLog PRIMARY KEY,
    UserName     nvarchar(64)   NOT NULL,
    LogDate      char(10)       NOT NULL,
    LogTime      char(8)        NOT NULL,
    ComputerName nvarchar(64)   NULL,
    IpAddress    varchar(45)    NULL,
    ActivityType tinyint        NOT NULL CONSTRAINT DF_UserLog_Activity DEFAULT (0),
    SubSystem    varchar(16)    NOT NULL,
    TableName    nvarchar(64)   NOT NULL,
    RecId        bigint         NULL,
    DocInfo      nvarchar(200)  NULL,
    FieldName    nvarchar(64)   NULL,
    OldValue     nvarchar(2000) NULL,
    NewValue     nvarchar(2000) NULL,
    CONSTRAINT CK_UserLog_Activity CHECK (ActivityType BETWEEN 1 AND 5)
  );
  CREATE INDEX IX_UserLog_Date ON pob.UserLog (LogDate, UserLogId);
  CREATE INDEX IX_UserLog_User ON pob.UserLog (UserName, LogDate);
  CREATE INDEX IX_UserLog_Sub  ON pob.UserLog (SubSystem, ActivityType, LogDate);
END
GO

/* توابع کمکی کانتکست لاگ — مقدارها از SESSION_CONTEXT (برنامه) یا نام لاگین SQL */
CREATE OR ALTER FUNCTION pob.FnLogUser() RETURNS nvarchar(64) AS BEGIN
  RETURN COALESCE(NULLIF(CAST(SESSION_CONTEXT(N'LogUser') AS nvarchar(64)), N''), CAST(SUSER_SNAME() AS nvarchar(64)));
END
GO
CREATE OR ALTER FUNCTION pob.FnLogIp() RETURNS varchar(45) AS BEGIN
  RETURN CAST(SESSION_CONTEXT(N'LogIp') AS varchar(45));
END
GO
CREATE OR ALTER FUNCTION pob.FnLogPc() RETURNS nvarchar(64) AS BEGIN
  RETURN CAST(SESSION_CONTEXT(N'LogPC') AS nvarchar(64));
END
GO
CREATE OR ALTER FUNCTION pob.FnLogDate() RETURNS char(10) AS BEGIN
  RETURN pob.GrgToJalali(CONVERT(datetime2(0), GETDATE()));
END
GO
CREATE OR ALTER FUNCTION pob.FnLogTime() RETURNS char(8) AS BEGIN
  RETURN CONVERT(char(8), GETDATE(), 114);
END
GO

/* ثبت یک سطر لاگ از سمت برنامه (ورود/خروج/حذف لاگ) */
CREATE OR ALTER PROCEDURE pob.UspUserLogAdd
  @Tbl nvarchar(64), @Act tinyint,
  @RecId bigint = NULL, @Doc nvarchar(200) = NULL, @Field nvarchar(64) = NULL,
  @Old nvarchar(2000) = NULL, @New nvarchar(2000) = NULL, @User nvarchar(64) = NULL
AS BEGIN
  SET NOCOUNT ON;
  INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress,
                           ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
  VALUES (COALESCE(NULLIF(@User, N''), pob.FnLogUser()),
          pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), @Act,
          CASE WHEN OBJECT_ID(N'ACC.' + @Tbl) IS NOT NULL THEN 'ACC' ELSE 'pob' END,
          @Tbl, @RecId, @Doc, @Field, @Old, @New);
END
GO


-- ----------------------------------------------------------
-- تریگر لاگ: AccGroup
-- ----------------------------------------------------------
CREATE OR ALTER TRIGGER ACC.Tr_ACC_AccGroup_Audit ON ACC.AccGroup
AFTER INSERT, UPDATE, DELETE AS
BEGIN
  SET NOCOUNT ON;
  /* ایجاد — یک سطر برای هر رکورد */
  IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 1, N'ACC', N'AccGroup', i.GroupId, i.Code + N' — ' + i.Title
    FROM inserted i;
  /* ویرایش — یک سطر برای هر فیلد تغییر یافته */
  IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
  BEGIN
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccGroup', i.GroupId, i.Code + N' — ' + i.Title, N'CompanyId', LEFT(CONVERT(nvarchar(2000), d.CompanyId), 2000), LEFT(CONVERT(nvarchar(2000), i.CompanyId), 2000)
    FROM inserted i JOIN deleted d ON d.GroupId = i.GroupId
    WHERE EXISTS (SELECT i.CompanyId EXCEPT SELECT d.CompanyId);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccGroup', i.GroupId, i.Code + N' — ' + i.Title, N'Code', LEFT(CONVERT(nvarchar(2000), d.Code), 2000), LEFT(CONVERT(nvarchar(2000), i.Code), 2000)
    FROM inserted i JOIN deleted d ON d.GroupId = i.GroupId
    WHERE EXISTS (SELECT i.Code EXCEPT SELECT d.Code);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccGroup', i.GroupId, i.Code + N' — ' + i.Title, N'Title', LEFT(CONVERT(nvarchar(2000), d.Title), 2000), LEFT(CONVERT(nvarchar(2000), i.Title), 2000)
    FROM inserted i JOIN deleted d ON d.GroupId = i.GroupId
    WHERE EXISTS (SELECT i.Title EXCEPT SELECT d.Title);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccGroup', i.GroupId, i.Code + N' — ' + i.Title, N'AccNature', LEFT(CONVERT(nvarchar(2000), d.AccNature), 2000), LEFT(CONVERT(nvarchar(2000), i.AccNature), 2000)
    FROM inserted i JOIN deleted d ON d.GroupId = i.GroupId
    WHERE EXISTS (SELECT i.AccNature EXCEPT SELECT d.AccNature);
  END
  /* حذف — یک سطر برای هر رکورد */
  IF NOT EXISTS (SELECT 1 FROM inserted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 3, N'ACC', N'AccGroup', d.GroupId, d.Code + N' — ' + d.Title, NULL, NULL, NULL
    FROM deleted d;
END
GO

-- ----------------------------------------------------------
-- تریگر لاگ: AccKol
-- ----------------------------------------------------------
CREATE OR ALTER TRIGGER ACC.Tr_ACC_AccKol_Audit ON ACC.AccKol
AFTER INSERT, UPDATE, DELETE AS
BEGIN
  SET NOCOUNT ON;
  /* ایجاد — یک سطر برای هر رکورد */
  IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 1, N'ACC', N'AccKol', i.KolId, i.Code + N' — ' + i.Title
    FROM inserted i;
  /* ویرایش — یک سطر برای هر فیلد تغییر یافته */
  IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
  BEGIN
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccKol', i.KolId, i.Code + N' — ' + i.Title, N'CompanyId', LEFT(CONVERT(nvarchar(2000), d.CompanyId), 2000), LEFT(CONVERT(nvarchar(2000), i.CompanyId), 2000)
    FROM inserted i JOIN deleted d ON d.KolId = i.KolId
    WHERE EXISTS (SELECT i.CompanyId EXCEPT SELECT d.CompanyId);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccKol', i.KolId, i.Code + N' — ' + i.Title, N'Code', LEFT(CONVERT(nvarchar(2000), d.Code), 2000), LEFT(CONVERT(nvarchar(2000), i.Code), 2000)
    FROM inserted i JOIN deleted d ON d.KolId = i.KolId
    WHERE EXISTS (SELECT i.Code EXCEPT SELECT d.Code);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccKol', i.KolId, i.Code + N' — ' + i.Title, N'GroupCode', LEFT(CONVERT(nvarchar(2000), d.GroupCode), 2000), LEFT(CONVERT(nvarchar(2000), i.GroupCode), 2000)
    FROM inserted i JOIN deleted d ON d.KolId = i.KolId
    WHERE EXISTS (SELECT i.GroupCode EXCEPT SELECT d.GroupCode);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccKol', i.KolId, i.Code + N' — ' + i.Title, N'Title', LEFT(CONVERT(nvarchar(2000), d.Title), 2000), LEFT(CONVERT(nvarchar(2000), i.Title), 2000)
    FROM inserted i JOIN deleted d ON d.KolId = i.KolId
    WHERE EXISTS (SELECT i.Title EXCEPT SELECT d.Title);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccKol', i.KolId, i.Code + N' — ' + i.Title, N'AccNature', LEFT(CONVERT(nvarchar(2000), d.AccNature), 2000), LEFT(CONVERT(nvarchar(2000), i.AccNature), 2000)
    FROM inserted i JOIN deleted d ON d.KolId = i.KolId
    WHERE EXISTS (SELECT i.AccNature EXCEPT SELECT d.AccNature);
  END
  /* حذف — یک سطر برای هر رکورد */
  IF NOT EXISTS (SELECT 1 FROM inserted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 3, N'ACC', N'AccKol', d.KolId, d.Code + N' — ' + d.Title, NULL, NULL, NULL
    FROM deleted d;
END
GO

-- ----------------------------------------------------------
-- تریگر لاگ: AccMoein
-- ----------------------------------------------------------
CREATE OR ALTER TRIGGER ACC.Tr_ACC_AccMoein_Audit ON ACC.AccMoein
AFTER INSERT, UPDATE, DELETE AS
BEGIN
  SET NOCOUNT ON;
  /* ایجاد — یک سطر برای هر رکورد */
  IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 1, N'ACC', N'AccMoein', i.MoeinId, i.Code + N' — ' + i.Title
    FROM inserted i;
  /* ویرایش — یک سطر برای هر فیلد تغییر یافته */
  IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
  BEGIN
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccMoein', i.MoeinId, i.Code + N' — ' + i.Title, N'CompanyId', LEFT(CONVERT(nvarchar(2000), d.CompanyId), 2000), LEFT(CONVERT(nvarchar(2000), i.CompanyId), 2000)
    FROM inserted i JOIN deleted d ON d.MoeinId = i.MoeinId
    WHERE EXISTS (SELECT i.CompanyId EXCEPT SELECT d.CompanyId);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccMoein', i.MoeinId, i.Code + N' — ' + i.Title, N'Code', LEFT(CONVERT(nvarchar(2000), d.Code), 2000), LEFT(CONVERT(nvarchar(2000), i.Code), 2000)
    FROM inserted i JOIN deleted d ON d.MoeinId = i.MoeinId
    WHERE EXISTS (SELECT i.Code EXCEPT SELECT d.Code);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccMoein', i.MoeinId, i.Code + N' — ' + i.Title, N'KolCode', LEFT(CONVERT(nvarchar(2000), d.KolCode), 2000), LEFT(CONVERT(nvarchar(2000), i.KolCode), 2000)
    FROM inserted i JOIN deleted d ON d.MoeinId = i.MoeinId
    WHERE EXISTS (SELECT i.KolCode EXCEPT SELECT d.KolCode);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccMoein', i.MoeinId, i.Code + N' — ' + i.Title, N'Title', LEFT(CONVERT(nvarchar(2000), d.Title), 2000), LEFT(CONVERT(nvarchar(2000), i.Title), 2000)
    FROM inserted i JOIN deleted d ON d.MoeinId = i.MoeinId
    WHERE EXISTS (SELECT i.Title EXCEPT SELECT d.Title);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccMoein', i.MoeinId, i.Code + N' — ' + i.Title, N'AccNature', LEFT(CONVERT(nvarchar(2000), d.AccNature), 2000), LEFT(CONVERT(nvarchar(2000), i.AccNature), 2000)
    FROM inserted i JOIN deleted d ON d.MoeinId = i.MoeinId
    WHERE EXISTS (SELECT i.AccNature EXCEPT SELECT d.AccNature);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccMoein', i.MoeinId, i.Code + N' — ' + i.Title, N'Taf1TypeId', LEFT(CONVERT(nvarchar(2000), d.Taf1TypeId), 2000), LEFT(CONVERT(nvarchar(2000), i.Taf1TypeId), 2000)
    FROM inserted i JOIN deleted d ON d.MoeinId = i.MoeinId
    WHERE EXISTS (SELECT i.Taf1TypeId EXCEPT SELECT d.Taf1TypeId);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccMoein', i.MoeinId, i.Code + N' — ' + i.Title, N'Taf2TypeId', LEFT(CONVERT(nvarchar(2000), d.Taf2TypeId), 2000), LEFT(CONVERT(nvarchar(2000), i.Taf2TypeId), 2000)
    FROM inserted i JOIN deleted d ON d.MoeinId = i.MoeinId
    WHERE EXISTS (SELECT i.Taf2TypeId EXCEPT SELECT d.Taf2TypeId);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccMoein', i.MoeinId, i.Code + N' — ' + i.Title, N'Taf3TypeId', LEFT(CONVERT(nvarchar(2000), d.Taf3TypeId), 2000), LEFT(CONVERT(nvarchar(2000), i.Taf3TypeId), 2000)
    FROM inserted i JOIN deleted d ON d.MoeinId = i.MoeinId
    WHERE EXISTS (SELECT i.Taf3TypeId EXCEPT SELECT d.Taf3TypeId);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccMoein', i.MoeinId, i.Code + N' — ' + i.Title, N'Trackable', LEFT(CONVERT(nvarchar(2000), d.Trackable), 2000), LEFT(CONVERT(nvarchar(2000), i.Trackable), 2000)
    FROM inserted i JOIN deleted d ON d.MoeinId = i.MoeinId
    WHERE EXISTS (SELECT i.Trackable EXCEPT SELECT d.Trackable);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccMoein', i.MoeinId, i.Code + N' — ' + i.Title, N'Countable', LEFT(CONVERT(nvarchar(2000), d.Countable), 2000), LEFT(CONVERT(nvarchar(2000), i.Countable), 2000)
    FROM inserted i JOIN deleted d ON d.MoeinId = i.MoeinId
    WHERE EXISTS (SELECT i.Countable EXCEPT SELECT d.Countable);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccMoein', i.MoeinId, i.Code + N' — ' + i.Title, N'IsFx', LEFT(CONVERT(nvarchar(2000), d.IsFx), 2000), LEFT(CONVERT(nvarchar(2000), i.IsFx), 2000)
    FROM inserted i JOIN deleted d ON d.MoeinId = i.MoeinId
    WHERE EXISTS (SELECT i.IsFx EXCEPT SELECT d.IsFx);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccMoein', i.MoeinId, i.Code + N' — ' + i.Title, N'FxConvertible', LEFT(CONVERT(nvarchar(2000), d.FxConvertible), 2000), LEFT(CONVERT(nvarchar(2000), i.FxConvertible), 2000)
    FROM inserted i JOIN deleted d ON d.MoeinId = i.MoeinId
    WHERE EXISTS (SELECT i.FxConvertible EXCEPT SELECT d.FxConvertible);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccMoein', i.MoeinId, i.Code + N' — ' + i.Title, N'IsActive', LEFT(CONVERT(nvarchar(2000), d.IsActive), 2000), LEFT(CONVERT(nvarchar(2000), i.IsActive), 2000)
    FROM inserted i JOIN deleted d ON d.MoeinId = i.MoeinId
    WHERE EXISTS (SELECT i.IsActive EXCEPT SELECT d.IsActive);
  END
  /* حذف — یک سطر برای هر رکورد */
  IF NOT EXISTS (SELECT 1 FROM inserted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 3, N'ACC', N'AccMoein', d.MoeinId, d.Code + N' — ' + d.Title, NULL, NULL, NULL
    FROM deleted d;
END
GO

-- ----------------------------------------------------------
-- تریگر لاگ: AccTafsiliType
-- ----------------------------------------------------------
CREATE OR ALTER TRIGGER ACC.Tr_ACC_AccTafsiliType_Audit ON ACC.AccTafsiliType
AFTER INSERT, UPDATE, DELETE AS
BEGIN
  SET NOCOUNT ON;
  /* ایجاد — یک سطر برای هر رکورد */
  IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 1, N'ACC', N'AccTafsiliType', i.TafsiliTypeId, i.Title
    FROM inserted i;
  /* ویرایش — یک سطر برای هر فیلد تغییر یافته */
  IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
  BEGIN
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccTafsiliType', i.TafsiliTypeId, i.Title, N'CompanyId', LEFT(CONVERT(nvarchar(2000), d.CompanyId), 2000), LEFT(CONVERT(nvarchar(2000), i.CompanyId), 2000)
    FROM inserted i JOIN deleted d ON d.TafsiliTypeId = i.TafsiliTypeId
    WHERE EXISTS (SELECT i.CompanyId EXCEPT SELECT d.CompanyId);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccTafsiliType', i.TafsiliTypeId, i.Title, N'Title', LEFT(CONVERT(nvarchar(2000), d.Title), 2000), LEFT(CONVERT(nvarchar(2000), i.Title), 2000)
    FROM inserted i JOIN deleted d ON d.TafsiliTypeId = i.TafsiliTypeId
    WHERE EXISTS (SELECT i.Title EXCEPT SELECT d.Title);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccTafsiliType', i.TafsiliTypeId, i.Title, N'LatinTitle', LEFT(CONVERT(nvarchar(2000), d.LatinTitle), 2000), LEFT(CONVERT(nvarchar(2000), i.LatinTitle), 2000)
    FROM inserted i JOIN deleted d ON d.TafsiliTypeId = i.TafsiliTypeId
    WHERE EXISTS (SELECT i.LatinTitle EXCEPT SELECT d.LatinTitle);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccTafsiliType', i.TafsiliTypeId, i.Title, N'CodeListType', LEFT(CONVERT(nvarchar(2000), d.CodeListType), 2000), LEFT(CONVERT(nvarchar(2000), i.CodeListType), 2000)
    FROM inserted i JOIN deleted d ON d.TafsiliTypeId = i.TafsiliTypeId
    WHERE EXISTS (SELECT i.CodeListType EXCEPT SELECT d.CodeListType);
  END
  /* حذف — یک سطر برای هر رکورد */
  IF NOT EXISTS (SELECT 1 FROM inserted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 3, N'ACC', N'AccTafsiliType', d.TafsiliTypeId, d.Title, NULL, NULL, NULL
    FROM deleted d;
END
GO

-- ----------------------------------------------------------
-- تریگر لاگ: AccTafsiliCategory
-- ----------------------------------------------------------
CREATE OR ALTER TRIGGER ACC.Tr_ACC_AccTafsiliCategory_Audit ON ACC.AccTafsiliCategory
AFTER INSERT, UPDATE, DELETE AS
BEGIN
  SET NOCOUNT ON;
  /* ایجاد — یک سطر برای هر رکورد */
  IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 1, N'ACC', N'AccTafsiliCategory', i.CategoryId, i.Title
    FROM inserted i;
  /* ویرایش — یک سطر برای هر فیلد تغییر یافته */
  IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
  BEGIN
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccTafsiliCategory', i.CategoryId, i.Title, N'CompanyId', LEFT(CONVERT(nvarchar(2000), d.CompanyId), 2000), LEFT(CONVERT(nvarchar(2000), i.CompanyId), 2000)
    FROM inserted i JOIN deleted d ON d.CategoryId = i.CategoryId
    WHERE EXISTS (SELECT i.CompanyId EXCEPT SELECT d.CompanyId);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccTafsiliCategory', i.CategoryId, i.Title, N'Title', LEFT(CONVERT(nvarchar(2000), d.Title), 2000), LEFT(CONVERT(nvarchar(2000), i.Title), 2000)
    FROM inserted i JOIN deleted d ON d.CategoryId = i.CategoryId
    WHERE EXISTS (SELECT i.Title EXCEPT SELECT d.Title);
  END
  /* حذف — یک سطر برای هر رکورد */
  IF NOT EXISTS (SELECT 1 FROM inserted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 3, N'ACC', N'AccTafsiliCategory', d.CategoryId, d.Title, NULL, NULL, NULL
    FROM deleted d;
END
GO

-- ----------------------------------------------------------
-- تریگر لاگ: AccTafsiliCategoryLink
-- ----------------------------------------------------------
CREATE OR ALTER TRIGGER ACC.Tr_ACC_AccTafsiliCategoryLink_Audit ON ACC.AccTafsiliCategoryLink
AFTER INSERT, UPDATE, DELETE AS
BEGIN
  SET NOCOUNT ON;
  /* ایجاد — یک سطر برای هر رکورد */
  IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 1, N'ACC', N'AccTafsiliCategoryLink', i.CategoryId, N'طبقهٔ ' + CONVERT(nvarchar(10), i.CategoryId) + N' / تفصیلی ' + CONVERT(nvarchar(10), i.TafsiliId)
    FROM inserted i;
  /* ویرایش — یک سطر برای هر فیلد تغییر یافته */
  IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
  BEGIN
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccTafsiliCategoryLink', i.CategoryId, N'طبقهٔ ' + CONVERT(nvarchar(10), i.CategoryId) + N' / تفصیلی ' + CONVERT(nvarchar(10), i.TafsiliId), N'CategoryId', LEFT(CONVERT(nvarchar(2000), d.CategoryId), 2000), LEFT(CONVERT(nvarchar(2000), i.CategoryId), 2000)
    FROM inserted i JOIN deleted d ON d.CategoryId = i.CategoryId AND d.TafsiliId = i.TafsiliId
    WHERE EXISTS (SELECT i.CategoryId EXCEPT SELECT d.CategoryId);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccTafsiliCategoryLink', i.CategoryId, N'طبقهٔ ' + CONVERT(nvarchar(10), i.CategoryId) + N' / تفصیلی ' + CONVERT(nvarchar(10), i.TafsiliId), N'TafsiliId', LEFT(CONVERT(nvarchar(2000), d.TafsiliId), 2000), LEFT(CONVERT(nvarchar(2000), i.TafsiliId), 2000)
    FROM inserted i JOIN deleted d ON d.CategoryId = i.CategoryId AND d.TafsiliId = i.TafsiliId
    WHERE EXISTS (SELECT i.TafsiliId EXCEPT SELECT d.TafsiliId);
  END
  /* حذف — یک سطر برای هر رکورد */
  IF NOT EXISTS (SELECT 1 FROM inserted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 3, N'ACC', N'AccTafsiliCategoryLink', d.CategoryId, N'طبقهٔ ' + CONVERT(nvarchar(10), d.CategoryId) + N' / تفصیلی ' + CONVERT(nvarchar(10), d.TafsiliId), NULL, NULL, NULL
    FROM deleted d;
END
GO

-- ----------------------------------------------------------
-- تریگر لاگ: AccTafsili
-- ----------------------------------------------------------
CREATE OR ALTER TRIGGER ACC.Tr_ACC_AccTafsili_Audit ON ACC.AccTafsili
AFTER INSERT, UPDATE, DELETE AS
BEGIN
  SET NOCOUNT ON;
  /* ایجاد — یک سطر برای هر رکورد */
  IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 1, N'ACC', N'AccTafsili', i.TafsiliId, i.Code + N' — ' + i.Title
    FROM inserted i;
  /* ویرایش — یک سطر برای هر فیلد تغییر یافته */
  IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
  BEGIN
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccTafsili', i.TafsiliId, i.Code + N' — ' + i.Title, N'CompanyId', LEFT(CONVERT(nvarchar(2000), d.CompanyId), 2000), LEFT(CONVERT(nvarchar(2000), i.CompanyId), 2000)
    FROM inserted i JOIN deleted d ON d.TafsiliId = i.TafsiliId
    WHERE EXISTS (SELECT i.CompanyId EXCEPT SELECT d.CompanyId);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccTafsili', i.TafsiliId, i.Code + N' — ' + i.Title, N'TafsiliTypeId', LEFT(CONVERT(nvarchar(2000), d.TafsiliTypeId), 2000), LEFT(CONVERT(nvarchar(2000), i.TafsiliTypeId), 2000)
    FROM inserted i JOIN deleted d ON d.TafsiliId = i.TafsiliId
    WHERE EXISTS (SELECT i.TafsiliTypeId EXCEPT SELECT d.TafsiliTypeId);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccTafsili', i.TafsiliId, i.Code + N' — ' + i.Title, N'Code', LEFT(CONVERT(nvarchar(2000), d.Code), 2000), LEFT(CONVERT(nvarchar(2000), i.Code), 2000)
    FROM inserted i JOIN deleted d ON d.TafsiliId = i.TafsiliId
    WHERE EXISTS (SELECT i.Code EXCEPT SELECT d.Code);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccTafsili', i.TafsiliId, i.Code + N' — ' + i.Title, N'Title', LEFT(CONVERT(nvarchar(2000), d.Title), 2000), LEFT(CONVERT(nvarchar(2000), i.Title), 2000)
    FROM inserted i JOIN deleted d ON d.TafsiliId = i.TafsiliId
    WHERE EXISTS (SELECT i.Title EXCEPT SELECT d.Title);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccTafsili', i.TafsiliId, i.Code + N' — ' + i.Title, N'LatinTitle', LEFT(CONVERT(nvarchar(2000), d.LatinTitle), 2000), LEFT(CONVERT(nvarchar(2000), i.LatinTitle), 2000)
    FROM inserted i JOIN deleted d ON d.TafsiliId = i.TafsiliId
    WHERE EXISTS (SELECT i.LatinTitle EXCEPT SELECT d.LatinTitle);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccTafsili', i.TafsiliId, i.Code + N' — ' + i.Title, N'IsActive', LEFT(CONVERT(nvarchar(2000), d.IsActive), 2000), LEFT(CONVERT(nvarchar(2000), i.IsActive), 2000)
    FROM inserted i JOIN deleted d ON d.TafsiliId = i.TafsiliId
    WHERE EXISTS (SELECT i.IsActive EXCEPT SELECT d.IsActive);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccTafsili', i.TafsiliId, i.Code + N' — ' + i.Title, N'PartyRef', LEFT(CONVERT(nvarchar(2000), d.PartyRef), 2000), LEFT(CONVERT(nvarchar(2000), i.PartyRef), 2000)
    FROM inserted i JOIN deleted d ON d.TafsiliId = i.TafsiliId
    WHERE EXISTS (SELECT i.PartyRef EXCEPT SELECT d.PartyRef);
  END
  /* حذف — یک سطر برای هر رکورد */
  IF NOT EXISTS (SELECT 1 FROM inserted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 3, N'ACC', N'AccTafsili', d.TafsiliId, d.Code + N' — ' + d.Title, NULL, NULL, NULL
    FROM deleted d;
END
GO

-- ----------------------------------------------------------
-- تریگر لاگ: AccStdNarration
-- ----------------------------------------------------------
CREATE OR ALTER TRIGGER ACC.Tr_ACC_AccStdNarration_Audit ON ACC.AccStdNarration
AFTER INSERT, UPDATE, DELETE AS
BEGIN
  SET NOCOUNT ON;
  /* ایجاد — یک سطر برای هر رکورد */
  IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 1, N'ACC', N'AccStdNarration', i.NarrationId, i.MoeinCode + N' — ' + LEFT(i.DescText, 50)
    FROM inserted i;
  /* ویرایش — یک سطر برای هر فیلد تغییر یافته */
  IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
  BEGIN
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccStdNarration', i.NarrationId, i.MoeinCode + N' — ' + LEFT(i.DescText, 50), N'CompanyId', LEFT(CONVERT(nvarchar(2000), d.CompanyId), 2000), LEFT(CONVERT(nvarchar(2000), i.CompanyId), 2000)
    FROM inserted i JOIN deleted d ON d.NarrationId = i.NarrationId
    WHERE EXISTS (SELECT i.CompanyId EXCEPT SELECT d.CompanyId);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccStdNarration', i.NarrationId, i.MoeinCode + N' — ' + LEFT(i.DescText, 50), N'MoeinCode', LEFT(CONVERT(nvarchar(2000), d.MoeinCode), 2000), LEFT(CONVERT(nvarchar(2000), i.MoeinCode), 2000)
    FROM inserted i JOIN deleted d ON d.NarrationId = i.NarrationId
    WHERE EXISTS (SELECT i.MoeinCode EXCEPT SELECT d.MoeinCode);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccStdNarration', i.NarrationId, i.MoeinCode + N' — ' + LEFT(i.DescText, 50), N'Seq', LEFT(CONVERT(nvarchar(2000), d.Seq), 2000), LEFT(CONVERT(nvarchar(2000), i.Seq), 2000)
    FROM inserted i JOIN deleted d ON d.NarrationId = i.NarrationId
    WHERE EXISTS (SELECT i.Seq EXCEPT SELECT d.Seq);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccStdNarration', i.NarrationId, i.MoeinCode + N' — ' + LEFT(i.DescText, 50), N'DescText', LEFT(CONVERT(nvarchar(2000), d.DescText), 2000), LEFT(CONVERT(nvarchar(2000), i.DescText), 2000)
    FROM inserted i JOIN deleted d ON d.NarrationId = i.NarrationId
    WHERE EXISTS (SELECT i.DescText EXCEPT SELECT d.DescText);
  END
  /* حذف — یک سطر برای هر رکورد */
  IF NOT EXISTS (SELECT 1 FROM inserted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 3, N'ACC', N'AccStdNarration', d.NarrationId, d.MoeinCode + N' — ' + LEFT(d.DescText, 50), NULL, NULL, NULL
    FROM deleted d;
END
GO

-- ----------------------------------------------------------
-- تریگر لاگ: AccOpeningBalance
-- ----------------------------------------------------------
CREATE OR ALTER TRIGGER ACC.Tr_ACC_AccOpeningBalance_Audit ON ACC.AccOpeningBalance
AFTER INSERT, UPDATE, DELETE AS
BEGIN
  SET NOCOUNT ON;
  /* ایجاد — یک سطر برای هر رکورد */
  IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 1, N'ACC', N'AccOpeningBalance', i.ObId, N'ماندهٔ ابتدای دوره — ' + i.KolCode + N'/' + i.MoeinCode
    FROM inserted i;
  /* ویرایش — یک سطر برای هر فیلد تغییر یافته */
  IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
  BEGIN
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccOpeningBalance', i.ObId, N'ماندهٔ ابتدای دوره — ' + i.KolCode + N'/' + i.MoeinCode, N'CompanyId', LEFT(CONVERT(nvarchar(2000), d.CompanyId), 2000), LEFT(CONVERT(nvarchar(2000), i.CompanyId), 2000)
    FROM inserted i JOIN deleted d ON d.ObId = i.ObId
    WHERE EXISTS (SELECT i.CompanyId EXCEPT SELECT d.CompanyId);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccOpeningBalance', i.ObId, N'ماندهٔ ابتدای دوره — ' + i.KolCode + N'/' + i.MoeinCode, N'YearId', LEFT(CONVERT(nvarchar(2000), d.YearId), 2000), LEFT(CONVERT(nvarchar(2000), i.YearId), 2000)
    FROM inserted i JOIN deleted d ON d.ObId = i.ObId
    WHERE EXISTS (SELECT i.YearId EXCEPT SELECT d.YearId);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccOpeningBalance', i.ObId, N'ماندهٔ ابتدای دوره — ' + i.KolCode + N'/' + i.MoeinCode, N'KolCode', LEFT(CONVERT(nvarchar(2000), d.KolCode), 2000), LEFT(CONVERT(nvarchar(2000), i.KolCode), 2000)
    FROM inserted i JOIN deleted d ON d.ObId = i.ObId
    WHERE EXISTS (SELECT i.KolCode EXCEPT SELECT d.KolCode);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccOpeningBalance', i.ObId, N'ماندهٔ ابتدای دوره — ' + i.KolCode + N'/' + i.MoeinCode, N'MoeinCode', LEFT(CONVERT(nvarchar(2000), d.MoeinCode), 2000), LEFT(CONVERT(nvarchar(2000), i.MoeinCode), 2000)
    FROM inserted i JOIN deleted d ON d.ObId = i.ObId
    WHERE EXISTS (SELECT i.MoeinCode EXCEPT SELECT d.MoeinCode);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccOpeningBalance', i.ObId, N'ماندهٔ ابتدای دوره — ' + i.KolCode + N'/' + i.MoeinCode, N'Taf1Id', LEFT(CONVERT(nvarchar(2000), d.Taf1Id), 2000), LEFT(CONVERT(nvarchar(2000), i.Taf1Id), 2000)
    FROM inserted i JOIN deleted d ON d.ObId = i.ObId
    WHERE EXISTS (SELECT i.Taf1Id EXCEPT SELECT d.Taf1Id);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccOpeningBalance', i.ObId, N'ماندهٔ ابتدای دوره — ' + i.KolCode + N'/' + i.MoeinCode, N'Taf2Id', LEFT(CONVERT(nvarchar(2000), d.Taf2Id), 2000), LEFT(CONVERT(nvarchar(2000), i.Taf2Id), 2000)
    FROM inserted i JOIN deleted d ON d.ObId = i.ObId
    WHERE EXISTS (SELECT i.Taf2Id EXCEPT SELECT d.Taf2Id);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccOpeningBalance', i.ObId, N'ماندهٔ ابتدای دوره — ' + i.KolCode + N'/' + i.MoeinCode, N'Taf3Id', LEFT(CONVERT(nvarchar(2000), d.Taf3Id), 2000), LEFT(CONVERT(nvarchar(2000), i.Taf3Id), 2000)
    FROM inserted i JOIN deleted d ON d.ObId = i.ObId
    WHERE EXISTS (SELECT i.Taf3Id EXCEPT SELECT d.Taf3Id);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccOpeningBalance', i.ObId, N'ماندهٔ ابتدای دوره — ' + i.KolCode + N'/' + i.MoeinCode, N'Dbt', LEFT(CONVERT(nvarchar(2000), d.Dbt), 2000), LEFT(CONVERT(nvarchar(2000), i.Dbt), 2000)
    FROM inserted i JOIN deleted d ON d.ObId = i.ObId
    WHERE EXISTS (SELECT i.Dbt EXCEPT SELECT d.Dbt);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccOpeningBalance', i.ObId, N'ماندهٔ ابتدای دوره — ' + i.KolCode + N'/' + i.MoeinCode, N'Crt', LEFT(CONVERT(nvarchar(2000), d.Crt), 2000), LEFT(CONVERT(nvarchar(2000), i.Crt), 2000)
    FROM inserted i JOIN deleted d ON d.ObId = i.ObId
    WHERE EXISTS (SELECT i.Crt EXCEPT SELECT d.Crt);
  END
  /* حذف — یک سطر برای هر رکورد */
  IF NOT EXISTS (SELECT 1 FROM inserted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 3, N'ACC', N'AccOpeningBalance', d.ObId, N'ماندهٔ ابتدای دوره — ' + d.KolCode + N'/' + d.MoeinCode, NULL, NULL, NULL
    FROM deleted d;
END
GO

-- ----------------------------------------------------------
-- تریگر لاگ: AccVoucherType
-- ----------------------------------------------------------
CREATE OR ALTER TRIGGER ACC.Tr_ACC_AccVoucherType_Audit ON ACC.AccVoucherType
AFTER INSERT, UPDATE, DELETE AS
BEGIN
  SET NOCOUNT ON;
  /* ایجاد — یک سطر برای هر رکورد */
  IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 1, N'ACC', N'AccVoucherType', i.VoucherTypeId, i.Title
    FROM inserted i;
  /* ویرایش — یک سطر برای هر فیلد تغییر یافته */
  IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
  BEGIN
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccVoucherType', i.VoucherTypeId, i.Title, N'CompanyId', LEFT(CONVERT(nvarchar(2000), d.CompanyId), 2000), LEFT(CONVERT(nvarchar(2000), i.CompanyId), 2000)
    FROM inserted i JOIN deleted d ON d.VoucherTypeId = i.VoucherTypeId
    WHERE EXISTS (SELECT i.CompanyId EXCEPT SELECT d.CompanyId);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccVoucherType', i.VoucherTypeId, i.Title, N'Title', LEFT(CONVERT(nvarchar(2000), d.Title), 2000), LEFT(CONVERT(nvarchar(2000), i.Title), 2000)
    FROM inserted i JOIN deleted d ON d.VoucherTypeId = i.VoucherTypeId
    WHERE EXISTS (SELECT i.Title EXCEPT SELECT d.Title);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'ACC', N'AccVoucherType', i.VoucherTypeId, i.Title, N'LatinTitle', LEFT(CONVERT(nvarchar(2000), d.LatinTitle), 2000), LEFT(CONVERT(nvarchar(2000), i.LatinTitle), 2000)
    FROM inserted i JOIN deleted d ON d.VoucherTypeId = i.VoucherTypeId
    WHERE EXISTS (SELECT i.LatinTitle EXCEPT SELECT d.LatinTitle);
  END
  /* حذف — یک سطر برای هر رکورد */
  IF NOT EXISTS (SELECT 1 FROM inserted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 3, N'ACC', N'AccVoucherType', d.VoucherTypeId, d.Title, NULL, NULL, NULL
    FROM deleted d;
END
GO

-- ----------------------------------------------------------
-- تریگر لاگ: AccVoucher
-- ----------------------------------------------------------
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
  END
  /* حذف — یک سطر برای هر رکورد */
  IF NOT EXISTS (SELECT 1 FROM inserted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 3, N'ACC', N'AccVoucher', d.VoucherId, N'سند شمارهٔ ' + CONVERT(nvarchar(10), d.VchNo) + N' — ' + d.VchDate, NULL, NULL, NULL
    FROM deleted d;
END
GO

-- ----------------------------------------------------------
-- تریگر لاگ: AccVoucherItm
-- ----------------------------------------------------------
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
  END
  /* حذف — یک سطر برای کل سند (تعداد ردیف) */
  IF NOT EXISTS (SELECT 1 FROM inserted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 3, N'ACC', N'AccVoucherItm', NULL, N'سند شمارهٔ ' + CONVERT(nvarchar(10), MIN(h.VchNo)) + N' — ' + CONVERT(nvarchar(10), COUNT(*)) + N' ردیف', NULL, NULL, NULL
    FROM deleted d JOIN ACC.AccVoucher h ON h.VoucherId = d.VoucherId
    GROUP BY d.VoucherId;
END
GO

-- ----------------------------------------------------------
-- تریگر لاگ: AppUser
-- ----------------------------------------------------------
CREATE OR ALTER TRIGGER pob.Tr_pob_AppUser_Audit ON pob.AppUser
AFTER INSERT, UPDATE, DELETE AS
BEGIN
  SET NOCOUNT ON;
  /* ایجاد — یک سطر برای هر رکورد */
  IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 1, N'pob', N'AppUser', i.UserId, CAST(i.Username AS nvarchar(64))
    FROM inserted i;
  /* ویرایش — یک سطر برای هر فیلد تغییر یافته */
  IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
  BEGIN
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'pob', N'AppUser', i.UserId, CAST(i.Username AS nvarchar(64)), N'Username', LEFT(CONVERT(nvarchar(2000), d.Username), 2000), LEFT(CONVERT(nvarchar(2000), i.Username), 2000)
    FROM inserted i JOIN deleted d ON d.UserId = i.UserId
    WHERE EXISTS (SELECT i.Username EXCEPT SELECT d.Username);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'pob', N'AppUser', i.UserId, CAST(i.Username AS nvarchar(64)), N'DisplayName', LEFT(CONVERT(nvarchar(2000), d.DisplayName), 2000), LEFT(CONVERT(nvarchar(2000), i.DisplayName), 2000)
    FROM inserted i JOIN deleted d ON d.UserId = i.UserId
    WHERE EXISTS (SELECT i.DisplayName EXCEPT SELECT d.DisplayName);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'pob', N'AppUser', i.UserId, CAST(i.Username AS nvarchar(64)), N'RoleCode', LEFT(CONVERT(nvarchar(2000), d.RoleCode), 2000), LEFT(CONVERT(nvarchar(2000), i.RoleCode), 2000)
    FROM inserted i JOIN deleted d ON d.UserId = i.UserId
    WHERE EXISTS (SELECT i.RoleCode EXCEPT SELECT d.RoleCode);
        INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'pob', N'AppUser', i.UserId, CAST(i.Username AS nvarchar(64)), N'IsActive', LEFT(CONVERT(nvarchar(2000), d.IsActive), 2000), LEFT(CONVERT(nvarchar(2000), i.IsActive), 2000)
    FROM inserted i JOIN deleted d ON d.UserId = i.UserId
    WHERE EXISTS (SELECT i.IsActive EXCEPT SELECT d.IsActive);
  END
  /* حذف — یک سطر برای هر رکورد */
  IF NOT EXISTS (SELECT 1 FROM inserted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 3, N'pob', N'AppUser', d.UserId, CAST(d.Username AS nvarchar(64)), NULL, NULL, NULL
    FROM deleted d;
END
GO

PRINT '=== UserLog layer deployed ===';
GO
