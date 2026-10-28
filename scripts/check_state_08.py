#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""بررسی وضعیت اسکیمای دیتابیس مشتری پیش از اعمال 08_review"""
import pymssql

c = pymssql.connect(server="85.133.175.190", port=1433, user="acc_app",
                    password="Acc!2026$Web#p7Km", database="acc", charset="UTF-8",
                    login_timeout=15, timeout=30, autocommit=True)
cur = c.cursor()

def q(sql, label):
    try:
        cur.execute(sql)
        rows = cur.fetchall()
        print(f"{label}:")
        for r in rows[:12]:
            print("  ", r)
        if not rows:
            print("   (empty)")
    except Exception as e:
        print(f"{label}: ERR {str(e)[:150]}")

q("SELECT COUNT(*) FROM sys.tables WHERE schema_id=SCHEMA_ID('ACC') AND name IN ('AccNoteHdr','AccNoteItm')", "notes tables")
q("SELECT COUNT(*) FROM sys.tables WHERE name='AppliedMigration' AND schema_id=SCHEMA_ID('pob')", "AppliedMigration")
q("SELECT COUNT(*) FROM sys.columns WHERE object_id=OBJECT_ID('ACC.AccVoucherItm') AND name IN ('FxId','FxAmount','FxRate','TrackNo')", "05 fx cols present")
q("SELECT COUNT(*) FROM sys.indexes WHERE name IN ('IX_AccVoucherItm_Moein','IX_AccVoucherItm_Kol','IX_AccVoucherItm_Taf1','IX_AccVoucherItm_Fx','IX_AccVoucher_Date')", "review indexes")
q("SELECT CompanyId, CompanyCode, TitleFa FROM pob.Companies", "companies")
q("SELECT CompanyId, YearId, JalaliYear, IsClosed FROM pob.FiscalYear ORDER BY YearId", "years")
q("SELECT TOP 5 h.State, COUNT(*) FROM ACC.AccVoucher h GROUP BY h.State", "voucher states")
q("SELECT COUNT(*) N FROM ACC.AccVoucherItm", "total voucher items")
q("SELECT COUNT(*) N FROM ACC.AccVoucherItm WHERE FxId IS NOT NULL", "fx items")
c.close()
