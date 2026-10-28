#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""مولد اسکریپت‌های مهاجرت v1.2.0 (بازنامینی YFG) — خروجی:
   sql/10_snapshot_v1.2.0.sql  (پشتیبان داخل دیتابیس — YfgBak)
   sql/11_datacopy_v1.2.0.sql  (کپی داده از جدول‌های قدیم به جدید، Idempotent)
   sql/12_dropold_v1.2.0.sql   (حذف اشیای قدیم + راستی‌آزمایی)
اسکریپت‌های 01/03/03b نو (بازنام‌شده) ساخت اشیای جدید را انجام می‌دهند."""
import json, io, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
cat = json.load(io.open(os.path.join(ROOT, "scripts/_catalog.json"), encoding="utf-8"))
OLD = cat["tables"]

TMAP = {
 "Prm.Company": "YfgPrm.Company", "Prm.AppUser": "YfgPrm.AppUser",
 "Prm.FiscalYear": "YfgPrm.FiscalYear", "Prm.FiscalPeriod": "YfgPrm.FiscalPeriod",
 "Acc.DlType": "YfgAcc.TafsiliType", "Acc.DL": "YfgAcc.Tafsili",
 "Acc.DlCtgry": "YfgAcc.TafsiliCategory", "Acc.DlCtgryLink": "YfgAcc.TafsiliCategoryLink",
 "Acc.Group": "YfgAcc.AccGroup", "Acc.Kol": "YfgAcc.Kol", "Acc.Moein": "YfgAcc.Moein",
 "Acc.StdDesc": "YfgAcc.StdNarration", "Acc.OpeningBalance": "YfgAcc.OpeningBalance",
 "Vch.Type": "YfgVch.VoucherType", "Vch.Hdr": "YfgVch.Voucher",
 "Vch.Itm": "YfgVch.VoucherLine", "Vch.WfLog": "YfgVch.VoucherFlow",
 "gnr.Crspnd": "YfgGen.Party", "gnr.Address": "YfgGen.PartyAddress",
 "gnr.GeoPos": "YfgGen.GeoPlace", "gnr.CrspndCtgry": "YfgGen.PartyCategory",
 "gnr.gnrCrspndCat": "YfgGen.PartyCategoryLink", "gnr.MisSetup": "YfgGen.AppSetting",
 "gnr.Lookup": "YfgGen.CodeList", "gnr.Systems": "YfgGen.SubSystem",
 "gnr.TableIdGen": "YfgGen.IdSequence", "gnr.gnrHolidayTypes": "YfgGen.HolidayType",
 "gnr.gnrHolidays": "YfgGen.Holiday", "gnr.gnrNonWorkingTimes": "YfgGen.NonWorkingTime",
}

CMAP = {  # تغییر نام ستون‌ها (دقیق، حساس به حروف)
 "CrspndRef":"PartyRef","CompType":"PartyKind","GeoPosRef":"GeoPlaceRef","GeoPosId":"GeoPlaceId",
 "MisSetupId":"SettingId","LookupId":"CodeId","LookupType":"CodeListType",
 "DlTypeId":"TafsiliTypeId","Dl1TypeId":"Taf1TypeId","Dl2TypeId":"Taf2TypeId","Dl3TypeId":"Taf3TypeId",
 "Dl1Id":"Taf1Id","Dl2Id":"Taf2Id","Dl3Id":"Taf3Id","DlId":"TafsiliId",
 "CtgryId":"CategoryId","CtgryRef":"CategoryRef","HdrId":"VoucherId","ItmId":"LineId",
 "TypeId":"VoucherTypeId","StdDescId":"NarrationId",
}

# ترتیب کپی: والد قبل از فرزند
ORDER = ["Prm.Company","Prm.AppUser","Prm.FiscalYear","Prm.FiscalPeriod",
 "Acc.DlType","gnr.Crspnd","gnr.GeoPos","gnr.Address","gnr.CrspndCtgry","gnr.gnrCrspndCat",
 "Acc.DL","Acc.DlCtgry","Acc.DlCtgryLink","Acc.Group","Acc.Kol","Acc.Moein","Acc.StdDesc",
 "Acc.OpeningBalance","Vch.Type","Vch.Hdr","Vch.Itm","Vch.WfLog",
 "gnr.Systems","gnr.MisSetup","gnr.Lookup","gnr.TableIdGen","gnr.gnrHolidayTypes",
 "gnr.gnrHolidays","gnr.gnrNonWorkingTimes"]

# تبدیل درجای مقدار + شرط تکرارنپذیری برای جدول‌های بذری
VALUE_CAST = {
 "gnr.Lookup":   {"Type": "CASE WHEN s.[Type]='CompType' THEN 'PartyKind' ELSE s.[Type] END"},
 "gnr.Systems":  {"SystemCode": "CASE WHEN s.[SystemCode]='GNR' THEN 'GEN' ELSE s.[SystemCode] END"},
 "gnr.MisSetup": {"SystemName": "CASE WHEN s.[SystemName]='GNR' THEN 'GEN' ELSE s.[SystemName] END"},
}
DEDUP = {  # جدول‌های بذری — ردیف تکراریِ حاصل از seed جدید نریز
 "gnr.GeoPos":  "NOT EXISTS (SELECT 1 FROM {new} n WHERE n.[Title]=s.[Title] AND n.[GeoType]=s.[GeoType])",
 "gnr.Systems": "NOT EXISTS (SELECT 1 FROM {new} n WHERE n.[SystemCode]=CASE WHEN s.[SystemCode]='GNR' THEN 'GEN' ELSE s.[SystemCode] END)",
 "gnr.MisSetup":"NOT EXISTS (SELECT 1 FROM {new} n WHERE n.[KeyValue]=s.[KeyValue] AND n.[SystemName]=CASE WHEN s.[SystemName]='GNR' THEN 'GEN' ELSE s.[SystemName] END)",
 "gnr.Lookup":  "NOT EXISTS (SELECT 1 FROM {new} n WHERE n.[Type]=CASE WHEN s.[Type]='CompType' THEN 'PartyKind' ELSE s.[Type] END AND n.[Code]=s.[Code])",
 "gnr.gnrHolidayTypes": "NOT EXISTS (SELECT 1 FROM {new} n WHERE n.[Title]=s.[Title])",
}

def q(name):  # [schema].[table] با پشتیبانی [Group]
    a, b = name.split(".", 1)
    return f"[{a}].[{b}]"

def real_cols(tbl):
    return [c for c in OLD[tbl] if not c["comp"]]

def has_identity(tbl):
    return any(c["id"] for c in OLD[tbl])

def id_col(tbl):
    return next((c["col"] for c in OLD[tbl] if c["id"]), None)

def gen_snapshot():
    L = ["/* اسنپ‌شات امنیتی پیش از مهاجرت v1.2.0 — در شِمای YfgBak (حذف‌شدنی پس از تأیید کارفرما) */",
         "IF SCHEMA_ID('YfgBak') IS NULL EXEC('CREATE SCHEMA YfgBak');", "GO"]
    for t in ORDER:
        b = t.replace(".", "_").replace(" ", "")
        L.append(f"IF OBJECT_ID('YfgBak.{b}') IS NOT NULL DROP TABLE YfgBak.{b};")
        L.append(f"SELECT * INTO YfgBak.{b} FROM {q(t)};")
        L.append("GO")
    L.append("PRINT '=== snapshot done ===';"); L.append("GO")
    return "\n".join(L)

def gen_datacopy():
    L = ["/* مهاجرت v1.2.0 — کپی داده از اشیای قدیم (Prm/Acc/Vch/gnr) به جدید (YfgPrm/YfgAcc/YfgVch/YfgGen)",
         "   اجرای تکرارپذیر (Idempotent) — ردیف‌های موجود با کلید یکتا دوباره درج نمی‌شوند */", "GO"]
    for t in ORDER:
        new = TMAP[t]; cols = real_cols(t)
        sel, ins = [], []
        for c in cols:
            oc = c["col"]; nc = CMAP.get(oc, oc)
            cast = VALUE_CAST.get(t, {}).get(oc)
            sel.append(cast if cast else f"s.[{oc}]")
            ins.append(f"[{nc}]")
        ident = has_identity(t)
        idold, idnew = (None, None)
        if ident:
            idold = id_col(t); idnew = CMAP.get(idold, idold)
        where = ""
        if t in DEDUP:
            where = "WHERE " + DEDUP[t].format(new=q(new))
        elif ident:
            where = f"WHERE NOT EXISTS (SELECT 1 FROM {q(new)} n WHERE n.[{idnew}]=s.[{idold}])"
        elif idold is None:
            pkmap = {"Acc.DlCtgryLink": ("CtgryId","DlId","CategoryId","TafsiliId"),
                     "gnr.gnrCrspndCat": ("CrspndRef","CtgryRef","PartyRef","CategoryRef"),
                     "gnr.TableIdGen": ("TableName",None,"TableName",None)}
            a,b,na,nb = pkmap[t]
            cond = f"n.[{na}]=s.[{a}]" + (f" AND n.[{nb}]=s.[{b}]" if b else "")
            where = f"WHERE NOT EXISTS (SELECT 1 FROM {q(new)} n WHERE {cond})"
        if ident:
            L.append(f"SET IDENTITY_INSERT {q(new)} ON;")
        L.append(f"INSERT INTO {q(new)} ({', '.join(ins)})")
        L.append(f"SELECT {', '.join(sel)} FROM {q(t)} s {where};")
        if ident:
            L.append(f"SET IDENTITY_INSERT {q(new)} OFF;")
        L.append(f"PRINT 'copied {t} → {new}';"); L.append("GO")
    # راستی‌آزمایی تعداد
    L.append("SELECT N'table' src, N'old' side, COUNT(*) cnt FROM gnr.Crspnd")
    L.append("UNION ALL SELECT N'YfgGen.Party', N'new', COUNT(*) FROM YfgGen.Party")
    L.append("UNION ALL SELECT N'YfgVch.Voucher', N'new', COUNT(*) FROM YfgVch.Voucher")
    L.append("UNION ALL SELECT N'YfgVch.VoucherLine', N'new', COUNT(*) FROM YfgVch.VoucherLine;")
    L.append("GO")
    return "\n".join(L)

DROP_ORDER = ["Vch.Itm","Vch.WfLog","Vch.Hdr","Vch.Type",
 "Acc.OpeningBalance","Acc.StdDesc","Acc.Moein","Acc.Kol","Acc.Group","Acc.DlCtgryLink",
 "Acc.DlCtgry","Acc.DL","Acc.DlType",
 "gnr.gnrNonWorkingTimes","gnr.gnrHolidays","gnr.gnrHolidayTypes","gnr.TableIdGen",
 "gnr.Systems","gnr.Lookup","gnr.MisSetup","gnr.gnrCrspndCat","gnr.CrspndCtgry",
 "gnr.Address","gnr.GeoPos","gnr.Crspnd",
 "Prm.FiscalPeriod","Prm.FiscalYear","Prm.AppUser","Prm.Company"]
FUNCS = ["gnr.Grg2Jal","gnr.Jal2Grg","gnr._Jal2Jdn","gnr._JalMarch","gnr._Jdn2Grg",
         "gnr._JalLeap","gnr._Grg2Jdn","gnr._JalBreak"]

def gen_dropold():
    L = ["/* مهاجرت v1.2.0 — حذف اشیای قدیم (پس از کپی موفق داده) */", "GO",
         "IF OBJECT_ID('Acc.VwChart') IS NOT NULL DROP VIEW Acc.VwChart;", "GO"]
    for t in DROP_ORDER:
        L.append(f"IF OBJECT_ID('{t}') IS NOT NULL DROP TABLE {q(t)};")
        L.append("GO")
    for f in FUNCS:
        L.append(f"IF OBJECT_ID('{f}') IS NOT NULL DROP FUNCTION {q(f)};")
        L.append("GO")
    for s in ["Prm","Acc","Vch","gnr"]:
        L.append(f"IF SCHEMA_ID('{s}') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM sys.objects WHERE schema_id=SCHEMA_ID('{s}')) EXEC('DROP SCHEMA {s}');")
        L.append("GO")
    L.append("""/* راستی‌آزمایی نهایی */
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
UNION ALL SELECT N'YfgAcc.Tafsili', COUNT(*) FROM YfgAcc.Tafsili;""")
    L.append("GO")
    return "\n".join(L)

if __name__ == "__main__":
    missing = [t for t in ORDER if t not in OLD]
    if missing:
        raise SystemExit(f"OLD catalog missing: {missing}")
    for fn, gen in [("sql/10_snapshot_v1.2.0.sql", gen_snapshot),
                    ("sql/11_datacopy_v1.2.0.sql", gen_datacopy),
                    ("sql/12_dropold_v1.2.0.sql", gen_dropold)]:
        io.open(os.path.join(ROOT, fn), "w", encoding="utf-8").write(gen() + "\n")
        print("generated", fn)
