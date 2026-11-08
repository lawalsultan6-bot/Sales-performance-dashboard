/* =====================================================================
   TASK 2: EXPLORATORY DATA ANALYSIS (EDA) - SUPERSTORE DATASET
   Language : SQL (written in standard SQL; tested in SQLite)
   Table    : superstore (51,290 rows x 27 columns)

   HOW TO RUN
   1. Import superstore.csv into a table called  superstore
      (SQLite: DB Browser > File > Import > Table from CSV;
       MySQL / SQL Server / PostgreSQL: use the import wizard).
   2. Column names below use underscores and lower case
      (e.g. Order.Date -> order_date, Sub.Category -> sub_category,
       Customer.ID -> customer_id, "记录数" -> record_count).
      Rename the columns on import, or adjust the names in the queries.
   3. Dates are stored as text 'YYYY-MM-DD' (time part removed on import).
      SQLite date functions are used (julianday, strftime). Dialect notes are
      given in the comments where syntax differs (MySQL / SQL Server).
   ===================================================================== */


/* =====================================================================
   SECTION 1: MEANINGFUL QUESTIONS WE WANT TO ANSWER
   ---------------------------------------------------------------------
   Q1.  How big is the dataset and what does each column contain?
   Q2.  Is the data complete (nulls), unique (duplicates) and consistent?
   Q3.  How have Sales and Profit grown from 2011 to 2014?
   Q4.  Which Categories / Sub-Categories make or lose money?
   Q5.  Which Markets / Regions are the most and least profitable?
   Q6.  How does Discount affect Profit?
   Q7.  Which Customer Segment is most valuable?
   Q8.  Does Ship Mode change delivery time and shipping cost?
   Q9.  Is there seasonality across months / quarters?
   Q10. Who are the top customers and products?
   Q11. Hypotheses to test (see Section 5).
   Q12. What data problems must be fixed before further analysis?
   ===================================================================== */


/* =====================================================================
   SECTION 2: EXPLORE THE DATA STRUCTURE
   ===================================================================== */

-- 2.1 Row count
SELECT COUNT(*) AS total_rows FROM superstore;

-- 2.2 Column names and data types
--   SQLite:      PRAGMA table_info(superstore);
--   MySQL:       DESCRIBE superstore;
--   SQL Server:  EXEC sp_help 'superstore';
--   PostgreSQL:  SELECT column_name, data_type FROM information_schema.columns
--                WHERE table_name = 'superstore';
PRAGMA table_info(superstore);

-- 2.3 Preview the first 10 rows
SELECT * FROM superstore LIMIT 10;

-- 2.4 Date coverage
SELECT MIN(order_date) AS first_order,
       MAX(order_date) AS last_order,
       MIN(ship_date)  AS first_ship,
       MAX(ship_date)  AS last_ship
FROM superstore;

-- 2.5 Cardinality of key columns (how many distinct values each has)
SELECT COUNT(DISTINCT order_id)      AS orders,
       COUNT(DISTINCT customer_id)   AS customer_ids,
       COUNT(DISTINCT customer_name) AS customer_names,
       COUNT(DISTINCT product_id)    AS product_ids,
       COUNT(DISTINCT product_name)  AS product_names,
       COUNT(DISTINCT country)       AS countries,
       COUNT(DISTINCT state)         AS states,
       COUNT(DISTINCT city)          AS cities,
       COUNT(DISTINCT market)        AS markets,
       COUNT(DISTINCT region)        AS regions
FROM superstore;

-- 2.6 Categorical value lists
SELECT category, COUNT(*) AS rows_count FROM superstore GROUP BY category;
SELECT segment, COUNT(*) AS rows_count FROM superstore GROUP BY segment;
SELECT ship_mode, COUNT(*) AS rows_count FROM superstore GROUP BY ship_mode;
SELECT order_priority, COUNT(*) AS rows_count FROM superstore GROUP BY order_priority;
SELECT market, market2, COUNT(*) AS rows_count FROM superstore GROUP BY market, market2;

-- 2.7 Summary statistics of numeric columns
SELECT 'sales' AS column_name,
       MIN(sales) AS min_v, ROUND(AVG(sales),2) AS avg_v, MAX(sales) AS max_v, ROUND(SUM(sales),0) AS total
