/* ============================================================================
   YFG ACC-WEB 1.1.0 - Part B: audit columns on existing tables
   Directive: audit fields on ALL tables (issuer/approver/editor/source-system/
   created-at/updated-at) + Jalali J companions. ASCII comments only (TDS safe).
   Sources: employer directive 2026-10-28 + YfgVch.Voucher original pattern.
   ============================================================================ */

-- YfgPrm.Company
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgPrm.Company') AND name='CreatedBy')
  ALTER TABLE YfgPrm.Company ADD CreatedBy varchar(50) NULL;
GO
UPDATE YfgPrm.Company SET CreatedBy=N'system' WHERE CreatedBy IS NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgPrm.Company') AND name='CreatedBy')
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgPrm.Company') AND name='CreatedBy' AND is_nullable=1)
  ALTER TABLE YfgPrm.Company ALTER COLUMN CreatedBy varchar(50) NOT NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgPrm.Company') AND name='UpdatedAt')
  ALTER TABLE YfgPrm.Company ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgPrm.Company') AND name='SourceSystem')
  ALTER TABLE YfgPrm.Company ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Prm_Company_SrcSys DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgPrm.Company') AND name='CreatedAtJ')
  ALTER TABLE YfgPrm.Company ADD CreatedAtJ AS YfgGen.GrgToJalali(CreatedAt), UpdatedAtJ AS YfgGen.GrgToJalali(UpdatedAt);
GO

-- YfgPrm.AppUser
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgPrm.AppUser') AND name='CreatedBy')
  ALTER TABLE YfgPrm.AppUser ADD CreatedBy varchar(50) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgPrm.AppUser') AND name='CreatedBy')
BEGIN
  UPDATE YfgPrm.AppUser SET CreatedBy=N'system' WHERE CreatedBy IS NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgPrm.AppUser') AND name='CreatedBy' AND is_nullable=1)
  ALTER TABLE YfgPrm.AppUser ALTER COLUMN CreatedBy varchar(50) NOT NULL;
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgPrm.AppUser') AND name='UpdatedAt')
  ALTER TABLE YfgPrm.AppUser ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgPrm.AppUser') AND name='SourceSystem')
  ALTER TABLE YfgPrm.AppUser ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Prm_AppUser_SrcSys DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgPrm.AppUser') AND name='CreatedAtJ')
  ALTER TABLE YfgPrm.AppUser ADD CreatedAtJ AS YfgGen.GrgToJalali(CreatedAt), UpdatedAtJ AS YfgGen.GrgToJalali(UpdatedAt);
GO

-- YfgPrm.FiscalYear
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgPrm.FiscalYear') AND name='CreatedBy')
  ALTER TABLE YfgPrm.FiscalYear ADD CreatedBy varchar(50) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgPrm.FiscalYear') AND name='CreatedBy')
BEGIN
  UPDATE YfgPrm.FiscalYear SET CreatedBy=N'system' WHERE CreatedBy IS NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgPrm.FiscalYear') AND name='CreatedBy' AND is_nullable=1)
  ALTER TABLE YfgPrm.FiscalYear ALTER COLUMN CreatedBy varchar(50) NOT NULL;
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgPrm.FiscalYear') AND name='UpdatedAt')
  ALTER TABLE YfgPrm.FiscalYear ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgPrm.FiscalYear') AND name='SourceSystem')
  ALTER TABLE YfgPrm.FiscalYear ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Prm_FiscalYear_SrcSys DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgPrm.FiscalYear') AND name='CreatedAtJ')
  ALTER TABLE YfgPrm.FiscalYear ADD CreatedAtJ AS YfgGen.GrgToJalali(CreatedAt), UpdatedAtJ AS YfgGen.GrgToJalali(UpdatedAt);
GO

-- YfgPrm.FiscalPeriod
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgPrm.FiscalPeriod') AND name='CreatedAt')
  ALTER TABLE YfgPrm.FiscalPeriod ADD CreatedBy varchar(50) NULL, CreatedAt datetime2(0) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgPrm.FiscalPeriod') AND name='CreatedAt')
