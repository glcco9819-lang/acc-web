#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ساخت دیتابیس acc روی سرور کارفرما + اجرای اسکیمای وفادار + لاگین اپ + دادهٔ پایه"""
import pymssql, sys, io

HOST = "85.133.175.190"
SA_USER, SA_PASS = "sa", "Uat#Admin"
APP_USER, APP_PASS = "acc_app", "Acc!2026$Web#p7Km"

def connect(db, user=SA_USER, password=SA_PASS):
    return pymssql.connect(server=HOST, port=1433, user=user, password=password,
                           database=db, charset="UTF-8", login_timeout=15,
                           timeout=120, autocommit=True)

def run_batches(cur, path):
    raw = io.open(path, "r", encoding="utf-8-sig").read()
    batches = [b.strip() for b in raw.replace("\r\n", "\n").split("\nGO") if b.strip()]
    for i, b in enumerate(batches, 1):
        try:
            cur.execute(b)
        except Exception as e:
            print(f"  ✗ batch {i} FAILED: {str(e)[:150]}")
            print("  ---", b[:200].replace("\n", " "), "...")
            raise
    print(f"  ✓ {len(batches)} batch executed from {path.split('/')[-1]}")

def main():
    # ۱) ساخت دیتابیس
    m = connect("master")
    cur = m.cursor()
    cur.execute("SELECT name FROM sys.databases WHERE name='acc'")
    if cur.fetchone():
        print("DB acc: exists")
    else:
        cur.execute("CREATE DATABASE [acc]")
        print("DB acc: CREATED")
    m.close()

    # ۲) لاگین اختصاصی اپ (بدون sa در برنامه)
    m = connect("master")
    cur = m.cursor()
    cur.execute("SELECT name FROM sys.sql_logins WHERE name=%s", APP_USER)
    if not cur.fetchone():
        cur.execute("CREATE LOGIN [%s] WITH PASSWORD='%s', CHECK_POLICY=OFF" % (APP_USER, APP_PASS))
        print("login acc_app: CREATED")
    else:
        print("login acc_app: exists")
    m.close()

    # ۳) db_owner در acc
    c = connect("acc")
    cur = c.cursor()
    cur.execute("SELECT name FROM sys.database_principals WHERE name=%s", APP_USER)
    if not cur.fetchone():
        cur.execute("CREATE USER [%s] FOR LOGIN [%s]" % (APP_USER, APP_USER))
        cur.execute("ALTER ROLE db_owner ADD MEMBER [%s]" % APP_USER)
        print("user acc_app in acc: db_owner")
    else:
        print("user acc_app: exists")

    # ۴) اسکیما + گاردها
    run_batches(cur, "/home/z/my-project/accweb/sql/01_schema.sql")
    c.close()

    # ۵) راستی‌آزمایی
    c = connect("acc")
    cur = c.cursor()
    cur.execute("""SELECT TABLE_SCHEMA + '.' + TABLE_NAME FROM INFORMATION_SCHEMA.TABLES
                   WHERE TABLE_SCHEMA IN ('Prm','Acc','Vch') ORDER BY 1""")
    tables = [r[0] for r in cur.fetchall()]
    print("tables:", tables)
    cur.execute("SELECT name FROM sys.triggers WHERE name LIKE 'Tr_Yfg%' ORDER BY name")
    print("guards:", [r[0] for r in cur.fetchall()])
    cur.execute("SELECT name FROM sys.views WHERE name='VwChart'")
    print("view VwChart:", cur.fetchone())
    c.close()
    print("SCHEMA READY ✓")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print("FATAL:", str(e)[:300]); sys.exit(1)
