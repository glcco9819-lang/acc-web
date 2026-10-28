#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""سازندهٔ sql/06_meta_dictionary.sql — واژه‌نامهٔ داده (سه جدول YFG.TableName/FieldName/LinkField)
   Seed کامل: ۳۶ جدول + همهٔ ستون‌ها با نام فارسی بر اساس نقش + پیوندها"""
import io

# ---------- نام فارسی جدول‌ها بر اساس نقش (مثال کارفرما: لیست اسناد) ----------
TBL = {
 "ACC.AccBranch":            ("تعریف شعب", 1),
 "ACC.AccFx":                ("تعریف ارزها", 1),
 "ACC.AccGroup":             ("گروه‌های حساب کل", 1),
 "ACC.AccKol":               ("کدینگ حساب‌های کل", 1),
 "ACC.AccMoein":             ("کدینگ حساب‌های معین", 1),
 "ACC.AccOpeningBalance":    ("ماندهٔ افتتاحیهٔ حساب‌ها", 0),
 "ACC.AccStdNarration":      ("شرح‌های استاندارد سند", 1),
 "ACC.AccTafsili":           ("حساب‌های تفصیلی", 1),
 "ACC.AccTafsiliCategory":   ("طبقه‌بندی تفصیلی", 1),
 "ACC.AccTafsiliCategoryLink":("پیوند تفصیلی به طبقه‌بندی", 0),
 "ACC.AccTafsiliType":       ("انواع تفصیلی", 1),
 "ACC.AccVoucher":           ("اسناد حسابداری (لیست اسناد)", 0),
 "ACC.AccVoucherFlow":       ("جریان وضعیت اسناد", 0),
 "ACC.AccVoucherItm":        ("اقلام اسناد حسابداری", 0),
 "ACC.AccVoucherType":       ("انواع سند حسابداری", 1),
 "ACC.AccVwChart":           ("نمای درختی کدینگ حساب‌ها", 0),
 "pob.AppSetting":           ("تنظیمات برنامه", 1),
 "pob.AppUser":              ("کاربران برنامه", 1),
 "pob.CodeList":             ("فهرست‌های کد ثابت", 1),
 "pob.Companies":            ("لیست شرکت‌ها", 1),
 "pob.FiscalPeriod":         ("دوره‌های مالی (ماه‌ها)", 1),
 "pob.FiscalYear":           ("سال‌های مالی", 1),
 "pob.GeoPlace":             ("تقسیمات جغرافیایی", 1),
 "pob.Holiday":              ("تعطیلات و تقویم", 1),
 "pob.HolidayType":          ("انواع تعطیلات", 1),
 "pob.IdSequence":           ("شمارنده‌های یکتا", 0),
 "pob.NonWorkingTime":       ("ساعات غیرکاری", 1),
 "pob.Party":                ("اشخاص و طرف حساب‌ها", 1),
 "pob.PartyAddress":         ("نشانی اشخاص", 1),
 "pob.PartyCategory":        ("دسته‌بندی اشخاص", 1),
 "pob.PartyCategoryLink":    ("پیوند شخص به دسته‌بندی", 0),
 "pob.SubSystem":            ("زیرسیستم‌ها", 1),
 "pob.UserLog":              ("لاگ فعالیت کاربران", 0),
 "YFG.TableName":            ("واژه‌نامهٔ جدول‌ها", 1),
 "YFG.FieldName":            ("واژه‌نامهٔ فیلدها", 1),
 "YFG.LinkField":            ("واژه‌نامهٔ پیوندها", 1),
}
MODULE = {"ACC": "حسابداری", "pob": "عمومی (بستر)", "YFG": "واژه‌نامه"}

# ---------- نام فارسی فیلدها بر اساس نقش (مثال کارفرما: شماره سند) ----------
GLB = {
 "CompanyId":"کد شرکت","CreatedBy":"ایجادکننده","CreatedAt":"تاریخ ایجاد",
 "CreatedAtJ":"تاریخ ایجاد (شمسی)","UpdatedBy":"ویرایش‌کننده","UpdatedAt":"تاریخ ویرایش",
 "UpdatedAtJ":"تاریخ ویرایش (شمسی)","SourceSystem":"سیستم مبدأ","IsActive":"فعال (بله/خیر)",
}
COL = {
 "ACC.AccBranch":{"BranchId":"شناسهٔ شعبه","Code":"کد شعبه","Title":"عنوان شعبه"},
 "ACC.AccFx":{"FxId":"شناسهٔ ارز","Code":"کد ارز","Title":"عنوان ارز","LatinTitle":"عنوان لاتین ارز","IsBase":"ارز پایه (بله/خیر)"},
 "ACC.AccGroup":{"GroupId":"شناسهٔ گروه","Code":"کد گروه","Title":"عنوان گروه","AccNature":"ماهیت حساب"},
 "ACC.AccKol":{"KolId":"شناسهٔ حساب کل","Code":"کد کل","GroupCode":"کد گروه","Title":"عنوان کل","AccNature":"ماهیت حساب"},
 "ACC.AccMoein":{"MoeinId":"شناسهٔ حساب معین","Code":"کد معین","KolCode":"کد کل","Title":"عنوان معین","AccNature":"ماهیت حساب",
   "Taf1TypeId":"نوع تفصیلی سطح ۴","Taf2TypeId":"نوع تفصیلی سطح ۵","Taf3TypeId":"نوع تفصیلی سطح ۶",
   "Trackable":"قابل پیگیری (بله/خیر)","Countable":"قابل شمارش (بله/خیر)","IsFx":"ارزی (بله/خیر)","FxConvertible":"قابل تبدیل ارز (بله/خیر)"},
 "ACC.AccOpeningBalance":{"ObId":"شناسهٔ ردیف","YearId":"سال مالی","KolCode":"کد کل","MoeinCode":"کد معین",
   "Taf1Id":"تفصیلی سطح ۴","Taf2Id":"تفصیلی سطح ۵","Taf3Id":"تفصیلی سطح ۶","Dbt":"بدهکار","Crt":"بستانکار"},
 "ACC.AccStdNarration":{"NarrationId":"شناسهٔ شرح","MoeinCode":"کد معین","Seq":"ترتیب","DescText":"متن شرح استاندارد"},
 "ACC.AccTafsili":{"TafsiliId":"شناسهٔ تفصیلی","TafsiliTypeId":"نوع تفصیلی","Code":"کد تفصیلی","Title":"عنوان تفصیلی",
   "LatinTitle":"عنوان لاتین","PartyRef":"مرجع شخص"},
 "ACC.AccTafsiliCategory":{"CategoryId":"شناسهٔ طبقه‌بندی","Title":"عنوان طبقه‌بندی"},
 "ACC.AccTafsiliCategoryLink":{"CategoryId":"طبقه‌بندی","TafsiliId":"تفصیلی"},
 "ACC.AccTafsiliType":{"TafsiliTypeId":"شناسهٔ نوع تفصیلی","Title":"عنوان نوع تفصیلی","LatinTitle":"عنوان لاتین","CodeListType":"نوع فهرست کد"},
 "ACC.AccVoucher":{"VoucherId":"شناسهٔ سند","FolioNo":"شمارهٔ عطف","VchNo":"شمارهٔ سند","VoucherTypeId":"نوع سند",
   "VchDate":"تاریخ سند (جلالی)","Descr":"شرح سند","State":"وضعیت سند","ReversalOf":"شناسهٔ سند مبنای ابطال",
   "SourceModule":"ماژول مبدأ","CheckedBy":"بررسی‌کننده","CheckedAt":"تاریخ بررسی","CheckedAtJ":"تاریخ بررسی (شمسی)",
   "FinalizedBy":"قطعی‌کننده","FinalizedAt":"تاریخ قطعی","FinalizedAtJ":"تاریخ قطعی (شمسی)",
   "EditedBy":"آخرین ویراستار","EditedAt":"تاریخ ویرایش","EditedAtJ":"تاریخ ویرایش (شمسی)",
   "BranchId":"شعبه","DayNo":"شمارهٔ روزانهٔ سند","SubNo":"شمارهٔ فرعی سند","LatinDescr":"شرح لاتین سند"},
 "ACC.AccVoucherFlow":{"LogId":"شناسهٔ ردیف جریان","VoucherId":"شناسهٔ سند","Action":"عملیات","ByUser":"کاربر",
   "At":"زمان","AtJ":"زمان (شمسی)","Note":"یادداشت"},
 "ACC.AccVoucherItm":{"LineId":"شناسهٔ قلم","VoucherId":"شناسهٔ سند","RowNo":"ردیف قلم","KolCode":"کد کل",
   "MoeinCode":"کد معین","Taf1Id":"تفصیلی سطح ۴","Taf2Id":"تفصیلی سطح ۵","Taf3Id":"تفصیلی سطح ۶",
   "Descr":"شرح قلم","Dbt":"بدهکار","Crt":"بستانکار",
   "FxId":"نوع ارز قلم","FxAmount":"مبلغ ارزی","FxRate":"نرخ ارز",
   "TrackNo":"شمارهٔ پیگیری","TrackDate":"تاریخ پیگیری (جلالی)","LatinDescr":"شرح لاتین قلم"},
 "ACC.AccVoucherType":{"VoucherTypeId":"شناسهٔ نوع سند","Title":"عنوان نوع سند","LatinTitle":"شرح لاتین"},
 "ACC.AccVwChart":{"GroupCode":"کد گروه","GroupTitle":"عنوان گروه","KolCode":"کد کل","KolTitle":"عنوان کل",
   "MoeinCode":"کد معین","MoeinTitle":"عنوان معین","MoeinActive":"فعال (بله/خیر)",
   "Taf1TypeId":"نوع تفصیلی سطح ۴","Taf2TypeId":"نوع تفصیلی سطح ۵","Taf3TypeId":"نوع تفصیلی سطح ۶"},
 "pob.AppSetting":{"SettingId":"شناسهٔ تنظیم","KeyValue":"کلید تنظیم","DataValue":"مقدار","SystemName":"زیرسیستم","Descr":"توضیح"},
 "pob.AppUser":{"UserId":"شناسهٔ کاربر","Username":"نام کاربری","DisplayName":"نام نمایشی","RoleCode":"کد نقش","PassHash":"هش رمز عبور"},
 "pob.CodeList":{"CodeId":"شناسهٔ کد","Type":"نوع فهرست","Code":"کد","Title":"عنوان","Aux":"ستون کمکی","SystemName":"زیرسیستم"},
 "pob.Companies":{"CompanyId":"شناسهٔ شرکت","CompanyCode":"کد شرکت","TitleFa":"نام شرکت (فارسی)",
   "NationalId":"شناسهٔ ملی","EconomicCode":"کد اقتصادی","CodingMode":"حالت کدینگ"},
 "pob.FiscalPeriod":{"PeriodId":"شناسهٔ دوره","YearId":"سال مالی","MonthNo":"شمارهٔ ماه","Title":"عنوان دوره","IsClosed":"بسته‌شده (بله/خیر)"},
 "pob.FiscalYear":{"YearId":"شناسهٔ سال مالی","JalaliYear":"سال شمسی","Title":"عنوان سال مالی",
   "StartDate":"تاریخ شروع (جلالی)","EndDate":"تاریخ پایان (جلالی)","IsClosed":"بسته‌شده (بله/خیر)"},
 "pob.GeoPlace":{"GeoPlaceId":"شناسهٔ موقعیت","ParentRef":"موقعیت والد","Title":"عنوان","GeoType":"نوع تقسیم","LatinTitle":"عنوان لاتین"},
 "pob.Holiday":{"HolidayId":"شناسهٔ تعطیلی","JDate":"تاریخ (جلالی)","GDate":"تاریخ (میلادی)","HolidayTypeRef":"نوع تعطیلی","Descr":"توضیح"},
 "pob.HolidayType":{"HolidayTypeId":"شناسهٔ نوع تعطیلی","Title":"عنوان نوع تعطیلی"},
 "pob.IdSequence":{"TableName":"نام جدول","LastId":"آخرین شناسه"},
 "pob.NonWorkingTime":{"NonWorkId":"شناسهٔ ردیف","JDate":"تاریخ (جلالی)","FromTime":"از ساعت","ToTime":"تا ساعت","Descr":"توضیح"},
 "pob.Party":{"Serial":"شناسهٔ شخص","RecType":"نوع رکورد (شخص/شرکت)","PartyKind":"نوع شخص (حقیقی/حقوقی)",
   "CompName":"نام شرکت","Title":"عنوان شخص","FName":"نام","LName":"نام خانوادگی","NickName":"لقب",
   "Title_En":"عنوان لاتین","FName_En":"نام لاتین","LName_En":"نام خانوادگی لاتین","CompName_En":"نام شرکت لاتین",
   "EconCode":"کد اقتصادی","NationalCode":"کد/شناسهٔ ملی","FatherName":"نام پدر","IDNo":"شمارهٔ شناسنامه","MainAddrRef":"مرجع نشانی اصلی"},
 "pob.PartyAddress":{"Serial":"شناسهٔ نشانی","PartyRef":"شناسهٔ شخص","Title":"عنوان نشانی","Address":"نشانی",
   "Address_En":"نشانی لاتین","ZipCode":"کد پستی","PostBox":"صندوق پستی","Phone":"تلفن","Fax":"فکس",
   "EMail":"ایمیل","Modem":"مودم","Mobile":"تلفن همراه","GeoPlaceRef":"موقعیت جغرافیایی"},
 "pob.PartyCategory":{"CategoryId":"شناسهٔ دسته‌بندی","Title":"عنوان دسته‌بندی","ParentRef":"دستهٔ والد"},
 "pob.PartyCategoryLink":{"PartyRef":"شناسهٔ شخص","CategoryRef":"شناسهٔ دسته‌بندی"},
 "pob.SubSystem":{"SystemCode":"کد زیرسیستم","TitleFa":"عنوان فارسی","LatinTitle":"عنوان لاتین"},
 "pob.UserLog":{"UserLogId":"شناسهٔ لاگ","UserName":"کاربر","LogDate":"تاریخ (جلالی)","LogTime":"زمان",
   "ComputerName":"نام رایانه","IpAddress":"آدرس IP","ActivityType":"نوع فعالیت","SubSystem":"زیرسیستم",
   "TableName":"نام جدول","RecId":"شناسهٔ رکورد","DocInfo":"اطلاعات سند","FieldName":"نام فیلد",
   "OldValue":"مقدار قبلی","NewValue":"مقدار جدید"},
 "YFG.TableName":{"TableId":"شناسهٔ جدول","TableSchema":"شمای جدول","TableName":"نام جدول (انگلیسی)",
   "TableFa":"نام فارسی جدول بر اساس نقش","Module":"ماژول","IsLookup":"جدول مرجع (بله/خیر)"},
 "YFG.FieldName":{"FieldId":"شناسهٔ فیلد","TableSchema":"شمای جدول","TableName":"نام جدول","FieldName":"نام فیلد (انگلیسی)",
   "FieldFa":"نام فارسی فیلد بر اساس نقش","Module":"ماژول","DataType":"نوع داده"},
 "YFG.LinkField":{"LinkId":"شناسهٔ پیوند","TableSchema":"شمای جدول","TableName":"نام جدول","FieldName":"نام فیلد",
   "FieldFa":"نام فارسی فیلد بر اساس نقش","LinkTableSchema":"شمای جدول لینک","LinkTableName":"نام جدول لینک",
   "LinkFieldName":"نام فیلد لینک","LinkFieldFa":"نام فارسی فیلد لینک","LinkRole":"نقش فیلد در پیوند"},
}

# ---------- پیوندها (فیلد → جدول لینک) ----------
# (schema,table,field, linkSchema,linkTable,linkField, نقش)
LNK = [
 ("ACC","AccFx","CompanyId","pob","Companies","CompanyId","مرجع شرکت مالک ارز"),
 ("ACC","AccBranch","CompanyId","pob","Companies","CompanyId","مرجع شرکت مالک شعبه"),
 ("ACC","AccGroup","CompanyId","pob","Companies","CompanyId","مرجع شرکت مالک گروه"),
 ("ACC","AccKol","CompanyId","pob","Companies","CompanyId","مرجع شرکت مالک کل"),
 ("ACC","AccKol","GroupCode","ACC","AccGroup","Code","کد گروهِ حساب کل"),
 ("ACC","AccMoein","CompanyId","pob","Companies","CompanyId","مرجع شرکت مالک معین"),
 ("ACC","AccMoein","KolCode","ACC","AccKol","Code","حساب کلِ معین"),
 ("ACC","AccMoein","Taf1TypeId","ACC","AccTafsiliType","TafsiliTypeId","نوع تفصیلی سطح چهارم معین"),
 ("ACC","AccMoein","Taf2TypeId","ACC","AccTafsiliType","TafsiliTypeId","نوع تفصیلی سطح پنجم معین"),
 ("ACC","AccMoein","Taf3TypeId","ACC","AccTafsiliType","TafsiliTypeId","نوع تفصیلی سطح ششم معین"),
 ("ACC","AccTafsili","CompanyId","pob","Companies","CompanyId","مرجع شرکت مالک تفصیلی"),
 ("ACC","AccTafsili","TafsiliTypeId","ACC","AccTafsiliType","TafsiliTypeId","نوعِ تفصیلی"),
 ("ACC","AccTafsili","PartyRef","pob","Party","Serial","شخص متناظر با تفصیلی"),
 ("ACC","AccTafsiliCategoryLink","CategoryId","ACC","AccTafsiliCategory","CategoryId","طبقه‌بندیِ پیوند"),
 ("ACC","AccTafsiliCategoryLink","TafsiliId","ACC","AccTafsili","TafsiliId","تفصیلیِ پیوند"),
 ("ACC","AccOpeningBalance","CompanyId","pob","Companies","CompanyId","مرجع شرکت ماندهٔ افتتاحیه"),
 ("ACC","AccOpeningBalance","YearId","pob","FiscalYear","YearId","سال مالی ماندهٔ افتتاحیه"),
 ("ACC","AccOpeningBalance","KolCode","ACC","AccKol","Code","کد کل ماندهٔ افتتاحیه"),
 ("ACC","AccOpeningBalance","MoeinCode","ACC","AccMoein","Code","کد معین ماندهٔ افتتاحیه"),
 ("ACC","AccOpeningBalance","Taf1Id","ACC","AccTafsili","TafsiliId","تفصیلی سطح چهارم ماندهٔ افتتاحیه"),
 ("ACC","AccOpeningBalance","Taf2Id","ACC","AccTafsili","TafsiliId","تفصیلی سطح پنجم ماندهٔ افتتاحیه"),
 ("ACC","AccOpeningBalance","Taf3Id","ACC","AccTafsili","TafsiliId","تفصیلی سطح ششم ماندهٔ افتتاحیه"),
 ("ACC","AccStdNarration","CompanyId","pob","Companies","CompanyId","مرجع شرکت شرح استاندارد"),
 ("ACC","AccStdNarration","MoeinCode","ACC","AccMoein","Code","کد معینِ شرح استاندارد"),
 ("ACC","AccVoucher","CompanyId","pob","Companies","CompanyId","شرکت مالک سند"),
 ("ACC","AccVoucher","YearId","pob","FiscalYear","YearId","سال مالی سند"),
 ("ACC","AccVoucher","VoucherTypeId","ACC","AccVoucherType","VoucherTypeId","نوع سند"),
 ("ACC","AccVoucher","BranchId","ACC","AccBranch","BranchId","شعبهٔ سند"),
 ("ACC","AccVoucher","ReversalOf","ACC","AccVoucher","VoucherId","سند مبنای ابطال/برگشت"),
 ("ACC","AccVoucherFlow","VoucherId","ACC","AccVoucher","VoucherId","سند مالک ردیف جریان"),
 ("ACC","AccVoucherItm","VoucherId","ACC","AccVoucher","VoucherId","سند مالک قلم"),
 ("ACC","AccVoucherItm","KolCode","ACC","AccKol","Code","کد کل قلم"),
 ("ACC","AccVoucherItm","MoeinCode","ACC","AccMoein","Code","کد معین قلم"),
 ("ACC","AccVoucherItm","Taf1Id","ACC","AccTafsili","TafsiliId","تفصیلی سطح چهارم قلم"),
 ("ACC","AccVoucherItm","Taf2Id","ACC","AccTafsili","TafsiliId","تفصیلی سطح پنجم قلم"),
 ("ACC","AccVoucherItm","Taf3Id","ACC","AccTafsili","TafsiliId","تفصیلی سطح ششم قلم"),
 ("ACC","AccVoucherItm","FxId","ACC","AccFx","FxId","ارز قلم سند"),
 ("pob","FiscalYear","CompanyId","pob","Companies","CompanyId","شرکت مالک سال مالی"),
 ("pob","FiscalPeriod","YearId","pob","FiscalYear","YearId","سال مالیِ دوره"),
 ("pob","Holiday","HolidayTypeRef","pob","HolidayType","HolidayTypeId","نوع تعطیلی"),
 ("pob","PartyAddress","PartyRef","pob","Party","Serial","شخصِ نشانی"),
 ("pob","PartyAddress","GeoPlaceRef","pob","GeoPlace","GeoPlaceId","موقعیت جغرافیایی نشانی"),
 ("pob","PartyCategoryLink","PartyRef","pob","Party","Serial","شخصِ پیوند"),
 ("pob","PartyCategoryLink","CategoryRef","pob","PartyCategory","CategoryId","دسته‌بندیِ پیوند"),
 ("pob","PartyCategory","ParentRef","pob","PartyCategory","CategoryId","دستهٔ والد"),
 ("pob","GeoPlace","ParentRef","pob","GeoPlace","GeoPlaceId","موقعیت والد"),
]

def q(s):  # escape single quotes
    return s.replace("'", "''")

def field_fa(tbl, col):
    return COL.get(tbl, {}).get(col) or GLB.get(col) or col

out = io.StringIO()
W = out.write

W("""/* ============================================================
   YFG ACC-WEB — دیتابیس acc — ۰۶: واژه‌نامهٔ داده (درخواست کارفرما)
   سه جدول مرجع برای مستندسازی خودکار دیتابیس:
     YFG.TableName  : نام جدول انگلیسی + شمای جدول + نام فارسی بر اساس نقش (مثل «لیست اسناد»)
     YFG.FieldName  : نام فیلد + نام جدول + شما + نام فارسی بر اساس نقش (مثل «شماره سند») + ماژول
     YFG.LinkField  : فیلد مبدأ + فیلد لینک + جدول/شمای لینک + نام فارسی + نقش فیلد در پیوند
   هم‌گام‌سازی خودکار: هر بار اجرا، جدول‌ها/ستون‌های تازه از INFORMATION_SCHEMA ثبت می‌شوند
   و نام‌های فارسی شناخته‌شده تازه‌سازی می‌گردند — اجرای مجدد بی‌خطر است (Idempotent)
   استانداردها: بله/خیر bit · ستون‌های ممیزی کامل · SourceSystem · تریگر UserLog
   ============================================================ */

