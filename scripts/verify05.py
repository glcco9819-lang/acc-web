#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""راستی‌آزمایی 05_vch_fields — وضعیت جداول/ستون‌ها/قیدها/تریگرها"""
import pymssql

c = pymssql.connect(server="85.133.175.190", port=1433, user="acc_app",
                    password="Acc!2026$Web#p7Km", database="acc",
                    charset="UTF-8", login_timeout=15, timeout=60, autocommit=True)
cur = c.cursor()
cur.execute("""
SELECT 'AccFx' T, COUNT(*) N FROM ACC.AccFx
UNION ALL SELECT 'AccBranch', COUNT(*) FROM ACC.AccBranch
UNION ALL SELECT 'Voucher.NewCols', COUNT(*) FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccVoucher') AND name IN ('BranchId','DayNo','SubNo','LatinDescr')
UNION ALL SELECT 'Itm.NewCols', COUNT(*) FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccVoucherItm') AND name IN ('FxId','FxAmount','FxRate','TrackNo','TrackDate','LatinDescr')
UNION ALL SELECT 'UQ_VchNoSub', COUNT(*) FROM sys.key_constraints WHERE name='UQ_AccVoucher_VchNoSub'
UNION ALL SELECT 'CK_Line_Fx', COUNT(*) FROM sys.check_constraints WHERE name='CK_Line_Fx'
UNION ALL SELECT 'FK_Voucher_Branch', COUNT(*) FROM sys.foreign_keys WHERE name='FK_Voucher_Branch'
UNION ALL SELECT 'FK_Line_Fx', COUNT(*) FROM sys.foreign_keys WHERE name='FK_Line_Fx'
UNION ALL SELECT 'Trg_AccFx', COUNT(*) FROM sys.triggers WHERE parent_id=OBJECT_ID('ACC.AccFx')
UNION ALL SELECT 'Trg_AccBranch', COUNT(*) FROM sys.triggers WHERE parent_id=OBJECT_ID('ACC.AccBranch')
UNION ALL SELECT 'Vouchers_intact', COUNT(*) FROM ACC.AccVoucher
UNION ALL SELECT 'Items_intact', COUNT(*) FROM ACC.AccVoucherItm
""")
for t, n in cur.fetchall():
    print(f"  {t:22s} = {n}")
c.close()
