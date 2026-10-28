/* ============================================================================
   YFG ACC-WEB 1.1.0 - Part B: audit columns on existing tables
   Directive: audit fields on ALL tables (issuer/approver/editor/source-system/
   created-at/updated-at) + Jalali J companions. ASCII comments only (TDS safe).
   Sources: employer directive 2026-10-28 + ACC.AccVoucher original pattern.
   ============================================================================ */

-- pob.Companies
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('pob.Companies') AND name='CreatedBy')
  ALTER TABLE pob.Companies ADD CreatedBy varchar(50) NULL;
GO
UPDATE pob.Companies SET CreatedBy=N'system' WHERE CreatedBy IS NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('pob.Companies') AND name='CreatedBy')
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('pob.Companies') AND name='CreatedBy' AND is_nullable=1)
  ALTER TABLE pob.Companies ALTER COLUMN CreatedBy varchar(50) NOT NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('pob.Companies') AND name='UpdatedAt')
  ALTER TABLE pob.Companies ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('pob.Companies') AND name='SourceSystem')
  ALTER TABLE pob.Companies ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Companies_SourceSystem DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('pob.Companies') AND name='CreatedAtJ')
  ALTER TABLE pob.Companies ADD CreatedAtJ AS pob.GrgToJalali(CreatedAt), UpdatedAtJ AS pob.GrgToJalali(UpdatedAt);
GO

-- pob.AppUser
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('pob.AppUser') AND name='CreatedBy')
  ALTER TABLE pob.AppUser ADD CreatedBy varchar(50) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('pob.AppUser') AND name='CreatedBy')
BEGIN
  UPDATE pob.AppUser SET CreatedBy=N'system' WHERE CreatedBy IS NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('pob.AppUser') AND name='CreatedBy' AND is_nullable=1)
  ALTER TABLE pob.AppUser ALTER COLUMN CreatedBy varchar(50) NOT NULL;
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('pob.AppUser') AND name='UpdatedAt')
  ALTER TABLE pob.AppUser ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('pob.AppUser') AND name='SourceSystem')
  ALTER TABLE pob.AppUser ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_AppUser_SourceSystem DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('pob.AppUser') AND name='CreatedAtJ')
  ALTER TABLE pob.AppUser ADD CreatedAtJ AS pob.GrgToJalali(CreatedAt), UpdatedAtJ AS pob.GrgToJalali(UpdatedAt);
GO

-- pob.FiscalYear
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('pob.FiscalYear') AND name='CreatedBy')
  ALTER TABLE pob.FiscalYear ADD CreatedBy varchar(50) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('pob.FiscalYear') AND name='CreatedBy')
BEGIN
  UPDATE pob.FiscalYear SET CreatedBy=N'system' WHERE CreatedBy IS NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('pob.FiscalYear') AND name='CreatedBy' AND is_nullable=1)
  ALTER TABLE pob.FiscalYear ALTER COLUMN CreatedBy varchar(50) NOT NULL;
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('pob.FiscalYear') AND name='UpdatedAt')
  ALTER TABLE pob.FiscalYear ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('pob.FiscalYear') AND name='SourceSystem')
  ALTER TABLE pob.FiscalYear ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_FiscalYear_SourceSystem DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('pob.FiscalYear') AND name='CreatedAtJ')
  ALTER TABLE pob.FiscalYear ADD CreatedAtJ AS pob.GrgToJalali(CreatedAt), UpdatedAtJ AS pob.GrgToJalali(UpdatedAt);
GO

-- pob.FiscalPeriod
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('pob.FiscalPeriod') AND name='CreatedAt')
  ALTER TABLE pob.FiscalPeriod ADD CreatedBy varchar(50) NULL, CreatedAt datetime2(0) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('pob.FiscalPeriod') AND name='CreatedAt')