BEGIN
  UPDATE YfgPrm.FiscalPeriod SET CreatedBy=N'system', CreatedAt=SYSDATETIME() WHERE CreatedAt IS NULL OR CreatedBy IS NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgPrm.FiscalPeriod') AND name='CreatedBy' AND is_nullable=1)
  ALTER TABLE YfgPrm.FiscalPeriod ALTER COLUMN CreatedBy varchar(50) NOT NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgPrm.FiscalPeriod') AND name='CreatedAt' AND is_nullable=1)
  ALTER TABLE YfgPrm.FiscalPeriod ALTER COLUMN CreatedAt datetime2(0) NOT NULL;
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgPrm.FiscalPeriod') AND name='UpdatedAt')
  ALTER TABLE YfgPrm.FiscalPeriod ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgPrm.FiscalPeriod') AND name='SourceSystem')
  ALTER TABLE YfgPrm.FiscalPeriod ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Prm_FiscalPeriod_SrcSys DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgPrm.FiscalPeriod') AND name='CreatedAtJ')
  ALTER TABLE YfgPrm.FiscalPeriod ADD CreatedAtJ AS YfgGen.GrgToJalali(CreatedAt), UpdatedAtJ AS YfgGen.GrgToJalali(UpdatedAt);
GO

-- YfgAcc.AccGroup
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.AccGroup') AND name='CreatedAt')
  ALTER TABLE YfgAcc.AccGroup ADD CreatedBy varchar(50) NULL, CreatedAt datetime2(0) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.AccGroup') AND name='CreatedAt')
BEGIN
  UPDATE YfgAcc.AccGroup SET CreatedBy=N'system', CreatedAt=SYSDATETIME() WHERE CreatedAt IS NULL OR CreatedBy IS NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.AccGroup') AND name='CreatedBy' AND is_nullable=1)
  ALTER TABLE YfgAcc.AccGroup ALTER COLUMN CreatedBy varchar(50) NOT NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.AccGroup') AND name='CreatedAt' AND is_nullable=1)
  ALTER TABLE YfgAcc.AccGroup ALTER COLUMN CreatedAt datetime2(0) NOT NULL;
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.AccGroup') AND name='UpdatedAt')
  ALTER TABLE YfgAcc.AccGroup ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.AccGroup') AND name='SourceSystem')
  ALTER TABLE YfgAcc.AccGroup ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Acc_Group_SrcSys DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.AccGroup') AND name='CreatedAtJ')
  ALTER TABLE YfgAcc.AccGroup ADD CreatedAtJ AS YfgGen.GrgToJalali(CreatedAt), UpdatedAtJ AS YfgGen.GrgToJalali(UpdatedAt);
GO

-- YfgAcc.Kol
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.Kol') AND name='CreatedAt')
  ALTER TABLE YfgAcc.Kol ADD CreatedBy varchar(50) NULL, CreatedAt datetime2(0) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.Kol') AND name='CreatedAt')
BEGIN
  UPDATE YfgAcc.Kol SET CreatedBy=N'system', CreatedAt=SYSDATETIME() WHERE CreatedAt IS NULL OR CreatedBy IS NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.Kol') AND name='CreatedBy' AND is_nullable=1)
  ALTER TABLE YfgAcc.Kol ALTER COLUMN CreatedBy varchar(50) NOT NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.Kol') AND name='CreatedAt' AND is_nullable=1)
  ALTER TABLE YfgAcc.Kol ALTER COLUMN CreatedAt datetime2(0) NOT NULL;
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.Kol') AND name='UpdatedAt')
  ALTER TABLE YfgAcc.Kol ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.Kol') AND name='SourceSystem')
  ALTER TABLE YfgAcc.Kol ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Acc_Kol_SrcSys DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.Kol') AND name='CreatedAtJ')
  ALTER TABLE YfgAcc.Kol ADD CreatedAtJ AS YfgGen.GrgToJalali(CreatedAt), UpdatedAtJ AS YfgGen.GrgToJalali(UpdatedAt);
GO

-- YfgAcc.Moein
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.Moein') AND name='CreatedAt')
  ALTER TABLE YfgAcc.Moein ADD CreatedBy varchar(50) NULL, CreatedAt datetime2(0) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.Moein') AND name='CreatedAt')
BEGIN
  UPDATE YfgAcc.Moein SET CreatedBy=N'system', CreatedAt=SYSDATETIME() WHERE CreatedAt IS NULL OR CreatedBy IS NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.Moein') AND name='CreatedBy' AND is_nullable=1)
  ALTER TABLE YfgAcc.Moein ALTER COLUMN CreatedBy varchar(50) NOT NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.Moein') AND name='CreatedAt' AND is_nullable=1)
  ALTER TABLE YfgAcc.Moein ALTER COLUMN CreatedAt datetime2(0) NOT NULL;
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.Moein') AND name='UpdatedAt')
  ALTER TABLE YfgAcc.Moein ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.Moein') AND name='SourceSystem')
  ALTER TABLE YfgAcc.Moein ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Acc_Moein_SrcSys DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.Moein') AND name='CreatedAtJ')
  ALTER TABLE YfgAcc.Moein ADD CreatedAtJ AS YfgGen.GrgToJalali(CreatedAt), UpdatedAtJ AS YfgGen.GrgToJalali(UpdatedAt);