/* ---------- بخش ۱: شمای YFG ---------- */
IF SCHEMA_ID('YFG') IS NULL EXEC('CREATE SCHEMA YFG');
GO
""")

# ---------- بخش ۲: جدول‌ها ----------
W("""/* ---------- بخش ۲: YFG.TableName ---------- */
IF OBJECT_ID('YFG.TableName') IS NULL
CREATE TABLE YFG.TableName (
  TableId   int          IDENTITY(1,1) NOT NULL CONSTRAINT PK_YFG_TableName PRIMARY KEY,
  TableSchema varchar(50)   NOT NULL,                /* شمای جدول */
  TableName varchar(128)  NOT NULL,                /* نام جدول انگلیسی */
  TableFa   nvarchar(200) NOT NULL,                /* نام فارسی بر اساس نقش */
  Module    nvarchar(50)  NOT NULL CONSTRAINT DF_YFGT_Module DEFAULT(N'عمومی'), /* ماژول */
  IsLookup  bit           NOT NULL CONSTRAINT DF_YFGT_Lookup DEFAULT(0),        /* جدول مرجع — بله/خیر */
  IsActive  bit           NOT NULL CONSTRAINT DF_YFGT_Active DEFAULT(1),
  CreatedBy varchar(50)   NOT NULL CONSTRAINT DF_YFGT_CB DEFAULT('system'),
  CreatedAt datetime2(0)  NOT NULL CONSTRAINT DF_YFGT_CA DEFAULT(SYSDATETIME()),
  UpdatedBy varchar(50)   NULL,
  UpdatedAt datetime2(0)  NULL,
  SourceSystem varchar(20) NOT NULL CONSTRAINT DF_YFGT_SS DEFAULT('ACCWEB'),
  CreatedAtJ AS pob.GrgToJalali(CreatedAt),
  UpdatedAtJ AS pob.GrgToJalali(UpdatedAt),
  CONSTRAINT UQ_YFG_TableName UNIQUE(TableSchema, TableName)
);
GO

