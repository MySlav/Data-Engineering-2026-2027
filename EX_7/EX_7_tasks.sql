-- =====================================================================================
--  Data Engineering – Exercise 7: SQL basics – SELECT, WHERE, NULL, ORDER BY, GROUP BY, HAVING
--  Database: transactional (the online shop of the SQL pod)      Tool: pgAdmin → Query Tool
--  Week 7 videos: SQL Basics Part 1 (SELECT, WHERE, logical operators) · Part 2 (NULL, LIKE, IN, BETWEEN, ORDER BY)
--                 · Part 3 (aggregate functions, GROUP BY, HAVING, aliases)
-- =====================================================================================
--
--  HOW TO WORK
--   1. Run EX_7_prep.sql once (in database transactional) – it creates schema ex7 and the function ex7.check_task.
--   2. ▶️ EXAMPLE: select the statement with the mouse and press F5. Look at the result (or the error).
--      F5 without a selection runs the WHOLE script – don't do that here.
--   3. 🧩 TASK: write your query between $$ and $$.
--        – result only:  select ONLY your query (the lines between $$ and $$) → F5
--        – check:        select the WHOLE block from  SELECT ex7.check_task(  to  $$);  → F5
--      The check prints ✅ or explains what is wrong. Column names (AS) do not matter,
--      but the columns must be exactly those listed under "Columns", in that order.
--      The order of the rows matters only when the task asks for a sort.
--   4. ✏️ QUESTION: write the answer in a comment (a line that starts with --).
--   5. Save your work: disk icon (Save As) → EX_7_tasks_my_work.sql
--
--  If you get stuck, go on – the tasks do not depend on each other.
--  Nothing here changes the shop data: sections 0–6 and 8 only read; section 7 creates one small table in schema ex7.
--
--  TABLES (database transactional, schema public)            PK = primary key, FK = foreign key
--    category       (id_category PK, category_name)
--    product        (id_product PK, category_id FK, sku, product_name, price, active, created_at)
--    customer       (id_customer PK, first_name, last_name, email, phone, address, city, country, created_at, updated_at)
--    customer_order (id_customer_order PK, customer_id FK, order_date, status)
--                    status: created, paid, shipped, delivered, cancelled, returned
--    order_item     (id_order_item PK, customer_order_id FK, product_id FK, quantity, unit_price)
--    payment        (id_payment PK, customer_order_id FK, payment_date, payment_method, amount, status)
--                    payment_method: Credit Card, PayPal, Bank Transfer   status: success, failed, refunded
--    shipment       (id_shipment PK, customer_order_id FK, shipment_date, delivery_date, carrier, tracking_number, status)
--                    carrier: GLS, DPD, Hrvatska pošta, Overseas Express   status: in_transit, delivered, returned
--  All tables are related (FK → PK), but today every query reads ONE table – joining tables comes with SQL Advanced.
-- =====================================================================================



-- #####################################################################################
-- 0. Setup – connection and function ex7.check_task   (≈ 5 min)
-- #####################################################################################
--   • Database: transactional. EX_7_prep.sql (run once) creates schema ex7 and the function ex7.check_task.
--   • The shop tables live in schema public, so you write just  customer , not  public.customer .

-- ▶️ EXAMPLE 0.a  How many customers does our shop have?
SELECT count(*) AS customers
FROM customer;

-- ▶️ EXAMPLE 0.b  A first look at a table: all columns, only 10 rows (LIMIT – you know it from Exercise 6).
SELECT *
FROM customer
LIMIT 10;

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 0
--    Trial task: the solution is already written. Select the whole block (from SELECT ex7.check_task to $$);) and press F5.
--    If it says ✅, everything works.
--    Columns: customers
SELECT ex7.check_task('0', $$
SELECT count(*) AS customers
FROM customer
$$);


-- #####################################################################################
-- 1. SELECT, column aliases (AS) and DISTINCT   (≈ 7 min)
-- #####################################################################################
--   • SELECT columns FROM table;      * = all columns (fine for a look, not for real queries: name the columns you need)
--   • AS gives a column a new name in the result (an alias) – also for calculated columns
--   • DISTINCT removes repeated rows from the result