BEGIN
  UPDATE pob.FiscalPeriod SET CreatedBy=N'system', CreatedAt=SYSDATETIME() WHERE CreatedAt IS NULL OR CreatedBy IS NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('pob.FiscalPeriod') AND name='CreatedBy' AND is_nullable=1)
  ALTER TABLE pob.FiscalPeriod ALTER COLUMN CreatedBy varchar(50) NOT NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('pob.FiscalPeriod') AND name='CreatedAt' AND is_nullable=1)
  ALTER TABLE pob.FiscalPeriod ALTER COLUMN CreatedAt datetime2(0) NOT NULL;
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('pob.FiscalPeriod') AND name='UpdatedAt')
  ALTER TABLE pob.FiscalPeriod ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('pob.FiscalPeriod') AND name='SourceSystem')
  ALTER TABLE pob.FiscalPeriod ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_FiscalPeriod_SourceSystem DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('pob.FiscalPeriod') AND name='CreatedAtJ')
  ALTER TABLE pob.FiscalPeriod ADD CreatedAtJ AS pob.GrgToJalali(CreatedAt), UpdatedAtJ AS pob.GrgToJalali(UpdatedAt);
GO

-- ACC.AccGroup
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccGroup') AND name='CreatedAt')
  ALTER TABLE ACC.AccGroup ADD CreatedBy varchar(50) NULL, CreatedAt datetime2(0) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccGroup') AND name='CreatedAt')
BEGIN
  UPDATE ACC.AccGroup SET CreatedBy=N'system', CreatedAt=SYSDATETIME() WHERE CreatedAt IS NULL OR CreatedBy IS NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccGroup') AND name='CreatedBy' AND is_nullable=1)
  ALTER TABLE ACC.AccGroup ALTER COLUMN CreatedBy varchar(50) NOT NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccGroup') AND name='CreatedAt' AND is_nullable=1)
  ALTER TABLE ACC.AccGroup ALTER COLUMN CreatedAt datetime2(0) NOT NULL;
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccGroup') AND name='UpdatedAt')
  ALTER TABLE ACC.AccGroup ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccGroup') AND name='SourceSystem')
  ALTER TABLE ACC.AccGroup ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Acc_Group_SrcSys DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccGroup') AND name='CreatedAtJ')
  ALTER TABLE ACC.AccGroup ADD CreatedAtJ AS pob.GrgToJalali(CreatedAt), UpdatedAtJ AS pob.GrgToJalali(UpdatedAt);
GO

-- ACC.AccKol
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccKol') AND name='CreatedAt')
  ALTER TABLE ACC.AccKol ADD CreatedBy varchar(50) NULL, CreatedAt datetime2(0) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccKol') AND name='CreatedAt')
BEGIN
  UPDATE ACC.AccKol SET CreatedBy=N'system', CreatedAt=SYSDATETIME() WHERE CreatedAt IS NULL OR CreatedBy IS NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccKol') AND name='CreatedBy' AND is_nullable=1)
  ALTER TABLE ACC.AccKol ALTER COLUMN CreatedBy varchar(50) NOT NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccKol') AND name='CreatedAt' AND is_nullable=1)
  ALTER TABLE ACC.AccKol ALTER COLUMN CreatedAt datetime2(0) NOT NULL;
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccKol') AND name='UpdatedAt')
  ALTER TABLE ACC.AccKol ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccKol') AND name='SourceSystem')
  ALTER TABLE ACC.AccKol ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Acc_Kol_SrcSys DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccKol') AND name='CreatedAtJ')
  ALTER TABLE ACC.AccKol ADD CreatedAtJ AS pob.GrgToJalali(CreatedAt), UpdatedAtJ AS pob.GrgToJalali(UpdatedAt);
GO

-- ACC.AccMoein
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccMoein') AND name='CreatedAt')
  ALTER TABLE ACC.AccMoein ADD CreatedBy varchar(50) NULL, CreatedAt datetime2(0) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccMoein') AND name='CreatedAt')
BEGIN
  UPDATE ACC.AccMoein SET CreatedBy=N'system', CreatedAt=SYSDATETIME() WHERE CreatedAt IS NULL OR CreatedBy IS NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccMoein') AND name='CreatedBy' AND is_nullable=1)
  ALTER TABLE ACC.AccMoein ALTER COLUMN CreatedBy varchar(50) NOT NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccMoein') AND name='CreatedAt' AND is_nullable=1)
  ALTER TABLE ACC.AccMoein ALTER COLUMN CreatedAt datetime2(0) NOT NULL;
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccMoein') AND name='UpdatedAt')
  ALTER TABLE ACC.AccMoein ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccMoein') AND name='SourceSystem')
  ALTER TABLE ACC.AccMoein ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Acc_Moein_SrcSys DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccMoein') AND name='CreatedAtJ')
  ALTER TABLE ACC.AccMoein ADD CreatedAtJ AS pob.GrgToJalali(CreatedAt), UpdatedAtJ AS pob.GrgToJalali(UpdatedAt);