/* ---------- بخش ۳: YFG.FieldName ---------- */
IF OBJECT_ID('YFG.FieldName') IS NULL
CREATE TABLE YFG.FieldName (
  FieldId   int          IDENTITY(1,1) NOT NULL CONSTRAINT PK_YFG_FieldName PRIMARY KEY,
  TableSchema varchar(50)   NOT NULL,                /* شما */
  TableName varchar(128)  NOT NULL,                /* نام تیبل */
  FieldName varchar(128)  NOT NULL,                /* نام فیلد انگلیسی */
  FieldFa   nvarchar(200) NOT NULL,                /* نام فارسی بر اساس نقش */
  Module    nvarchar(50)  NOT NULL CONSTRAINT DF_YFGF_Module DEFAULT(N'عمومی'), /* ماژول */
  DataType  varchar(30)   NULL,                    /* نوع داده */
  IsActive  bit           NOT NULL CONSTRAINT DF_YFGF_Active DEFAULT(1),
  CreatedBy varchar(50)   NOT NULL CONSTRAINT DF_YFGF_CB DEFAULT('system'),
  CreatedAt datetime2(0)  NOT NULL CONSTRAINT DF_YFGF_CA DEFAULT(SYSDATETIME()),
  UpdatedBy varchar(50)   NULL,
  UpdatedAt datetime2(0)  NULL,
  SourceSystem varchar(20) NOT NULL CONSTRAINT DF_YFGF_SS DEFAULT('ACCWEB'),
  CreatedAtJ AS pob.GrgToJalali(CreatedAt),
  UpdatedAtJ AS pob.GrgToJalali(UpdatedAt),
  CONSTRAINT UQ_YFG_FieldName UNIQUE(TableSchema, TableName, FieldName)
);
GO

