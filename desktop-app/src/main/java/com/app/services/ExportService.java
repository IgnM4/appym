package com.app.services;

import com.app.config.DbConfig;
import com.app.repositories.KpiRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVPrinter;

import java.io.IOException;
import java.io.Writer;
import java.nio.file.FileSystem;
import java.nio.file.FileSystems;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.Date;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.List;

/**
 * Exporta datos a archivos en el lado de la aplicación utilizando vistas o
 * materialized views expuestas por la base de datos. Evita escribir archivos
 * desde procedimientos almacenados en el servidor.
 */
public class ExportService {
    private final DbConfig cfg;
    private final KpiService kpiService;
    private final FileSystem fs;
    private final ObjectMapper mapper = new ObjectMapper();

    public ExportService() {
        this(DbConfig.load(), new KpiService(), FileSystems.getDefault());
    }

    public ExportService(DbConfig cfg, KpiService kpiService, FileSystem fs) {
        this.cfg = cfg;
        this.kpiService = kpiService;
        this.fs = fs;
    }

    public void exportVentasDiarias(LocalDate from, LocalDate to) throws SQLException, IOException {
        List<KpiRepository.VentaDiaria> data = kpiService.getVentasDiarias(from, to);

        if (cfg.vendor().equals("oracle") && cfg.useExportProc()) {
            exportWithProc("pr_export_ventas_diarias", from, to, "ventas_hoy.csv");
        } else {
            Path csv = fs.getPath(cfg.exportDir(), "ventas_hoy.csv");
            try (Writer w = Files.newBufferedWriter(csv);
                 CSVPrinter printer = new CSVPrinter(w, CSVFormat.DEFAULT.withHeader("dia", "total_ventas"))) {
                for (var v : data) {
                    printer.printRecord(v.fecha(), v.total());
                }
            }
        }

        Path json = fs.getPath(cfg.exportDir(), "ventas_hoy.json");
        mapper.writeValue(json.toFile(), data);
    }

    public void exportVentasPorProducto(LocalDate from, LocalDate to) throws SQLException, IOException {
        List<KpiRepository.VentaProducto> data = kpiService.getVentasPorProducto(from, to);

        if (cfg.vendor().equals("oracle") && cfg.useExportProc()) {
            exportWithProc("pr_export_ventas_por_producto", from, to, "ventas_prod_ult7d.csv");
        } else {
            Path csv = fs.getPath(cfg.exportDir(), "ventas_prod_ult7d.csv");
            try (Writer w = Files.newBufferedWriter(csv);
                 CSVPrinter printer = new CSVPrinter(w, CSVFormat.DEFAULT.withHeader("sku", "nombre", "unidades", "monto"))) {
                for (var v : data) {
                    printer.printRecord(v.sku(), v.nombre(), v.unidades(), v.monto());
                }
            }
        }

        Path json = fs.getPath(cfg.exportDir(), "ventas_prod_ult7d.json");
        mapper.writeValue(json.toFile(), data);
    }

    private void exportWithProc(String procName, LocalDate from, LocalDate to, String file) throws SQLException {
        try (Connection c = DriverManager.getConnection(cfg.url(), cfg.user(), cfg.pass());
             CallableStatement cs = c.prepareCall("{call " + procName + "(?, ?, ?)}")) {
            cs.setDate(1, Date.valueOf(from));
            cs.setDate(2, Date.valueOf(to));
            cs.setString(3, file);
            cs.execute();
        }
    }

    public String getExportDir() {
        return cfg.exportDir();
    }
}
