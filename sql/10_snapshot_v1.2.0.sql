/* اسنپ‌شات امنیتی پیش از مهاجرت v1.2.0 — در شِمای YfgBak (حذف‌شدنی پس از تأیید کارفرما) */
IF SCHEMA_ID('YfgBak') IS NULL EXEC('CREATE SCHEMA YfgBak');
GO
IF OBJECT_ID('YfgBak.Prm_Company') IS NOT NULL DROP TABLE YfgBak.Prm_Company;
SELECT * INTO YfgBak.Prm_Company FROM [Prm].[Company];
GO
IF OBJECT_ID('YfgBak.Prm_AppUser') IS NOT NULL DROP TABLE YfgBak.Prm_AppUser;
SELECT * INTO YfgBak.Prm_AppUser FROM [Prm].[AppUser];
GO
IF OBJECT_ID('YfgBak.Prm_FiscalYear') IS NOT NULL DROP TABLE YfgBak.Prm_FiscalYear;
SELECT * INTO YfgBak.Prm_FiscalYear FROM [Prm].[FiscalYear];
GO
IF OBJECT_ID('YfgBak.Prm_FiscalPeriod') IS NOT NULL DROP TABLE YfgBak.Prm_FiscalPeriod;
SELECT * INTO YfgBak.Prm_FiscalPeriod FROM [Prm].[FiscalPeriod];
GO
IF OBJECT_ID('YfgBak.Acc_DlType') IS NOT NULL DROP TABLE YfgBak.Acc_DlType;
SELECT * INTO YfgBak.Acc_DlType FROM [Acc].[DlType];
GO
IF OBJECT_ID('YfgBak.gnr_Crspnd') IS NOT NULL DROP TABLE YfgBak.gnr_Crspnd;
SELECT * INTO YfgBak.gnr_Crspnd FROM [gnr].[Crspnd];
GO
IF OBJECT_ID('YfgBak.gnr_GeoPos') IS NOT NULL DROP TABLE YfgBak.gnr_GeoPos;
SELECT * INTO YfgBak.gnr_GeoPos FROM [gnr].[GeoPos];
GO
IF OBJECT_ID('YfgBak.gnr_Address') IS NOT NULL DROP TABLE YfgBak.gnr_Address;
SELECT * INTO YfgBak.gnr_Address FROM [gnr].[Address];
GO
IF OBJECT_ID('YfgBak.gnr_CrspndCtgry') IS NOT NULL DROP TABLE YfgBak.gnr_CrspndCtgry;
SELECT * INTO YfgBak.gnr_CrspndCtgry FROM [gnr].[CrspndCtgry];
GO
IF OBJECT_ID('YfgBak.gnr_gnrCrspndCat') IS NOT NULL DROP TABLE YfgBak.gnr_gnrCrspndCat;
SELECT * INTO YfgBak.gnr_gnrCrspndCat FROM [gnr].[gnrCrspndCat];
GO
IF OBJECT_ID('YfgBak.Acc_DL') IS NOT NULL DROP TABLE YfgBak.Acc_DL;
SELECT * INTO YfgBak.Acc_DL FROM [Acc].[DL];
GO
IF OBJECT_ID('YfgBak.Acc_DlCtgry') IS NOT NULL DROP TABLE YfgBak.Acc_DlCtgry;
SELECT * INTO YfgBak.Acc_DlCtgry FROM [Acc].[DlCtgry];
GO
IF OBJECT_ID('YfgBak.Acc_DlCtgryLink') IS NOT NULL DROP TABLE YfgBak.Acc_DlCtgryLink;
SELECT * INTO YfgBak.Acc_DlCtgryLink FROM [Acc].[DlCtgryLink];
GO
IF OBJECT_ID('YfgBak.Acc_Group') IS NOT NULL DROP TABLE YfgBak.Acc_Group;
SELECT * INTO YfgBak.Acc_Group FROM [Acc].[Group];
GO
IF OBJECT_ID('YfgBak.Acc_Kol') IS NOT NULL DROP TABLE YfgBak.Acc_Kol;
SELECT * INTO YfgBak.Acc_Kol FROM [Acc].[Kol];
GO
IF OBJECT_ID('YfgBak.Acc_Moein') IS NOT NULL DROP TABLE YfgBak.Acc_Moein;
SELECT * INTO YfgBak.Acc_Moein FROM [Acc].[Moein];
GO
IF OBJECT_ID('YfgBak.Acc_StdDesc') IS NOT NULL DROP TABLE YfgBak.Acc_StdDesc;
SELECT * INTO YfgBak.Acc_StdDesc FROM [Acc].[StdDesc];
GO
IF OBJECT_ID('YfgBak.Acc_OpeningBalance') IS NOT NULL DROP TABLE YfgBak.Acc_OpeningBalance;
SELECT * INTO YfgBak.Acc_OpeningBalance FROM [Acc].[OpeningBalance];
GO
IF OBJECT_ID('YfgBak.Vch_Type') IS NOT NULL DROP TABLE YfgBak.Vch_Type;
SELECT * INTO YfgBak.Vch_Type FROM [Vch].[Type];
GO
IF OBJECT_ID('YfgBak.Vch_Hdr') IS NOT NULL DROP TABLE YfgBak.Vch_Hdr;
SELECT * INTO YfgBak.Vch_Hdr FROM [Vch].[Hdr];
GO
IF OBJECT_ID('YfgBak.Vch_Itm') IS NOT NULL DROP TABLE YfgBak.Vch_Itm;
SELECT * INTO YfgBak.Vch_Itm FROM [Vch].[Itm];
GO
IF OBJECT_ID('YfgBak.Vch_WfLog') IS NOT NULL DROP TABLE YfgBak.Vch_WfLog;
SELECT * INTO YfgBak.Vch_WfLog FROM [Vch].[WfLog];
GO
IF OBJECT_ID('YfgBak.gnr_Systems') IS NOT NULL DROP TABLE YfgBak.gnr_Systems;
SELECT * INTO YfgBak.gnr_Systems FROM [gnr].[Systems];
GO
IF OBJECT_ID('YfgBak.gnr_MisSetup') IS NOT NULL DROP TABLE YfgBak.gnr_MisSetup;
SELECT * INTO YfgBak.gnr_MisSetup FROM [gnr].[MisSetup];
GO
IF OBJECT_ID('YfgBak.gnr_Lookup') IS NOT NULL DROP TABLE YfgBak.gnr_Lookup;
SELECT * INTO YfgBak.gnr_Lookup FROM [gnr].[Lookup];
GO
IF OBJECT_ID('YfgBak.gnr_TableIdGen') IS NOT NULL DROP TABLE YfgBak.gnr_TableIdGen;
SELECT * INTO YfgBak.gnr_TableIdGen FROM [gnr].[TableIdGen];
GO
IF OBJECT_ID('YfgBak.gnr_gnrHolidayTypes') IS NOT NULL DROP TABLE YfgBak.gnr_gnrHolidayTypes;
SELECT * INTO YfgBak.gnr_gnrHolidayTypes FROM [gnr].[gnrHolidayTypes];
GO
IF OBJECT_ID('YfgBak.gnr_gnrHolidays') IS NOT NULL DROP TABLE YfgBak.gnr_gnrHolidays;
SELECT * INTO YfgBak.gnr_gnrHolidays FROM [gnr].[gnrHolidays];
GO
IF OBJECT_ID('YfgBak.gnr_gnrNonWorkingTimes') IS NOT NULL DROP TABLE YfgBak.gnr_gnrNonWorkingTimes;
SELECT * INTO YfgBak.gnr_gnrNonWorkingTimes FROM [gnr].[gnrNonWorkingTimes];
GO
PRINT '=== snapshot done ===';
GO