GO

-- ACC.AccTafsiliType
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccTafsiliType') AND name='CreatedBy')
  ALTER TABLE ACC.AccTafsiliType ADD CreatedBy varchar(50) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccTafsiliType') AND name='CreatedBy')
BEGIN
  UPDATE ACC.AccTafsiliType SET CreatedBy=N'system' WHERE CreatedBy IS NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccTafsiliType') AND name='CreatedBy' AND is_nullable=1)
  ALTER TABLE ACC.AccTafsiliType ALTER COLUMN CreatedBy varchar(50) NOT NULL;
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccTafsiliType') AND name='UpdatedAt')
  ALTER TABLE ACC.AccTafsiliType ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccTafsiliType') AND name='SourceSystem')
  ALTER TABLE ACC.AccTafsiliType ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Acc_TafsiliType_SrcSys DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccTafsiliType') AND name='CreatedAtJ')
  ALTER TABLE ACC.AccTafsiliType ADD CreatedAtJ AS pob.GrgToJalali(CreatedAt), UpdatedAtJ AS pob.GrgToJalali(UpdatedAt);
GO

-- ACC.AccTafsili
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccTafsili') AND name='CreatedBy')
  ALTER TABLE ACC.AccTafsili ADD CreatedBy varchar(50) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccTafsili') AND name='CreatedBy')
BEGIN
  UPDATE ACC.AccTafsili SET CreatedBy=N'system' WHERE CreatedBy IS NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccTafsili') AND name='CreatedBy' AND is_nullable=1)
  ALTER TABLE ACC.AccTafsili ALTER COLUMN CreatedBy varchar(50) NOT NULL;
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccTafsili') AND name='UpdatedAt')
  ALTER TABLE ACC.AccTafsili ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccTafsili') AND name='SourceSystem')
  ALTER TABLE ACC.AccTafsili ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Acc_Tafsili_SrcSys DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccTafsili') AND name='CreatedAtJ')
  ALTER TABLE ACC.AccTafsili ADD CreatedAtJ AS pob.GrgToJalali(CreatedAt), UpdatedAtJ AS pob.GrgToJalali(UpdatedAt);
GO

-- ACC.AccTafsiliCategory
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccTafsiliCategory') AND name='CreatedAt')
  ALTER TABLE ACC.AccTafsiliCategory ADD CreatedBy varchar(50) NULL, CreatedAt datetime2(0) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccTafsiliCategory') AND name='CreatedAt')
BEGIN
  UPDATE ACC.AccTafsiliCategory SET CreatedBy=N'system', CreatedAt=SYSDATETIME() WHERE CreatedAt IS NULL OR CreatedBy IS NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccTafsiliCategory') AND name='CreatedBy' AND is_nullable=1)
  ALTER TABLE ACC.AccTafsiliCategory ALTER COLUMN CreatedBy varchar(50) NOT NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccTafsiliCategory') AND name='CreatedAt' AND is_nullable=1)
  ALTER TABLE ACC.AccTafsiliCategory ALTER COLUMN CreatedAt datetime2(0) NOT NULL;
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccTafsiliCategory') AND name='UpdatedAt')
  ALTER TABLE ACC.AccTafsiliCategory ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccTafsiliCategory') AND name='SourceSystem')
  ALTER TABLE ACC.AccTafsiliCategory ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Acc_TafsiliCategory_SrcSys DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccTafsiliCategory') AND name='CreatedAtJ')
  ALTER TABLE ACC.AccTafsiliCategory ADD CreatedAtJ AS pob.GrgToJalali(CreatedAt), UpdatedAtJ AS pob.GrgToJalali(UpdatedAt);
GO

-- ACC.AccStdNarration
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccStdNarration') AND name='CreatedAt')
  ALTER TABLE ACC.AccStdNarration ADD CreatedBy varchar(50) NULL, CreatedAt datetime2(0) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccStdNarration') AND name='CreatedAt')
