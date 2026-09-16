USE superstore_finance;

-- Return exposure by category; use sales as exposure, not automatically as lost revenue.
SELECT p.category,
       COUNT(DISTINCT f.order_id) AS orders,
       COUNT(DISTINCT CASE WHEN r.returned THEN f.order_id END) AS returned_orders,
       ROUND(COUNT(DISTINCT CASE WHEN r.returned THEN f.order_id END) /
             NULLIF(COUNT(DISTINCT f.order_id), 0) * 100, 2) AS return_rate_pct,
       ROUND(SUM(CASE WHEN r.returned THEN f.sales ELSE 0 END), 2) AS returned_order_sales_exposure
FROM fact_order_line f
JOIN dim_product p USING (product_key)
LEFT JOIN fact_return r ON r.order_id = f.order_id
GROUP BY p.category ORDER BY return_rate_pct DESC;

-- Customers with high revenue but negative lifetime profit.
SELECT c.customer_id, c.customer_name, c.segment,
       ROUND(SUM(f.sales), 2) AS lifetime_sales,
       ROUND(SUM(f.profit), 2) AS lifetime_profit,
       ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100, 2) AS margin_pct,
       AVG(f.discount) AS average_discount
FROM fact_order_line f JOIN dim_customer c USING (customer_key)
GROUP BY c.customer_id, c.customer_name, c.segment
HAVING SUM(f.profit) < 0
ORDER BY lifetime_sales DESC LIMIT 25;

