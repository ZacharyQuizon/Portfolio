USE superstore_finance;

-- Executive annual KPIs with YoY growth and margin.
WITH annual AS (
    SELECT YEAR(order_date) AS fiscal_year,
           SUM(sales) AS sales,
           SUM(profit) AS profit,
           COUNT(DISTINCT order_id) AS orders
    FROM fact_order_line GROUP BY YEAR(order_date)
)
SELECT fiscal_year, ROUND(sales, 2) AS sales, ROUND(profit, 2) AS profit,
       ROUND(profit / NULLIF(sales, 0) * 100, 2) AS profit_margin_pct,
       orders,
       ROUND((sales / NULLIF(LAG(sales) OVER (ORDER BY fiscal_year), 0) - 1) * 100, 2) AS sales_yoy_pct,
       ROUND((profit / NULLIF(LAG(profit) OVER (ORDER BY fiscal_year), 0) - 1) * 100, 2) AS profit_yoy_pct
FROM annual ORDER BY fiscal_year;

-- Rank region/category combinations and expose loss-making areas.
WITH profitability AS (
    SELECT YEAR(f.order_date) AS fiscal_year, g.region, p.category,
           SUM(f.sales) AS sales, SUM(f.profit) AS profit
    FROM fact_order_line f
    JOIN dim_geography g USING (geography_key)
    JOIN dim_product p USING (product_key)
    GROUP BY YEAR(f.order_date), g.region, p.category
)
SELECT *, ROUND(profit / NULLIF(sales, 0) * 100, 2) AS margin_pct,
       DENSE_RANK() OVER (PARTITION BY fiscal_year ORDER BY profit DESC) AS profit_rank
FROM profitability ORDER BY fiscal_year DESC, profit_rank;

-- Discount bands reveal whether sales growth is being bought unprofitably.
SELECT CASE
         WHEN discount = 0 THEN '0%'
         WHEN discount <= .10 THEN '1-10%'
         WHEN discount <= .20 THEN '11-20%'
         WHEN discount <= .30 THEN '21-30%'
         WHEN discount <= .50 THEN '31-50%'
         ELSE 'Over 50%'
       END AS discount_band,
       ROUND(SUM(sales), 2) AS sales,
       ROUND(SUM(profit), 2) AS profit,
       ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2) AS margin_pct
FROM fact_order_line
WHERE YEAR(order_date) = (SELECT MAX(YEAR(order_date)) FROM fact_order_line)
GROUP BY discount_band ORDER BY MIN(discount);

