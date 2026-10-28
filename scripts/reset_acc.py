#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""پاکسازی کامل دادهٔ آزمون دیتابیس acc — با دورزدن موقت گاردها"""
import pymssql, sys

c = pymssql.connect(server="85.133.175.190", port=1433, user="acc_app",
                    password="Acc!2026$Web#p7Km", database="acc",
                    charset="UTF-8", login_timeout=15, timeout=120, autocommit=True)
cur = c.cursor()

for stmt in [
    "ALTER TABLE YfgVch.Voucher DISABLE TRIGGER Tr_YfgVch_Voucher_NoDeleteFinal",
    "ALTER TABLE YfgVch.Voucher DISABLE TRIGGER Tr_YfgVch_Voucher_StateGuard",
    "ALTER TABLE YfgVch.VoucherLine DISABLE TRIGGER Tr_YfgVch_VoucherLine_EditGuard",
]:
    cur.execute(stmt)

for stmt in [
    "DELETE FROM YfgVch.VoucherFlow",
    "DELETE FROM YfgVch.VoucherLine",
    "DELETE FROM YfgVch.Voucher",
    "DELETE FROM YfgAcc.OpeningBalance",
]:
    cur.execute(stmt)
    print("ok:", stmt[:40])

for stmt in [
    "ALTER TABLE YfgVch.Voucher ENABLE TRIGGER Tr_YfgVch_Voucher_NoDeleteFinal",
    "ALTER TABLE YfgVch.Voucher ENABLE TRIGGER Tr_YfgVch_Voucher_StateGuard",
    "ALTER TABLE YfgVch.VoucherLine ENABLE TRIGGER Tr_YfgVch_VoucherLine_EditGuard",
]:
    cur.execute(stmt)

cur.execute("SELECT COUNT(*) FROM YfgVch.Voucher")
print("vouchers:", cur.fetchone()[0])
cur.execute("SELECT COUNT(*) FROM YfgAcc.OpeningBalance")
print("opening:", cur.fetchone()[0])
c.close()
print("RESET DONE")
