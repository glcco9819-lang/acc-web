# قواعد نام‌گذاری دیتابیس YFG ERP — نسخهٔ ۱.۳.۰ (تأیید کارفرما)

## قاعدهٔ کلی (دائمی)
1. هر ماژول یک **مخفف ۳ حرفی** دارد که **برای هر ماژول از کارفرما پرسیده می‌شود** و تأیید می‌گیرد.
2. مخفف ماژول، خودِ **اسکیما** می‌شود: `ACC.AccVoucher`
3. نام جدول با همان مخفف شروع می‌شود: `vucher → AccVoucher` ، `voucheritm → AccVoucherItm`
4. هرچه بین ماژول‌ها **مشترک** است زیر اسکیمای `pob` می‌رود (به ازای هر ماژول جدید دوباره پرسیده می‌شود):
   `companeis → pob.Companies`
5. **املا درست** انگلیسی ملاک است مگر کارفرما صریحاً املای دیگری تأکید کند: `Voucher`، `Companies`

## کدهای ثبت‌شدهٔ ماژول‌ها
| کد | ماژول | وضعیت |
|----|-------|-------|
| `ACC` | حسابداری | تأییدشده — فعال |
| `pob` | مشترک بین ماژول‌ها | تأییدشده — فعال |
| `STR` | انبار | ثبت — تأیید نهایی هنگام شروع ماژول |
| `SLE` | فروش | ثبت — تأیید نهایی هنگام شروع ماژول |
| `RAP` | دریافت و پرداخت | ثبت — تأیید نهایی هنگام شروع ماژول (در محصول قدیم Rpa بود) |
| `CRM` | سی آر ام | ثبت — تأیید نهایی هنگام شروع ماژول |

## نقشهٔ جداول فعلی (v1.3.0)
- **ACC (۱۳):** AccVoucher, AccVoucherItm, AccVoucherType, AccVoucherFlow, AccKol, AccMoein, AccGroup,
  AccTafsili, AccTafsiliType, AccTafsiliCategory, AccTafsiliCategoryLink, AccOpeningBalance, AccStdNarration
- **pob (۱۶):** Companies, AppUser, FiscalYear, FiscalPeriod, Party, PartyAddress, PartyCategory,
  PartyCategoryLink, GeoPlace, CodeList, SubSystem, AppSetting, IdSequence, Holiday, HolidayType, NonWorkingTime
- توابع تاریخ: `pob.GrgToJalali` / `pob.JalToGrg` (+۶ تابع داخلی)
- view شجره: `ACC.AccVwChart` — تریگرها: `Tr_ACC_*`

## یادداشت
- ستون‌ها و نام‌های فیلدها تغییر نکرده‌اند (VchNo، JDate و...).
- اسنپ‌شات ساختار قدیم در اسکیمای `YfgBak` نگهداری می‌شود و پس از تثبیت v1.3.0 حذف خواهد شد.
- تغییر نام‌های بعدی فقط با تأیید کارفرما و طبق همین سند انجام می‌شود.

## لاگ فعالیت کاربران (۱۴۰۵/۰۸/۰۶ — اضافه شد)
- جدول: `pob.UserLog` — ثبت در پیش‌زمینهٔ دیتابیس (تریگر)، نرم‌افزار فقط پنجرهٔ نمایش
- انواع فعالیت: 1=ایجاد 2=ویرایش 3=حذف 4=ورود 5=خروج
- تریگرهای ممیزی: `Tr_ACC_*_Audit` (۱۲ جدول ACC) + `Tr_pob_AppUser_Audit`
- ایجاد/حذف: یک سطر برای هر سند/رکورد (ردیف‌های سند: تجمیعی «N ردیف»)
- ویرایش: یک سطر برای هر **فیلد** تغییر یافته (OldValue → NewValue)
- توابع کانتکست: `pob.FnLogUser/FnLogIp/FnLogPc/FnLogDate/FnLogTime`
- ثبت از سمت برنامه: `pob.UspUserLogAdd` (ورود/خروج/حذف لاگ)
- کانتکست کاربر/IP/PC از `SESSION_CONTEXT` — دسترسی مستقیم دیتابیس با نام لاگین SQL ثبت می‌شود
- حذف لاگ: فقط مدیر، بازه‌ای (از–تا) — خودِ حذف هم یک سطر لاگ می‌گذارد
