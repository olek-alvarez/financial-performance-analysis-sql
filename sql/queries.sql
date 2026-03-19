-- ========================================
-- 1. DATA EXPLORATION
-- ========================================

SELECT * FROM ventas_2017 LIMIT 10;
SELECT * FROM productos LIMIT 10;
SELECT * FROM productos_categorias LIMIT 10;
SELECT * FROM territorios LIMIT 10;
SELECT * FROM campanas LIMIT 10;


-- ========================================
-- 2. DATA PREPARATION (JOINS + CLEANING)
-- ========================================

SELECT 
    v.numero_pedido, 
    v.clave_producto, 
    p.nombre_producto, 
    pc.clave_categoria, 
    COALESCE(p.precio_producto,0) AS precio_producto, 
    COALESCE(v.cantidad_pedido,0) AS cantidad_pedido, 
    COALESCE(p.costo_producto,0) AS costo_producto,
    t.pais, 
    t.continente, 
    v.clave_territorio
FROM ventas_2017 v
LEFT JOIN productos p 
    ON v.clave_producto = p.clave_producto
LEFT JOIN productos_categorias pc 
    ON p.clave_subcategoria = pc.clave_subcategoria
LEFT JOIN territorios t 
    ON v.clave_territorio = t.clave_territorio;


-- Add calculated fields (revenue & cost)

SELECT
    v.numero_pedido,
    v.clave_producto,
    p.nombre_producto,
    pc.clave_categoria,
    COALESCE(p.precio_producto, 0)  AS precio_producto,
    COALESCE(v.cantidad_pedido, 0)  AS cantidad_pedido,
    COALESCE(p.costo_producto, 0)   AS costo_producto,
    t.pais,
    t.continente,
    v.clave_territorio,
    
    -- KPIs
    COALESCE(p.precio_producto, 0)*COALESCE(v.cantidad_pedido, 0) AS ingreso_total,
    COALESCE(p.costo_producto, 0)*COALESCE(v.cantidad_pedido, 0) AS costo_total

FROM ventas_2017 AS v
JOIN productos AS p
  ON v.clave_producto = p.clave_producto
LEFT JOIN productos_categorias AS pc
  ON p.clave_subcategoria = pc.clave_subcategoria
LEFT JOIN territorios AS t
  ON v.clave_territorio = t.clave_territorio;


-- ========================================
-- 3. FINANCIAL ANALYSIS
-- ========================================

-- Revenue and cost by country

SELECT 
    pais,
    clave_territorio, 
    SUM(ingreso_total)::integer AS ingresos,
    SUM(costo_total)::integer AS costos
FROM ventas_clean
GROUP BY pais, clave_territorio
ORDER BY ingresos DESC;


-- Add marketing cost

SELECT
    v.pais,
    v.clave_territorio,
    SUM(v.ingreso_total)::integer AS ingresos,
    SUM(v.costo_total)::integer  AS costos,
    COALESCE(SUM(c.costo_campana::integer),0) AS costo_campana
FROM ventas_clean AS v
LEFT JOIN campanas AS c
  ON v.clave_territorio = c.clave_territorio::integer
GROUP BY
    v.pais,
    v.clave_territorio
ORDER BY
    ingresos DESC;


-- Final KPIs

SELECT
    p.pais,
    p.clave_territorio,
    SUM(p.ingresos)::integer AS ingresos,
    SUM(p.costos)::integer AS costos,
    COALESCE(SUM(c.costo_campana),0)::integer AS costo_campana,

    -- Business metrics
    SUM(p.ingresos)::integer - SUM(p.costos)::integer AS beneficio_bruto,

    (SUM(p.ingresos) - SUM(p.costos)) * 100 / NULLIF(SUM(p.ingresos),0) AS margen_pct,

    (SUM(p.ingresos) - SUM(p.costos)) * 100 / NULLIF(SUM(c.costo_campana),0) AS roi_pct

FROM pais_ingreso_costo AS p
LEFT JOIN pais_campanas AS c
  ON p.clave_territorio = c.clave_territorio
GROUP BY
    p.pais,
    p.clave_territorio
ORDER BY
    p.clave_territorio;


-- ========================================
-- 4. DATA VALIDATION (QA)
-- ========================================

-- Check NULLs in key columns

SELECT 
    SUM(CASE WHEN numero_pedido IS NULL THEN 1 ELSE 0 END) AS nulos_numero_pedido,
    SUM(CASE WHEN clave_producto IS NULL THEN 1 ELSE 0 END) AS nulos_clave_producto,
    SUM(CASE WHEN clave_territorio IS NULL THEN 1 ELSE 0 END) AS nulos_clave_territorio
FROM ventas_2017;


-- Check invalid quantities

SELECT 
    COUNT(*) AS filas_cantidad_no_valida
FROM ventas_2017
WHERE cantidad_pedido <= 0;


-- Check invalid prices

SELECT 
    COUNT(*) AS productos_precio_no_valido
FROM productos
WHERE precio_producto < 0;