FROM superstore
UNION ALL
SELECT 'profit', ROUND(MIN(profit),2), ROUND(AVG(profit),2), ROUND(MAX(profit),2), ROUND(SUM(profit),0) FROM superstore
UNION ALL
SELECT 'quantity', MIN(quantity), ROUND(AVG(quantity),2), MAX(quantity), SUM(quantity) FROM superstore
UNION ALL
SELECT 'discount', MIN(discount), ROUND(AVG(discount),3), MAX(discount), NULL FROM superstore
UNION ALL
SELECT 'shipping_cost', MIN(shipping_cost), ROUND(AVG(shipping_cost),2), MAX(shipping_cost), ROUND(SUM(shipping_cost),0) FROM superstore;

-- 2.8 Headline KPIs
SELECT ROUND(SUM(sales),0)                          AS total_sales,
       ROUND(SUM(profit),0)                         AS total_profit,
       ROUND(100.0*SUM(profit)/SUM(sales),2)        AS profit_margin_pct,
       SUM(quantity)                                AS units_sold,
       COUNT(DISTINCT order_id)                     AS orders,
       ROUND(SUM(sales)/COUNT(DISTINCT order_id),2) AS avg_order_value
FROM superstore;


/* =====================================================================
   SECTION 3: DATA QUALITY CHECKS  (DETECT DATA ISSUES OR PROBLEMS)
   ===================================================================== */

-- 3.1 Null / empty check on every column (all should be 0)
SELECT
  SUM(CASE WHEN category        IS NULL OR category        = '' THEN 1 ELSE 0 END) AS null_category,
  SUM(CASE WHEN city            IS NULL OR city            = '' THEN 1 ELSE 0 END) AS null_city,
  SUM(CASE WHEN country         IS NULL OR country         = '' THEN 1 ELSE 0 END) AS null_country,
  SUM(CASE WHEN customer_id     IS NULL OR customer_id     = '' THEN 1 ELSE 0 END) AS null_customer_id,
  SUM(CASE WHEN customer_name   IS NULL OR customer_name   = '' THEN 1 ELSE 0 END) AS null_customer_name,
  SUM(CASE WHEN discount        IS NULL THEN 1 ELSE 0 END)                          AS null_discount,
  SUM(CASE WHEN order_date      IS NULL OR order_date      = '' THEN 1 ELSE 0 END) AS null_order_date,
  SUM(CASE WHEN order_id        IS NULL OR order_id        = '' THEN 1 ELSE 0 END) AS null_order_id,
  SUM(CASE WHEN product_id      IS NULL OR product_id      = '' THEN 1 ELSE 0 END) AS null_product_id,
  SUM(CASE WHEN profit          IS NULL THEN 1 ELSE 0 END)                          AS null_profit,
  SUM(CASE WHEN sales           IS NULL THEN 1 ELSE 0 END)                          AS null_sales,
  SUM(CASE WHEN ship_date       IS NULL OR ship_date       = '' THEN 1 ELSE 0 END) AS null_ship_date,
  SUM(CASE WHEN state           IS NULL OR state           = '' THEN 1 ELSE 0 END) AS null_state
FROM superstore;

-- 3.2 Duplicate rows (row_id must be unique)
SELECT COUNT(*) - COUNT(DISTINCT row_id) AS duplicate_row_ids FROM superstore;

-- 3.3 Fully duplicated records (same order + product + date + quantity + sales)
SELECT order_id, product_id, order_date, quantity, sales, COUNT(*) AS times_repeated
FROM superstore
GROUP BY order_id, product_id, order_date, quantity, sales
HAVING COUNT(*) > 1
ORDER BY times_repeated DESC
LIMIT 20;

-- 3.4 Logical date check: shipped before ordered (should be 0)
SELECT COUNT(*) AS ship_before_order
FROM superstore
WHERE ship_date < order_date;

-- 3.5 Year column consistent with Order.Date (should be 0)
SELECT COUNT(*) AS year_mismatch
FROM superstore
WHERE year <> CAST(SUBSTR(order_date,1,4) AS INTEGER);
--   MySQL: WHERE year <> YEAR(order_date)   | SQL Server: WHERE year <> YEAR(order_date)

-- 3.6 Constant / useless column: record_count (the "记录数" Tableau helper column)
SELECT record_count, COUNT(*) AS rows_count FROM superstore GROUP BY record_count;

-- 3.7 Redundant column: market vs market2 (market2 only merges US + Canada)
SELECT market, market2, COUNT(*) AS rows_count
FROM superstore GROUP BY market, market2 ORDER BY market;

-- 3.8 Customer ID problem: many IDs share one name
SELECT COUNT(DISTINCT customer_id)   AS distinct_ids,
       COUNT(DISTINCT customer_name) AS distinct_names
