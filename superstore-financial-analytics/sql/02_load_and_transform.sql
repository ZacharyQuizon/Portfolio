USE superstore_finance;

-- Refresh only this project's tables so the script can be rerun without
-- appending duplicate records. The database itself is not dropped.
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE fact_order_line;
TRUNCATE TABLE fact_return;
TRUNCATE TABLE fact_budget;
TRUNCATE TABLE dim_customer;
TRUNCATE TABLE dim_product;
TRUNCATE TABLE dim_geography;
TRUNCATE TABLE stg_orders;
TRUNCATE TABLE stg_people;
TRUNCATE TABLE stg_returns;
SET FOREIGN_KEY_CHECKS = 1;

-- Before running, replace C:/path/to/ with the absolute location of this
-- repository. Use forward slashes. LOAD DATA requires literal file paths,
-- so these statements cannot use a prepared statement or a path variable.

LOAD DATA LOCAL INFILE
'C:/path/to/superstore-financial-analytics/data/orders.csv'
INTO TABLE stg_orders
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(row_id, order_id, order_date, ship_date, ship_mode, customer_id,
 customer_name, segment, country_region, city, state_province, postal_code,
 region, product_id, category, sub_category, product_name, sales, quantity,
 discount, @profit)
SET profit = CAST(TRIM(TRAILING '\r' FROM @profit) AS DECIMAL(14,4));

LOAD DATA LOCAL INFILE
'C:/path/to/superstore-financial-analytics/data/people.csv'
INTO TABLE stg_people
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(regional_manager, @region)
SET region = TRIM(TRAILING '\r' FROM @region);

LOAD DATA LOCAL INFILE
'C:/path/to/superstore-financial-analytics/data/returns.csv'
INTO TABLE stg_returns
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(order_id, @returned)
SET returned = TRIM(TRAILING '\r' FROM @returned);

LOAD DATA LOCAL INFILE
'C:/path/to/superstore-financial-analytics/data/simulated_budget.csv'
INTO TABLE fact_budget
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(budget_month, region, category, budget_sales, budget_profit, @budget_method)
SET budget_method = TRIM(TRAILING '\r' FROM @budget_method);

START TRANSACTION;

INSERT INTO dim_customer (customer_id, customer_name, segment)
SELECT customer_id, MAX(customer_name), MAX(segment)
FROM stg_orders
GROUP BY customer_id;

INSERT INTO dim_product (product_id, category, sub_category, product_name)
SELECT product_id, MAX(category), MAX(sub_category), MAX(product_name)
FROM stg_orders
GROUP BY product_id;

INSERT INTO dim_geography
    (country_region, city, state_province, postal_code, region)
SELECT DISTINCT country_region, city, state_province,
       COALESCE(postal_code, ''), region
FROM stg_orders;

INSERT INTO fact_order_line
    (row_id, order_id, order_date, ship_date, ship_mode, customer_key,
     product_key, geography_key, sales, quantity, discount, profit)
SELECT o.row_id, o.order_id, o.order_date, o.ship_date, o.ship_mode,
       c.customer_key, p.product_key, g.geography_key,
       o.sales, o.quantity, o.discount, o.profit
FROM stg_orders o
JOIN dim_customer c ON c.customer_id = o.customer_id
JOIN dim_product p ON p.product_id = o.product_id
JOIN dim_geography g
  ON g.country_region = o.country_region
 AND g.city = o.city
 AND g.state_province = o.state_province
 AND g.postal_code = COALESCE(o.postal_code, '')
 AND g.region = o.region;

INSERT INTO fact_return (order_id, returned)
SELECT order_id, TRUE
FROM stg_returns
WHERE UPPER(TRIM(returned)) = 'YES';

COMMIT;