BEGIN
  UPDATE ACC.AccStdNarration SET CreatedBy=N'system', CreatedAt=SYSDATETIME() WHERE CreatedAt IS NULL OR CreatedBy IS NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccStdNarration') AND name='CreatedBy' AND is_nullable=1)
  ALTER TABLE ACC.AccStdNarration ALTER COLUMN CreatedBy varchar(50) NOT NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccStdNarration') AND name='CreatedAt' AND is_nullable=1)
  ALTER TABLE ACC.AccStdNarration ALTER COLUMN CreatedAt datetime2(0) NOT NULL;
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccStdNarration') AND name='UpdatedAt')
  ALTER TABLE ACC.AccStdNarration ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccStdNarration') AND name='SourceSystem')
  ALTER TABLE ACC.AccStdNarration ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Acc_StdNarration_SrcSys DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccStdNarration') AND name='CreatedAtJ')
  ALTER TABLE ACC.AccStdNarration ADD CreatedAtJ AS pob.GrgToJalali(CreatedAt), UpdatedAtJ AS pob.GrgToJalali(UpdatedAt);
GO

-- ACC.AccOpeningBalance
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccOpeningBalance') AND name='CreatedAt')
  ALTER TABLE ACC.AccOpeningBalance ADD CreatedBy varchar(50) NULL, CreatedAt datetime2(0) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccOpeningBalance') AND name='CreatedAt')
BEGIN
  UPDATE ACC.AccOpeningBalance SET CreatedBy=N'system', CreatedAt=SYSDATETIME() WHERE CreatedAt IS NULL OR CreatedBy IS NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccOpeningBalance') AND name='CreatedBy' AND is_nullable=1)
  ALTER TABLE ACC.AccOpeningBalance ALTER COLUMN CreatedBy varchar(50) NOT NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccOpeningBalance') AND name='CreatedAt' AND is_nullable=1)
  ALTER TABLE ACC.AccOpeningBalance ALTER COLUMN CreatedAt datetime2(0) NOT NULL;
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccOpeningBalance') AND name='UpdatedAt')
  ALTER TABLE ACC.AccOpeningBalance ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccOpeningBalance') AND name='SourceSystem')
  ALTER TABLE ACC.AccOpeningBalance ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Acc_OB_SrcSys DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccOpeningBalance') AND name='CreatedAtJ')
  ALTER TABLE ACC.AccOpeningBalance ADD CreatedAtJ AS pob.GrgToJalali(CreatedAt), UpdatedAtJ AS pob.GrgToJalali(UpdatedAt);
GO

-- ACC.AccVoucherType
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccVoucherType') AND name='CreatedAt')
  ALTER TABLE ACC.AccVoucherType ADD CreatedBy varchar(50) NULL, CreatedAt datetime2(0) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccVoucherType') AND name='CreatedAt')
BEGIN
  UPDATE ACC.AccVoucherType SET CreatedBy=N'system', CreatedAt=SYSDATETIME() WHERE CreatedAt IS NULL OR CreatedBy IS NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccVoucherType') AND name='CreatedBy' AND is_nullable=1)
  ALTER TABLE ACC.AccVoucherType ALTER COLUMN CreatedBy varchar(50) NOT NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccVoucherType') AND name='CreatedAt' AND is_nullable=1)
  ALTER TABLE ACC.AccVoucherType ALTER COLUMN CreatedAt datetime2(0) NOT NULL;
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccVoucherType') AND name='UpdatedAt')
  ALTER TABLE ACC.AccVoucherType ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccVoucherType') AND name='SourceSystem')
  ALTER TABLE ACC.AccVoucherType ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_AccVoucherType_SourceSystem DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccVoucherType') AND name='CreatedAtJ')
  ALTER TABLE ACC.AccVoucherType ADD CreatedAtJ AS pob.GrgToJalali(CreatedAt), UpdatedAtJ AS pob.GrgToJalali(UpdatedAt);
GO

-- ACC.AccVoucher: Updated + Edited + SourceSystem (audit standard: ALL tables)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccVoucher') AND name='SourceSystem')
  ALTER TABLE ACC.AccVoucher ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_AccVoucher_SourceSystem DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccVoucher') AND name='UpdatedAt')
  ALTER TABLE ACC.AccVoucher ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccVoucher') AND name='EditedBy')
  ALTER TABLE ACC.AccVoucher ADD EditedBy varchar(50) NULL, EditedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccVoucher') AND name='CreatedAtJ')
  ALTER TABLE ACC.AccVoucher ADD CreatedAtJ AS pob.GrgToJalali(CreatedAt), UpdatedAtJ AS pob.GrgToJalali(UpdatedAt),
    CheckedAtJ AS pob.GrgToJalali(CheckedAt), FinalizedAtJ AS pob.GrgToJalali(FinalizedAt), EditedAtJ AS pob.GrgToJalali(EditedAt);