-- ▶️ EXAMPLE 1.a  Chosen columns, with aliases.
SELECT first_name AS name,
       last_name  AS surname,
       city
FROM customer;

-- ▶️ EXAMPLE 1.b  A calculated column needs an alias – otherwise PostgreSQL calls it ?column?.
SELECT product_name,
       price,
       round(price * 1.25, 2) AS price_with_vat
FROM product;

-- ▶️ EXAMPLE 1.c  In which countries do our customers live? Every country once. (Look closely at the result – we come back to it in 6.2.)
SELECT DISTINCT country
FROM customer;

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 1.1
--    Show the name and the price of all products. Name the result columns product and price_eur.
--    Columns: product, price_eur   (table product, columns product_name, price)
SELECT ex7.check_task('1.1', $$

    -- write your query here

$$);

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 1.2
--    Which payment methods appear in the table payment? Show each one once.
--    Columns: payment_method
SELECT ex7.check_task('1.2', $$

    -- write your query here

$$);

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 1.3
--    Which combinations of carrier and shipment status appear in the table shipment?
--    Columns: carrier, status
--    Tip: DISTINCT works on the whole row, i.e. on the combination of all selected columns.
SELECT ex7.check_task('1.3', $$

    -- write your query here

$$);


-- #####################################################################################
-- 2. WHERE, comparison operators, AND / OR / NOT   (≈ 11 min)
-- #####################################################################################
--   • WHERE condition – keeps only the rows for which the condition is true
--   • operators:  =   <> (or !=)   <   >   <=   >=       text and dates go in single quotes: 'Zagreb', '2026-11-13'
--   • text comparison is case-sensitive: 'Zagreb' <> 'zagreb'
--   • precedence: NOT first, then AND, then OR – use parentheses, also just to make the query readable

-- ▶️ EXAMPLE 2.a  Products that cost more than 1000 €.
SELECT product_name, price
FROM product
WHERE price > 1000;

-- ▶️ EXAMPLE 2.b  Customers from Croatia who live in Split or Rijeka – with parentheses (20 rows).
SELECT first_name, last_name, city, country
FROM customer
WHERE country = 'Croatia'
  AND (city = 'Split' OR city = 'Rijeka');

-- ▶️ EXAMPLE 2.c  The same without parentheses: AND is evaluated first, so this means (Croatia AND Split) OR Rijeka – 21 rows.
--    Find the extra row: its country is not 'Croatia'.
SELECT first_name, last_name, city, country
FROM customer
WHERE country = 'Croatia'
  AND city = 'Split' OR city = 'Rijeka';

-- ▶️ EXAMPLE 2.d  NOT turns a condition around. These two queries return the same rows.
SELECT id_customer_order, status FROM customer_order WHERE NOT status = 'delivered';
SELECT id_customer_order, status FROM customer_order WHERE status <> 'delivered';

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 2.1
--    Show the active products (active = true) that cost more than 500 €.
--    Columns: product_name, price
SELECT ex7.check_task('2.1', $$

    -- write your query here

$$);

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 2.2
--    Show the orders that were cancelled ('cancelled') or returned ('returned').
--    Columns: id_customer_order, order_date, status
SELECT ex7.check_task('2.2', $$

    -- write your query here

$$);

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 2.3
--    Show the payments made by 'PayPal' or by 'Bank Transfer' with an amount above 2000 €.
--    (The amount condition must hold for both methods.)
--    Columns: id_payment, payment_method, amount
SELECT ex7.check_task('2.3', $$

    -- write your query here

$$);
-- ✏️ QUESTION 2.3  Remove the parentheses from your 2.3 query and run it again. How many rows do you get now, and why?
-- Answer: 

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 2.4
--    Show the shipments that were NOT carried by 'GLS' and whose status is not 'delivered'.
--    Columns: id_shipment, carrier, status
SELECT ex7.check_task('2.4', $$

    -- write your query here

$$);


