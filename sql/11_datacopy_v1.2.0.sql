/* مهاجرت v1.2.0 — کپی داده از اشیای قدیم (Prm/Acc/Vch/gnr) به جدید (YfgPrm/YfgAcc/YfgVch/YfgGen)
   اجرای تکرارپذیر (Idempotent) — ردیف‌های موجود با کلید یکتا دوباره درج نمی‌شوند */
GO
SET IDENTITY_INSERT [YfgPrm].[Company] ON;
INSERT INTO [YfgPrm].[Company] ([CompanyId], [CompanyCode], [TitleFa], [NationalId], [EconomicCode], [CodingMode], [IsActive], [CreatedAt], [CreatedBy], [UpdatedBy], [UpdatedAt], [SourceSystem])
SELECT s.[CompanyId], s.[CompanyCode], s.[TitleFa], s.[NationalId], s.[EconomicCode], s.[CodingMode], s.[IsActive], s.[CreatedAt], s.[CreatedBy], s.[UpdatedBy], s.[UpdatedAt], s.[SourceSystem] FROM [Prm].[Company] s WHERE NOT EXISTS (SELECT 1 FROM [YfgPrm].[Company] n WHERE n.[CompanyId]=s.[CompanyId]);
SET IDENTITY_INSERT [YfgPrm].[Company] OFF;
PRINT 'copied Prm.Company → YfgPrm.Company';
GO
SET IDENTITY_INSERT [YfgPrm].[AppUser] ON;
INSERT INTO [YfgPrm].[AppUser] ([UserId], [Username], [DisplayName], [RoleCode], [PassHash], [IsActive], [CreatedAt], [CreatedBy], [UpdatedBy], [UpdatedAt], [SourceSystem])
SELECT s.[UserId], s.[Username], s.[DisplayName], s.[RoleCode], s.[PassHash], s.[IsActive], s.[CreatedAt], s.[CreatedBy], s.[UpdatedBy], s.[UpdatedAt], s.[SourceSystem] FROM [Prm].[AppUser] s WHERE NOT EXISTS (SELECT 1 FROM [YfgPrm].[AppUser] n WHERE n.[UserId]=s.[UserId]);
SET IDENTITY_INSERT [YfgPrm].[AppUser] OFF;
PRINT 'copied Prm.AppUser → YfgPrm.AppUser';
GO
SET IDENTITY_INSERT [YfgPrm].[FiscalYear] ON;
INSERT INTO [YfgPrm].[FiscalYear] ([YearId], [CompanyId], [JalaliYear], [Title], [StartDate], [EndDate], [IsClosed], [CreatedAt], [CreatedBy], [UpdatedBy], [UpdatedAt], [SourceSystem])
SELECT s.[YearId], s.[CompanyId], s.[JalaliYear], s.[Title], s.[StartDate], s.[EndDate], s.[IsClosed], s.[CreatedAt], s.[CreatedBy], s.[UpdatedBy], s.[UpdatedAt], s.[SourceSystem] FROM [Prm].[FiscalYear] s WHERE NOT EXISTS (SELECT 1 FROM [YfgPrm].[FiscalYear] n WHERE n.[YearId]=s.[YearId]);
SET IDENTITY_INSERT [YfgPrm].[FiscalYear] OFF;
PRINT 'copied Prm.FiscalYear → YfgPrm.FiscalYear';
GO
SET IDENTITY_INSERT [YfgPrm].[FiscalPeriod] ON;
INSERT INTO [YfgPrm].[FiscalPeriod] ([PeriodId], [YearId], [MonthNo], [Title], [IsClosed], [CreatedBy], [CreatedAt], [UpdatedBy], [UpdatedAt], [SourceSystem])
SELECT s.[PeriodId], s.[YearId], s.[MonthNo], s.[Title], s.[IsClosed], s.[CreatedBy], s.[CreatedAt], s.[UpdatedBy], s.[UpdatedAt], s.[SourceSystem] FROM [Prm].[FiscalPeriod] s WHERE NOT EXISTS (SELECT 1 FROM [YfgPrm].[FiscalPeriod] n WHERE n.[PeriodId]=s.[PeriodId]);
SET IDENTITY_INSERT [YfgPrm].[FiscalPeriod] OFF;
PRINT 'copied Prm.FiscalPeriod → YfgPrm.FiscalPeriod';
GO
SET IDENTITY_INSERT [YfgAcc].[TafsiliType] ON;
INSERT INTO [YfgAcc].[TafsiliType] ([TafsiliTypeId], [CompanyId], [Title], [LatinTitle], [CreatedAt], [CodeListType], [CreatedBy], [UpdatedBy], [UpdatedAt], [SourceSystem])
SELECT s.[DlTypeId], s.[CompanyId], s.[Title], s.[LatinTitle], s.[CreatedAt], s.[LookupType], s.[CreatedBy], s.[UpdatedBy], s.[UpdatedAt], s.[SourceSystem] FROM [Acc].[DlType] s WHERE NOT EXISTS (SELECT 1 FROM [YfgAcc].[TafsiliType] n WHERE n.[TafsiliTypeId]=s.[DlTypeId]);
SET IDENTITY_INSERT [YfgAcc].[TafsiliType] OFF;
PRINT 'copied Acc.DlType → YfgAcc.TafsiliType';
GO
SET IDENTITY_INSERT [YfgGen].[Party] ON;
INSERT INTO [YfgGen].[Party] ([Serial], [RecType], [PartyKind], [CompName], [Title], [FName], [LName], [NickName], [Title_En], [FName_En], [LName_En], [CompName_En], [EconCode], [NationalCode], [FatherName], [IDNo], [MainAddrRef], [IsActive], [CreatedBy], [CreatedAt], [UpdatedBy], [UpdatedAt], [SourceSystem])
SELECT s.[Serial], s.[RecType], s.[CompType], s.[CompName], s.[Title], s.[FName], s.[LName], s.[NickName], s.[Title_En], s.[FName_En], s.[LName_En], s.[CompName_En], s.[EconCode], s.[NationalCode], s.[FatherName], s.[IDNo], s.[MainAddrRef], s.[IsActive], s.[CreatedBy], s.[CreatedAt], s.[UpdatedBy], s.[UpdatedAt], s.[SourceSystem] FROM [gnr].[Crspnd] s WHERE NOT EXISTS (SELECT 1 FROM [YfgGen].[Party] n WHERE n.[Serial]=s.[Serial]);
SET IDENTITY_INSERT [YfgGen].[Party] OFF;
PRINT 'copied gnr.Crspnd → YfgGen.Party';
GO
SET IDENTITY_INSERT [YfgGen].[GeoPlace] ON;
INSERT INTO [YfgGen].[GeoPlace] ([GeoPlaceId], [ParentRef], [Title], [GeoType], [LatinTitle], [CreatedBy], [CreatedAt], [UpdatedBy], [UpdatedAt], [SourceSystem])
SELECT s.[GeoPosId], s.[ParentRef], s.[Title], s.[GeoType], s.[LatinTitle], s.[CreatedBy], s.[CreatedAt], s.[UpdatedBy], s.[UpdatedAt], s.[SourceSystem] FROM [gnr].[GeoPos] s WHERE NOT EXISTS (SELECT 1 FROM [YfgGen].[GeoPlace] n WHERE n.[Title]=s.[Title] AND n.[GeoType]=s.[GeoType]);
SET IDENTITY_INSERT [YfgGen].[GeoPlace] OFF;
PRINT 'copied gnr.GeoPos → YfgGen.GeoPlace';
GO
SET IDENTITY_INSERT [YfgGen].[PartyAddress] ON;
INSERT INTO [YfgGen].[PartyAddress] ([Serial], [PartyRef], [Title], [Address], [Address_En], [ZipCode], [PostBox], [Phone], [Fax], [EMail], [Modem], [Mobile], [GeoPlaceRef], [CreatedBy], [CreatedAt], [UpdatedBy], [UpdatedAt], [SourceSystem])
SELECT s.[Serial], s.[CrspndRef], s.[Title], s.[Address], s.[Address_En], s.[ZipCode], s.[PostBox], s.[Phone], s.[Fax], s.[EMail], s.[Modem], s.[Mobile], s.[GeoPosRef], s.[CreatedBy], s.[CreatedAt], s.[UpdatedBy], s.[UpdatedAt], s.[SourceSystem] FROM [gnr].[Address] s WHERE NOT EXISTS (SELECT 1 FROM [YfgGen].[PartyAddress] n WHERE n.[Serial]=s.[Serial]);
SET IDENTITY_INSERT [YfgGen].[PartyAddress] OFF;
PRINT 'copied gnr.Address → YfgGen.PartyAddress';
GO
SET IDENTITY_INSERT [YfgGen].[PartyCategory] ON;
INSERT INTO [YfgGen].[PartyCategory] ([CategoryId], [Title], [ParentRef], [CreatedBy], [CreatedAt], [UpdatedBy], [UpdatedAt], [SourceSystem])
SELECT s.[CtgryId], s.[Title], s.[ParentRef], s.[CreatedBy], s.[CreatedAt], s.[UpdatedBy], s.[UpdatedAt], s.[SourceSystem] FROM [gnr].[CrspndCtgry] s WHERE NOT EXISTS (SELECT 1 FROM [YfgGen].[PartyCategory] n WHERE n.[CategoryId]=s.[CtgryId]);
SET IDENTITY_INSERT [YfgGen].[PartyCategory] OFF;
PRINT 'copied gnr.CrspndCtgry → YfgGen.PartyCategory';
GO
INSERT INTO [YfgGen].[PartyCategoryLink] ([PartyRef], [CategoryRef], [CreatedBy], [CreatedAt], [UpdatedBy], [UpdatedAt], [SourceSystem])
SELECT s.[CrspndRef], s.[CtgryRef], s.[CreatedBy], s.[CreatedAt], s.[UpdatedBy], s.[UpdatedAt], s.[SourceSystem] FROM [gnr].[gnrCrspndCat] s WHERE NOT EXISTS (SELECT 1 FROM [YfgGen].[PartyCategoryLink] n WHERE n.[PartyRef]=s.[CrspndRef] AND n.[CategoryRef]=s.[CtgryRef]);
PRINT 'copied gnr.gnrCrspndCat → YfgGen.PartyCategoryLink';
GO
SET IDENTITY_INSERT [YfgAcc].[Tafsili] ON;
INSERT INTO [YfgAcc].[Tafsili] ([TafsiliId], [CompanyId], [TafsiliTypeId], [Code], [Title], [LatinTitle], [IsActive], [CreatedAt], [PartyRef], [CreatedBy], [UpdatedBy], [UpdatedAt], [SourceSystem])
SELECT s.[DlId], s.[CompanyId], s.[DlTypeId], s.[Code], s.[Title], s.[LatinTitle], s.[IsActive], s.[CreatedAt], s.[CrspndRef], s.[CreatedBy], s.[UpdatedBy], s.[UpdatedAt], s.[SourceSystem] FROM [Acc].[DL] s WHERE NOT EXISTS (SELECT 1 FROM [YfgAcc].[Tafsili] n WHERE n.[TafsiliId]=s.[DlId]);
SET IDENTITY_INSERT [YfgAcc].[Tafsili] OFF;
PRINT 'copied Acc.DL → YfgAcc.Tafsili';
GO
SET IDENTITY_INSERT [YfgAcc].[TafsiliCategory] ON;
INSERT INTO [YfgAcc].[TafsiliCategory] ([CategoryId], [CompanyId], [Title], [CreatedBy], [CreatedAt], [UpdatedBy], [UpdatedAt], [SourceSystem])
SELECT s.[CtgryId], s.[CompanyId], s.[Title], s.[CreatedBy], s.[CreatedAt], s.[UpdatedBy], s.[UpdatedAt], s.[SourceSystem] FROM [Acc].[DlCtgry] s WHERE NOT EXISTS (SELECT 1 FROM [YfgAcc].[TafsiliCategory] n WHERE n.[CategoryId]=s.[CtgryId]);
SET IDENTITY_INSERT [YfgAcc].[TafsiliCategory] OFF;
PRINT 'copied Acc.DlCtgry → YfgAcc.TafsiliCategory';
GO
INSERT INTO [YfgAcc].[TafsiliCategoryLink] ([CategoryId], [TafsiliId], [CreatedBy], [CreatedAt], [UpdatedBy], [UpdatedAt], [SourceSystem])
SELECT s.[CtgryId], s.[DlId], s.[CreatedBy], s.[CreatedAt], s.[UpdatedBy], s.[UpdatedAt], s.[SourceSystem] FROM [Acc].[DlCtgryLink] s WHERE NOT EXISTS (SELECT 1 FROM [YfgAcc].[TafsiliCategoryLink] n WHERE n.[CategoryId]=s.[CtgryId] AND n.[TafsiliId]=s.[DlId]);
PRINT 'copied Acc.DlCtgryLink → YfgAcc.TafsiliCategoryLink';
GO
SET IDENTITY_INSERT [YfgAcc].[AccGroup] ON;
INSERT INTO [YfgAcc].[AccGroup] ([GroupId], [CompanyId], [Code], [Title], [AccNature], [CreatedBy], [CreatedAt], [UpdatedBy], [UpdatedAt], [SourceSystem])
SELECT s.[GroupId], s.[CompanyId], s.[Code], s.[Title], s.[AccNature], s.[CreatedBy], s.[CreatedAt], s.[UpdatedBy], s.[UpdatedAt], s.[SourceSystem] FROM [Acc].[Group] s WHERE NOT EXISTS (SELECT 1 FROM [YfgAcc].[AccGroup] n WHERE n.[GroupId]=s.[GroupId]);
SET IDENTITY_INSERT [YfgAcc].[AccGroup] OFF;
PRINT 'copied Acc.Group → YfgAcc.AccGroup';
GO
SET IDENTITY_INSERT [YfgAcc].[Kol] ON;
INSERT INTO [YfgAcc].[Kol] ([KolId], [CompanyId], [Code], [GroupCode], [Title], [AccNature], [CreatedBy], [CreatedAt], [UpdatedBy], [UpdatedAt], [SourceSystem])
SELECT s.[KolId], s.[CompanyId], s.[Code], s.[GroupCode], s.[Title], s.[AccNature], s.[CreatedBy], s.[CreatedAt], s.[UpdatedBy], s.[UpdatedAt], s.[SourceSystem] FROM [Acc].[Kol] s WHERE NOT EXISTS (SELECT 1 FROM [YfgAcc].[Kol] n WHERE n.[KolId]=s.[KolId]);
SET IDENTITY_INSERT [YfgAcc].[Kol] OFF;
PRINT 'copied Acc.Kol → YfgAcc.Kol';
GO
SET IDENTITY_INSERT [YfgAcc].[Moein] ON;
INSERT INTO [YfgAcc].[Moein] ([MoeinId], [CompanyId], [Code], [KolCode], [Title], [AccNature], [Taf1TypeId], [Taf2TypeId], [Taf3TypeId], [Trackable], [Countable], [IsFx], [FxConvertible], [IsActive], [CreatedBy], [CreatedAt], [UpdatedBy], [UpdatedAt], [SourceSystem])
SELECT s.[MoeinId], s.[CompanyId], s.[Code], s.[KolCode], s.[Title], s.[AccNature], s.[Dl1TypeId], s.[Dl2TypeId], s.[Dl3TypeId], s.[Trackable], s.[Countable], s.[IsFx], s.[FxConvertible], s.[IsActive], s.[CreatedBy], s.[CreatedAt], s.[UpdatedBy], s.[UpdatedAt], s.[SourceSystem] FROM [Acc].[Moein] s WHERE NOT EXISTS (SELECT 1 FROM [YfgAcc].[Moein] n WHERE n.[MoeinId]=s.[MoeinId]);
SET IDENTITY_INSERT [YfgAcc].[Moein] OFF;
PRINT 'copied Acc.Moein → YfgAcc.Moein';
GO
SET IDENTITY_INSERT [YfgAcc].[StdNarration] ON;
INSERT INTO [YfgAcc].[StdNarration] ([NarrationId], [CompanyId], [MoeinCode], [Seq], [DescText], [CreatedBy], [CreatedAt], [UpdatedBy], [UpdatedAt], [SourceSystem])
SELECT s.[StdDescId], s.[CompanyId], s.[MoeinCode], s.[Seq], s.[DescText], s.[CreatedBy], s.[CreatedAt], s.[UpdatedBy], s.[UpdatedAt], s.[SourceSystem] FROM [Acc].[StdDesc] s WHERE NOT EXISTS (SELECT 1 FROM [YfgAcc].[StdNarration] n WHERE n.[NarrationId]=s.[StdDescId]);
SET IDENTITY_INSERT [YfgAcc].[StdNarration] OFF;
PRINT 'copied Acc.StdDesc → YfgAcc.StdNarration';
GO
SET IDENTITY_INSERT [YfgAcc].[OpeningBalance] ON;
INSERT INTO [YfgAcc].[OpeningBalance] ([ObId], [CompanyId], [YearId], [KolCode], [MoeinCode], [Taf1Id], [Taf2Id], [Taf3Id], [Dbt], [Crt], [CreatedBy], [CreatedAt], [UpdatedBy], [UpdatedAt], [SourceSystem])
SELECT s.[ObId], s.[CompanyId], s.[YearId], s.[KolCode], s.[MoeinCode], s.[Dl1Id], s.[Dl2Id], s.[Dl3Id], s.[Dbt], s.[Crt], s.[CreatedBy], s.[CreatedAt], s.[UpdatedBy], s.[UpdatedAt], s.[SourceSystem] FROM [Acc].[OpeningBalance] s WHERE NOT EXISTS (SELECT 1 FROM [YfgAcc].[OpeningBalance] n WHERE n.[ObId]=s.[ObId]);
SET IDENTITY_INSERT [YfgAcc].[OpeningBalance] OFF;
PRINT 'copied Acc.OpeningBalance → YfgAcc.OpeningBalance';
GO
SET IDENTITY_INSERT [YfgVch].[VoucherType] ON;
INSERT INTO [YfgVch].[VoucherType] ([VoucherTypeId], [CompanyId], [Title], [LatinTitle], [CreatedBy], [CreatedAt], [UpdatedBy], [UpdatedAt], [SourceSystem])
SELECT s.[TypeId], s.[CompanyId], s.[Title], s.[LatinTitle], s.[CreatedBy], s.[CreatedAt], s.[UpdatedBy], s.[UpdatedAt], s.[SourceSystem] FROM [Vch].[Type] s WHERE NOT EXISTS (SELECT 1 FROM [YfgVch].[VoucherType] n WHERE n.[VoucherTypeId]=s.[TypeId]);
SET IDENTITY_INSERT [YfgVch].[VoucherType] OFF;
PRINT 'copied Vch.Type → YfgVch.VoucherType';
GO
SET IDENTITY_INSERT [YfgVch].[Voucher] ON;
INSERT INTO [YfgVch].[Voucher] ([VoucherId], [CompanyId], [YearId], [FolioNo], [VchNo], [VoucherTypeId], [VchDate], [Descr], [State], [ReversalOf], [SourceModule], [CreatedBy], [CreatedAt], [CheckedBy], [CheckedAt], [FinalizedBy], [FinalizedAt], [UpdatedBy], [UpdatedAt], [EditedBy], [EditedAt], [SourceSystem])
SELECT s.[HdrId], s.[CompanyId], s.[YearId], s.[FolioNo], s.[VchNo], s.[TypeId], s.[VchDate], s.[Descr], s.[State], s.[ReversalOf], s.[SourceModule], s.[CreatedBy], s.[CreatedAt], s.[CheckedBy], s.[CheckedAt], s.[FinalizedBy], s.[FinalizedAt], s.[UpdatedBy], s.[UpdatedAt], s.[EditedBy], s.[EditedAt], s.[SourceSystem] FROM [Vch].[Hdr] s WHERE NOT EXISTS (SELECT 1 FROM [YfgVch].[Voucher] n WHERE n.[VoucherId]=s.[HdrId]);
SET IDENTITY_INSERT [YfgVch].[Voucher] OFF;
PRINT 'copied Vch.Hdr → YfgVch.Voucher';
GO
SET IDENTITY_INSERT [YfgVch].[VoucherLine] ON;
INSERT INTO [YfgVch].[VoucherLine] ([LineId], [VoucherId], [RowNo], [KolCode], [MoeinCode], [Taf1Id], [Taf2Id], [Taf3Id], [Descr], [Dbt], [Crt], [CreatedBy], [CreatedAt], [UpdatedBy], [UpdatedAt], [SourceSystem])
SELECT s.[ItmId], s.[HdrId], s.[RowNo], s.[KolCode], s.[MoeinCode], s.[Dl1Id], s.[Dl2Id], s.[Dl3Id], s.[Descr], s.[Dbt], s.[Crt], s.[CreatedBy], s.[CreatedAt], s.[UpdatedBy], s.[UpdatedAt], s.[SourceSystem] FROM [Vch].[Itm] s WHERE NOT EXISTS (SELECT 1 FROM [YfgVch].[VoucherLine] n WHERE n.[LineId]=s.[ItmId]);
SET IDENTITY_INSERT [YfgVch].[VoucherLine] OFF;
PRINT 'copied Vch.Itm → YfgVch.VoucherLine';
GO
SET IDENTITY_INSERT [YfgVch].[VoucherFlow] ON;
INSERT INTO [YfgVch].[VoucherFlow] ([LogId], [VoucherId], [Action], [ByUser], [At], [Note])
SELECT s.[LogId], s.[HdrId], s.[Action], s.[ByUser], s.[At], s.[Note] FROM [Vch].[WfLog] s WHERE NOT EXISTS (SELECT 1 FROM [YfgVch].[VoucherFlow] n WHERE n.[LogId]=s.[LogId]);
SET IDENTITY_INSERT [YfgVch].[VoucherFlow] OFF;
PRINT 'copied Vch.WfLog → YfgVch.VoucherFlow';
GO
INSERT INTO [YfgGen].[SubSystem] ([SystemCode], [TitleFa], [LatinTitle], [IsActive], [CreatedBy], [CreatedAt], [UpdatedBy], [UpdatedAt], [SourceSystem])
SELECT CASE WHEN s.[SystemCode]='GNR' THEN 'GEN' ELSE s.[SystemCode] END, s.[TitleFa], s.[LatinTitle], s.[IsActive], s.[CreatedBy], s.[CreatedAt], s.[UpdatedBy], s.[UpdatedAt], s.[SourceSystem] FROM [gnr].[Systems] s WHERE NOT EXISTS (SELECT 1 FROM [YfgGen].[SubSystem] n WHERE n.[SystemCode]=CASE WHEN s.[SystemCode]='GNR' THEN 'GEN' ELSE s.[SystemCode] END);
PRINT 'copied gnr.Systems → YfgGen.SubSystem';
GO
SET IDENTITY_INSERT [YfgGen].[AppSetting] ON;
INSERT INTO [YfgGen].[AppSetting] ([SettingId], [KeyValue], [DataValue], [SystemName], [Descr], [CreatedBy], [CreatedAt], [UpdatedBy], [UpdatedAt], [SourceSystem])
SELECT s.[MisSetupId], s.[KeyValue], s.[DataValue], CASE WHEN s.[SystemName]='GNR' THEN 'GEN' ELSE s.[SystemName] END, s.[Descr], s.[CreatedBy], s.[CreatedAt], s.[UpdatedBy], s.[UpdatedAt], s.[SourceSystem] FROM [gnr].[MisSetup] s WHERE NOT EXISTS (SELECT 1 FROM [YfgGen].[AppSetting] n WHERE n.[KeyValue]=s.[KeyValue] AND n.[SystemName]=CASE WHEN s.[SystemName]='GNR' THEN 'GEN' ELSE s.[SystemName] END);
SET IDENTITY_INSERT [YfgGen].[AppSetting] OFF;
PRINT 'copied gnr.MisSetup → YfgGen.AppSetting';
GO
SET IDENTITY_INSERT [YfgGen].[CodeList] ON;
INSERT INTO [YfgGen].[CodeList] ([CodeId], [Type], [Code], [Title], [Aux], [SystemName], [CreatedBy], [CreatedAt], [UpdatedBy], [UpdatedAt], [SourceSystem])
SELECT s.[LookupId], CASE WHEN s.[Type]='CompType' THEN 'PartyKind' ELSE s.[Type] END, s.[Code], s.[Title], s.[Aux], s.[SystemName], s.[CreatedBy], s.[CreatedAt], s.[UpdatedBy], s.[UpdatedAt], s.[SourceSystem] FROM [gnr].[Lookup] s WHERE NOT EXISTS (SELECT 1 FROM [YfgGen].[CodeList] n WHERE n.[Type]=CASE WHEN s.[Type]='CompType' THEN 'PartyKind' ELSE s.[Type] END AND n.[Code]=s.[Code]);
SET IDENTITY_INSERT [YfgGen].[CodeList] OFF;
PRINT 'copied gnr.Lookup → YfgGen.CodeList';
GO
INSERT INTO [YfgGen].[IdSequence] ([TableName], [LastId], [CreatedBy], [CreatedAt], [UpdatedBy], [UpdatedAt], [SourceSystem])
SELECT s.[TableName], s.[LastId], s.[CreatedBy], s.[CreatedAt], s.[UpdatedBy], s.[UpdatedAt], s.[SourceSystem] FROM [gnr].[TableIdGen] s WHERE NOT EXISTS (SELECT 1 FROM [YfgGen].[IdSequence] n WHERE n.[TableName]=s.[TableName]);
PRINT 'copied gnr.TableIdGen → YfgGen.IdSequence';
GO
SET IDENTITY_INSERT [YfgGen].[HolidayType] ON;
INSERT INTO [YfgGen].[HolidayType] ([HolidayTypeId], [Title], [IsActive], [CreatedBy], [CreatedAt], [UpdatedBy], [UpdatedAt], [SourceSystem])
SELECT s.[HolidayTypeId], s.[Title], s.[IsActive], s.[CreatedBy], s.[CreatedAt], s.[UpdatedBy], s.[UpdatedAt], s.[SourceSystem] FROM [gnr].[gnrHolidayTypes] s WHERE NOT EXISTS (SELECT 1 FROM [YfgGen].[HolidayType] n WHERE n.[Title]=s.[Title]);
SET IDENTITY_INSERT [YfgGen].[HolidayType] OFF;
PRINT 'copied gnr.gnrHolidayTypes → YfgGen.HolidayType';
GO
SET IDENTITY_INSERT [YfgGen].[Holiday] ON;
INSERT INTO [YfgGen].[Holiday] ([HolidayId], [JDate], [HolidayTypeRef], [Descr], [CreatedBy], [CreatedAt], [UpdatedBy], [UpdatedAt], [SourceSystem])
SELECT s.[HolidayId], s.[JDate], s.[HolidayTypeRef], s.[Descr], s.[CreatedBy], s.[CreatedAt], s.[UpdatedBy], s.[UpdatedAt], s.[SourceSystem] FROM [gnr].[gnrHolidays] s WHERE NOT EXISTS (SELECT 1 FROM [YfgGen].[Holiday] n WHERE n.[HolidayId]=s.[HolidayId]);
SET IDENTITY_INSERT [YfgGen].[Holiday] OFF;
PRINT 'copied gnr.gnrHolidays → YfgGen.Holiday';
GO
SET IDENTITY_INSERT [YfgGen].[NonWorkingTime] ON;
INSERT INTO [YfgGen].[NonWorkingTime] ([NonWorkId], [JDate], [FromTime], [ToTime], [Descr], [CreatedBy], [CreatedAt], [UpdatedBy], [UpdatedAt], [SourceSystem])
SELECT s.[NonWorkId], s.[JDate], s.[FromTime], s.[ToTime], s.[Descr], s.[CreatedBy], s.[CreatedAt], s.[UpdatedBy], s.[UpdatedAt], s.[SourceSystem] FROM [gnr].[gnrNonWorkingTimes] s WHERE NOT EXISTS (SELECT 1 FROM [YfgGen].[NonWorkingTime] n WHERE n.[NonWorkId]=s.[NonWorkId]);
SET IDENTITY_INSERT [YfgGen].[NonWorkingTime] OFF;
PRINT 'copied gnr.gnrNonWorkingTimes → YfgGen.NonWorkingTime';
GO
SELECT N'table' src, N'old' side, COUNT(*) cnt FROM gnr.Crspnd
UNION ALL SELECT N'YfgGen.Party', N'new', COUNT(*) FROM YfgGen.Party
UNION ALL SELECT N'YfgVch.Voucher', N'new', COUNT(*) FROM YfgVch.Voucher
UNION ALL SELECT N'YfgVch.VoucherLine', N'new', COUNT(*) FROM YfgVch.VoucherLine;
GO
