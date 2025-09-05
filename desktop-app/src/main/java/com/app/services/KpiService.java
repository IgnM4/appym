package com.app.services;

import com.app.config.DbConfig;
import com.app.repositories.KpiRepository;
import com.app.repositories.OracleKpiRepository;
import com.app.repositories.PostgresKpiRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.sql.SQLException;
import java.time.LocalDate;
import java.util.List;

/**
 * Servicio que delega en un {@link KpiRepository} para obtener los datos de KPI.
 * Permite cambiar de motor de base de datos según el JDBC URL.
 */
public class KpiService {
    private static final Logger log = LoggerFactory.getLogger(KpiService.class);
    private final KpiRepository repo;

    public KpiService() {
        DbConfig cfg = DbConfig.load();
        this.repo = switch (cfg.vendor()) {
            case "postgres" -> new PostgresKpiRepository();
            default -> new OracleKpiRepository();
        };
    }

    public KpiService(KpiRepository repo) {
        this.repo = repo;
    }

    public List<KpiRepository.VentaDiaria> getVentasDiarias(LocalDate from, LocalDate to) throws SQLException {
        return repo.getVentasDiarias(from, to);
    }

    /**
     * Obtiene las ventas agrupadas por producto en un rango de fechas utilizando
     * las relaciones entre boletas, sus detalles y los productos.
     */
    public List<KpiRepository.VentaProducto> getVentasPorProducto(LocalDate from, LocalDate to) throws SQLException {
        log.debug("Obteniendo ventas por producto entre {} y {}", from, to);
        return repo.getVentasPorProducto(from, to);
    }

    public void refreshMaterializedViews() throws SQLException {
        repo.refreshMaterializedViews();
    }
}
