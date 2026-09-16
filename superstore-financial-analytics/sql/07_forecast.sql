USE superstore_finance;

-- Simple run-rate forecast: trailing three complete months projected forward.
-- This is an analyst baseline, not a statistical forecast.
WITH monthly AS (
    SELECT DATE_FORMAT(order_date, '%Y-%m-01') AS month,
           SUM(sales) AS sales, SUM(profit) AS profit
    FROM fact_order_line
    GROUP BY DATE_FORMAT(order_date, '%Y-%m-01')
), ranked AS (
    SELECT *, ROW_NUMBER() OVER (ORDER BY month DESC) AS recency_rank FROM monthly
)
SELECT ROUND(AVG(sales), 2) AS monthly_sales_run_rate,
       ROUND(AVG(profit), 2) AS monthly_profit_run_rate,
       ROUND(AVG(profit) / NULLIF(AVG(sales), 0) * 100, 2) AS expected_margin_pct
FROM ranked WHERE recency_rank <= 3;

-- Rolling 3-month performance for trend visualization.
SELECT month, ROUND(sales, 2) AS sales, ROUND(profit, 2) AS profit,
       ROUND(AVG(sales) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS sales_3m_average,
       ROUND(AVG(profit) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS profit_3m_average
FROM (
    SELECT DATE_FORMAT(order_date, '%Y-%m-01') AS month,
           SUM(sales) AS sales, SUM(profit) AS profit
    FROM fact_order_line GROUP BY DATE_FORMAT(order_date, '%Y-%m-01')
) m ORDER BY month;

-- Tableau Public extract view: historical monthly actuals plus a 12-month base forecast.
-- Forecast uses the latest year's monthly Region x Category pattern, 6% sales growth,
-- and a 0.5 percentage-point improvement in profit margin.
CREATE OR REPLACE VIEW vw_tableau_forecast AS
WITH monthly_actual AS (
    SELECT CAST(DATE_FORMAT(f.order_date, '%Y-%m-01') AS DATE) AS month,
           g.region, p.category,
           SUM(f.sales) AS sales,
           SUM(f.profit) AS profit,
           SUM(f.profit) / NULLIF(SUM(f.sales), 0) AS profit_margin,
           YEAR(f.order_date) AS source_year
    FROM fact_order_line f
    JOIN dim_geography g USING (geography_key)
    JOIN dim_product p USING (product_key)
    GROUP BY month, g.region, p.category, source_year
), latest AS (
    SELECT MAX(source_year) AS latest_year FROM monthly_actual
)
SELECT month, 'Actual' AS result_type, region, category, sales, profit, profit_margin,
       source_year, NULL AS sales_growth_assumption,
       NULL AS margin_improvement_assumption, 'Source actual' AS forecast_method
FROM monthly_actual
UNION ALL
SELECT DATE_ADD(a.month, INTERVAL 1 YEAR), 'Forecast', a.region, a.category,
       a.sales * 1.06,
       (a.sales * 1.06) * (a.profit_margin + 0.005),
       a.profit_margin + 0.005,
       a.source_year, 0.06, 0.005,
       'Prior-year monthly actual; 6% sales growth; margin +0.5 percentage points'
FROM monthly_actual a
JOIN latest l ON a.source_year = l.latest_year;
