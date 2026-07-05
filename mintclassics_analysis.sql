-- ============================================================
-- MINT CLASSICS INVENTORY ANALYSIS
-- Author: Pham Thu Trang
-- Goal: Identify which warehouse could be closed, and how to
-- reorganize/reduce inventory while maintaining 24-hour shipping.
-- ============================================================


-- ============================================================
-- SECTION 0: Data Type Cleanup / Setup
-- Notes: warehousePctCap is stored as VARCHAR; cast to numeric
-- when doing calculations or sorting.
-- ============================================================
SELECT 
    warehouseCode,
    warehouseName,
    CAST(warehousePctCap AS UNSIGNED) AS pct_cap
FROM mintclassics.warehouses;


-- ============================================================
-- SECTION 1: Warehouse Overview
-- Question: How many products and how much stock does each
-- warehouse currently hold, and how full is each warehouse?
-- ============================================================
SELECT
    w.warehouseCode,
    w.warehouseName,
    CAST(w.warehousePctCap AS UNSIGNED)   AS pct_cap,
    COUNT(p.productCode)                  AS num_products,
    SUM(p.quantityInStock)                AS total_units_in_stock,
    ROUND(AVG(p.quantityInStock))         AS avg_units_per_product
FROM mintclassics.warehouses w
LEFT JOIN mintclassics.products p
    ON w.warehouseCode = p.warehouseCode
GROUP BY w.warehouseCode, w.warehouseName, w.warehousePctCap
ORDER BY total_units_in_stock DESC;

-- ============================================================
-- SECTION 2: Sales Velocity vs. Stock, by Warehouse (CTE version)
-- Question: How much has actually been sold (via orderdetails)
-- for products in each warehouse, and how does that compare to
-- how much stock is sitting there?
-- Note: quantityInStock is at the product grain, and
-- quantityOrdered is at the orderdetails grain. Joining them
-- directly double-counts stock across every order line, so we
-- aggregate stock and sales separately in CTEs, then join the
-- two summarized results together.
-- ============================================================
WITH stock_by_warehouse AS (
    SELECT
        warehouseCode,
        SUM(quantityInStock) AS total_stock
    FROM mintclassics.products
    GROUP BY warehouseCode
),
sales_by_warehouse AS (
    SELECT
        p.warehouseCode,
        SUM(od.quantityOrdered) AS total_units_sold
    FROM mintclassics.products p
    JOIN mintclassics.orderdetails od
        ON p.productCode = od.productCode
    GROUP BY p.warehouseCode
)
SELECT
    w.warehouseCode,
    w.warehouseName,
    s.total_stock,
    sl.total_units_sold,
    ROUND(s.total_stock / sl.total_units_sold, 2) AS stock_to_sales_ratio
FROM mintclassics.warehouses w
JOIN stock_by_warehouse s  ON w.warehouseCode = s.warehouseCode
JOIN sales_by_warehouse sl ON w.warehouseCode = sl.warehouseCode
ORDER BY stock_to_sales_ratio DESC;

-- ============================================================
-- SECTION 3: Product-Level Detail for West Warehouse
-- Question: Within West (our leading closure candidate), which
-- specific products are overstocked relative to sales, and are
-- there any fast-movers that would need careful handling if
-- relocated?
-- ============================================================
WITH product_sales AS (
    SELECT
        productCode,
        SUM(quantityOrdered) AS units_sold
    FROM mintclassics.orderdetails
    GROUP BY productCode
)
SELECT
    p.productCode,
    p.productName,
    p.productLine,
    p.quantityInStock,
    COALESCE(ps.units_sold, 0) AS units_sold,
    ROUND(p.quantityInStock / NULLIF(ps.units_sold, 0), 2) AS stock_to_sales_ratio
FROM mintclassics.products p
LEFT JOIN product_sales ps ON p.productCode = ps.productCode
WHERE p.warehouseCode = 'c'
ORDER BY stock_to_sales_ratio DESC;

-- ============================================================
-- SECTION 4: Product Line Distribution Across Warehouses
-- Question: Is each product line concentrated in a single
-- warehouse, or spread across multiple? This tells us whether
-- closing West means relocating a whole product line, or
-- whether other warehouses could already absorb it.
-- ============================================================
SELECT
    p.productLine,
    w.warehouseCode,
    w.warehouseName,
    COUNT(*) AS num_products
FROM mintclassics.products p
JOIN mintclassics.warehouses w
    ON p.warehouseCode = w.warehouseCode
GROUP BY p.productLine, w.warehouseCode, w.warehouseName
ORDER BY p.productLine, num_products DESC;

