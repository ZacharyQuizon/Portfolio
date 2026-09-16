USE superstore_finance;

-- The budget is simulated and exists only for the latest actual year.
WITH actual AS (
    SELECT CAST(DATE_FORMAT(f.order_date, '%Y-%m-01') AS DATE) AS month,
           g.region, p.category, SUM(f.sales) AS actual_sales, SUM(f.profit) AS actual_profit
    FROM fact_order_line f
    JOIN dim_geography g USING (geography_key)
    JOIN dim_product p USING (product_key)
    GROUP BY month, g.region, p.category
), variance AS (
    SELECT b.budget_month, b.region, b.category,
           COALESCE(a.actual_sales, 0) AS actual_sales, b.budget_sales,
           COALESCE(a.actual_profit, 0) AS actual_profit, b.budget_profit
    FROM fact_budget b
    LEFT JOIN actual a ON a.month = b.budget_month AND a.region = b.region AND a.category = b.category
)
SELECT budget_month, region, category,
       ROUND(actual_sales, 2) AS actual_sales, budget_sales,
       ROUND(actual_sales - budget_sales, 2) AS sales_variance,
       ROUND((actual_sales - budget_sales) / NULLIF(budget_sales, 0) * 100, 2) AS sales_variance_pct,
       ROUND(actual_profit, 2) AS actual_profit, budget_profit,
       ROUND(actual_profit - budget_profit, 2) AS profit_variance,
       CASE WHEN actual_profit >= budget_profit THEN 'Favorable' ELSE 'Unfavorable' END AS profit_status
FROM variance ORDER BY budget_month, profit_variance;

-- Driver contribution: which regions explain the total profit variance?
WITH region_variance AS (
    SELECT g.region,
           SUM(f.profit) - (SELECT SUM(budget_profit) FROM fact_budget b WHERE b.region = g.region) AS profit_variance
    FROM fact_order_line f JOIN dim_geography g USING (geography_key)
    WHERE YEAR(f.order_date) = (SELECT YEAR(MAX(budget_month)) FROM fact_budget)
    GROUP BY g.region
)
SELECT region, ROUND(profit_variance, 2) AS profit_variance,
       ROUND(ABS(profit_variance) / NULLIF(SUM(ABS(profit_variance)) OVER (), 0) * 100, 2) AS share_of_absolute_variance_pct
FROM region_variance ORDER BY profit_variance;
