package com.app.db;

import com.app.config.DbConfig;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;
import java.nio.file.Path;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Exporta el contenido de una vista o materialized view a un archivo JSON
 * utilizando JDBC.
 */
public class JsonExportService extends DatabaseService {
    private final ObjectMapper mapper = new ObjectMapper();

    public JsonExportService(DbConfig config) {
        super(config);
    }

    public void exportViewToJson(String viewName, Path output) throws SQLException, IOException {
        try (var conn = getConnection();
             var stmt = conn.createStatement();
             var rs = stmt.executeQuery("SELECT * FROM " + viewName)) {

            var meta = rs.getMetaData();
            List<Map<String, Object>> rows = new ArrayList<>();
            while (rs.next()) {
                Map<String, Object> row = new LinkedHashMap<>();
                for (int i = 1; i <= meta.getColumnCount(); i++) {
                    row.put(meta.getColumnLabel(i), rs.getObject(i));
                }
                rows.add(row);
            }
            mapper.writerWithDefaultPrettyPrinter().writeValue(output.toFile(), rows);
        }
    }
}