/* ---------- بخش ۴: YFG.LinkField ---------- */
IF OBJECT_ID('YFG.LinkField') IS NULL
CREATE TABLE YFG.LinkField (
  LinkId    int          IDENTITY(1,1) NOT NULL CONSTRAINT PK_YFG_LinkField PRIMARY KEY,
  TableSchema varchar(50)   NOT NULL,                /* شمای جدول مبدأ */
  TableName varchar(128)  NOT NULL,                /* نام جدول مبدأ */
  FieldName varchar(128)  NOT NULL,                /* نام فیلد مبدأ */
  FieldFa   nvarchar(200) NOT NULL,                /* نام فارسی فیلد بر اساس نقش */
  LinkTableSchema varchar(50)  NOT NULL,           /* شمای تیبل لینک */
  LinkTableName varchar(128) NOT NULL,            /* نام تیبل لینک */
  LinkFieldName varchar(128) NOT NULL,            /* نام فیلد لینک */
  LinkFieldFa nvarchar(200) NOT NULL,             /* نام فارسی فیلد لینک */
  LinkRole  nvarchar(200) NULL,                   /* نقش فیلد در فیلد لینک */
  IsActive  bit           NOT NULL CONSTRAINT DF_YFGL_Active DEFAULT(1),
  CreatedBy varchar(50)   NOT NULL CONSTRAINT DF_YFGL_CB DEFAULT('system'),
  CreatedAt datetime2(0)  NOT NULL CONSTRAINT DF_YFGL_CA DEFAULT(SYSDATETIME()),
  UpdatedBy varchar(50)   NULL,
  UpdatedAt datetime2(0)  NULL,
  SourceSystem varchar(20) NOT NULL CONSTRAINT DF_YFGL_SS DEFAULT('ACCWEB'),
  CreatedAtJ AS pob.GrgToJalali(CreatedAt),
  UpdatedAtJ AS pob.GrgToJalali(UpdatedAt),
  CONSTRAINT UQ_YFG_LinkField UNIQUE(TableSchema, TableName, FieldName, LinkTableSchema, LinkTableName, LinkFieldName)
);
GO

