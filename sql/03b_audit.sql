/* ============================================================================
   YFG ACC-WEB 1.1.0 - Part B: audit columns on existing tables
   Directive: audit fields on ALL tables (issuer/approver/editor/source-system/
   created-at/updated-at) + Jalali J companions. ASCII comments only (TDS safe).
   Sources: employer directive 2026-10-28 + Vch.Hdr original pattern.
   ============================================================================ */

-- Prm.Company
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Prm.Company') AND name='CreatedBy')
  ALTER TABLE Prm.Company ADD CreatedBy varchar(50) NULL;
GO
UPDATE Prm.Company SET CreatedBy=N'system' WHERE CreatedBy IS NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Prm.Company') AND name='CreatedBy')
  ALTER TABLE Prm.Company ALTER COLUMN CreatedBy varchar(50) NOT NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Prm.Company') AND name='UpdatedAt')
  ALTER TABLE Prm.Company ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Prm.Company') AND name='SourceSystem')
  ALTER TABLE Prm.Company ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Prm_Company_SrcSys DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Prm.Company') AND name='CreatedAtJ')
  ALTER TABLE Prm.Company ADD CreatedAtJ AS gnr.Grg2Jal(CreatedAt), UpdatedAtJ AS gnr.Grg2Jal(UpdatedAt);
GO

-- Prm.AppUser
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Prm.AppUser') AND name='CreatedBy')
  ALTER TABLE Prm.AppUser ADD CreatedBy varchar(50) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Prm.AppUser') AND name='CreatedBy')
BEGIN
  UPDATE Prm.AppUser SET CreatedBy=N'system' WHERE CreatedBy IS NULL;
  ALTER TABLE Prm.AppUser ALTER COLUMN CreatedBy varchar(50) NOT NULL;
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Prm.AppUser') AND name='UpdatedAt')
  ALTER TABLE Prm.AppUser ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Prm.AppUser') AND name='SourceSystem')
  ALTER TABLE Prm.AppUser ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Prm_AppUser_SrcSys DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Prm.AppUser') AND name='CreatedAtJ')
  ALTER TABLE Prm.AppUser ADD CreatedAtJ AS gnr.Grg2Jal(CreatedAt), UpdatedAtJ AS gnr.Grg2Jal(UpdatedAt);
GO

-- Prm.FiscalYear
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Prm.FiscalYear') AND name='CreatedBy')
  ALTER TABLE Prm.FiscalYear ADD CreatedBy varchar(50) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Prm.FiscalYear') AND name='CreatedBy')
BEGIN
  UPDATE Prm.FiscalYear SET CreatedBy=N'system' WHERE CreatedBy IS NULL;
  ALTER TABLE Prm.FiscalYear ALTER COLUMN CreatedBy varchar(50) NOT NULL;
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Prm.FiscalYear') AND name='UpdatedAt')
  ALTER TABLE Prm.FiscalYear ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Prm.FiscalYear') AND name='SourceSystem')
  ALTER TABLE Prm.FiscalYear ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Prm_FiscalYear_SrcSys DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Prm.FiscalYear') AND name='CreatedAtJ')
  ALTER TABLE Prm.FiscalYear ADD CreatedAtJ AS gnr.Grg2Jal(CreatedAt), UpdatedAtJ AS gnr.Grg2Jal(UpdatedAt);
GO

-- Prm.FiscalPeriod
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Prm.FiscalPeriod') AND name='CreatedAt')
  ALTER TABLE Prm.FiscalPeriod ADD CreatedBy varchar(50) NULL, CreatedAt datetime2(0) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Prm.FiscalPeriod') AND name='CreatedAt')
BEGIN
  UPDATE Prm.FiscalPeriod SET CreatedBy=N'system', CreatedAt=SYSDATETIME() WHERE CreatedAt IS NULL OR CreatedBy IS NULL;
  ALTER TABLE Prm.FiscalPeriod ALTER COLUMN CreatedBy varchar(50) NOT NULL;
  ALTER TABLE Prm.FiscalPeriod ALTER COLUMN CreatedAt datetime2(0) NOT NULL;
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Prm.FiscalPeriod') AND name='UpdatedAt')
  ALTER TABLE Prm.FiscalPeriod ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Prm.FiscalPeriod') AND name='SourceSystem')
  ALTER TABLE Prm.FiscalPeriod ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Prm_FiscalPeriod_SrcSys DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Prm.FiscalPeriod') AND name='CreatedAtJ')
  ALTER TABLE Prm.FiscalPeriod ADD CreatedAtJ AS gnr.Grg2Jal(CreatedAt), UpdatedAtJ AS gnr.Grg2Jal(UpdatedAt);