-- #####################################################################################
-- 3. NULL, LIKE, IN and BETWEEN   (≈ 14 min)
-- #####################################################################################
--   • NULL = no value (unknown). Test it with IS NULL / IS NOT NULL – never with = NULL or <> NULL
--   • LIKE: % = any number of characters (also none), _ = exactly one character.   NOT LIKE = the opposite
--     PostgreSQL only: ILIKE = LIKE that ignores upper/lower case
--   • IN (a, b, c) = short for several OR conditions; the list can also come from a subquery: IN (SELECT …)
--   • BETWEEN a AND b includes both ends (numbers, text, dates)

-- ▶️ EXAMPLE 3.a  Customers without an e-mail address (they ordered by phone).
SELECT first_name, last_name, phone
FROM customer
WHERE email IS NULL;

-- ▶️ EXAMPLE 3.b  The trap: = NULL is never true. 0 rows and NO error – the worst kind of mistake.
SELECT first_name, last_name, phone
FROM customer
WHERE email = NULL;

-- ▶️ EXAMPLE 3.c  LIKE with %: all Apple products.   LIKE with _: surnames whose second letter is 'a'.
SELECT product_name, price FROM product WHERE product_name LIKE 'Apple%';
SELECT first_name, last_name FROM customer WHERE last_name LIKE '_a%';

-- ▶️ EXAMPLE 3.d  LIKE is case-sensitive, ILIKE is not. Compare the two numbers.
SELECT count(*) FROM customer WHERE city LIKE 'zagreb';
SELECT count(*) FROM customer WHERE city ILIKE 'zagreb';

-- ▶️ EXAMPLE 3.e  IN with a list: customers from Split, Rijeka or Zadar.
SELECT first_name, last_name, city
FROM customer
WHERE city IN ('Split', 'Rijeka', 'Zadar');

-- ▶️ EXAMPLE 3.f  IN with a subquery: customers who have at least one returned order.
--    The inner SELECT runs first and returns a list of customer ids. Run it alone to see the list.
SELECT first_name, last_name
FROM customer
WHERE id_customer IN (SELECT customer_id
                      FROM customer_order
                      WHERE status = 'returned');

-- ▶️ EXAMPLE 3.g  BETWEEN with numbers: products from 100 to 150 € (both ends included).
SELECT product_name, price
FROM product
WHERE price BETWEEN 100 AND 150;

-- ▶️ EXAMPLE 3.h  BETWEEN with dates – a trap when the column also has a time (order_date is a timestamp):
--    '2024-09-30' means 2024-09-30 00:00, so the orders made during 30 September are lost (17 instead of 19).
--    For a whole month use  >= first day  AND  < first day of the next month.
SELECT count(*) FROM customer_order WHERE order_date BETWEEN '2024-09-01' AND '2024-09-30';
SELECT count(*) FROM customer_order WHERE order_date >= '2024-09-01' AND order_date < '2024-10-01';

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 3.1
--    Show the customers who have no phone number.
--    Columns: first_name, last_name, email
SELECT ex7.check_task('3.1', $$

    -- write your query here

$$);

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 3.2
--    Show the shipments that are not delivered yet (they have no delivery date – delivery_date).
--    Columns: id_shipment, customer_order_id, carrier, shipment_date
SELECT ex7.check_task('3.2', $$

    -- write your query here

$$);

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 3.3
--    Show the customers whose e-mail address ends with @gmail.com.
--    Columns: first_name, last_name, email
SELECT ex7.check_task('3.3', $$

    -- write your query here

$$);
-- ✏️ QUESTION 3.3  The customers without an e-mail are in neither  email LIKE '%@gmail.com'  nor  email NOT LIKE '%@gmail.com' . Why?
-- Answer: 

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 3.4
--    Show the customers from Ljubljana, Graz or München. Use IN.
--    Columns: first_name, last_name, city
SELECT ex7.check_task('3.4', $$

    -- write your query here

$$);
-- ✏️ QUESTION 3.4  Run  SELECT city FROM customer WHERE city ILIKE '%münchen%';  Did 3.4 find all customers from München? Why not?
-- Answer: 

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 3.5
--    Show the orders of January 2026 (the whole month).
--    Columns: id_customer_order, order_date
--    Tip: order_date has a time part – see the last example above.
SELECT ex7.check_task('3.5', $$

    -- write your query here

$$);

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 3.6
--    Show the orders that have at least one failed payment (payment.status = 'failed'). Use IN with a subquery.
--    Columns: id_customer_order, status
SELECT ex7.check_task('3.6', $$

    -- write your query here

$$);