/* ---------- بخش ۵: ثبت جدول‌ها (نام فارسی بر اساس نقش) — هم‌گام‌سازی ---------- */
""")
for t, (fa, lk) in sorted(TBL.items()):
    sch, name = t.split(".", 1)
    W(f"""IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='{q(sch)}' AND TableName='{q(name)}')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  VALUES ('{q(sch)}', '{q(name)}', N'{q(fa)}', N'{q(MODULE[sch])}', {lk});
""")
    W(f"""UPDATE YFG.TableName SET TableFa=N'{q(fa)}', Module=N'{q(MODULE[sch])}', IsLookup={lk}
WHERE TableSchema='{q(sch)}' AND TableName='{q(name)}' AND (TableFa<>N'{q(fa)}' OR Module<>N'{q(MODULE[sch])}' OR IsLookup<>{lk});
""")
W("GO\n\n/* ---------- بخش ۶: ثبت همهٔ فیلدها (نام فارسی بر اساس نقش) — هم‌گام‌سازی ---------- */\n")

for t in sorted(set(TBL) | set(COL)):
    sch, name = t.split(".", 1)
    if t not in COL and not t.startswith("YFG."):
        continue  # جدول‌های ACC/pob بدون نقشهٔ ستون: بخش ۷ خودکار پر می‌کند
    W(f"/* --- {t} --- */\n")
    W(f"""IF NOT EXISTS (SELECT 1 FROM YFG.TableName WHERE TableSchema='{q(sch)}' AND TableName='{q(name)}')
  INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
  SELECT '{q(sch)}', '{q(name)}', '{q(name)}', N'{q(MODULE[sch])}', 0
  WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='{q(sch)}' AND TABLE_NAME='{q(name)}');