GO

-- YfgAcc.TafsiliType
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.TafsiliType') AND name='CreatedBy')
  ALTER TABLE YfgAcc.TafsiliType ADD CreatedBy varchar(50) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.TafsiliType') AND name='CreatedBy')
BEGIN
  UPDATE YfgAcc.TafsiliType SET CreatedBy=N'system' WHERE CreatedBy IS NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.TafsiliType') AND name='CreatedBy' AND is_nullable=1)
  ALTER TABLE YfgAcc.TafsiliType ALTER COLUMN CreatedBy varchar(50) NOT NULL;
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.TafsiliType') AND name='UpdatedAt')
  ALTER TABLE YfgAcc.TafsiliType ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.TafsiliType') AND name='SourceSystem')
  ALTER TABLE YfgAcc.TafsiliType ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Acc_TafsiliType_SrcSys DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.TafsiliType') AND name='CreatedAtJ')
  ALTER TABLE YfgAcc.TafsiliType ADD CreatedAtJ AS YfgGen.GrgToJalali(CreatedAt), UpdatedAtJ AS YfgGen.GrgToJalali(UpdatedAt);
GO

-- YfgAcc.Tafsili
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.Tafsili') AND name='CreatedBy')
  ALTER TABLE YfgAcc.Tafsili ADD CreatedBy varchar(50) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.Tafsili') AND name='CreatedBy')
BEGIN
  UPDATE YfgAcc.Tafsili SET CreatedBy=N'system' WHERE CreatedBy IS NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.Tafsili') AND name='CreatedBy' AND is_nullable=1)
  ALTER TABLE YfgAcc.Tafsili ALTER COLUMN CreatedBy varchar(50) NOT NULL;
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.Tafsili') AND name='UpdatedAt')
  ALTER TABLE YfgAcc.Tafsili ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.Tafsili') AND name='SourceSystem')
  ALTER TABLE YfgAcc.Tafsili ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Acc_Tafsili_SrcSys DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.Tafsili') AND name='CreatedAtJ')
  ALTER TABLE YfgAcc.Tafsili ADD CreatedAtJ AS YfgGen.GrgToJalali(CreatedAt), UpdatedAtJ AS YfgGen.GrgToJalali(UpdatedAt);
GO

-- YfgAcc.TafsiliCategory
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.TafsiliCategory') AND name='CreatedAt')
  ALTER TABLE YfgAcc.TafsiliCategory ADD CreatedBy varchar(50) NULL, CreatedAt datetime2(0) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.TafsiliCategory') AND name='CreatedAt')
BEGIN
  UPDATE YfgAcc.TafsiliCategory SET CreatedBy=N'system', CreatedAt=SYSDATETIME() WHERE CreatedAt IS NULL OR CreatedBy IS NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.TafsiliCategory') AND name='CreatedBy' AND is_nullable=1)
  ALTER TABLE YfgAcc.TafsiliCategory ALTER COLUMN CreatedBy varchar(50) NOT NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.TafsiliCategory') AND name='CreatedAt' AND is_nullable=1)
  ALTER TABLE YfgAcc.TafsiliCategory ALTER COLUMN CreatedAt datetime2(0) NOT NULL;
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.TafsiliCategory') AND name='UpdatedAt')
  ALTER TABLE YfgAcc.TafsiliCategory ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.TafsiliCategory') AND name='SourceSystem')
  ALTER TABLE YfgAcc.TafsiliCategory ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Acc_TafsiliCategory_SrcSys DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.TafsiliCategory') AND name='CreatedAtJ')
  ALTER TABLE YfgAcc.TafsiliCategory ADD CreatedAtJ AS YfgGen.GrgToJalali(CreatedAt), UpdatedAtJ AS YfgGen.GrgToJalali(UpdatedAt);
GO

-- YfgAcc.StdNarration
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.StdNarration') AND name='CreatedAt')
  ALTER TABLE YfgAcc.StdNarration ADD CreatedBy varchar(50) NULL, CreatedAt datetime2(0) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.StdNarration') AND name='CreatedAt')
