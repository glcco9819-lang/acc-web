declare module "mssql" {
  export class ConnectionPool {
    constructor(config: unknown);
    connected: boolean;
    connect(): Promise<ConnectionPool>;
    request(): any;
  }
  export class Transaction {
    constructor(pool: ConnectionPool);
    begin(): Promise<void>;
    commit(): Promise<void>;
    rollback(): Promise<void>;
  }
  export class Request {
    input(name: string, value: unknown): Request;
    query(text: string): Promise<{ recordset: any[] }>;
  }
  const _default: {
    ConnectionPool: typeof ConnectionPool;
    Transaction: typeof Transaction;
    Request: typeof Request;
  };
  export default _default;
}
