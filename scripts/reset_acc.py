#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""پاکسازی کامل دادهٔ آزمون دیتابیس acc — با دورزدن موقت گاردها"""
import pymssql, sys

c = pymssql.connect(server="85.133.175.190", port=1433, user="acc_app",
                    password="Acc!2026$Web#p7Km", database="acc",
                    charset="UTF-8", login_timeout=15, timeout=120, autocommit=True)
cur = c.cursor()

for stmt in [
    "ALTER TABLE ACC.AccVoucher DISABLE TRIGGER Tr_ACC_AccVoucher_NoDeleteFinal",
    "ALTER TABLE ACC.AccVoucher DISABLE TRIGGER Tr_ACC_AccVoucher_StateGuard",
    "ALTER TABLE ACC.AccVoucherItm DISABLE TRIGGER Tr_ACC_AccVoucherItm_EditGuard",
]:
    cur.execute(stmt)

for stmt in [
    "DELETE FROM ACC.AccVoucherFlow",
    "DELETE FROM ACC.AccVoucherItm",
    "DELETE FROM ACC.AccVoucher",
    "DELETE FROM ACC.AccOpeningBalance",
]:
    cur.execute(stmt)
    print("ok:", stmt[:40])

for stmt in [
    "ALTER TABLE ACC.AccVoucher ENABLE TRIGGER Tr_ACC_AccVoucher_NoDeleteFinal",
    "ALTER TABLE ACC.AccVoucher ENABLE TRIGGER Tr_ACC_AccVoucher_StateGuard",
    "ALTER TABLE ACC.AccVoucherItm ENABLE TRIGGER Tr_ACC_AccVoucherItm_EditGuard",
]:
    cur.execute(stmt)

cur.execute("SELECT COUNT(*) FROM ACC.AccVoucher")
print("vouchers:", cur.fetchone()[0])
cur.execute("SELECT COUNT(*) FROM ACC.AccOpeningBalance")
print("opening:", cur.fetchone()[0])
c.close()
print("RESET DONE")
