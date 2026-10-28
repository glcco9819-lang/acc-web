#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""اجراکنندهٔ اسکریپت‌های SQL روی دیتابیس acc (بدون GO — تفکیک دستی)"""
import pymssql, sys, io

HOST = "85.133.175.190"
USER, PASS, DB = "acc_app", "Acc!2026$Web#p7Km", "acc"

def main(path):
    c = pymssql.connect(server=HOST, port=1433, user=USER, password=PASS, database=DB,
                        charset="UTF-8", login_timeout=15, timeout=120, autocommit=True)
    cur = c.cursor()
    raw = io.open(path, "r", encoding="utf-8-sig").read()
    batches = [b.strip() for b in raw.replace("\r\n", "\n").split("\nGO") if b.strip()]
    for i, b in enumerate(batches, 1):
        try:
            cur.execute(b)
            print(f"  ✓ batch {i}")
        except Exception as e:
            print(f"  ✗ batch {i}: {str(e)[:200]}")
            print("   ", b[:180].replace("\n", " "))
            raise
    c.close()
    print("DONE:", path.split('/')[-1])

if __name__ == "__main__":
    main(sys.argv[1])