FROM superstore;

-- 3.8b Examples of one name that has many Customer IDs
SELECT customer_name, COUNT(DISTINCT customer_id) AS ids_per_name
FROM superstore
GROUP BY customer_name
ORDER BY ids_per_name DESC
LIMIT 10;

-- 3.9 Product ID problem: same Product.ID with more than one Product.Name
SELECT COUNT(*) AS product_ids_with_multiple_names
FROM (SELECT product_id
      FROM superstore
      GROUP BY product_id
      HAVING COUNT(DISTINCT product_name) > 1);

-- 3.10 Sales stored as whole numbers (rounded) - check tiny values
SELECT COUNT(*) AS rows_with_sales_lte_1 FROM superstore WHERE sales <= 1;

-- 3.11 Shipping cost larger than the sale value
SELECT COUNT(*) AS shipping_exceeds_sales FROM superstore WHERE shipping_cost > sales;

-- 3.12 Profit larger than sales (impossible unless negative cost)
SELECT COUNT(*) AS profit_exceeds_sales FROM superstore WHERE profit > sales;

-- 3.13 Outliers: IQR-free method using mean + 3 standard deviations on Sales
--      (SQLite has no STDDEV, so variance is computed manually)
WITH stats AS (
  SELECT AVG(sales) AS mu,
         SQRT(AVG(sales*sales) - AVG(sales)*AVG(sales)) AS sigma
  FROM superstore
)
SELECT COUNT(*) AS sales_outliers_over_3_sigma,
       ROUND(100.0*COUNT(*)/(SELECT COUNT(*) FROM superstore),2) AS pct_of_rows
FROM superstore, stats
WHERE sales > mu + 3*sigma;

-- 3.14 Top 10 largest single transactions (check for obvious errors)
SELECT order_id, product_name, sales, quantity, discount, profit
FROM superstore
ORDER BY sales DESC
LIMIT 10;

-- 3.15 Negative-profit rows
SELECT COUNT(*) AS loss_making_rows,
       ROUND(100.0*COUNT(*)/(SELECT COUNT(*) FROM superstore),2) AS pct_of_rows,
       ROUND(SUM(profit),0) AS total_loss
FROM superstore
WHERE profit < 0;

-- 3.16 Inconsistent geography: states whose Region differs between rows
SELECT country, state, COUNT(DISTINCT region) AS regions_for_state
FROM superstore
GROUP BY country, state
HAVING COUNT(DISTINCT region) > 1
LIMIT 20;


/* =====================================================================
   SECTION 4: TRENDS, PATTERNS AND ANOMALIES
   ===================================================================== */

-- 4.1 Yearly Sales / Profit / margin
SELECT year,
       ROUND(SUM(sales),0)                   AS sales,
       ROUND(SUM(profit),0)                  AS profit,
       ROUND(100.0*SUM(profit)/SUM(sales),2) AS margin_pct,
       COUNT(DISTINCT order_id)              AS orders
FROM superstore
GROUP BY year
ORDER BY year;

-- 4.2 Year-over-year growth
WITH y AS (
  SELECT year, SUM(sales) AS sales, SUM(profit) AS profit
  FROM superstore GROUP BY year
)
SELECT year,
       ROUND(sales,0)  AS sales,
       ROUND(100.0*(sales  - LAG(sales)  OVER (ORDER BY year)) / LAG(sales)  OVER (ORDER BY year),2) AS sales_growth_pct,
       ROUND(profit,0) AS profit,
       ROUND(100.0*(profit - LAG(profit) OVER (ORDER BY year)) / LAG(profit) OVER (ORDER BY year),2) AS profit_growth_pct
FROM y
ORDER BY year;

-- 4.3 Monthly trend (SQLite strftime; MySQL: DATE_FORMAT(order_date,'%Y-%m'); SQL Server: FORMAT(order_date,'yyyy-MM'))
SELECT STRFTIME('%Y-%m', order_date) AS year_month,
       ROUND(SUM(sales),0)  AS sales,
       ROUND(SUM(profit),0) AS profit
FROM superstore
GROUP BY year_month
ORDER BY year_month;

-- 4.4 Seasonality: average sales by calendar month across all years
SELECT STRFTIME('%m', order_date)  AS month_no,
       ROUND(SUM(sales),0)         AS total_sales,
       ROUND(AVG(sales),2)         AS avg_line_sales,
       COUNT(*)                    AS order_lines
FROM superstore
GROUP BY month_no
ORDER BY month_no;

