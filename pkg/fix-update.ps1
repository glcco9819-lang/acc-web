# YFG ACC-WEB — نصب قطعی آپدیت معلق (نسخهٔ تعمیر)
# چرا این اسکریپت؟ update.ps1 خودکار در برابر قفل‌شدن لحظه‌ای فایل‌ها
# (پروسسه‌های node باقی‌مانده / اسکن آنتی‌ویروس) بی‌صدا شکست می‌خورد و
# آپدیت معلق می‌ماند. این اسکریپت: سرویس را می‌بندد، پوشه‌های نیمه‌کاره
# را با تلاش مجدد پاک می‌کند، بستهٔ دانلودشده را نصب می‌کند.
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

function Log($m) { $stamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"); Write-Host "[$stamp] $m" }

Log "=== YFG ACC-WEB — نصب آپدیت معلق ==="

# ۱) بستن کامل سرویس (همهٔ پروسه‌های node)
Log "بستن پروسه‌های node..."
Get-Process node -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 3

# ۲) خواندن فلگ آپدیت
$flagPath = Join-Path $root "app\UPDATE.flag"
if (-not (Test-Path $flagPath)) { Log "فلگ آپدیت یافت نشد — چیزی برای نصب نیست (احتمالاً قبلاً نصب شده)"; exit 0 }
$flag = Get-Content $flagPath -Raw | ConvertFrom-Json
$zip = $flag.zip
Log ("نصب نسخهٔ {0} (از {1})" -f $flag.to, $flag.from)
if (-not (Test-Path $zip)) { Log ("بسته یافت نشد: " + $zip); exit 1 }
Log ("اندازهٔ بسته: {0:N0} بایت" -f (Get-Item $zip).Length)

# ۳) پاک‌سازی پوشه‌های نیمه‌کاره با تلاش مجدد
function Remove-WithRetry($path, $tries) {
  for ($i = 1; $i -le $tries; $i++) {
    if (-not (Test-Path $path)) { return $true }
    try { Remove-Item $path -Recurse -Force -ErrorAction Stop; return $true }
    catch { Log ("تلاش {0}/{1} برای حذف {2} ناموفق: {3}" -f $i, $tries, $path, $_.Exception.Message.Split("`n")[0]); Start-Sleep -Seconds 2 }
  }
  return (-not (Test-Path $path))
}
$tmp = Join-Path $root "app_new"
$old = Join-Path $root "app_old"
if (-not (Remove-WithRetry $tmp 5)) { Log "حذف app_new ناموفق ماند — چند لحظه بعد دوباره این فایل را اجرا کنید"; exit 1 }
if (-not (Remove-WithRetry $old 5)) { Log "حذف app_old ناموفق ماند — چند لحظه بعد دوباره اجرا کنید"; exit 1 }

# ۴) استخراج بسته
Log "استخراج بسته (ممکن است ۱-۲ دقیقه طول بکشد)..."
Expand-Archive -Path $zip -DestinationPath $tmp -Force
$inner = Join-Path $tmp "app"
if (Test-Path $inner) { $src = $inner } else { $src = $tmp }

# ۵) جابجایی با تلاش مجدد
function Move-WithRetry($from, $to, $tries) {
  for ($i = 1; $i -le $tries; $i++) {
    try { Move-Item $from $to -Force -ErrorAction Stop; return $true }
    catch { Log ("تلاش {0}/{1} برای جابجایی {2}: {3}" -f $i, $tries, $from, $_.Exception.Message.Split("`n")[0]); Start-Sleep -Seconds 2 }
  }
  return $false
}
if (-not (Move-WithRetry (Join-Path $root "app") $old 5)) { Log "جابجایی پوشهٔ app ناموفق ماند"; exit 1 }
if (-not (Move-WithRetry $src (Join-Path $root "app") 5)) { Log "جابجایی نسخهٔ جدید ناموفق — نسخهٔ قبلی در app_old محفوظ است"; exit 1 }

# ۶) حفظ پیکربندی دیتابیس سرور مشتری
$oc = Join-Path $old "db-config.json"
$nc = Join-Path $root "app\db-config.json"
if ((Test-Path $oc) -and (Test-Path $nc)) { Copy-Item $oc $nc -Force; Log "db-config.json حفظ شد" }

# ۷) پاک‌سازی
Remove-WithRetry $old 3 | Out-Null
Remove-Item $flagPath -Force -ErrorAction SilentlyContinue
Log "نصب کامل شد — سرویس خودکار راه‌اندازی می‌شود..."
