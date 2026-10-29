/* تبدیل تاریخ میلادی/جلالی — الگوریتم استاندارد jalaali */

function div(a: number, b: number) { return ~~(a / b); }

export function jalaliToGregorian(jy: number, jm: number, jd: number): [number, number, number] {
  jy += 1595;
  let days = -355668 + (365 * jy) + (~~(jy / 33) * 8) + ~~(((jy % 33) + 3) / 4)
    + jd + ((jm < 7) ? (jm - 1) * 31 : ((jm - 7) * 30) + 186);
  let gy = 400 * ~~(days / 146097);
  days %= 146097;
  if (days > 36524) {
    gy += 100 * ~~(--days / 36524);
    days %= 36524;
    if (days >= 365) days++;
  }
  gy += 4 * ~~(days / 1461);
  days %= 1461;
  if (days > 365) {
    gy += ~~((days - 1) / 365);
    days = (days - 1) % 365;
  }
  let gd = days + 1;
  const sal_a = [0, 31, (gy % 4 === 0 && gy % 100 !== 0) || (gy % 400 === 0) ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  let gm = 0;
  for (gm = 1; gm <= 12 && gd > sal_a[gm]; gm++) gd -= sal_a[gm];
  return [gy, gm, gd];
}

export function gregorianToJalali(gy: number, gm: number, gd: number): [number, number, number] {
  const g_d_m = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
  let jy = (gy <= 1600) ? 0 : 979;
  gy -= (gy <= 1600) ? 621 : 1600;
  const gy2 = (gm > 2) ? (gy + 1) : gy;
  let days = (365 * gy) + (~~((gy2 + 3) / 4)) - (~~((gy2 + 99) / 100))
    + (~~((gy2 + 399) / 400)) - 80 + gd + g_d_m[gm - 1];
  jy += 33 * ~~(days / 12053);
  days %= 12053;
  jy += 4 * ~~(days / 1461);
  days %= 1461;
  if (days > 365) {
    jy += ~~((days - 1) / 365);
    days = (days - 1) % 365;
  }
  let jm = (days < 186) ? 1 + ~~(days / 31) : 7 + ~~((days - 186) / 30);
  const jd = 1 + ((days < 186) ? (days % 31) : ((days - 186) % 30));
  return [jy, jm, jd];
}

export function todayJalali(): string {
  const now = new Date(Date.now() + 3.5 * 3600 * 1000); /* تهران */
  const [jy, jm, jd] = gregorianToJalali(now.getUTCFullYear(), now.getUTCMonth() + 1, now.getUTCDate());
  return `${jy}/${String(jm).padStart(2, "0")}/${String(jd).padStart(2, "0")}`;
}

/* تبدیل datetime میلادی (سرور UTC) به رشتهٔ شمسی «YYYY/MM/DD HH:MM» — تهران +03:30
   [رفع «تاریخ‌ها شمسی نیستند»: ردپای عملیات سند و زمان‌های سیستم با تاریخ میلادی نمایش داده می‌شد] */
export function faDateTime(v: string | Date | null | undefined): string {
  if (!v) return "";
  const d = typeof v === "string" ? new Date(v.endsWith("Z") || v.includes("T") ? v : v.replace(" ", "T") + "Z") : v;
  if (isNaN(d.getTime())) return "";
  const t = new Date(d.getTime() + 3.5 * 3600 * 1000); /* تهران */
  const [jy, jm, jd] = gregorianToJalali(t.getUTCFullYear(), t.getUTCMonth() + 1, t.getUTCDate());
  const hh = String(t.getUTCHours()).padStart(2, "0");
  const mi = String(t.getUTCMinutes()).padStart(2, "0");
  return `${jy}/${String(jm).padStart(2, "0")}/${String(jd).padStart(2, "0")} ${hh}:${mi}`;
}

export function isValidJalali(s: string): boolean {
  const m = /^(\d{4})\/(\d{1,2})\/(\d{1,2})$/.exec(s.trim());
  if (!m) return false;
  const y = +m[1], mo = +m[2], d = +m[3];
  if (y < 1300 || y > 1500 || mo < 1 || mo > 12 || d < 1 || d > 31) return false;
  if (mo > 6 && d > 30) return false;
  if (mo === 12 && d === 30) {
    /* کبیسه: سالی که باقی‌مانده بر ۳۳ در مجموعهٔ 1,5,9,13,17,22,26,30 باشد */
    const r = y % 33;
    return [1, 5, 9, 13, 17, 22, 26, 30].includes(r);
  }
  return true;
}

export const MONTHS_FA = ["فروردین", "اردیبهشت", "خرداد", "تیر", "مرداد", "شهریور",
  "مهر", "آبان", "آذر", "دی", "بهمن", "اسفند"];