-- 4.5 Quarterly share of annual sales
SELECT year,
       CASE WHEN CAST(STRFTIME('%m', order_date) AS INTEGER) BETWEEN 1 AND 3  THEN 'Q1'
            WHEN CAST(STRFTIME('%m', order_date) AS INTEGER) BETWEEN 4 AND 6  THEN 'Q2'
            WHEN CAST(STRFTIME('%m', order_date) AS INTEGER) BETWEEN 7 AND 9  THEN 'Q3'
            ELSE 'Q4' END AS quarter,
       ROUND(SUM(sales),0) AS sales,
       ROUND(SUM(profit),0) AS profit
FROM superstore
GROUP BY year, quarter
ORDER BY year, quarter;

-- 4.6 Category performance
SELECT category,
       ROUND(SUM(sales),0)                   AS sales,
       ROUND(SUM(profit),0)                  AS profit,
       ROUND(100.0*SUM(profit)/SUM(sales),2) AS margin_pct,
       ROUND(AVG(discount),3)                AS avg_discount
FROM superstore
GROUP BY category
ORDER BY profit DESC;

-- 4.7 Sub-Category performance (look for losers)
SELECT category, sub_category,
       ROUND(SUM(sales),0)                   AS sales,
       ROUND(SUM(profit),0)                  AS profit,
       ROUND(100.0*SUM(profit)/SUM(sales),2) AS margin_pct,
       ROUND(AVG(discount),3)                AS avg_discount
FROM superstore
GROUP BY category, sub_category
ORDER BY profit ASC;

-- 4.8 ANOMALY: Tables is the only Sub-Category that loses money. Why?
SELECT year,
       ROUND(SUM(sales),0)    AS sales,
       ROUND(SUM(profit),0)   AS profit,
       ROUND(AVG(discount),3) AS avg_discount
FROM superstore
WHERE sub_category = 'Tables'
GROUP BY year
ORDER BY year;

-- 4.9 Market performance
SELECT market,
       ROUND(SUM(sales),0)                   AS sales,
       ROUND(SUM(profit),0)                  AS profit,
       ROUND(100.0*SUM(profit)/SUM(sales),2) AS margin_pct,
       ROUND(AVG(shipping_cost),2)           AS avg_shipping_cost
FROM superstore
GROUP BY market
ORDER BY profit DESC;

-- 4.10 Region performance
SELECT market, region,
       ROUND(SUM(sales),0)                   AS sales,
       ROUND(SUM(profit),0)                  AS profit,
       ROUND(100.0*SUM(profit)/SUM(sales),2) AS margin_pct
FROM superstore
GROUP BY market, region
ORDER BY profit DESC;

-- 4.11 Top 10 and bottom 10 countries by profit
SELECT country, ROUND(SUM(sales),0) AS sales, ROUND(SUM(profit),0) AS profit
FROM superstore GROUP BY country ORDER BY profit DESC LIMIT 10;

SELECT country, ROUND(SUM(sales),0) AS sales, ROUND(SUM(profit),0) AS profit
FROM superstore GROUP BY country ORDER BY profit ASC LIMIT 10;

-- 4.12 Segment performance
SELECT segment,
       ROUND(SUM(sales),0)                   AS sales,
       ROUND(SUM(profit),0)                  AS profit,
       ROUND(100.0*SUM(profit)/SUM(sales),2) AS margin_pct,
       COUNT(DISTINCT order_id)              AS orders
FROM superstore
GROUP BY segment
ORDER BY profit DESC;

-- 4.13 Discount bands vs profit  (KEY INSIGHT)
SELECT CASE WHEN discount = 0    THEN '1) No discount'
            WHEN discount <= 0.2 THEN '2) 1% - 20%'
            WHEN discount <= 0.4 THEN '3) 21% - 40%'
            ELSE                      '4) Over 40%' END AS discount_band,
       COUNT(*)                              AS order_lines,
       ROUND(SUM(sales),0)                   AS sales,
       ROUND(SUM(profit),0)                  AS profit,
       ROUND(AVG(profit),2)                  AS avg_profit_per_line,
       ROUND(100.0*SUM(profit)/SUM(sales),2) AS margin_pct,
       ROUND(100.0*SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END)/COUNT(*),1) AS pct_lines_losing_money
FROM superstore
GROUP BY discount_band
ORDER BY discount_band;

-- 4.14 Shipping mode: delivery days and cost
SELECT ship_mode,
       ROUND(AVG(JULIANDAY(ship_date) - JULIANDAY(order_date)),2) AS avg_days_to_ship,
       ROUND(AVG(shipping_cost),2)                                AS avg_shipping_cost,
       COUNT(*)                                                   AS order_lines
