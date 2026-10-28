#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""YFG ACC-WEB v1.2.0 — بازنامینی سراسری (copyright-safe, role-based, YFG prefix)
دستور کارفرما: نام‌ها عیناً از محصول اصلی کپی نشود؛ نام‌گذاری بر اساس نقش جدول/فایل؛
پیشوند YFG در ابتدای نام‌ها. یک‌بار مصرف — به‌عنوان سند نگاشت نگه داشته می‌شود."""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOOSE = lambda t: r'(?<![A-Za-z0-9])' + t + r'(?![A-Za-z0-9])'

# ---- قوانین عمومی (همهٔ فایل‌ها) — به ترتیب، همه با re.sub ----
RULES = [
    # A. تریگرها
    (r'TrAccWeb_Hdr_NoDeleteFinal', 'Tr_YfgVch_Voucher_NoDeleteFinal'),
    (r'TrAccWeb_Hdr_StateGuard',    'Tr_YfgVch_Voucher_StateGuard'),
    (r'TrAccWeb_Itm_EditGuard',     'Tr_YfgVch_VoucherLine_EditGuard'),
    (r'TrAccWeb_Kol_Prefix',        'Tr_YfgAcc_Kol_Prefix'),
    (r'TrAccWeb_Moein_Prefix',      'Tr_YfgAcc_Moein_Prefix'),
    # B. جدول‌های واجد شِما
    (r'gnr\.gnrNonWorkingTimes', 'YfgGen.NonWorkingTime'),
    (r'gnr\.gnrHolidayTypes',    'YfgGen.HolidayType'),
    (r'gnr\.gnrHolidays',        'YfgGen.Holiday'),
    (r'gnr\.gnrCrspndCat',       'YfgGen.PartyCategoryLink'),
    (r'gnr\.CrspndCtgry',        'YfgGen.PartyCategory'),
    (r'gnr\.TableIdGen',         'YfgGen.IdSequence'),
    (r'gnr\.MisSetup',           'YfgGen.AppSetting'),
    (r'gnr\.Lookup',             'YfgGen.CodeList'),
    (r'gnr\.Systems',            'YfgGen.SubSystem'),
    (r'gnr\.GeoPos',             'YfgGen.GeoPlace'),
    (r'gnr\.Address',            'YfgGen.PartyAddress'),
    (r'gnr\.Crspnd',             'YfgGen.Party'),
    (r'Acc\.DlCtgryLink',        'YfgAcc.TafsiliCategoryLink'),
    (r'Acc\.DlCtgry',            'YfgAcc.TafsiliCategory'),
    (r'Acc\.DlType',             'YfgAcc.TafsiliType'),
    (r'Acc\.DL',                 'YfgAcc.Tafsili'),
    (r'Acc\.\[Group\]',          'YfgAcc.AccGroup'),
    (r'Acc\.Group\b',            'YfgAcc.AccGroup'),
    (r'Acc\.Kol',                'YfgAcc.Kol'),
    (r'Acc\.Moein',              'YfgAcc.Moein'),
    (r'Acc\.StdDesc',            'YfgAcc.StdNarration'),
    (r'Acc\.OpeningBalance',     'YfgAcc.OpeningBalance'),
    (r'Acc\.VwChart',            'YfgAcc.VwChart'),
    (r'Vch\.\[Type\]',           'YfgVch.VoucherType'),
    (r'Vch\.Type\b',             'YfgVch.VoucherType'),
    (r'Vch\.Hdr',                'YfgVch.Voucher'),
    (r'Vch\.Itm',                'YfgVch.VoucherLine'),
    (r'Vch\.WfLog',              'YfgVch.VoucherFlow'),
    (r'Prm\.FiscalPeriod',       'YfgPrm.FiscalPeriod'),
    (r'Prm\.FiscalYear',         'YfgPrm.FiscalYear'),
    (r'Prm\.AppUser',            'YfgPrm.AppUser'),
    (r'Prm\.Company',            'YfgPrm.Company'),
    # C. مسیر پنجره‌ها و API
    (r'/windows/crspnd-ctgry',   '/windows/party-categories'),
    (r'/windows/crspnd',         '/windows/parties'),
    (r'/windows/geopos',         '/windows/geo-places'),
    (r'/windows/mis-setup',      '/windows/app-settings'),
    (r'/windows/dl-categories',  '/windows/tafsili-categories'),
    (r'/windows/dl-types',       '/windows/tafsili-types'),
    (r'/windows/dl\b',           '/windows/tafsili'),
    (r'/windows/std-desc',       '/windows/std-narrations'),
    (r'/api/gnr',                '/api/gen'),
    (r'/api/acc/dlctgries',      '/api/acc/tafsili-ctgries'),
    (r'/api/acc/dltypes',        '/api/acc/tafsili-types'),
    (r'/api/acc/dl\b',           '/api/acc/tafsili'),
    # D. ستون‌ها
    (LOOSE('CrspndRef'),  'PartyRef'),
    (LOOSE('CompType'),   'PartyKind'),
    (LOOSE('GeoPosRef'),  'GeoPlaceRef'),
    (LOOSE('GeoPosId'),   'GeoPlaceId'),
    (LOOSE('MisSetupId'), 'SettingId'),
    (LOOSE('LookupId'),   'CodeId'),
    (LOOSE('LookupType'), 'CodeListType'),
    (LOOSE('Dl1TypeId'),  'Taf1TypeId'),
    (LOOSE('Dl2TypeId'),  'Taf2TypeId'),
    (LOOSE('Dl3TypeId'),  'Taf3TypeId'),
    (LOOSE('Dl1Title'),   'Taf1Title'),
    (LOOSE('Dl2Title'),   'Taf2Title'),
    (LOOSE('Dl3Title'),   'Taf3Title'),
    (LOOSE('Dl1Id'),      'Taf1Id'),
    (LOOSE('Dl2Id'),      'Taf2Id'),
    (LOOSE('Dl3Id'),      'Taf3Id'),
    (LOOSE('DlTypeId'),   'TafsiliTypeId'),
    (LOOSE('DlId'),       'TafsiliId'),
    (LOOSE('CtgryId'),    'CategoryId'),
    (LOOSE('CtgryRef'),   'CategoryRef'),
    (LOOSE('HdrId'),      'VoucherId'),
    (LOOSE('ItmId'),      'LineId'),
    (LOOSE('TypeId'),     'VoucherTypeId'),
    (LOOSE('StdDescId'),  'NarrationId'),
    # E. توکن‌های باقی‌مانده (قیدها/ایندکس‌ها/کامنت‌ها)
    (LOOSE('gnrNonWorkingTimes'), 'YfgGen.NonWorkingTime'),
    (LOOSE('gnrHolidayTypes'),    'YfgGen.HolidayType'),
    (LOOSE('gnrHolidays'),        'YfgGen.Holiday'),
    (LOOSE('gnrCrspndCat'),       'YfgGen.PartyCategoryLink'),
    (LOOSE('DlCtgryLink'),        'TafsiliCategoryLink'),
    (LOOSE('DlCtgry'),            'TafsiliCategory'),
    (LOOSE('DlType'),             'TafsiliType'),
    (LOOSE('CrspndCtgry'),        'PartyCategory'),
    (LOOSE('CrspndCat'),          'PartyCategoryLink'),
    (LOOSE('StdDesc'),            'StdNarration'),
    (LOOSE('MisSetup'),           'AppSetting'),
    (LOOSE('TableIdGen'),         'IdSequence'),
    (LOOSE('VchType'),            'VoucherType'),
    (LOOSE('HolidayTypes'),       'HolidayType'),
    (LOOSE('NonWorkingTimes'),    'NonWorkingTime'),
    (LOOSE('Holidays'),           'Holiday'),
    (LOOSE('GeoPos'),             'GeoPlace'),
    (LOOSE('Crspnd'),             'Party'),
    (LOOSE('Hdr'),                'Voucher'),
    (LOOSE('Itm'),                'Line'),
    (LOOSE('DL'),                 'Tafsili'),
    (LOOSE('WfLog'),              'VoucherFlow'),
    # F. slug های انتیتی (نقل‌قول‌دار)
    (r'"crspndcat"', '"party-cat"'),
    (r"'crspndcat'", "'party-cat'"),
    (r'"crspnd"',    '"party"'),
    (r"'crspnd'",    "'party'"),
    (r'"ctgry"',     '"party-ctgry"'),
    (r"'ctgry'",     "'party-ctgry'"),
    (r'"geopos"',    '"geo-place"'),
    (r"'geopos'",    "'geo-place'"),
    (r'"missetup"',  '"app-setting"'),
    (r"'missetup'",  "'app-setting'"),
    (r'"stddesc"',   '"std-narration"'),
    (r"'stddesc'",   "'std-narration'"),
    (r'"dltypes"',   '"tafsili-types"'),
    (r"'dltypes'",   "'tafsili-types'"),
    (r'"dlctgries"', '"tafsili-ctgries"'),
    (r"'dlctgries'", "'tafsili-ctgries'"),
    (r'"dl"',        '"tafsili"'),
    (r"'dl'",        "'tafsili'"),
    # G. توابع تاریخ شمسی
    (LOOSE('Grg2Jal'), 'GrgToJalali'),
    (LOOSE('Jal2Grg'), 'JalToGrg'),
    (LOOSE('Grg2Jdn'), 'GrgToJdn'),
    (LOOSE('Jal2Jdn'), 'JalToJdn'),
    (LOOSE('Jdn2Grg'), 'JdnToGrg'),
    (LOOSE('JalMarch'),'JalNowruz'),
    (LOOSE('JalBreak'),'JalBreaks'),
    # H. پیشوند نام قیدهای gnr_
    (r'(?<![A-Za-z0-9])gnr_(?=[A-Za-z])', 'YfgGen_'),
    # J. مؤلفه/اسکریپت با نام گنر
    (r'GnrWindow', 'GenWindow'),
    (r'e2e_gnr',   'e2e_gen'),
    # K. داده‌ها: کد سامانه GNR → GEN (در همه؛ رمزها GNR ندارند)
    (LOOSE('GNR'), 'GEN'),
]

# ---- قوانین فقط-SQL (شِماهای بدون واجد) — جدا تا رمزها/رشته‌های کد آسیب نبینند ----
SQL_ONLY = [
    (r"(?<![A-Za-z0-9_.])gnr(?![A-Za-z0-9_])", 'YfgGen'),
    (r"(?<![A-Za-z0-9_.])Prm(?![A-Za-z0-9_])", 'YfgPrm'),
    (r"(?<![A-Za-z0-9_.])Acc(?![A-Za-z0-9_])", 'YfgAcc'),
    (r"(?<![A-Za-z0-9_.])Vch(?![A-Za-z0-9_])", 'YfgVch'),
]

FOLDERS = [  # (مسیر نسبی قدیم، جدید)
    ('src/app/api/gnr', 'src/app/api/gen'),
    ('src/app/windows/crspnd-ctgry', 'src/app/windows/party-categories'),
    ('src/app/windows/crspnd',       'src/app/windows/parties'),
    ('src/app/windows/geopos',       'src/app/windows/geo-places'),
    ('src/app/windows/mis-setup',    'src/app/windows/app-settings'),
    ('src/app/windows/dl-categories','src/app/windows/tafsili-categories'),
    ('src/app/windows/dl-types',     'src/app/windows/tafsili-types'),
    ('src/app/windows/dl',           'src/app/windows/tafsili'),
    ('src/app/windows/std-desc',     'src/app/windows/std-narrations'),
]
FILES = [
    ('src/components/GnrWindow.tsx', 'src/components/GenWindow.tsx'),
    ('scripts/e2e_gnr.mjs',          'scripts/e2e_gen.mjs'),
]

LEFTOVER = re.compile(r'gnr|Gnr|Crspnd|GeoPos|MisSetup|TableIdGen|DlType|DlCtgry|StdDesc|TrAccWeb|Grg2Jal|Jal2Grg|\bDL\b|gnrHolidays|NonWorkingTimes', re.I)

def iter_files():
    for base in ('sql', 'src', 'scripts'):
        for dp, _, fns in os.walk(os.path.join(ROOT, base)):
            for fn in fns:
                if fn == 'rename_yfg.py':  # سند نگاشت — خودش تغییر نکند
                    continue
                if fn.endswith(('.ts', '.tsx', '.sql', '.mjs', '.py')):
                    yield os.path.join(dp, fn), fn.endswith('.sql')

def main(apply=True):
    changed = 0
    for path, is_sql in iter_files():
        with open(path, 'r', encoding='utf-8') as f:
            src = f.read()
        out = src
        for pat, rep in RULES:
            out = re.sub(pat, rep, out)
        if is_sql:
            for pat, rep in SQL_ONLY:
                out = re.sub(pat, rep, out)
        if out != src:
            changed += 1
            rel = os.path.relpath(path, ROOT)
            n = sum(1 for a, b in zip(src.split('\n'), out.split('\n')) if a != b)
            print(f'  ~ {rel} ({n} lines)')
            if apply:
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(out)
    print(f'files changed: {changed}')
    if not apply:
        return
    # تغییر نام پوشه‌ها (عمیق‌ترین اول)
    for old, new in sorted(FOLDERS, key=lambda x: -len(x[0])):
        o, n = os.path.join(ROOT, old), os.path.join(ROOT, new)
        if os.path.isdir(o):
            os.rename(o, n); print(f'  dir {old} → {new}')
    for old, new in FILES:
        o, n = os.path.join(ROOT, old), os.path.join(ROOT, new)
        if os.path.isfile(o):
            os.renames(o, n); print(f'  file {old} → {new}')
    # اسکن باقی‌مانده‌ها
    print('\n== leftovers ==')
    hits = 0
    for path, _ in iter_files():
        with open(path, 'r', encoding='utf-8') as f:
            for i, line in enumerate(f, 1):
                m = LEFTOVER.search(line)
                if m:
                    hits += 1
                    print(f'  {os.path.relpath(path, ROOT)}:{i}: {line.strip()[:150]}')
    print(f'leftover lines: {hits}')

if __name__ == '__main__':
    main(apply='--dry' not in sys.argv)
