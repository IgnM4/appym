package com.app.db;

import com.app.config.DbConfig;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 * Servicio base para obtener conexiones JDBC utilizando {@link DbConfig}.
 */
public class DatabaseService {
    private final DbConfig config;

    public DatabaseService(DbConfig config) {
        this.config = config;
    }

    protected Connection getConnection() throws SQLException {
        return DriverManager.getConnection(config.url(), config.user(), config.pass());
    }
}