FROM superstore
GROUP BY ship_mode
ORDER BY avg_days_to_ship;
--   MySQL: DATEDIFF(ship_date, order_date)  | SQL Server: DATEDIFF(day, order_date, ship_date)

-- 4.15 Order priority vs shipping cost
SELECT order_priority,
       COUNT(*)                    AS order_lines,
       ROUND(AVG(shipping_cost),2) AS avg_shipping_cost,
       ROUND(AVG(JULIANDAY(ship_date) - JULIANDAY(order_date)),2) AS avg_days_to_ship
FROM superstore
GROUP BY order_priority
ORDER BY avg_shipping_cost DESC;

-- 4.16 Top 10 customers by profit
SELECT customer_id, customer_name,
       COUNT(DISTINCT order_id) AS orders,
       ROUND(SUM(sales),0)      AS sales,
       ROUND(SUM(profit),0)     AS profit
FROM superstore
GROUP BY customer_id, customer_name
ORDER BY profit DESC
LIMIT 10;

-- 4.17 Top 10 products by sales
SELECT product_id, product_name,
       ROUND(SUM(sales),0)  AS sales,
       ROUND(SUM(profit),0) AS profit,
       SUM(quantity)        AS units
FROM superstore
GROUP BY product_id, product_name
ORDER BY sales DESC
LIMIT 10;

-- 4.18 Top 10 loss-making products
SELECT product_id, product_name,
       ROUND(SUM(sales),0)  AS sales,
       ROUND(SUM(profit),0) AS profit,
       ROUND(AVG(discount),3) AS avg_discount
FROM superstore
GROUP BY product_id, product_name
ORDER BY profit ASC
LIMIT 10;

-- 4.19 Customer concentration: how much of sales comes from the top 10% of customers?
WITH cust AS (
  SELECT customer_id, SUM(sales) AS sales
  FROM superstore GROUP BY customer_id
),
ranked AS (
  SELECT customer_id, sales,
         NTILE(10) OVER (ORDER BY sales DESC) AS decile
  FROM cust
)
SELECT decile,
       COUNT(*)                                                    AS customers,
       ROUND(SUM(sales),0)                                         AS sales,
       ROUND(100.0*SUM(sales)/(SELECT SUM(sales) FROM cust),2)     AS pct_of_total_sales
FROM ranked
GROUP BY decile
ORDER BY decile;


/* =====================================================================
   SECTION 5: TEST HYPOTHESES AND VALIDATE ASSUMPTIONS
   ===================================================================== */

/* ---------------------------------------------------------------------
   H1: Higher discounts reduce profit.
   Test: Pearson correlation between discount and profit margin per line.
   --------------------------------------------------------------------- */
WITH d AS (
  SELECT discount AS x, (profit*1.0/NULLIF(sales,0)) AS y
  FROM superstore
  WHERE sales > 0
),
s AS (
  SELECT COUNT(*) AS n,
         AVG(x) AS mx, AVG(y) AS my,
         AVG(x*y) AS mxy, AVG(x*x) AS mxx, AVG(y*y) AS myy
  FROM d
)
SELECT ROUND((mxy - mx*my) / (SQRT(mxx - mx*mx) * SQRT(myy - my*my)), 4)
       AS correlation_discount_vs_profit_margin
FROM s;
-- Reading: a clearly negative value (close to -1) supports H1.

-- H1 supporting evidence: profit flips from positive to negative as discount grows
SELECT ROUND(discount,2) AS discount_level,
       COUNT(*)              AS order_lines,
       ROUND(AVG(profit),2)  AS avg_profit
FROM superstore
GROUP BY ROUND(discount,2)
HAVING COUNT(*) >= 100
ORDER BY discount_level;

/* ---------------------------------------------------------------------
   H2: Discounting above 20% makes an order line lose money.
   --------------------------------------------------------------------- */
SELECT CASE WHEN discount > 0.2 THEN 'Over 20%' ELSE '20% or less' END AS discount_group,
       COUNT(*) AS order_lines,
       SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END) AS losing_lines,
       ROUND(100.0*SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END)/COUNT(*),2) AS pct_losing
FROM superstore
GROUP BY discount_group;

-- Check: do any lines with NO discount lose money? (tests whether discount is the driver)
SELECT COUNT(*) AS losing_lines_with_zero_discount
FROM superstore
WHERE discount = 0 AND profit < 0;

