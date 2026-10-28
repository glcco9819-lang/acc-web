import sql from "mssql";
import { readFileSync } from "fs";
import { join } from "path";
import { getLogCtx, logCtxPrefix, LogCtx } from "./logctx";

/* کانتکست لاگ: پیشوند هر بچ SQL — تریگرهای pob.UserLog کاربر/IP/PC را از SESSION_CONTEXT می‌خوانند */
async function prep(text: string, inp?: Record<string, unknown>): Promise<{ text: string; inp: Record<string, unknown> }> {
  const all: Record<string, unknown> = { ...(inp || {}) };
  try {
    const ctx: LogCtx | null = await getLogCtx();
    if (ctx) return { text: logCtxPrefix(ctx, all) + text, inp: all };
  } catch { /* بدون کانتکست — تریگر به نام لاگین SQL برمی‌گردد */ }
  return { text, inp: all };
}

type Pool = import("mssql").ConnectionPool;
type Txn = import("mssql").Transaction;

let cfg: { host: string; port: number; database: string; user: string; password: string };
function loadCfg() {
  if (cfg) return cfg;
  cfg = {
    host: process.env.DB_HOST || "127.0.0.1",
    port: Number(process.env.DB_PORT || 1433),
    database: process.env.DB_NAME || "acc",
    user: process.env.DB_USER || "acc_app",
    password: process.env.DB_PASS || "Acc!2026$Web#p7Km",
  };
  try {
    const f = readFileSync(join(process.cwd(), "db-config.json"), "utf8");
    const j = JSON.parse(f);
    if (!process.env.DB_HOST) {
      cfg = { host: j.host, port: j.port || 1433, database: j.database, user: j.user, password: j.password };
    }
  } catch { /* فایل نبود — env */ }
  return cfg;
}

let pool: Pool | null = null;

export async function getPool(): Promise<Pool> {
  if (pool && pool.connected) return pool;
  const c = loadCfg();
  pool = await new sql.ConnectionPool({
    server: c.host, port: c.port, user: c.user, password: c.password,
    database: c.database, options: { encrypt: false, trustServerCertificate: true },
    requestTimeout: 60000, connectionTimeout: 30000,
  }).connect();
  return pool;
}

export async function q<T = any>(text: string, inp?: Record<string, unknown>): Promise<T[]> {
  const p = await getPool();
  const { text: t2, inp: i2 } = await prep(text, inp);
  const r = p.request();
  for (const [k, v] of Object.entries(i2)) r.input(k, v as any);
  const res = await r.query(t2);
  /* دستورهای DML/DDL بدون recordset برمی‌گردند — همیشه آرایهٔ معتبر بده */
  return ((res && res.recordset) || []) as T[];
}

export async function one<T = any>(text: string, inp?: Record<string, unknown>): Promise<T | null> {
  const rows = await q<T>(text, inp);
  return rows[0] ?? null;
}

export async function scalar(text: string, inp?: Record<string, unknown>): Promise<any> {
  const p = await getPool();
  const { text: t2, inp: i2 } = await prep(text, inp);
  const r = p.request();
  for (const [k, v] of Object.entries(i2)) r.input(k, v as any);
  const res = await r.query(t2);
  const rs = (res && res.recordset) || [];
  const first = rs[0];
  return first ? Object.values(first)[0] : null;
}

export async function tx(fn: (run: (t: string, inp?: Record<string, unknown>) => Promise<any>) => Promise<void>): Promise<void> {
  const p = await getPool();
  const t = new sql.Transaction(p as any);
  await t.begin();
  try {
    const run = async (text: string, inp?: Record<string, unknown>) => {
      const { text: t2, inp: i2 } = await prep(text, inp);
      const r = new (sql.Request as any)(t);
      for (const [k, v] of Object.entries(i2)) r.input(k, v as any);
      const res = await r.query(t2);
      return (res && res.recordset) || [];
    };
    await fn(run);
    await t.commit();
  } catch (e) {
    try { await t.rollback(); } catch { /* already */ }
    throw e;
  }
}

export function fail(res: any, msg: string, code = 400, errCode = "ERR") {
  return res.status(code).json({ ok: false, error: msg, code: errCode });
}
export function ok(res: any, data: Record<string, unknown> = {}) {
  return res.status(200).json({ ok: true, ...data });
}