""")
    for col, fa in sorted(COL[t].items()):
        W(f"""IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='{q(sch)}' AND TABLE_NAME='{q(name)}' AND COLUMN_NAME='{q(col)}')
BEGIN
  IF NOT EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='{q(sch)}' AND TableName='{q(name)}' AND FieldName='{q(col)}')
    INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
    SELECT '{q(sch)}', '{q(name)}', '{q(col)}', N'{q(fa)}', N'{q(MODULE[sch])}', DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='{q(sch)}' AND TABLE_NAME='{q(name)}' AND COLUMN_NAME='{q(col)}';
  UPDATE YFG.FieldName SET FieldFa=N'{q(fa)}', Module=N'{q(MODULE[sch])}'
  WHERE TableSchema='{q(sch)}' AND TableName='{q(name)}' AND FieldName='{q(col)}' AND (FieldFa<>N'{q(fa)}' OR Module<>N'{q(MODULE[sch])}');
END
GO
""")

W("""/* ---------- بخش ۷: هم‌گام‌سازی خودکار با INFORMATION_SCHEMA (جدول/ستون‌های تازه) ---------- */
INSERT INTO YFG.TableName (TableSchema, TableName, TableFa, Module, IsLookup)
SELECT c.TABLE_SCHEMA, c.TABLE_NAME, c.TABLE_NAME,
       CASE c.TABLE_SCHEMA WHEN N'ACC' THEN N'حسابداری' WHEN N'YFG' THEN N'واژه‌نامه' ELSE N'عمومی (بستر)' END, 0
