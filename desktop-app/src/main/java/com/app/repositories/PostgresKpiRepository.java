package com.app.repositories;

import com.app.config.DbConfig;

import java.sql.*;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/**
 * PostgreSQL implementation of {@link KpiRepository}.
 */
public class PostgresKpiRepository implements KpiRepository {
    private final DbConfig cfg = DbConfig.load();

    private Connection getConnection() throws SQLException {
        return DriverManager.getConnection(cfg.url(), cfg.user(), cfg.pass());
    }

    @Override
    public List<VentaDiaria> getVentasDiarias(LocalDate from, LocalDate to) throws SQLException {
        List<VentaDiaria> list = new ArrayList<>();
        String sql = "SELECT TO_CHAR(dia,'YYYY-MM-DD') dia, total_ventas FROM v_kpi_ventas_diarias WHERE dia BETWEEN ? AND ? ORDER BY dia";
        try (Connection c = getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setObject(1, from);
            ps.setObject(2, to);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(new VentaDiaria(rs.getString("dia"), rs.getDouble("total_ventas")));
                }
            }
        }
        return list;
    }

    @Override
    public List<VentaProducto> getVentasPorProducto(LocalDate from, LocalDate to) throws SQLException {
        List<VentaProducto> list = new ArrayList<>();
        String sql = """
            SELECT p.sku,
                   p.nombre,
                   SUM(d.cantidad)   unidades,
                   SUM(d.subtotal)   monto
            FROM boleta_venta b
            JOIN boleta_venta_detalle d ON b.id_boleta = d.id_boleta
            JOIN producto p ON p.id_producto = d.id_producto
            WHERE b.fecha BETWEEN ? AND ?
            GROUP BY p.sku, p.nombre
            ORDER BY p.sku
            """;
        try (Connection c = getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setObject(1, from);
            ps.setObject(2, to);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(new VentaProducto(
                        rs.getString("sku"),
                        rs.getString("nombre"),
                        rs.getInt("unidades"),
                        rs.getDouble("monto")));
                }
            }
        }
        return list;
    }

    @Override
    public void refreshMaterializedViews() throws SQLException {
        try (Connection c = getConnection(); Statement st = c.createStatement()) {
            st.execute("REFRESH MATERIALIZED VIEW IF EXISTS mv_ventas_diarias");
            st.execute("REFRESH MATERIALIZED VIEW IF EXISTS mv_ventas_por_producto");
        }
    }
}
