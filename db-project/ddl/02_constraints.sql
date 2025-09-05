-- Relaciones usuario/rol
ALTER TABLE usuario
  ADD CONSTRAINT fk_usuario__rol
  FOREIGN KEY (id_rol) REFERENCES rol(id_rol);

-- Inventario 1–1 producto
ALTER TABLE inventario
  ADD CONSTRAINT fk_inventario__producto
  FOREIGN KEY (id_producto) REFERENCES producto(id_producto);

-- Compras
ALTER TABLE factura_compra
  ADD CONSTRAINT fk_fc__proveedor FOREIGN KEY (id_proveedor) REFERENCES proveedor(id_proveedor);
ALTER TABLE factura_compra
  ADD CONSTRAINT fk_fc__usuario FOREIGN KEY (id_usuario_registra) REFERENCES usuario(id_usuario);

ALTER TABLE factura_compra
  ADD CONSTRAINT uq_fc__prov_num UNIQUE (id_proveedor, numero);

ALTER TABLE factura_compra_detalle
  ADD CONSTRAINT fk_fc_det__fc FOREIGN KEY (id_factura_compra) REFERENCES factura_compra(id_factura_compra);
ALTER TABLE factura_compra_detalle
  ADD CONSTRAINT fk_fc_det__producto FOREIGN KEY (id_producto) REFERENCES producto(id_producto);

-- Ventas
ALTER TABLE boleta_venta
  ADD CONSTRAINT fk_bol__usuario FOREIGN KEY (id_usuario_vende) REFERENCES usuario(id_usuario);
ALTER TABLE boleta_venta
  ADD CONSTRAINT fk_bol__cliente FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente);

ALTER TABLE boleta_venta
  ADD CONSTRAINT uq_boleta__numero UNIQUE (numero);

ALTER TABLE boleta_venta_detalle
  ADD CONSTRAINT fk_bol_det__boleta FOREIGN KEY (id_boleta) REFERENCES boleta_venta(id_boleta);
ALTER TABLE boleta_venta_detalle
  ADD CONSTRAINT fk_bol_det__producto FOREIGN KEY (id_producto) REFERENCES producto(id_producto);

-- Historial de precios
ALTER TABLE producto_precio_hist
  ADD CONSTRAINT fk_pph__producto FOREIGN KEY (id_producto) REFERENCES producto(id_producto);
