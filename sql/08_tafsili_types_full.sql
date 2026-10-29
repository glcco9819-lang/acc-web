/* ============================================================
   08_tafsili_types_full.sql — v2.4.3
   تکمیل انواع تفصیل بر اساس فایل اولیه (سامانهٔ مبدأ YFG/SG) و سند ۹۰ (معماری هدف وب)
   - ستون‌های مرجع مبدأ در ACC.AccTafsili: BranchRef (ACC.AccBranch) و ListRef (pob.CodeList)
   - انواع استاندارد کامل برای هر شرکت موجود:
     مشتری/تأمین‌کننده (PARTY) · بانک (BANK) · شعبه (BRANCH) · پروژه (PROJECT) ·
     صندوق (CASH) · مرکز هزینه (COSTCENTER) · کارمند (EMPLOYEE) · کالا (GOODS) ·
     چک (CHECK) · اعتبارات اسنادی (LC) · سایر (بدون مبدأ = عنوان آزاد)
   Idempotent — اجرای مجدد بی‌اثر است.
   ============================================================ */
IF COL_LENGTH('ACC.AccTafsili','BranchRef') IS NULL
  ALTER TABLE ACC.AccTafsili ADD BranchRef int NULL;
IF COL_LENGTH('ACC.AccTafsili','ListRef') IS NULL
  ALTER TABLE ACC.AccTafsili ADD ListRef bigint NULL;
GO

/* پروژه → فهرست پروژه‌ها (فقط اگر مبدأ خالی است) */
UPDATE ACC.AccTafsiliType SET CodeListType='PROJECT', UpdatedBy='system', UpdatedAt=SYSDATETIME()
  WHERE CodeListType IS NULL AND Title = N'پروژه';
GO

/* انواع استاندارد کامل — برای هر شرکتی که انواع تفصیل دارد */
DECLARE @co smallint;
DECLARE @t nvarchar(100); DECLARE @l varchar(100); DECLARE @c varchar(40);
DECLARE cs CURSOR LOCAL FAST_FORWARD FOR SELECT DISTINCT CompanyId FROM ACC.AccTafsiliType;
OPEN cs; FETCH NEXT FROM cs INTO @co;
WHILE @@FETCH_STATUS = 0
BEGIN
  DECLARE v CURSOR LOCAL FAST_FORWARD FOR
    SELECT * FROM (VALUES
      (N'صندوق',           'Cash',           'CASH'),
      (N'مرکز هزینه',      'CostCenter',     'COSTCENTER'),
      (N'کارمند',          'Employee',       'EMPLOYEE'),
      (N'کالا',            'Goods',          'GOODS'),
      (N'چک',              'Check',          'CHECK'),
      (N'اعتبارات اسنادی', 'LetterOfCredit', 'LC'),
      (N'سایر',            'Other',          CAST(NULL AS varchar(40)))
    ) s(fa, la, clt);
  OPEN v; FETCH NEXT FROM v INTO @t, @l, @c;
  WHILE @@FETCH_STATUS = 0
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM ACC.AccTafsiliType WHERE CompanyId=@co AND Title=@t)
      INSERT INTO ACC.AccTafsiliType (CompanyId, Title, LatinTitle, CodeListType, CreatedBy, CreatedAt, SourceSystem)
      VALUES (@co, @t, @l, @c, 'system', SYSDATETIME(), 'ACCWEB');
    FETCH NEXT FROM v INTO @t, @l, @c;
  END
  CLOSE v; DEALLOCATE v;
  FETCH NEXT FROM cs INTO @co;
END
CLOSE cs; DEALLOCATE cs;
GO
