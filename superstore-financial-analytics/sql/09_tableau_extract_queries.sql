USE superstore_finance;

-- Tableau Public cannot connect directly to this local MySQL database.
-- Run each query in MySQL Workbench, then export the result grid as CSV.

-- Export as tableau_order_lines.csv
SELECT * FROM vw_tableau_order_lines ORDER BY row_id;

-- Export as tableau_budget_variance.csv
SELECT * FROM vw_tableau_budget_variance ORDER BY budget_month, region, category;

-- Export as tableau_forecast.csv
SELECT * FROM vw_tableau_forecast ORDER BY month, result_type, region, category;
