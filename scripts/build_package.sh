#!/usr/bin/env bash
# build_package.sh — ساخت بستهٔ استقرار ACCWeb.zip (نسخهٔ ویندوزی با node پرتابل)
# استفاده: bash scripts/build_package.sh [old_package.zip]
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="/home/z/my-project/download"
STAGE="/home/z/my-project/.pkgstage"
VER="$(python3 -c "import json;print(json.load(open('$REPO/version.json'))['version'])")"
OLD_ZIP="${1:-$OUT_DIR/ACCWeb.zip}"
OUT="$OUT_DIR/ACCWeb-$VER.zip"

echo "== بستهٔ YFG ACC-WEB v$VER =="
echo "stage: $STAGE"

# 1) app — خروجی standalone + static
rm -rf "$STAGE" && mkdir -p "$STAGE"
cp -r "$REPO/.next/standalone/." "$STAGE/app/"
mkdir -p "$STAGE/app/.next/static"
cp -r "$REPO/.next/static/." "$STAGE/app/.next/static/"
[ -d "$REPO/public" ] && { mkdir -p "$STAGE/app/public"; cp -r "$REPO/public/." "$STAGE/app/public/"; }
cp "$REPO/version.json" "$REPO/db-config.json" "$STAGE/app/"
# نسخهٔ sql داخل بستهٔ app — برای اجراکنندهٔ مهاجرت هنگام بوت (v2.1.0)
mkdir -p "$STAGE/app/sql"
cp "$REPO"/sql/*.sql "$STAGE/app/sql/"

# 2) node پرتابل — از بستهٔ قبلی (اگر نبود، بستهٔ قدیمی مسیر داده شود)
if [ ! -f "$OLD_ZIP" ]; then echo "بستهٔ مرجع برای node پرتابل یافت نشد: $OLD_ZIP"; exit 1; fi
unzip -o -q "$OLD_ZIP" "node/*" -d "$STAGE/"

# 3) sql + docs + راه‌اندازها + README — v2.4.0: نسخهٔ مقاوم update.ps1 داخل app
#    هم کپی می‌شود (update-latest.ps1) تا هنگام بوت، اسکریپت قدیمی ریشه خودترمیم شود
mkdir -p "$STAGE/sql" "$STAGE/docs"
cp "$REPO"/sql/*.sql "$STAGE/sql/"
cp "$REPO"/docs/*.md "$STAGE/docs/"
cp "$REPO"/pkg/setup.js "$REPO"/pkg/SETUP-ACC.cmd "$REPO"/pkg/START-ACC.bat "$REPO"/pkg/update.ps1 "$REPO"/pkg/fix-update.ps1 "$REPO"/pkg/README-FA.txt "$STAGE/"
cp "$REPO"/pkg/update.ps1 "$STAGE/app/update-latest.ps1"
cp "$REPO"/pkg/fix-update.ps1 "$STAGE/app/fix-update-latest.ps1"

# 4) zip
rm -f "$OUT"
(cd "$STAGE" && zip -q -r -9 "$OUT" .)
rm -rf "$STAGE"

echo "== ساخته شد: $OUT ($(du -h "$OUT" | cut -f1)) =="