GO

-- Acc.Group
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.[Group]') AND name='CreatedAt')
  ALTER TABLE Acc.[Group] ADD CreatedBy varchar(50) NULL, CreatedAt datetime2(0) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.[Group]') AND name='CreatedAt')
BEGIN
  UPDATE Acc.[Group] SET CreatedBy=N'system', CreatedAt=SYSDATETIME() WHERE CreatedAt IS NULL OR CreatedBy IS NULL;
  ALTER TABLE Acc.[Group] ALTER COLUMN CreatedBy varchar(50) NOT NULL;
  ALTER TABLE Acc.[Group] ALTER COLUMN CreatedAt datetime2(0) NOT NULL;
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.[Group]') AND name='UpdatedAt')
  ALTER TABLE Acc.[Group] ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.[Group]') AND name='SourceSystem')
  ALTER TABLE Acc.[Group] ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Acc_Group_SrcSys DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.[Group]') AND name='CreatedAtJ')
  ALTER TABLE Acc.[Group] ADD CreatedAtJ AS gnr.Grg2Jal(CreatedAt), UpdatedAtJ AS gnr.Grg2Jal(UpdatedAt);
GO

-- Acc.Kol
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.Kol') AND name='CreatedAt')
  ALTER TABLE Acc.Kol ADD CreatedBy varchar(50) NULL, CreatedAt datetime2(0) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.Kol') AND name='CreatedAt')
BEGIN
  UPDATE Acc.Kol SET CreatedBy=N'system', CreatedAt=SYSDATETIME() WHERE CreatedAt IS NULL OR CreatedBy IS NULL;
  ALTER TABLE Acc.Kol ALTER COLUMN CreatedBy varchar(50) NOT NULL;
  ALTER TABLE Acc.Kol ALTER COLUMN CreatedAt datetime2(0) NOT NULL;
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.Kol') AND name='UpdatedAt')
  ALTER TABLE Acc.Kol ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.Kol') AND name='SourceSystem')
  ALTER TABLE Acc.Kol ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Acc_Kol_SrcSys DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.Kol') AND name='CreatedAtJ')
  ALTER TABLE Acc.Kol ADD CreatedAtJ AS gnr.Grg2Jal(CreatedAt), UpdatedAtJ AS gnr.Grg2Jal(UpdatedAt);
GO

-- Acc.Moein
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.Moein') AND name='CreatedAt')
  ALTER TABLE Acc.Moein ADD CreatedBy varchar(50) NULL, CreatedAt datetime2(0) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.Moein') AND name='CreatedAt')
BEGIN
  UPDATE Acc.Moein SET CreatedBy=N'system', CreatedAt=SYSDATETIME() WHERE CreatedAt IS NULL OR CreatedBy IS NULL;
  ALTER TABLE Acc.Moein ALTER COLUMN CreatedBy varchar(50) NOT NULL;
  ALTER TABLE Acc.Moein ALTER COLUMN CreatedAt datetime2(0) NOT NULL;
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.Moein') AND name='UpdatedAt')
  ALTER TABLE Acc.Moein ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.Moein') AND name='SourceSystem')
  ALTER TABLE Acc.Moein ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Acc_Moein_SrcSys DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.Moein') AND name='CreatedAtJ')
  ALTER TABLE Acc.Moein ADD CreatedAtJ AS gnr.Grg2Jal(CreatedAt), UpdatedAtJ AS gnr.Grg2Jal(UpdatedAt);
GO

-- Acc.DlType
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.DlType') AND name='CreatedBy')
  ALTER TABLE Acc.DlType ADD CreatedBy varchar(50) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.DlType') AND name='CreatedBy')
