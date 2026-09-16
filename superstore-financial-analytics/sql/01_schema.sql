USE superstore_finance;

CREATE TABLE IF NOT EXISTS stg_orders (
    row_id INT PRIMARY KEY,
    order_id VARCHAR(20) NOT NULL,
    order_date DATE NOT NULL,
    ship_date DATE NOT NULL,
    ship_mode VARCHAR(30),
    customer_id VARCHAR(20),
    customer_name VARCHAR(100),
    segment VARCHAR(30),
    country_region VARCHAR(50),
    city VARCHAR(80),
    state_province VARCHAR(80),
    postal_code VARCHAR(15),
    region VARCHAR(20),
    product_id VARCHAR(30),
    category VARCHAR(40),
    sub_category VARCHAR(40),
    product_name VARCHAR(255),
    sales DECIMAL(14,4),
    quantity INT,
    discount DECIMAL(8,4),
    profit DECIMAL(14,4)
);

CREATE TABLE IF NOT EXISTS stg_people (
    regional_manager VARCHAR(100),
    region VARCHAR(20) PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS stg_returns (
    order_id VARCHAR(20) PRIMARY KEY,
    returned VARCHAR(10)
);

CREATE TABLE IF NOT EXISTS dim_customer (
    customer_key INT AUTO_INCREMENT PRIMARY KEY,
    customer_id VARCHAR(20) NOT NULL UNIQUE,
    customer_name VARCHAR(100) NOT NULL,
    segment VARCHAR(30) NOT NULL
);

CREATE TABLE IF NOT EXISTS dim_product (
    product_key INT AUTO_INCREMENT PRIMARY KEY,
    product_id VARCHAR(30) NOT NULL UNIQUE,
    category VARCHAR(40) NOT NULL,
    sub_category VARCHAR(40) NOT NULL,
    product_name VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS dim_geography (
    geography_key INT AUTO_INCREMENT PRIMARY KEY,
    country_region VARCHAR(50) NOT NULL,
    city VARCHAR(80) NOT NULL,
    state_province VARCHAR(80) NOT NULL,
    postal_code VARCHAR(15),
    region VARCHAR(20) NOT NULL,
    UNIQUE KEY uq_geography (country_region, city, state_province, postal_code, region)
);

CREATE TABLE IF NOT EXISTS fact_order_line (
    row_id INT PRIMARY KEY,
    order_id VARCHAR(20) NOT NULL,
    order_date DATE NOT NULL,
    ship_date DATE NOT NULL,
    ship_mode VARCHAR(30),
    customer_key INT NOT NULL,
    product_key INT NOT NULL,
    geography_key INT NOT NULL,
    sales DECIMAL(14,4) NOT NULL,
    quantity INT NOT NULL,
    discount DECIMAL(8,4) NOT NULL,
    profit DECIMAL(14,4) NOT NULL,
    INDEX ix_order_date (order_date),
    INDEX ix_order_id (order_id),
    INDEX ix_product (product_key),
    INDEX ix_geography (geography_key),
    CONSTRAINT fk_order_customer FOREIGN KEY (customer_key) REFERENCES dim_customer(customer_key),
    CONSTRAINT fk_order_product FOREIGN KEY (product_key) REFERENCES dim_product(product_key),
    CONSTRAINT fk_order_geography FOREIGN KEY (geography_key) REFERENCES dim_geography(geography_key)
);

CREATE TABLE IF NOT EXISTS fact_return (
    order_id VARCHAR(20) PRIMARY KEY,
    returned BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS fact_budget (
    budget_month DATE NOT NULL,
    region VARCHAR(20) NOT NULL,
    category VARCHAR(40) NOT NULL,
    budget_sales DECIMAL(14,2) NOT NULL,
    budget_profit DECIMAL(14,2) NOT NULL,
    budget_method VARCHAR(255) NOT NULL,
    PRIMARY KEY (budget_month, region, category)
);
