package com.app.config;

import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

public record DbConfig(String url, String user, String pass, String exportDir, boolean useExportProc) {
    public static DbConfig load() {
        Properties p = new Properties();
        try (InputStream in = DbConfig.class.getResourceAsStream("/app.properties")) {
            if (in != null) {
                p.load(in);
            }
        } catch (IOException e) {
            // ignore
        }
        String url = getenv("APP_DB_URL", p.getProperty("db.url"));
        String user = getenv("APP_DB_USER", p.getProperty("db.user"));
        String pass = getenv("APP_DB_PASS", p.getProperty("db.pass"));
        String dir = getenv("APP_EXPORT_DIR", p.getProperty("export.dir"));
        boolean useProc = Boolean.parseBoolean(getenv("APP_USE_EXPORT_PROC", p.getProperty("export.useProc")));
        return new DbConfig(url, user, pass, dir, useProc);
    }

    private static String getenv(String key, String def) {
        String val = System.getenv(key);
        return val != null && !val.isBlank() ? val : def;
    }

    /**
     * Attempts to infer the database vendor from the JDBC URL. Defaults to
     * {@code oracle} when the URL is not provided.
     */
    public String vendor() {
        if (url == null) {
            return "oracle";
        }
        if (url.startsWith("jdbc:postgresql")) {
            return "postgres";
        }
        if (url.startsWith("jdbc:mysql")) {
            return "mysql";
        }
        return "oracle";
    }
}