-- #####################################################################################
-- 4. ORDER BY and LIMIT   (≈ 10 min)
-- #####################################################################################
--   • ORDER BY column [ASC | DESC]   – ASC (smallest first) is the default
--   • several columns: ORDER BY country, city DESC   – the second column decides only inside equal values of the first
--   • without ORDER BY the order of the rows is NOT guaranteed – never rely on it
--   • LIMIT n = only the first n rows (PostgreSQL; standard SQL: FETCH FIRST n ROWS ONLY) – it only makes sense with ORDER BY

-- ▶️ EXAMPLE 4.a  The three most expensive products.
SELECT product_name, price
FROM product
ORDER BY price DESC
LIMIT 3;

-- ▶️ EXAMPLE 4.b  Two sort columns with different directions: countries A→Z, inside a country the newest customers first.
SELECT country, created_at, first_name, last_name
FROM customer
ORDER BY country, created_at DESC;

-- ▶️ EXAMPLE 4.c  Where do NULLs go? In PostgreSQL NULL counts as the LARGEST value: last with ASC, first with DESC (NULLS LAST / NULLS FIRST changes it).
SELECT first_name, last_name, phone
FROM customer
ORDER BY phone DESC
LIMIT 15;

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 4.1
--    Show all products whose name starts with Samsung, the most expensive first.
--    Columns: product_name, price
SELECT ex7.check_task('4.1', $$

    -- write your query here

$$);

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 4.2
--    Show the five cheapest products, the cheapest first.
--    Columns: product_name, price
SELECT ex7.check_task('4.2', $$

    -- write your query here

$$);

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 4.3
--    Show the customers from Slovenia, Austria and Germany, sorted by country (A→Z),
--    and inside a country by last name from Z to A.
--    Columns: country, last_name, first_name
SELECT ex7.check_task('4.3', $$

    -- write your query here

$$);

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 4.4
--    Exam-style: everything so far in one query, on a RAW table. raw.customer_signup holds sign-ups exactly as they arrived
--    from CSV files (all text; look at it first:  SELECT * FROM raw.customer_signup LIMIT 20; ).
--    Show each combination of full_name and email only once, for the sign-ups from Croatia – written as
--    'HR', 'Hrvatska', 'CRO' or 'Croatia' – whose e-mail contains the character @, sorted by full_name.
--    Columns: full_name, email
SELECT ex7.check_task('4.4', $$

    -- write your query here

$$);
-- ✏️ QUESTION 4.4  This query could be a step from the raw (Bronze) to the cleaned (Silver) layer. Which data problems does it handle, and name one it does NOT solve.
-- Answer: 


-- #####################################################################################
-- 5. Aggregate functions and nested functions   (≈ 9 min)
-- #####################################################################################
--   • COUNT, SUM, AVG, MIN, MAX – turn many rows into one value
--   • COUNT(*) counts rows, COUNT(column) counts only the rows where the column is NOT NULL, COUNT(DISTINCT column) counts different values
--   • SUM, AVG, MIN, MAX ignore NULLs as well
--   • functions can be nested: round(avg(price), 2), max(length(product_name)) – the inner one runs first

-- ▶️ EXAMPLE 5.a  Number of products, the lowest, the highest and the average price.
SELECT count(*)             AS products,
       min(price)           AS lowest,
       max(price)           AS highest,
       avg(price)           AS average,
       round(avg(price), 2) AS average_rounded
