/* مهاجرت v1.2.0 — حذف اشیای قدیم (پس از کپی موفق داده) */
GO
IF OBJECT_ID('Acc.VwChart') IS NOT NULL DROP VIEW Acc.VwChart;
GO
IF OBJECT_ID('Vch.Itm') IS NOT NULL DROP TABLE [Vch].[Itm];
GO
IF OBJECT_ID('Vch.WfLog') IS NOT NULL DROP TABLE [Vch].[WfLog];
GO
IF OBJECT_ID('Vch.Hdr') IS NOT NULL DROP TABLE [Vch].[Hdr];
GO
IF OBJECT_ID('Vch.Type') IS NOT NULL DROP TABLE [Vch].[Type];
GO
IF OBJECT_ID('Acc.OpeningBalance') IS NOT NULL DROP TABLE [Acc].[OpeningBalance];
GO
IF OBJECT_ID('Acc.StdDesc') IS NOT NULL DROP TABLE [Acc].[StdDesc];
GO
IF OBJECT_ID('Acc.Moein') IS NOT NULL DROP TABLE [Acc].[Moein];
GO
IF OBJECT_ID('Acc.Kol') IS NOT NULL DROP TABLE [Acc].[Kol];
GO
IF OBJECT_ID('Acc.Group') IS NOT NULL DROP TABLE [Acc].[Group];
GO
IF OBJECT_ID('Acc.DlCtgryLink') IS NOT NULL DROP TABLE [Acc].[DlCtgryLink];
GO
IF OBJECT_ID('Acc.DlCtgry') IS NOT NULL DROP TABLE [Acc].[DlCtgry];
GO
IF OBJECT_ID('Acc.DL') IS NOT NULL DROP TABLE [Acc].[DL];
GO
IF OBJECT_ID('Acc.DlType') IS NOT NULL DROP TABLE [Acc].[DlType];
GO
IF OBJECT_ID('gnr.gnrNonWorkingTimes') IS NOT NULL DROP TABLE [gnr].[gnrNonWorkingTimes];
GO
IF OBJECT_ID('gnr.gnrHolidays') IS NOT NULL DROP TABLE [gnr].[gnrHolidays];
GO
IF OBJECT_ID('gnr.gnrHolidayTypes') IS NOT NULL DROP TABLE [gnr].[gnrHolidayTypes];
GO
IF OBJECT_ID('gnr.TableIdGen') IS NOT NULL DROP TABLE [gnr].[TableIdGen];
GO
IF OBJECT_ID('gnr.Systems') IS NOT NULL DROP TABLE [gnr].[Systems];
GO
IF OBJECT_ID('gnr.Lookup') IS NOT NULL DROP TABLE [gnr].[Lookup];
GO
IF OBJECT_ID('gnr.MisSetup') IS NOT NULL DROP TABLE [gnr].[MisSetup];
GO
IF OBJECT_ID('gnr.gnrCrspndCat') IS NOT NULL DROP TABLE [gnr].[gnrCrspndCat];
GO
IF OBJECT_ID('gnr.CrspndCtgry') IS NOT NULL DROP TABLE [gnr].[CrspndCtgry];
GO
IF OBJECT_ID('gnr.Address') IS NOT NULL DROP TABLE [gnr].[Address];
GO
IF OBJECT_ID('gnr.GeoPos') IS NOT NULL DROP TABLE [gnr].[GeoPos];
GO
IF OBJECT_ID('gnr.Crspnd') IS NOT NULL DROP TABLE [gnr].[Crspnd];
GO
IF OBJECT_ID('Prm.FiscalPeriod') IS NOT NULL DROP TABLE [Prm].[FiscalPeriod];
GO
IF OBJECT_ID('Prm.FiscalYear') IS NOT NULL DROP TABLE [Prm].[FiscalYear];
GO
IF OBJECT_ID('Prm.AppUser') IS NOT NULL DROP TABLE [Prm].[AppUser];
GO
IF OBJECT_ID('Prm.Company') IS NOT NULL DROP TABLE [Prm].[Company];
GO
IF OBJECT_ID('gnr.Grg2Jal') IS NOT NULL DROP FUNCTION [gnr].[Grg2Jal];
GO
IF OBJECT_ID('gnr.Jal2Grg') IS NOT NULL DROP FUNCTION [gnr].[Jal2Grg];
GO
IF OBJECT_ID('gnr._Jal2Jdn') IS NOT NULL DROP FUNCTION [gnr].[_Jal2Jdn];
GO
IF OBJECT_ID('gnr._JalMarch') IS NOT NULL DROP FUNCTION [gnr].[_JalMarch];
GO
IF OBJECT_ID('gnr._Jdn2Grg') IS NOT NULL DROP FUNCTION [gnr].[_Jdn2Grg];
GO
IF OBJECT_ID('gnr._JalLeap') IS NOT NULL DROP FUNCTION [gnr].[_JalLeap];
GO
IF OBJECT_ID('gnr._Grg2Jdn') IS NOT NULL DROP FUNCTION [gnr].[_Grg2Jdn];
GO
IF OBJECT_ID('gnr._JalBreak') IS NOT NULL DROP FUNCTION [gnr].[_JalBreak];
GO
IF SCHEMA_ID('Prm') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM sys.objects WHERE schema_id=SCHEMA_ID('Prm')) EXEC('DROP SCHEMA Prm');
GO
IF SCHEMA_ID('Acc') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM sys.objects WHERE schema_id=SCHEMA_ID('Acc')) EXEC('DROP SCHEMA Acc');
GO
IF SCHEMA_ID('Vch') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM sys.objects WHERE schema_id=SCHEMA_ID('Vch')) EXEC('DROP SCHEMA Vch');
GO
IF SCHEMA_ID('gnr') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM sys.objects WHERE schema_id=SCHEMA_ID('gnr')) EXEC('DROP SCHEMA gnr');
GO
/* راستی‌آزمایی نهایی */
IF OBJECT_ID('gnr.Crspnd') IS NOT NULL RAISERROR('OLD TABLE STILL EXISTS: gnr.Crspnd',16,1);
IF OBJECT_ID('Vch.Hdr') IS NOT NULL RAISERROR('OLD TABLE STILL EXISTS: Vch.Hdr',16,1);
IF SCHEMA_ID('gnr') IS NOT NULL RAISERROR('OLD SCHEMA STILL EXISTS: gnr',16,1);
IF OBJECT_ID('YfgGen.Party') IS NULL RAISERROR('NEW TABLE MISSING: YfgGen.Party',16,1);
IF OBJECT_ID('YfgVch.Voucher') IS NULL RAISERROR('NEW TABLE MISSING: YfgVch.Voucher',16,1);
IF OBJECT_ID('YfgAcc.Tafsili') IS NULL RAISERROR('NEW TABLE MISSING: YfgAcc.Tafsili',16,1);
IF OBJECT_ID('YfgGen.GrgToJalali') IS NULL RAISERROR('NEW FUNCTION MISSING',16,1);
IF OBJECT_ID('YfgVch.Tr_YfgVch_Voucher_NoDeleteFinal') IS NULL RAISERROR('NEW TRIGGER MISSING',16,1);
PRINT '=== v1.2.0 rename migration verified ===';
SELECT N'YfgGen.Party' t, COUNT(*) rows FROM YfgGen.Party
UNION ALL SELECT N'YfgVch.Voucher', COUNT(*) FROM YfgVch.Voucher
UNION ALL SELECT N'YfgVch.VoucherLine', COUNT(*) FROM YfgVch.VoucherLine
UNION ALL SELECT N'YfgAcc.Kol', COUNT(*) FROM YfgAcc.Kol
UNION ALL SELECT N'YfgAcc.Moein', COUNT(*) FROM YfgAcc.Moein
UNION ALL SELECT N'YfgAcc.Tafsili', COUNT(*) FROM YfgAcc.Tafsili;
GO