-- ============================================================
-- SECTION 5: Warehouse Capacity Headroom
-- Question: If West closes, do North, South, and East have
-- enough spare capacity to absorb West's inventory? We estimate
-- each warehouse's total capacity from its current stock and
-- % capacity used (pct_cap = current stock / total capacity),
-- then compute spare room = total capacity - current stock.
-- ============================================================
WITH warehouse_stock AS (
    SELECT
        w.warehouseCode,
        w.warehouseName,
        CAST(w.warehousePctCap AS UNSIGNED) AS pct_cap,
        SUM(p.quantityInStock) AS current_stock
    FROM mintclassics.warehouses w
    JOIN mintclassics.products p
        ON w.warehouseCode = p.warehouseCode
    GROUP BY w.warehouseCode, w.warehouseName, w.warehousePctCap
)
SELECT
    warehouseCode,
    warehouseName,
    pct_cap,
    current_stock,
    ROUND(current_stock / (pct_cap / 100.0)) AS estimated_total_capacity,
    ROUND(current_stock / (pct_cap / 100.0)) - current_stock AS estimated_spare_capacity
FROM warehouse_stock
ORDER BY estimated_spare_capacity DESC;

-- ============================================================
-- SECTION 6a: Company-Wide Slow-Movers / Drop Candidates
-- Question: Across ALL warehouses, which products have high
-- stock relative to sales (or have never sold), making them
-- candidates for inventory reduction or discontinuation rather
-- than relocation?
-- ============================================================
WITH product_sales AS (
    SELECT
        productCode,
        SUM(quantityOrdered) AS units_sold,
        COUNT(DISTINCT orderNumber) AS num_orders
    FROM mintclassics.orderdetails
    GROUP BY productCode
)
SELECT
    p.productCode,
    p.productName,
    p.productLine,
    p.warehouseCode,
    p.quantityInStock,
    COALESCE(ps.units_sold, 0) AS units_sold,
    COALESCE(ps.num_orders, 0) AS num_orders,
    ROUND(p.quantityInStock / NULLIF(ps.units_sold, 0), 2) AS stock_to_sales_ratio
FROM mintclassics.products p
LEFT JOIN product_sales ps ON p.productCode = ps.productCode
ORDER BY stock_to_sales_ratio DESC
LIMIT 20;

-- ============================================================
-- SECTION 6b: True Non-Movers (Zero Sales)
-- Question: Are there any products with NO recorded sales at
-- all? These are the only real "discontinue" candidates —
-- everything else is a "right-size the stock level" candidate.
-- ============================================================
SELECT
    p.productCode,
    p.productName,
    p.productLine,
    p.warehouseCode,
    p.quantityInStock
FROM mintclassics.products p
LEFT JOIN mintclassics.orderdetails od
    ON p.productCode = od.productCode
WHERE od.productCode IS NULL;

-- ============================================================
-- SECTION 7: Current Order Fulfillment Speed
-- Question: How long does it currently take to ship an order
-- (orderDate to shippedDate)? This tells us how much margin
-- for error exists before touching inventory levels, and
-- whether the 24-hour target is already being met today.
-- ============================================================
SELECT
    status,
    COUNT(*) AS num_orders,
    ROUND(AVG(DATEDIFF(shippedDate, orderDate)), 2) AS avg_days_to_ship,
    MIN(DATEDIFF(shippedDate, orderDate)) AS min_days_to_ship,
    MAX(DATEDIFF(shippedDate, orderDate)) AS max_days_to_ship
FROM mintclassics.orders
GROUP BY status;

-- ============================================================
-- ============================================================
-- SECTION 8a: Alternative Scenario — South's Product Line Stock
-- Question: If South closes instead of West, how many units
-- are in each of its 3 product lines (Trucks and Buses, Ships,
-- Trains)? This tells us what needs a new home.
-- ============================================================
WITH line_stock AS (
    SELECT
        productLine,
        SUM(quantityInStock) AS line_total_stock
    FROM mintclassics.products
    WHERE warehouseCode = 'd'
    GROUP BY productLine
)
SELECT * FROM line_stock;

-- ============================================================
-- SECTION 8b: Alternative Scenario — Remaining Warehouse Capacity
-- Question: If South closes, how much spare capacity exists in
-- East, North, and West to absorb South's 3 product lines?
-- ============================================================
SELECT
    warehouseCode,
    warehouseName,
    current_stock,
    estimated_total_capacity,
    spare_capacity
FROM (
    SELECT
        w.warehouseCode,
        w.warehouseName,
        SUM(p.quantityInStock) AS current_stock,
        ROUND(SUM(p.quantityInStock) / (CAST(w.warehousePctCap AS UNSIGNED) / 100.0)) AS estimated_total_capacity,
        ROUND(SUM(p.quantityInStock) / (CAST(w.warehousePctCap AS UNSIGNED) / 100.0)) - SUM(p.quantityInStock) AS spare_capacity
    FROM mintclassics.warehouses w
    JOIN mintclassics.products p ON w.warehouseCode = p.warehouseCode
    WHERE w.warehouseCode != 'd'
    GROUP BY w.warehouseCode, w.warehouseName, w.warehousePctCap
) x
ORDER BY spare_capacity DESC;