BEGIN
  UPDATE Acc.DlType SET CreatedBy=N'system' WHERE CreatedBy IS NULL;
  ALTER TABLE Acc.DlType ALTER COLUMN CreatedBy varchar(50) NOT NULL;
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.DlType') AND name='UpdatedAt')
  ALTER TABLE Acc.DlType ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.DlType') AND name='SourceSystem')
  ALTER TABLE Acc.DlType ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Acc_DlType_SrcSys DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.DlType') AND name='CreatedAtJ')
  ALTER TABLE Acc.DlType ADD CreatedAtJ AS gnr.Grg2Jal(CreatedAt), UpdatedAtJ AS gnr.Grg2Jal(UpdatedAt);
GO

-- Acc.DL
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.DL') AND name='CreatedBy')
  ALTER TABLE Acc.DL ADD CreatedBy varchar(50) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.DL') AND name='CreatedBy')
BEGIN
  UPDATE Acc.DL SET CreatedBy=N'system' WHERE CreatedBy IS NULL;
  ALTER TABLE Acc.DL ALTER COLUMN CreatedBy varchar(50) NOT NULL;
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.DL') AND name='UpdatedAt')
  ALTER TABLE Acc.DL ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.DL') AND name='SourceSystem')
  ALTER TABLE Acc.DL ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Acc_DL_SrcSys DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.DL') AND name='CreatedAtJ')
  ALTER TABLE Acc.DL ADD CreatedAtJ AS gnr.Grg2Jal(CreatedAt), UpdatedAtJ AS gnr.Grg2Jal(UpdatedAt);
GO

-- Acc.DlCtgry
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.DlCtgry') AND name='CreatedAt')
  ALTER TABLE Acc.DlCtgry ADD CreatedBy varchar(50) NULL, CreatedAt datetime2(0) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.DlCtgry') AND name='CreatedAt')
BEGIN
  UPDATE Acc.DlCtgry SET CreatedBy=N'system', CreatedAt=SYSDATETIME() WHERE CreatedAt IS NULL OR CreatedBy IS NULL;
  ALTER TABLE Acc.DlCtgry ALTER COLUMN CreatedBy varchar(50) NOT NULL;
  ALTER TABLE Acc.DlCtgry ALTER COLUMN CreatedAt datetime2(0) NOT NULL;
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.DlCtgry') AND name='UpdatedAt')
  ALTER TABLE Acc.DlCtgry ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.DlCtgry') AND name='SourceSystem')
  ALTER TABLE Acc.DlCtgry ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Acc_DlCtgry_SrcSys DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.DlCtgry') AND name='CreatedAtJ')
  ALTER TABLE Acc.DlCtgry ADD CreatedAtJ AS gnr.Grg2Jal(CreatedAt), UpdatedAtJ AS gnr.Grg2Jal(UpdatedAt);
GO

-- Acc.StdDesc
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.StdDesc') AND name='CreatedAt')
  ALTER TABLE Acc.StdDesc ADD CreatedBy varchar(50) NULL, CreatedAt datetime2(0) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.StdDesc') AND name='CreatedAt')
BEGIN
  UPDATE Acc.StdDesc SET CreatedBy=N'system', CreatedAt=SYSDATETIME() WHERE CreatedAt IS NULL OR CreatedBy IS NULL;
  ALTER TABLE Acc.StdDesc ALTER COLUMN CreatedBy varchar(50) NOT NULL;
  ALTER TABLE Acc.StdDesc ALTER COLUMN CreatedAt datetime2(0) NOT NULL;
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.StdDesc') AND name='UpdatedAt')
  ALTER TABLE Acc.StdDesc ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.StdDesc') AND name='SourceSystem')
  ALTER TABLE Acc.StdDesc ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Acc_StdDesc_SrcSys DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.StdDesc') AND name='CreatedAtJ')
  ALTER TABLE Acc.StdDesc ADD CreatedAtJ AS gnr.Grg2Jal(CreatedAt), UpdatedAtJ AS gnr.Grg2Jal(UpdatedAt);
GO

-- Acc.OpeningBalance
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.OpeningBalance') AND name='CreatedAt')
  ALTER TABLE Acc.OpeningBalance ADD CreatedBy varchar(50) NULL, CreatedAt datetime2(0) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.OpeningBalance') AND name='CreatedAt')