FROM (SELECT DISTINCT TABLE_SCHEMA, TABLE_NAME FROM INFORMATION_SCHEMA.TABLES
      WHERE TABLE_SCHEMA IN ('ACC','pob','YFG') AND TABLE_TYPE='BASE TABLE') c
WHERE NOT EXISTS (SELECT 1 FROM YFG.TableName e WHERE e.TableSchema=c.TABLE_SCHEMA AND e.TableName=c.TABLE_NAME);

INSERT INTO YFG.FieldName (TableSchema, TableName, FieldName, FieldFa, Module, DataType)
SELECT c.TABLE_SCHEMA, c.TABLE_NAME, c.COLUMN_NAME, c.COLUMN_NAME,
       CASE c.TABLE_SCHEMA WHEN N'ACC' THEN N'حسابداری' WHEN N'YFG' THEN N'واژه‌نامه' ELSE N'عمومی (بستر)' END, c.DATA_TYPE
FROM (SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS
      WHERE TABLE_SCHEMA IN ('ACC','pob','YFG')) c
WHERE NOT EXISTS (SELECT 1 FROM YFG.FieldName e
                  WHERE e.TableSchema=c.TABLE_SCHEMA AND e.TableName=c.TABLE_NAME AND e.FieldName=c.COLUMN_NAME);
GO

/* ---------- بخش ۸: پیوندها (YFG.LinkField) ---------- */
""")

for sch, tbl, fld, lsch, ltbl, lfld, role in LNK:
    ffa = field_fa(f"{sch}.{tbl}", fld)
    lffa = field_fa(f"{lsch}.{ltbl}", lfld)
    W(f"""IF NOT EXISTS (SELECT 1 FROM YFG.LinkField WHERE TableSchema='{q(sch)}' AND TableName='{q(tbl)}' AND FieldName='{q(fld)}'
                      AND LinkTableSchema='{q(lsch)}' AND LinkTableName='{q(ltbl)}' AND LinkFieldName='{q(lfld)}')
  INSERT INTO YFG.LinkField (TableSchema, TableName, FieldName, FieldFa, LinkTableSchema, LinkTableName, LinkFieldName, LinkFieldFa, LinkRole)
  SELECT '{q(sch)}', '{q(tbl)}', '{q(fld)}', N'{q(ffa)}', '{q(lsch)}', '{q(ltbl)}', '{q(lfld)}', N'{q(lffa)}', N'{q(role)}'
  WHERE EXISTS (SELECT 1 FROM YFG.FieldName WHERE TableSchema='{q(sch)}' AND TableName='{q(tbl)}' AND FieldName='{q(fld)}');
