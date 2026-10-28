#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""کاوش کاتالوگ سرور — فهرست جدول‌ها/ستون‌ها/ترتیب وابستگی برای مهاجرت v1.2.0"""
import pymssql, json, io

HOST = "85.133.175.190"
USER, PASS, DB = "acc_app", "Acc!2026$Web#p7Km", "acc"

def main():
    c = pymssql.connect(server=HOST, port=1433, user=USER, password=PASS, database=DB,
                        charset="UTF-8", login_timeout=15, timeout=60, autocommit=True)
    cur = c.cursor()
    cur.execute("""
      SELECT s.name, t.name, c.column_id, c.name, TYPE_NAME(c.user_type_id),
             c.max_length, c.is_identity, c.is_computed
      FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id
      JOIN sys.columns c ON c.object_id=t.object_id
      WHERE s.name IN ('Prm','Acc','Vch','gnr')
      ORDER BY s.name, t.name, c.column_id""")
    tables = {}
    for sch, tbl, cid, col, typ, mlen, ident, comp in cur.fetchall():
        tables.setdefault(f"{sch}.{tbl}", []).append(
            {"col": col, "type": typ, "len": mlen, "id": bool(ident), "comp": bool(comp)})
    cur.execute("""
      SELECT s.name, v.name FROM sys.views v JOIN sys.schemas s ON s.schema_id=v.schema_id
      WHERE s.name IN ('Prm','Acc','Vch','gnr')""")
    views = [f"{s}.{v}" for s, v in cur.fetchall()]
    cur.execute("""
      SELECT s.name, tr.name, OBJECT_NAME(tr.parent_id) FROM sys.triggers tr
      JOIN sys.objects o ON o.object_id = tr.object_id
      JOIN sys.schemas s ON s.schema_id = o.schema_id
      WHERE s.name IN ('Prm','Acc','Vch','gnr')""")
    trigs = [f"{s}.{t} ON {p}" for s, t, p in cur.fetchall()]
    cur.execute("""
      SELECT s.name, f.name FROM sys.objects f
      JOIN sys.schemas s ON s.schema_id = f.schema_id
      WHERE f.type IN ('FN','IF','TF') AND s.name IN ('Prm','Acc','Vch','gnr')""")
    fns = [f"{s}.{n}" for s, n in cur.fetchall()]
    counts = {}
    for sch, tbl in [(k.split('.')[0], k.split('.')[1]) for k in tables]:
        cur.execute(f"SELECT COUNT(*) FROM [{sch}].[{tbl}]")
        counts[f"{sch}.{tbl}"] = cur.fetchone()[0]
    out = {"tables": tables, "views": views, "triggers": trigs, "functions": fns, "counts": counts}
    io.open("scripts/_catalog.json", "w", encoding="utf-8").write(json.dumps(out, ensure_ascii=False, indent=1))
    print("views:", views); print("triggers:", trigs); print("functions:", fns)
    print("counts:", json.dumps(counts, ensure_ascii=False))
    c.close()

if __name__ == "__main__":
    main()