BEGIN
  UPDATE Acc.OpeningBalance SET CreatedBy=N'system', CreatedAt=SYSDATETIME() WHERE CreatedAt IS NULL OR CreatedBy IS NULL;
  ALTER TABLE Acc.OpeningBalance ALTER COLUMN CreatedBy varchar(50) NOT NULL;
  ALTER TABLE Acc.OpeningBalance ALTER COLUMN CreatedAt datetime2(0) NOT NULL;
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.OpeningBalance') AND name='UpdatedAt')
  ALTER TABLE Acc.OpeningBalance ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.OpeningBalance') AND name='SourceSystem')
  ALTER TABLE Acc.OpeningBalance ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Acc_OB_SrcSys DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Acc.OpeningBalance') AND name='CreatedAtJ')
  ALTER TABLE Acc.OpeningBalance ADD CreatedAtJ AS gnr.Grg2Jal(CreatedAt), UpdatedAtJ AS gnr.Grg2Jal(UpdatedAt);
GO

-- Vch.Type
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Vch.Type') AND name='CreatedAt')
  ALTER TABLE Vch.Type ADD CreatedBy varchar(50) NULL, CreatedAt datetime2(0) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Vch.Type') AND name='CreatedAt')
BEGIN
  UPDATE Vch.Type SET CreatedBy=N'system', CreatedAt=SYSDATETIME() WHERE CreatedAt IS NULL OR CreatedBy IS NULL;
  ALTER TABLE Vch.Type ALTER COLUMN CreatedBy varchar(50) NOT NULL;
  ALTER TABLE Vch.Type ALTER COLUMN CreatedAt datetime2(0) NOT NULL;
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Vch.Type') AND name='UpdatedAt')
  ALTER TABLE Vch.Type ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Vch.Type') AND name='SourceSystem')
  ALTER TABLE Vch.Type ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Vch_Type_SrcSys DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Vch.Type') AND name='CreatedAtJ')
  ALTER TABLE Vch.Type ADD CreatedAtJ AS gnr.Grg2Jal(CreatedAt), UpdatedAtJ AS gnr.Grg2Jal(UpdatedAt);
GO

-- Vch.Hdr: Updated + Edited + SourceSystem already present as SourceModule
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Vch.Hdr') AND name='UpdatedAt')
  ALTER TABLE Vch.Hdr ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Vch.Hdr') AND name='EditedBy')
  ALTER TABLE Vch.Hdr ADD EditedBy varchar(50) NULL, EditedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Vch.Hdr') AND name='CreatedAtJ')
  ALTER TABLE Vch.Hdr ADD CreatedAtJ AS gnr.Grg2Jal(CreatedAt), UpdatedAtJ AS gnr.Grg2Jal(UpdatedAt),
    CheckedAtJ AS gnr.Grg2Jal(CheckedAt), FinalizedAtJ AS gnr.Grg2Jal(FinalizedAt), EditedAtJ AS gnr.Grg2Jal(EditedAt);
GO

-- Vch.Itm
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Vch.Itm') AND name='CreatedAt')
  ALTER TABLE Vch.Itm ADD CreatedBy varchar(50) NULL, CreatedAt datetime2(0) NULL;
GO
-- Vch.Itm: audit stays NULLABLE - rows of reviewed/final vouchers are guarded
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Vch.Itm') AND name='CreatedBy')
  ALTER TABLE Vch.Itm ADD CreatedBy varchar(50) NULL, CreatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Vch.Itm') AND name='UpdatedAt')
  ALTER TABLE Vch.Itm ADD UpdatedBy varchar(50) NULL, UpdatedAt datetime2(0) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Vch.Itm') AND name='SourceSystem')
  ALTER TABLE Vch.Itm ADD SourceSystem varchar(20) NOT NULL CONSTRAINT DF_Vch_Itm_SrcSys DEFAULT('ACCWEB');
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Vch.Itm') AND name='CreatedAtJ')
  ALTER TABLE Vch.Itm ADD CreatedAtJ AS gnr.Grg2Jal(CreatedAt), UpdatedAtJ AS gnr.Grg2Jal(UpdatedAt);
GO

-- Vch.WfLog: only J companion
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Vch.WfLog') AND name='AtJ')
  ALTER TABLE Vch.WfLog ADD AtJ AS gnr.Grg2Jal(At);
GO
