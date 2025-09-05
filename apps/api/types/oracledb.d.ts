// Stub de tipos para compilar en CI sin binarios nativos de node-oracledb.
// Cubre uso de namespace (oracledb.Connection, oracledb.Pool, etc.)
// y llamadas comunes (getPool, createPool, close con drainTime/force).

declare module "oracledb" {
  namespace oracledb {
    interface ConnectionAttributes {
      user?: string;
      password?: string;
      connectString?: string;
      [k: string]: any;
    }

    interface PoolAttributes {
      user?: string;
      password?: string;
      connectString?: string;
      poolMin?: number;
      poolMax?: number;
      poolIncrement?: number;
      [k: string]: any;
    }

    interface ExecuteOptions {
      autoCommit?: boolean;
      outFormat?: number;
      [k: string]: any;
    }

    type BindParameters = Record<string, any> | any[];

    interface Result<T = any> {
      rows?: T[];
      rowsAffected?: number;
      outBinds?: Record<string, any> | any[];
      [k: string]: any;
    }

    interface Connection {
      execute<T = any>(
        sql: string,
        binds?: BindParameters,
        options?: ExecuteOptions
      ): Promise<Result<T>>;
      close(): Promise<void>;
      commit(): Promise<void>;
      rollback(): Promise<void>;
      [k: string]: any;
    }

    interface PoolConnection extends Connection {}

    interface Pool {
      getConnection(): Promise<PoolConnection>;
      // Acepta force (boolean), drainTime (number) o objeto de opciones
      close(
        arg?: boolean | number | { force?: boolean; drainTime?: number }
      ): Promise<void>;
      [k: string]: any;
    }
  }

  interface OracledbAPI {
    // Constantes comunes
    OUT_FORMAT_OBJECT: number;
    OUT_FORMAT_ARRAY: number;
    BIND_IN?: number;
    BIND_OUT?: number;
    BIND_INOUT?: number;
    STRING?: number;
    NUMBER?: number;
    DATE?: number;

    // APIs
    getConnection(
      attrs?: oracledb.ConnectionAttributes
    ): Promise<oracledb.Connection>;

    createPool(
      attrs?: oracledb.PoolAttributes
    ): Promise<oracledb.Pool>;

    // Hacemos getPool requerido para evitar "posiblemente indefinido"
    getPool(name?: string): oracledb.Pool;

    [k: string]: any;
  }

  const oracledb: OracledbAPI;
  export = oracledb;
}