BEGIN
  UPDATE YfgAcc.StdNarration SET CreatedBy=N'system', CreatedAt=SYSDATETIME() WHERE CreatedAt IS NULL OR CreatedBy IS NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.StdNarration') AND name='CreatedBy' AND is_nullable=1)
  ALTER TABLE YfgAcc.StdNarration ALTER COLUMN CreatedBy varchar(50) NOT NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.StdNarration') AND name='CreatedAt' AND is_nullable=1)
  ALTER TABLE YfgAcc.StdNarration ALTER COLUMN CreatedAt datetime2(0) NOT NULL;
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.StdNarration') AND name='UpdatedAt')
  ALTER TABLE YfgAcc.StdNarration ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.StdNarration') AND name='SourceSystem')
  ALTER TABLE YfgAcc.StdNarration ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Acc_StdNarration_SrcSys DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.StdNarration') AND name='CreatedAtJ')
  ALTER TABLE YfgAcc.StdNarration ADD CreatedAtJ AS YfgGen.GrgToJalali(CreatedAt), UpdatedAtJ AS YfgGen.GrgToJalali(UpdatedAt);
GO

-- YfgAcc.OpeningBalance
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.OpeningBalance') AND name='CreatedAt')
  ALTER TABLE YfgAcc.OpeningBalance ADD CreatedBy varchar(50) NULL, CreatedAt datetime2(0) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.OpeningBalance') AND name='CreatedAt')
BEGIN
  UPDATE YfgAcc.OpeningBalance SET CreatedBy=N'system', CreatedAt=SYSDATETIME() WHERE CreatedAt IS NULL OR CreatedBy IS NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.OpeningBalance') AND name='CreatedBy' AND is_nullable=1)
  ALTER TABLE YfgAcc.OpeningBalance ALTER COLUMN CreatedBy varchar(50) NOT NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.OpeningBalance') AND name='CreatedAt' AND is_nullable=1)
  ALTER TABLE YfgAcc.OpeningBalance ALTER COLUMN CreatedAt datetime2(0) NOT NULL;
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.OpeningBalance') AND name='UpdatedAt')
  ALTER TABLE YfgAcc.OpeningBalance ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.OpeningBalance') AND name='SourceSystem')
  ALTER TABLE YfgAcc.OpeningBalance ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Acc_OB_SrcSys DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.OpeningBalance') AND name='CreatedAtJ')
  ALTER TABLE YfgAcc.OpeningBalance ADD CreatedAtJ AS YfgGen.GrgToJalali(CreatedAt), UpdatedAtJ AS YfgGen.GrgToJalali(UpdatedAt);
GO

-- YfgVch.VoucherType
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgVch.VoucherType') AND name='CreatedAt')
  ALTER TABLE YfgVch.VoucherType ADD CreatedBy varchar(50) NULL, CreatedAt datetime2(0) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgVch.VoucherType') AND name='CreatedAt')
BEGIN
  UPDATE YfgVch.VoucherType SET CreatedBy=N'system', CreatedAt=SYSDATETIME() WHERE CreatedAt IS NULL OR CreatedBy IS NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgVch.VoucherType') AND name='CreatedBy' AND is_nullable=1)
  ALTER TABLE YfgVch.VoucherType ALTER COLUMN CreatedBy varchar(50) NOT NULL;
  IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgVch.VoucherType') AND name='CreatedAt' AND is_nullable=1)
  ALTER TABLE YfgVch.VoucherType ALTER COLUMN CreatedAt datetime2(0) NOT NULL;
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgVch.VoucherType') AND name='UpdatedAt')
  ALTER TABLE YfgVch.VoucherType ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgVch.VoucherType') AND name='SourceSystem')
  ALTER TABLE YfgVch.VoucherType ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Vch_Type_SrcSys DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgVch.VoucherType') AND name='CreatedAtJ')
  ALTER TABLE YfgVch.VoucherType ADD CreatedAtJ AS YfgGen.GrgToJalali(CreatedAt), UpdatedAtJ AS YfgGen.GrgToJalali(UpdatedAt);
GO

