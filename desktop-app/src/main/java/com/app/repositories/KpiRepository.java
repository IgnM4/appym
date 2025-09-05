package com.app.repositories;

import java.sql.SQLException;
import java.time.LocalDate;
import java.util.List;

/**
 * Repository interface to obtain KPI data from the database. Implementations
 * can target different database engines (Oracle, PostgreSQL, MySQL, etc.).
 */
public interface KpiRepository {
    /** Venta total por día. */
    record VentaDiaria(String fecha, double total) {}

    /** Venta agregada por producto. */
    record VentaProducto(String sku, String nombre, int unidades, double monto) {}

    List<VentaDiaria> getVentasDiarias(LocalDate from, LocalDate to) throws SQLException;

    List<VentaProducto> getVentasPorProducto(LocalDate from, LocalDate to) throws SQLException;

    void refreshMaterializedViews() throws SQLException;
}