GO

-- ACC.AccVoucherItm
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccVoucherItm') AND name='CreatedAt')
  ALTER TABLE ACC.AccVoucherItm ADD CreatedBy varchar(50) NULL, CreatedAt datetime2(0) NULL;
GO
-- ACC.AccVoucherItm: audit stays NULLABLE - rows of reviewed/final vouchers are guarded
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccVoucherItm') AND name='CreatedBy')
  ALTER TABLE ACC.AccVoucherItm ADD CreatedBy varchar(50) NULL, CreatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccVoucherItm') AND name='UpdatedAt')
  ALTER TABLE ACC.AccVoucherItm ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccVoucherItm') AND name='SourceSystem')
  ALTER TABLE ACC.AccVoucherItm ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_AccVoucherItm_SourceSystem DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccVoucherItm') AND name='CreatedAtJ')
  ALTER TABLE ACC.AccVoucherItm ADD CreatedAtJ AS pob.GrgToJalali(CreatedAt), UpdatedAtJ AS pob.GrgToJalali(UpdatedAt);
GO

-- ACC.AccVoucherFlow: only J companion
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccVoucherFlow') AND name='AtJ')
  ALTER TABLE ACC.AccVoucherFlow ADD AtJ AS pob.GrgToJalali(At);
GO

-- ACC.AccTafsiliCategoryLink (audit standard: ALL tables)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccTafsiliCategoryLink') AND name='CreatedBy')
  ALTER TABLE ACC.AccTafsiliCategoryLink ADD CreatedBy varchar(50) NOT NULL CONSTRAINT DF_AccTafsiliCategoryLink_CreatedBy DEFAULT('system'), CreatedAt datetime2(0) NOT NULL CONSTRAINT DF_AccTafsiliCategoryLink_CreatedAt DEFAULT(SYSDATETIME());
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccTafsiliCategoryLink') AND name='UpdatedAt')
  ALTER TABLE ACC.AccTafsiliCategoryLink ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccTafsiliCategoryLink') AND name='SourceSystem')
  ALTER TABLE ACC.AccTafsiliCategoryLink ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_AccTafsiliCategoryLink_SourceSystem DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccTafsiliCategoryLink') AND name='CreatedAtJ')
  ALTER TABLE ACC.AccTafsiliCategoryLink ADD CreatedAtJ AS pob.GrgToJalali(CreatedAt), UpdatedAtJ AS pob.GrgToJalali(UpdatedAt);
GO

-- Defaults for CreatedBy/CreatedAt on every audited table (same standard as pob)
DECLARE @df varchar(200), @t varchar(120), @col sysname, @src nvarchar(60);
DECLARE c CURSOR FOR
  SELECT OBJECT_SCHEMA_NAME(c.object_id)+'.'+OBJECT_NAME(c.object_id),
    CASE c.name WHEN 'CreatedBy' THEN '''system''' ELSE 'SYSDATETIME()' END,
    c.name, 'DF_'+OBJECT_NAME(c.object_id)+'_'+c.name
  FROM sys.columns c
  WHERE c.name IN ('CreatedBy','CreatedAt')
    AND OBJECT_SCHEMA_NAME(c.object_id) IN ('ACC','pob')
    AND NOT EXISTS (SELECT 1 FROM sys.default_constraints d WHERE d.parent_object_id=c.object_id AND d.parent_column_id=c.column_id);
OPEN c; FETCH NEXT FROM c INTO @t, @src, @col, @df;
WHILE @@FETCH_STATUS=0 BEGIN
  EXEC('ALTER TABLE '+@t+' ADD CONSTRAINT '+@df+' DEFAULT('+@src+') FOR '+@col+';');
  FETCH NEXT FROM c INTO @t, @src, @col, @df;
END; CLOSE c; DEALLOCATE c;
GO
PRINT '=== audit defaults done ===';
GO
