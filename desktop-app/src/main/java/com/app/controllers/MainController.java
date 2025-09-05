package com.app.controllers;

import com.app.repositories.KpiRepository;
import com.app.services.KpiService;
import com.app.services.ExportService;
import javafx.animation.FadeTransition;
import javafx.fxml.FXML;
import javafx.scene.chart.BarChart;
import javafx.scene.chart.LineChart;
import javafx.scene.chart.XYChart;
import javafx.scene.control.Alert;
import javafx.scene.control.ButtonType;
import javafx.scene.control.DatePicker;
import javafx.scene.control.TableView;
import javafx.scene.layout.VBox;
import javafx.util.Duration;

import java.nio.file.Paths;
import java.time.LocalDate;

public class MainController {
    @FXML private DatePicker dpFrom;
    @FXML private DatePicker dpTo;
    @FXML private LineChart<String, Number> lineChart;
    @FXML private BarChart<String, Number> barChart;
    @FXML private TableView<KpiRepository.VentaProducto> tblProductos;
    @FXML private VBox root;

    private final KpiService kpiService = new KpiService();
    private final ExportService exportService = new ExportService();

    @FXML
    public void initialize() {
        dpFrom.setValue(LocalDate.now().minusDays(7));
        dpTo.setValue(LocalDate.now());
        loadData();

        FadeTransition ft = new FadeTransition(Duration.millis(500), root);
        ft.setFromValue(0);
        ft.setToValue(1);
        ft.play();
    }

    @FXML
    private void loadData() {
        try {
            var diarias = kpiService.getVentasDiarias(dpFrom.getValue(), dpTo.getValue());
            XYChart.Series<String, Number> serie = new XYChart.Series<>();
            diarias.forEach(v -> serie.getData().add(new XYChart.Data<>(v.fecha(), v.total())));
            lineChart.getData().setAll(serie);

            var productos = kpiService.getVentasPorProducto(dpFrom.getValue(), dpTo.getValue());
            XYChart.Series<String, Number> barSerie = new XYChart.Series<>();
            productos.forEach(v -> barSerie.getData().add(new XYChart.Data<>(v.sku(), v.unidades())));
            barChart.getData().setAll(barSerie);
            tblProductos.getItems().setAll(productos);
        } catch (Exception ex) {
            showError(ex.getMessage());
        }
    }

    @FXML
    private void refreshKpis() {
        try {
            kpiService.refreshMaterializedViews();
            loadData();
        } catch (Exception ex) {
            showError(ex.getMessage());
        }
    }

    @FXML
    private void exportCsv() {
        try {
            exportService.exportVentasDiarias(dpFrom.getValue(), dpTo.getValue());
            exportService.exportVentasPorProducto(dpFrom.getValue(), dpTo.getValue());
        } catch (Exception ex) {
            showError(ex.getMessage());
        }
    }

    @FXML
    private void openFolder() {
        try {
            var path = Paths.get(exportService.getExportDir());
            java.awt.Desktop.getDesktop().open(path.toFile());
        } catch (Exception ex) {
            showError(ex.getMessage());
        }
    }

    private void showError(String msg) {
        new Alert(Alert.AlertType.ERROR, msg, ButtonType.OK).showAndWait();
    }
}