FROM product;

-- ▶️ EXAMPLE 5.b  Three kinds of COUNT – a quick completeness report of a table (remember the missing values of Week 5).
SELECT count(*)                AS all_rows,
       count(email)            AS with_email,
       count(phone)            AS with_phone,
       count(DISTINCT country) AS different_countries
FROM customer;

-- ▶️ EXAMPLE 5.c  Nested functions: the length of the longest surname. length() runs for every row, max() takes the largest result.
SELECT max(length(last_name)) AS longest_surname
FROM customer;

-- ▶️ EXAMPLE 5.d  MIN and MAX also work on dates and text.
SELECT min(order_date) AS first_order, max(order_date) AS last_order FROM customer_order;
SELECT min(last_name) AS first_surname, max(last_name) AS last_surname FROM customer;

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 5.1
--    How many customers have an e-mail address? The result is one number.
--    Columns: customers_with_email
--    Tip: Compare count(*) and count(email).
SELECT ex7.check_task('5.1', $$

    -- write your query here

$$);

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 5.2
--    For the successful payments (status = 'success'): how many there are, their total amount
--    and the average amount rounded to 2 decimals.
--    Columns: payments, total, average
SELECT ex7.check_task('5.2', $$

    -- write your query here

$$);

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 5.3
--    How many characters does the longest product name have? The result is one number.
--    Columns: longest_name
SELECT ex7.check_task('5.3', $$

    -- write your query here

$$);

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 5.4
--    How many DIFFERENT customers have ordered at least once? The result is one number.
--    Columns: customers_with_orders
SELECT ex7.check_task('5.4', $$

    -- write your query here

$$);
-- ✏️ QUESTION 5.4  The shop has 104 customers. What does the difference tell you?
-- Answer: 


-- #####################################################################################
-- 6. GROUP BY, HAVING and table aliases   (≈ 19 min)
-- #####################################################################################
--   • GROUP BY – one group = one row of the result; SELECT may contain only the GROUP BY columns and aggregates
--   • WHERE filters ROWS before grouping, HAVING filters GROUPS after grouping (so only HAVING can use count(*), sum(…) …)
--   • order of writing:  SELECT … FROM … WHERE … GROUP BY … HAVING … ORDER BY … LIMIT …
--   • order of execution: FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT
--   • table alias: FROM customer_order AS o  → o.status   (short names; necessary once a query joins several tables – SQL Advanced)

-- ▶️ EXAMPLE 6.a  Number of orders per status.
SELECT status,
       count(*) AS orders
FROM customer_order
GROUP BY status
ORDER BY orders DESC;

-- ▶️ EXAMPLE 6.b  WHERE, GROUP BY and HAVING in one query: carriers with more than 100 DELIVERED shipments.
SELECT carrier,
       count(*) AS shipments
FROM shipment
WHERE status = 'delivered'     -- 1. filters ROWS
GROUP BY carrier               -- 2. groups
HAVING count(*) > 100          -- 3. filters GROUPS
ORDER BY shipments DESC;

-- ▶️ EXAMPLE 6.c  Why not WHERE count(*) > 100? Run it and read the error.
SELECT carrier, count(*) AS shipments
FROM shipment
WHERE count(*) > 100
GROUP BY carrier;

-- ▶️ EXAMPLE 6.d  Table alias: p stands for payment. Average payment per method, with a nested function.
SELECT p.payment_method,
       round(avg(p.amount), 2) AS average_amount
