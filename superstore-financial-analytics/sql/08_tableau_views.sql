USE superstore_finance;

CREATE OR REPLACE VIEW vw_tableau_order_lines AS
SELECT f.row_id, f.order_id, f.order_date, f.ship_date, f.ship_mode,
       c.customer_id, c.customer_name, c.segment,
       p.product_id, p.category, p.sub_category, p.product_name,
       g.country_region, g.city, g.state_province, g.postal_code, g.region,
       sp.regional_manager,
       f.sales, f.quantity, f.discount, f.profit,
       f.profit / NULLIF(f.sales, 0) AS profit_margin,
       COALESCE(r.returned, FALSE) AS returned
FROM fact_order_line f
JOIN dim_customer c USING (customer_key)
JOIN dim_product p USING (product_key)
JOIN dim_geography g USING (geography_key)
LEFT JOIN stg_people sp ON sp.region = g.region
LEFT JOIN fact_return r ON r.order_id = f.order_id;

CREATE OR REPLACE VIEW vw_tableau_budget_variance AS
WITH actual AS (
    SELECT CAST(DATE_FORMAT(f.order_date, '%Y-%m-01') AS DATE) AS actual_month,
           g.region, p.category, SUM(f.sales) AS actual_sales, SUM(f.profit) AS actual_profit
    FROM fact_order_line f
    JOIN dim_geography g USING (geography_key)
    JOIN dim_product p USING (product_key)
    GROUP BY actual_month, g.region, p.category
)
SELECT b.budget_month, b.region, b.category, b.budget_sales, b.budget_profit,
       COALESCE(a.actual_sales, 0) AS actual_sales,
       COALESCE(a.actual_profit, 0) AS actual_profit,
       COALESCE(a.actual_sales, 0) - b.budget_sales AS sales_variance,
       COALESCE(a.actual_profit, 0) - b.budget_profit AS profit_variance,
       b.budget_method
FROM fact_budget b
LEFT JOIN actual a
  ON a.actual_month = b.budget_month
 AND a.region = b.region
 AND a.category = b.category;