GO
""")

W("""/* ---------- بخش ۹: تریگرهای ممیزی UserLog برای سه جدول واژه‌نامه ---------- */
CREATE OR ALTER TRIGGER YFG.Tr_YFG_TableName_Audit ON YFG.TableName
AFTER INSERT, UPDATE, DELETE AS
BEGIN
  SET NOCOUNT ON;
  IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 1, N'YFG', N'YFG.TableName', i.TableId, i.TableFa + N' (' + i.TableSchema + N'.' + i.TableName + N')'
    FROM inserted i;
  IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
  BEGIN
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'YFG', N'YFG.TableName', i.TableId, i.TableFa, N'TableFa', d.TableFa, i.TableFa
    FROM inserted i JOIN deleted d ON d.TableId = i.TableId WHERE EXISTS (SELECT i.TableFa EXCEPT SELECT d.TableFa);
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'YFG', N'YFG.TableName', i.TableId, i.TableFa, N'Module', d.Module, i.Module
    FROM inserted i JOIN deleted d ON d.TableId = i.TableId WHERE EXISTS (SELECT i.Module EXCEPT SELECT d.Module);
  END
  IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 3, N'YFG', N'YFG.TableName', NULL, d.TableFa + N' (' + d.TableSchema + N'.' + d.TableName + N')'
    FROM deleted d;
END
GO

CREATE OR ALTER TRIGGER YFG.Tr_YFG_FieldName_Audit ON YFG.FieldName
AFTER INSERT, UPDATE, DELETE AS
BEGIN
  SET NOCOUNT ON;
  IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 1, N'YFG', N'YFG.FieldName', i.FieldId, i.TableSchema + N'.' + i.TableName + N'.' + i.FieldName + N' = ' + i.FieldFa
    FROM inserted i;
  IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo, FieldName, OldValue, NewValue)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 2, N'YFG', N'YFG.FieldName', i.FieldId, i.TableSchema + N'.' + i.TableName + N'.' + i.FieldName, N'FieldFa', d.FieldFa, i.FieldFa
    FROM inserted i JOIN deleted d ON d.FieldId = i.FieldId WHERE EXISTS (SELECT i.FieldFa EXCEPT SELECT d.FieldFa);
  IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 3, N'YFG', N'YFG.FieldName', NULL, d.TableSchema + N'.' + d.TableName + N'.' + d.FieldName + N' = ' + d.FieldFa
    FROM deleted d;
END
GO

CREATE OR ALTER TRIGGER YFG.Tr_YFG_LinkField_Audit ON YFG.LinkField
AFTER INSERT, UPDATE, DELETE AS
BEGIN
  SET NOCOUNT ON;
  IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 1, N'YFG', N'YFG.LinkField', i.LinkId,
           i.TableSchema + N'.' + i.TableName + N'.' + i.FieldName + N' → ' + i.LinkTableSchema + N'.' + i.LinkTableName + N'.' + i.LinkFieldName
    FROM inserted i;
  IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    INSERT INTO pob.UserLog (UserName, LogDate, LogTime, ComputerName, IpAddress, ActivityType, SubSystem, TableName, RecId, DocInfo)
    SELECT pob.FnLogUser(), pob.FnLogDate(), pob.FnLogTime(), pob.FnLogPc(), pob.FnLogIp(), 3, N'YFG', N'YFG.LinkField', NULL,
           d.TableSchema + N'.' + d.TableName + N'.' + d.FieldName + N' → ' + d.LinkTableSchema + N'.' + d.LinkTableName + N'.' + d.LinkFieldName
    FROM deleted d;
END
GO

/* ---------- بخش ۱۰: راستی‌آزمایی ---------- */
PRINT '--- وضعیت واژه‌نامهٔ داده ---';
SELECT 'YFG.TableName' Tbl, COUNT(*) Cnt FROM YFG.TableName
UNION ALL SELECT 'YFG.FieldName', COUNT(*) FROM YFG.FieldName
UNION ALL SELECT 'YFG.LinkField', COUNT(*) FROM YFG.LinkField;
/* جدول‌های دیتابیس که هنوز در واژه‌نامه نیستند — باید صفر باشد */
SELECT COUNT(*) MissingTables FROM INFORMATION_SCHEMA.TABLES t
WHERE t.TABLE_SCHEMA IN ('ACC','pob','YFG') AND t.TABLE_TYPE='BASE TABLE'
  AND NOT EXISTS (SELECT 1 FROM YFG.TableName e WHERE e.TableSchema=t.TABLE_SCHEMA AND e.TableName=t.TABLE_NAME);
SELECT COUNT(*) MissingColumns FROM INFORMATION_SCHEMA.COLUMNS c
WHERE c.TABLE_SCHEMA IN ('ACC','pob','YFG')
  AND NOT EXISTS (SELECT 1 FROM YFG.FieldName e WHERE e.TableSchema=c.TABLE_SCHEMA AND e.TableName=c.TABLE_NAME AND e.FieldName=c.COLUMN_NAME);
PRINT '=== 06_meta_dictionary done ===';
GO
""")

io.open("/home/z/my-project/acc-web/sql/06_meta_dictionary.sql", "w", encoding="utf-8").write(out.getvalue())
print("written sql/06_meta_dictionary.sql —", len(out.getvalue().splitlines()), "lines")
