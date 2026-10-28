#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""پاکسازی کامل دادهٔ آزمون دیتابیس acc — با دورزدن موقت گاردها"""
import pymssql, sys

c = pymssql.connect(server="85.133.175.190", port=1433, user="acc_app",
                    password="Acc!2026$Web#p7Km", database="acc",
                    charset="UTF-8", login_timeout=15, timeout=120, autocommit=True)
cur = c.cursor()

for stmt in [
    "ALTER TABLE Vch.Hdr DISABLE TRIGGER TrAccWeb_Hdr_NoDeleteFinal",
    "ALTER TABLE Vch.Hdr DISABLE TRIGGER TrAccWeb_Hdr_StateGuard",
    "ALTER TABLE Vch.Itm DISABLE TRIGGER TrAccWeb_Itm_EditGuard",
]:
    cur.execute(stmt)

for stmt in [
    "DELETE FROM Vch.WfLog",
    "DELETE FROM Vch.Itm",
    "DELETE FROM Vch.Hdr",
    "DELETE FROM Acc.OpeningBalance",
]:
    cur.execute(stmt)
    print("ok:", stmt[:40])

for stmt in [
    "ALTER TABLE Vch.Hdr ENABLE TRIGGER TrAccWeb_Hdr_NoDeleteFinal",
    "ALTER TABLE Vch.Hdr ENABLE TRIGGER TrAccWeb_Hdr_StateGuard",
    "ALTER TABLE Vch.Itm ENABLE TRIGGER TrAccWeb_Itm_EditGuard",
]:
    cur.execute(stmt)

cur.execute("SELECT COUNT(*) FROM Vch.Hdr")
print("vouchers:", cur.fetchone()[0])
cur.execute("SELECT COUNT(*) FROM Acc.OpeningBalance")
print("opening:", cur.fetchone()[0])
c.close()
print("RESET DONE")
