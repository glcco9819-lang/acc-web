# YFG ACC-WEB — نصب آپدیت آنلاین
# خواندن UPDATE.flag → استخراج zip → جابجایی پوشهٔ app
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$flagPath = Join-Path $root "app\UPDATE.flag"

if (-not (Test-Path $flagPath)) { Write-Output "no flag"; exit 0 }

$flag = Get-Content $flagPath -Raw | ConvertFrom-Json
$zip = $flag.zip
Write-Output ("applying update {0} -> {1}" -f $flag.from, $flag.to)

if (-not (Test-Path $zip)) { Write-Output "zip missing: $zip"; exit 1 }

$tmp = Join-Path $root "app_new"
$old = Join-Path $root "app_old"
if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
if (Test-Path $old) { Remove-Item $old -Recurse -Force }

Expand-Archive -Path $zip -DestinationPath $tmp -Force
# zip شامل پوشهٔ app است
$inner = Join-Path $tmp "app"
if (Test-Path $inner) { $tmp = $inner }

Move-Item (Join-Path $root "app") $old -Force
Move-Item $tmp (Join-Path $root "app") -Force
Remove-Item $old -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $flagPath -Force -ErrorAction SilentlyContinue
Write-Output "UPDATE DONE — restarting..."