FROM payment AS p
WHERE p.status = 'success'
GROUP BY p.payment_method;

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 6.1
--    For the successful payments (status = 'success') show per payment method the number of payments and the total amount.
--    Columns: payment_method, payments, total
SELECT ex7.check_task('6.1', $$

    -- write your query here

$$);

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 6.2
--    How many customers do we have in each country? The country with the most customers first;
--    if two countries have the same number, sort them by name.
--    Columns: country, customers
SELECT ex7.check_task('6.2', $$

    -- write your query here

$$);
-- ✏️ QUESTION 6.2  Look at the country names. What is wrong with the data, which data quality dimension (Week 4) is it, and what would it do to a report "customers per country"?
-- Answer: 

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 6.3
--    Show the customers (customer_id) who have more than 10 orders, and how many orders each of them has.
--    Columns: customer_id, orders
SELECT ex7.check_task('6.3', $$

    -- write your query here

$$);

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 6.4
--    How many orders were there in each year? Sort by year.
--    Columns: year, orders
--    Tip: EXTRACT(YEAR FROM order_date) returns the year; put the same expression into GROUP BY.
SELECT ex7.check_task('6.4', $$

    -- write your query here

$$);

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 6.5
--    Look only at the order lines with a quantity of 2 or more (table order_item). For each product (product_id)
--    show the total quantity on those lines – but only the products whose total is above 100, the highest total first.
--    Columns: product_id, total_quantity
--    Tip: One condition is about rows (WHERE), the other one about groups (HAVING). This is the full chain: WHERE → GROUP BY → HAVING → ORDER BY.
SELECT ex7.check_task('6.5', $$

    -- write your query here

$$);

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 6.6
--    Data quality – possible duplicates: which combinations of first name and last name appear more than once
--    in the table customer, and how many times?
--    Columns: first_name, last_name, times
SELECT ex7.check_task('6.6', $$

    -- write your query here

$$);
-- ✏️ QUESTION 6.6  Which data quality dimension does this query check? Is it the same person twice – which other columns would you look at before deleting a row?
-- Answer: 

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 6.7
--    Exam-style, on the raw table: find the sign-ups that were loaded more than once, i.e. the combinations of
--    full_name, email and signup_date that occur in more than one row of raw.customer_signup, and how many times.
--    Columns: full_name, email, signup_date, times
SELECT ex7.check_task('6.7', $$

    -- write your query here

$$);
-- ✏️ QUESTION 6.7  What has to happen with these rows before the data moves on to the cleaned (Silver) layer? And the same GROUP BY on country alone (like 6.2) – what would it show here?
-- Answer: 


-- #####################################################################################
-- 7. Warm-up for the Week 7 assignment: your own table   (≈ 5 min)
-- #####################################################################################
--   • In the assignment you write queries on a student table that you create yourself. The steps are always the same:
--   • CREATE TABLE (choose the types – Exercise 6) → INSERT a few rows → SELECT.
--   • The example uses made-up temperature sensors; all its tables go into schema ex7.

-- ▶️ EXAMPLE 7.a  Create a table and insert rows. One INSERT can carry many rows. A value we don't know is NULL (without quotes).
--    Select all three statements together → F5. (DROP TABLE IF EXISTS lets you run it again.)
DROP TABLE IF EXISTS ex7.sensor;
CREATE TABLE ex7.sensor (
    id_sensor     integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sensor_name   varchar(30)  NOT NULL,
    location      varchar(30)  NOT NULL,
    installed_on  date         NOT NULL,
    last_reading  numeric(4,1)                 -- °C, NULL = the sensor has not sent anything yet
);
INSERT INTO ex7.sensor (sensor_name, location, installed_on, last_reading) VALUES
    ('T-101', 'Server room', '2019-03-14', 21.5),
    ('T-102', 'Server room', '2021-11-02', 22.1),
    ('T-103', 'Server room', '2024-06-20', NULL),
    ('T-201', 'Warehouse',   '2018-01-09', 14.8),
    ('T-202', 'Warehouse',   '2023-09-30', 15.2),
    ('T-301', 'Office',      '2022-05-17', 23.4),
    ('A-001', 'Roof',        '2020-08-25', 7.9);

-- ▶️ EXAMPLE 7.b  A value that can be calculated should not be stored: the age of a sensor changes every day, the installation date never.
--    age(date) returns the time passed until today; EXTRACT(YEAR FROM …) takes the full years.
SELECT sensor_name,
       installed_on,
       age(installed_on)                    AS exact_age,
       EXTRACT(YEAR FROM age(installed_on)) AS years_in_use