/* ---------------------------------------------------------------------
   H3: Tables loses money because of heavy discounting, not low demand.
   --------------------------------------------------------------------- */
SELECT CASE WHEN discount = 0    THEN 'No discount'
            WHEN discount <= 0.2 THEN '1-20%'
            WHEN discount <= 0.4 THEN '21-40%'
            ELSE 'Over 40%' END AS discount_band,
       COUNT(*)             AS order_lines,
       ROUND(SUM(sales),0)  AS sales,
       ROUND(SUM(profit),0) AS profit
FROM superstore
WHERE sub_category = 'Tables'
GROUP BY discount_band
ORDER BY discount_band;

/* ---------------------------------------------------------------------
   H4: The Technology category is the most profitable (by margin and total).
   (see 4.6 - Technology leads in both)
   --------------------------------------------------------------------- */
SELECT category,
       ROUND(100.0*SUM(profit)/SUM(sales),2) AS margin_pct,
       ROUND(SUM(profit),0)                  AS profit
FROM superstore GROUP BY category ORDER BY margin_pct DESC;

/* ---------------------------------------------------------------------
   H5: Faster shipping costs more.
   --------------------------------------------------------------------- */
SELECT ship_mode,
       ROUND(AVG(shipping_cost),2) AS avg_shipping_cost,
       ROUND(AVG(JULIANDAY(ship_date) - JULIANDAY(order_date)),2) AS avg_days
FROM superstore
GROUP BY ship_mode
ORDER BY avg_shipping_cost DESC;

/* ---------------------------------------------------------------------
   H6: Sales is growing every year (assumption of steady growth).
   --------------------------------------------------------------------- */
WITH y AS (SELECT year, SUM(sales) AS s FROM superstore GROUP BY year)
SELECT year, ROUND(s,0) AS sales,
       CASE WHEN s > LAG(s) OVER (ORDER BY year) THEN 'Growth'
            WHEN LAG(s) OVER (ORDER BY year) IS NULL THEN 'Base year'
            ELSE 'Decline' END AS vs_prior_year
FROM y ORDER BY year;

/* ---------------------------------------------------------------------
   H7: Profit margin is roughly the same across customer segments.
   --------------------------------------------------------------------- */
SELECT segment,
       ROUND(100.0*SUM(profit)/SUM(sales),2) AS margin_pct,
       ROUND(AVG(profit),2)                  AS avg_profit_per_line
FROM superstore
GROUP BY segment
ORDER BY margin_pct DESC;

/* ---------------------------------------------------------------------
   H8: EMEA is underperforming compared with other markets.
   --------------------------------------------------------------------- */
SELECT market,
       ROUND(100.0*SUM(profit)/SUM(sales),2) AS margin_pct,
       ROUND(AVG(discount),3)                AS avg_discount,
       ROUND(100.0*SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END)/COUNT(*),1) AS pct_lines_losing
FROM superstore
GROUP BY market
ORDER BY margin_pct;


/* =====================================================================
   SECTION 6: CLEAN VIEW FOR FURTHER ANALYSIS / POWER BI (TASK 3)
   Fixes the issues found in Section 3:
     - drops the constant helper column record_count
     - drops the redundant column market2
     - adds derived fields used in the dashboard
   ===================================================================== */
CREATE VIEW IF NOT EXISTS superstore_clean AS
SELECT row_id,
       order_id,
       order_date,
       ship_date,
       CAST(JULIANDAY(ship_date) - JULIANDAY(order_date) AS INTEGER) AS days_to_ship,
       year,
       CAST(STRFTIME('%m', order_date) AS INTEGER)                  AS month_no,
       STRFTIME('%Y-%m', order_date)                                AS year_month,
       weeknum,
       customer_id,
       customer_name,
       segment,
       market,
       region,
       country,
       state,
       city,
       category,
       sub_category,
       product_id,
       product_name,
       ship_mode,
       order_priority,
       sales,
       quantity,
       discount,
       profit,
       shipping_cost,
       CASE WHEN discount = 0    THEN 'No discount'
            WHEN discount <= 0.2 THEN '1-20%'
            WHEN discount <= 0.4 THEN '21-40%'
            ELSE 'Over 40%' END                                     AS discount_band,
       CASE WHEN profit < 0 THEN 'Loss' ELSE 'Profit' END           AS profit_flag
FROM superstore;

SELECT COUNT(*) AS rows_in_clean_view FROM superstore_clean;

/* ============================ END OF SCRIPT ============================ */
