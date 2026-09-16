USE superstore_finance;

-- Each check should return zero rows or a zero difference unless noted.
SELECT row_id, COUNT(*) AS duplicate_count
FROM stg_orders GROUP BY row_id HAVING COUNT(*) > 1;

SELECT * FROM stg_orders
WHERE order_date > ship_date OR sales < 0 OR quantity <= 0
   OR discount < 0 OR discount > 1;

SELECT 'staging_to_fact_row_count' AS check_name,
       (SELECT COUNT(*) FROM stg_orders) AS source_value,
       (SELECT COUNT(*) FROM fact_order_line) AS model_value,
       (SELECT COUNT(*) FROM stg_orders) - (SELECT COUNT(*) FROM fact_order_line) AS difference;

SELECT 'staging_to_fact_sales' AS check_name,
       ROUND((SELECT SUM(sales) FROM stg_orders), 2) AS source_value,
       ROUND((SELECT SUM(sales) FROM fact_order_line), 2) AS model_value,
       ROUND((SELECT SUM(sales) FROM stg_orders) - (SELECT SUM(sales) FROM fact_order_line), 2) AS difference;

SELECT r.order_id FROM fact_return r
LEFT JOIN fact_order_line f ON f.order_id = r.order_id
WHERE f.order_id IS NULL;