-- YfgVch.Voucher: Updated + Edited + SourceSystem (audit standard: ALL tables)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgVch.Voucher') AND name='SourceSystem')
  ALTER TABLE YfgVch.Voucher ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_YfgVch_Voucher_SrcSys DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgVch.Voucher') AND name='UpdatedAt')
  ALTER TABLE YfgVch.Voucher ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgVch.Voucher') AND name='EditedBy')
  ALTER TABLE YfgVch.Voucher ADD EditedBy varchar(50) NULL, EditedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgVch.Voucher') AND name='CreatedAtJ')
  ALTER TABLE YfgVch.Voucher ADD CreatedAtJ AS YfgGen.GrgToJalali(CreatedAt), UpdatedAtJ AS YfgGen.GrgToJalali(UpdatedAt),
    CheckedAtJ AS YfgGen.GrgToJalali(CheckedAt), FinalizedAtJ AS YfgGen.GrgToJalali(FinalizedAt), EditedAtJ AS YfgGen.GrgToJalali(EditedAt);
GO

-- YfgVch.VoucherLine
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgVch.VoucherLine') AND name='CreatedAt')
  ALTER TABLE YfgVch.VoucherLine ADD CreatedBy varchar(50) NULL, CreatedAt datetime2(0) NULL;
GO
-- YfgVch.VoucherLine: audit stays NULLABLE - rows of reviewed/final vouchers are guarded
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgVch.VoucherLine') AND name='CreatedBy')
  ALTER TABLE YfgVch.VoucherLine ADD CreatedBy varchar(50) NULL, CreatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgVch.VoucherLine') AND name='UpdatedAt')
  ALTER TABLE YfgVch.VoucherLine ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgVch.VoucherLine') AND name='SourceSystem')
  ALTER TABLE YfgVch.VoucherLine ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Vch_Line_SrcSys DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgVch.VoucherLine') AND name='CreatedAtJ')
  ALTER TABLE YfgVch.VoucherLine ADD CreatedAtJ AS YfgGen.GrgToJalali(CreatedAt), UpdatedAtJ AS YfgGen.GrgToJalali(UpdatedAt);
GO

-- YfgVch.VoucherFlow: only J companion
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgVch.VoucherFlow') AND name='AtJ')
  ALTER TABLE YfgVch.VoucherFlow ADD AtJ AS YfgGen.GrgToJalali(At);
GO

-- YfgAcc.TafsiliCategoryLink (audit standard: ALL tables)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.TafsiliCategoryLink') AND name='CreatedBy')
  ALTER TABLE YfgAcc.TafsiliCategoryLink ADD CreatedBy varchar(50) NOT NULL CONSTRAINT DF_YfgAcc_TCL_CreatedBy DEFAULT('system'), CreatedAt datetime2(0) NOT NULL CONSTRAINT DF_YfgAcc_TCL_CreatedAt DEFAULT(SYSDATETIME());
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.TafsiliCategoryLink') AND name='UpdatedAt')
  ALTER TABLE YfgAcc.TafsiliCategoryLink ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.TafsiliCategoryLink') AND name='SourceSystem')
  ALTER TABLE YfgAcc.TafsiliCategoryLink ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_YfgAcc_TCL_SrcSys DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('YfgAcc.TafsiliCategoryLink') AND name='CreatedAtJ')
  ALTER TABLE YfgAcc.TafsiliCategoryLink ADD CreatedAtJ AS YfgGen.GrgToJalali(CreatedAt), UpdatedAtJ AS YfgGen.GrgToJalali(UpdatedAt);
GO

-- Defaults for CreatedBy/CreatedAt on every audited table (same standard as YfgGen)
DECLARE @df varchar(200), @t varchar(120), @col sysname, @src nvarchar(60);
DECLARE c CURSOR FOR
  SELECT OBJECT_SCHEMA_NAME(c.object_id)+'.'+OBJECT_NAME(c.object_id),
    CASE c.name WHEN 'CreatedBy' THEN '''system''' ELSE 'SYSDATETIME()' END,
    c.name, 'DF_YfgAud_'+OBJECT_NAME(c.object_id)+'_'+c.name
  FROM sys.columns c
  WHERE c.name IN ('CreatedBy','CreatedAt')
    AND OBJECT_SCHEMA_NAME(c.object_id) IN ('YfgPrm','YfgAcc','YfgVch','YfgGen')
    AND NOT EXISTS (SELECT 1 FROM sys.default_constraints d WHERE d.parent_object_id=c.object_id AND d.parent_column_id=c.column_id);
OPEN c; FETCH NEXT FROM c INTO @t, @src, @col, @df;
WHILE @@FETCH_STATUS=0 BEGIN
  EXEC('ALTER TABLE '+@t+' ADD CONSTRAINT '+@df+' DEFAULT('+@src+') FOR '+@col+';');
  FETCH NEXT FROM c INTO @t, @src, @col, @df;
END; CLOSE c; DEALLOCATE c;
GO
PRINT '=== audit defaults done ===';
GO