FROM ex7.sensor
ORDER BY installed_on;

-- ▶️ EXAMPLE 7.c  The whole chain on your own table: locations with at least two sensors that have a reading.
SELECT location,
       count(*)                    AS sensors,
       round(avg(last_reading), 1) AS average_temperature
FROM ex7.sensor
WHERE last_reading IS NOT NULL
GROUP BY location
HAVING count(*) >= 2
ORDER BY location;

-- TIPS FOR THE WEEK 7 ASSIGNMENT (student table)
--   • Create the table yourself (in schema ex7 or in your own schema) and insert enough rows that every query returns
--     something AND leaves something out: students younger and older than 21, names that start with 'A' and names that
--     don't, departments with one student and departments with several.
--   • Choose the types on purpose: what is the right type for a date of birth? For an average grade like 4.25?
--   • "Older than 21": is a student who is exactly 21 included? Decide and say so in a comment.
--   • The table has both an age and a date of birth. Look at the second example above – what can go wrong when both are stored?
--     You may point it out in a comment (and show the query that finds rows where the two don't agree).
--   • "Count students per department using GROUP BY and HAVING": HAVING needs a condition – choose a sensible one
--     (e.g. only departments with at least a certain number of students) and write in a comment what it does.
--   • LIKE is case-sensitive: 'A%' does not find 'ana'.
--   • Submit the CREATE TABLE, the INSERT and the queries in one .sql file that runs from top to bottom without errors.


-- #####################################################################################
-- 8. ⭐ Optional tasks (for the fast ones, or at home)
-- #####################################################################################
--   • They combine everything from sections 1–6 and add a few text functions. The check works the same way.

-- ▶️ EXAMPLE 8.a  Text functions for cleaning: trim removes spaces at both ends, lower / upper / initcap change the case.
SELECT city                AS original,
       length(city)        AS characters,
       initcap(trim(city)) AS cleaned
FROM customer
WHERE city <> initcap(trim(city));

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 8.1
--    ⭐ Number of customers per city AFTER cleaning the city name: remove the spaces at both ends (trim) and unify
--    the case (initcap). The city with the most customers first; if the number is equal, sort by city.
--    Columns: city, customers
SELECT ex7.check_task('8.1', $$

    -- write your query here

$$);
-- ✏️ QUESTION 8.1  Compare with  SELECT city, count(*) FROM customer GROUP BY city;  How many rows disappeared, and why?
-- Answer: 

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 8.2
--    ⭐ How many customers are REALLY from Croatia? The country is written in several ways (see 6.2) –
--    count them all. The result is one number.
--    Columns: customers_from_croatia
--    Tip: lower(country) IN (…) saves you from listing every upper/lower-case variant.
SELECT ex7.check_task('8.2', $$

    -- write your query here

$$);

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 8.3
--    ⭐ The same person can hide behind different spellings: in raw.customer_signup, which e-mail addresses appear
--    more than once when you compare them in lower case, and how many times? Ignore the rows without an e-mail.
--    Columns: email, times
SELECT ex7.check_task('8.3', $$

    -- write your query here

$$);

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 8.4
--    ⭐ The three months with the most orders: the month as text in the form 2025-12, and the number of orders.
--    The busiest month first.
--    Columns: month, orders
--    Tip: to_char(order_date, 'YYYY-MM') turns a date into text like 2025-12.
SELECT ex7.check_task('8.4', $$

    -- write your query here

$$);
-- ✏️ QUESTION 8.4  Which months are on top, and what could be the reason?
-- Answer: 

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 8.5
--    ⭐ A subquery that returns ONE value can stand in a comparison: show the products that cost more than
--    the average price of all products, the most expensive first.
--    Columns: product_name, price
--    Tip: WHERE price > (SELECT avg(price) FROM product)
SELECT ex7.check_task('8.5', $$

    -- write your query here

$$);


-- The end. Save your work (Save) and close the Query Tool.
-- To clean up after this exercise:  DROP SCHEMA ex7 CASCADE;   (the shop data in schema public stays)
