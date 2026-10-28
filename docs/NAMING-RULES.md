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
