package com.app;

import com.app.config.DbConfig;
import com.app.services.ExportService;
import com.app.services.KpiService;
import com.google.common.jimfs.Jimfs;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.nio.file.FileSystem;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;
import java.time.LocalDate;

import static com.github.stefanbirkner.systemlambda.SystemLambda.withEnvironmentVariable;
import static org.junit.jupiter.api.Assertions.assertTrue;

@Testcontainers
class ExportServiceTest {
  @Container
  static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine")
      .withDatabaseName("testdb")
      .withUsername("test")
      .withPassword("test");

  @BeforeAll
  static void setupSchema() throws Exception {
    try (Connection conn = DriverManager.getConnection(postgres.getJdbcUrl(), postgres.getUsername(), postgres.getPassword());
         Statement st = conn.createStatement()) {
      st.execute("CREATE TABLE v_kpi_ventas_diarias (dia DATE, total_ventas DOUBLE PRECISION)");
      st.execute("INSERT INTO v_kpi_ventas_diarias VALUES ('2024-05-01', 40)");
      st.execute("CREATE TABLE producto (id_producto SERIAL PRIMARY KEY, sku VARCHAR(20), nombre VARCHAR(50))");
      st.execute("INSERT INTO producto (id_producto, sku, nombre) VALUES (1, 'ABC', 'Producto A')");
      st.execute("CREATE TABLE boleta_venta (id_boleta SERIAL PRIMARY KEY, fecha DATE)");
      st.execute("INSERT INTO boleta_venta (id_boleta, fecha) VALUES (1, '2024-05-01')");
      st.execute("CREATE TABLE boleta_venta_detalle (id_boleta INT, id_producto INT, cantidad INT, subtotal DOUBLE PRECISION)");
      st.execute("INSERT INTO boleta_venta_detalle (id_boleta, id_producto, cantidad, subtotal) VALUES (1, 1, 2, 40)");
    }
  }

  @Test
  void exportsFilesToMockFs() throws Exception {
    FileSystem fs = Jimfs.newFileSystem();
    Files.createDirectory(fs.getPath("/out"));

    withEnvironmentVariable("APP_DB_URL", postgres.getJdbcUrl())
        .and("APP_DB_USER", postgres.getUsername())
        .and("APP_DB_PASS", postgres.getPassword())
        .and("APP_EXPORT_DIR", "/out")
        .execute(() -> {
          ExportService svc = new ExportService(DbConfig.load(), new KpiService(), fs);
          svc.exportVentasDiarias(LocalDate.of(2024, 5, 1), LocalDate.of(2024, 5, 2));
          Path csv = fs.getPath("/out", "ventas_hoy.csv");
          Path json = fs.getPath("/out", "ventas_hoy.json");
          assertTrue(Files.exists(csv));
          assertTrue(Files.exists(json));
          String csvContent = Files.readString(csv);
          String jsonContent = Files.readString(json);
          assertTrue(csvContent.contains("2024-05-01"));
          assertTrue(jsonContent.contains("\"fecha\":\"2024-05-01\""));
        });
  }
}

