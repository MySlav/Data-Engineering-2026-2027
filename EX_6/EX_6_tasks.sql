-- =====================================================================================
--  Data Engineering – Exercise 6: Data types, loading data, outliers, transactions and indexes
--  Database: transactional, schema ex6        Tool: pgAdmin → Query Tool
--  Week 6 videos: Outliers · OLAP/OLTP, transactions, ACID, indexing · SQL introduction and data types
-- =====================================================================================
--
--  HOW TO WORK
--   1. Run EX_6_prep.sql once (in database transactional) – it creates schema ex6 and function check_task.
--   2. ▶️ EXAMPLE: select the statement with the mouse and press F5. Look at the result (or the error).
--      F5 without a selection runs the WHOLE script – don't do that here.
--   3. 🧩 TASK: write your SQL where you see ...
--        – tasks with  SELECT check_task('3.1', $$ … $$);  : your query goes between $$ and $$
--            result only:  select ONLY your query (the lines between $$ and $$) → F5
--            check:        select the WHOLE block from  SELECT check_task(  to  $$);  → F5
--        – tasks that create or change tables: run your statement(s), then the line  SELECT check_task('…');
--      The check prints ✅ or explains what is wrong. Column names (AS) do not matter,
--      but the columns must be exactly those listed under "Columns", in that order.
--   4. ✏️ QUESTION: write the answer in a comment (a line that starts with --).
--   5. Save your work: disk icon (Save As) → EX_6_tasks_my_work.sql
--
--  If you get stuck, go on – only sections 1 and 2 must be done first (they create the tables).
--  The result checks in sections 3 and 4 expect the data as loaded in section 2 (before the fixes in section 5).
--
--  TABLES OF THIS EXERCISE (schema ex6 – you create them yourself)
--    cars_raw  – the CSV exactly as it arrived: 17 text columns           (section 2)
--    cars      – the same data with proper types                           (sections 1–5)
--    fuel_log  – 1 000 000 refuelling records for the index experiment    (section 6)
--  Data: Car Features and MSRP (Kaggle, CooperUnion) – the same cars as in Exercise 5.
--  The column "Highway fuel consumption (l/100 km)" was added by the instructor: 235.215 / highway MPG, 1 decimal.
-- =====================================================================================



-- #####################################################################################
-- 0. Setup – connection and function check_task   (≈ 5 min)
-- #####################################################################################

-- ▶️ EXAMPLE 0.a  Where am I? You should see database transactional.
SELECT current_database() AS database, current_user AS user_name, version();

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 0
--    Trial task: the solution is already written. Select the whole block (from SELECT check_task to $$);) and press F5.
--    If it says ✅, everything works.
--    Columns: database
SELECT check_task('0', $$
SELECT current_database() AS database
$$);



-- #####################################################################################
-- 1. SQL command types and data types   (≈ 8 min)
-- #####################################################################################
--   • DDL (Data Definition):    CREATE, ALTER, DROP, TRUNCATE   – the structure (schemas, tables, indexes)
--   • DML (Data Manipulation):  INSERT, UPDATE, DELETE          – the rows
--   • DQL (Data Query):         SELECT                          – reading
--   • TCL (Transaction Control): BEGIN, COMMIT, ROLLBACK        – section 5
--   • DCL (Data Control):       GRANT, REVOKE                   – who may do what
--   Every column has a data type. The type decides which values are allowed, how much space they take
--   and what you can do with them (add numbers, compare dates, sort text).
--     boolean                      true / false
--     text, varchar(n), char(n)    text (varchar(n) = at most n characters)
--     smallint, integer, bigint    whole numbers: up to 32 767 / about 2.1 billion / about 9.2 × 10^18
--     numeric(p, s)                exact decimal number: p digits in total, s after the decimal point – money, measurements
--     real, double precision       approximate (floating point) numbers – fast, but 0.1 + 0.2 is not exactly 0.3
--     date, time, timestamp, interval

-- ▶️ EXAMPLE 1.a  Every value has a type – pg_typeof shows it.
SELECT 42 AS a, pg_typeof(42) AS type_a,
       4.2 AS b, pg_typeof(4.2) AS type_b,
       'Audi' AS c, pg_typeof('Audi'::text) AS type_c,
       DATE '2026-11-08' AS d, pg_typeof(DATE '2026-11-08') AS type_d,
       DATE '2026-11-08' - DATE '2026-11-02' AS days_between;

-- ▶️ EXAMPLE 1.b  numeric is exact, double precision is approximate.
SELECT 0.1::numeric + 0.2::numeric                   AS exact,
       0.1::double precision + 0.2::double precision AS approximate;

-- ▶️ EXAMPLE 1.c  Types protect the data. Run each line SEPARATELY and read the error message.
SELECT 40000::smallint;            -- out of range for smallint
SELECT '9,4'::numeric;             -- a comma is not a decimal separator in SQL
SELECT '1st'::integer;             -- text that only looks like a number
SELECT DATE '2026-02-30';          -- there is no 30 February

-- ▶️ EXAMPLE 1.d  A schema is a folder for tables. Ours was created by EX_6_prep.sql:
--    in pgAdmin: transactional → Schemas → ex6 (right-click → Refresh if you don't see it).
SELECT schema_name FROM information_schema.schemata WHERE schema_name IN ('public', 'raw', 'ex6');

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 1.1  Choose the data types
--    Replace each ... with a suitable type, then select the whole CREATE TABLE statement → F5,
--    and after it run the check. The comments tell you what the values look like.
--    Made a mistake?  DROP TABLE ex6.cars;  and run CREATE TABLE again.
CREATE TABLE ex6.cars (
    make               varchar(50),
    model              varchar(50),
    year               ...,                 -- 1990 – 2017
    engine_fuel_type   text,
    engine_hp          ...,                 -- 55 – 1001, some cells are empty
    engine_cylinders   smallint,
    transmission_type  text,
    driven_wheels      text,
    number_of_doors    smallint,
    market_category    text,
    vehicle_size       text,
    vehicle_style      text,
    highway_mpg        ...,                 -- miles per gallon on the highway, whole numbers 12 – 354
    city_mpg           smallint,
    popularity         integer,
    msrp               ...,                 -- price in USD, whole numbers 2 000 – 2 065 902
    fuel_l_100km       ...                  -- litres per 100 km, one decimal, 0.7 – 19.6
);

SELECT check_task('1.1');

-- ✏️ QUESTION 1.2  Why not smallint for msrp? Why not real for fuel_l_100km?
-- Answer:



-- #####################################################################################
-- 2. Loading data: Excel → CSV → raw table → typed table   (≈ 17 min)
-- #####################################################################################
--   The data comes as an Excel file (data/cars.xlsx) – just like the data for the Week 6 assignment.
--   PostgreSQL cannot read .xlsx, so we go in three steps:
--     1. Excel → CSV (File → Save As → CSV UTF-8),
--     2. CSV → ex6.cars_raw: every column is text, so the import never fails because of a type,
--     3. ex6.cars_raw → ex6.cars with INSERT … SELECT: here we convert and check the types.
--   This is the raw → clean idea from Exercise 4 (landing zone first, cleaning in SQL afterwards).

-- ▶️ EXAMPLE 2.a  (instructor demo, see README) Open data/cars.xlsx in Excel → File → Save As →
--    "CSV UTF-8 (Comma delimited) (*.csv)". Then open the CSV in Notepad and look at it:
--      • which character separates the columns?   With Croatian regional settings Excel writes ;  with English ,
--      • how are decimals written?                 9,4 or 9.4
--      • is the first line a header?               yes – the import must skip it
--    No Excel? Use data/cars_from_excel.csv – it is exactly what Excel with Croatian settings writes.

-- ▶️ EXAMPLE 2.b  The raw table: the same 17 columns in the same ORDER as in the file, all text.
--    The import matches columns by position, not by name – so the names can already be our snake_case names.
CREATE TABLE ex6.cars_raw (
    make text, model text, year text, engine_fuel_type text, engine_hp text, engine_cylinders text,
    transmission_type text, driven_wheels text, number_of_doors text, market_category text,
    vehicle_size text, vehicle_style text, highway_mpg text, city_mpg text, popularity text,
    msrp text, fuel_l_100km text
);

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 2.1  Import the CSV into ex6.cars_raw with pgAdmin (step-by-step pictures: README, section "Import")
--    1. Object Explorer: transactional → Schemas → ex6 → Tables (right-click → Refresh) → cars_raw
--       → right-click → Import/Export Data…
--    2. General: Import · Filename: click the folder icon → Upload (cloud icon) → drag your CSV in → close → select it → Select
--                Format: csv · Encoding: UTF8
--    3. Options: Header ON · Delimiter: the character you saw in Notepad (; or ,) · Quote: "
--    4. OK. Bottom right: "Process completed" (if it failed: View Processes → details).
--    Then run the check:
SELECT check_task('2.1');

-- ▶️ EXAMPLE 2.c  What arrived? Everything is text – note fuel_l_100km and the empty (NULL) cells.
SELECT * FROM ex6.cars_raw LIMIT 20;

-- ▶️ EXAMPLE 2.d  Why we need the raw table: the cast fails if the file uses a decimal comma.
--    Run the first statement (error if your CSV has 9,4), then the second one.
SELECT fuel_l_100km, fuel_l_100km::numeric FROM ex6.cars_raw;
SELECT fuel_l_100km, replace(fuel_l_100km, ',', '.')::numeric AS fuel FROM ex6.cars_raw LIMIT 5;

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 2.2  Copy the data into the typed table
--    Complete the SELECT: convert every column with ::type (the same types as in 1.1).
--    The text columns need no conversion. Empty cells are NULL in cars_raw and stay NULL – good.
--    Ran it twice?  TRUNCATE ex6.cars;  and run it once.
INSERT INTO ex6.cars (make, model, year, engine_fuel_type, engine_hp, engine_cylinders, transmission_type,
                      driven_wheels, number_of_doors, market_category, vehicle_size, vehicle_style,
                      highway_mpg, city_mpg, popularity, msrp, fuel_l_100km)
SELECT make,
       model,
       ...,                              -- year
       engine_fuel_type,
       ...,                              -- engine_hp
       engine_cylinders::smallint,
       transmission_type,
       driven_wheels,
       number_of_doors::smallint,
       market_category,
       vehicle_size,
       vehicle_style,
       ...,                              -- highway_mpg
       city_mpg::smallint,
       popularity::integer,
       ...,                              -- msrp
       ...                               -- fuel_l_100km: careful with the decimal comma (2.d)
FROM ex6.cars_raw;

SELECT check_task('2.2');

-- ▶️ EXAMPLE 2.e  Text that looks like a number sorts like text: '100th' comes before '2nd'.
--    (Useful for the Week 6 assignment!)
SELECT place
FROM (VALUES ('1st'), ('2nd'), ('3rd'), ('10th'), ('21st'), ('100th'), ('179th')) AS t(place)
ORDER BY place;                                              -- text order: 100th, 10th, 179th, 1st, …

SELECT place, regexp_replace(place, '[^0-9]', '', 'g')::integer AS place_number
FROM (VALUES ('1st'), ('2nd'), ('3rd'), ('10th'), ('21st'), ('100th'), ('179th')) AS t(place)
ORDER BY place_number;                                       -- keep only the digits, then convert

-- The same trap with comparisons: as text, '10,0' < '7' is TRUE (the character '1' comes before '7').
SELECT '10,0' < '7' AS compared_as_text, 10.0 < 7 AS compared_as_numbers;



-- #####################################################################################
-- 3. First queries: SELECT, WHERE, ORDER BY, LIMIT   (≈ 10 min)
-- #####################################################################################
--   SELECT columns FROM table WHERE condition ORDER BY column [ASC | DESC] LIMIT n;
--   ASC (default) = smallest first, DESC = largest first. More SQL in Week 7.

-- ▶️ EXAMPLE 3.a  The five most powerful cars of 2017. Run both – what is different?
SELECT make, model, engine_hp
FROM ex6.cars
WHERE year = 2017
ORDER BY engine_hp DESC
LIMIT 5;                                                     -- NULL (unknown) counts as the largest value!

SELECT make, model, engine_hp
FROM ex6.cars
WHERE year = 2017
ORDER BY engine_hp DESC NULLS LAST
LIMIT 5;

-- ▶️ EXAMPLE 3.b  The first and the last place in ONE result: two queries glued together with UNION ALL.
--    Each part needs its own parentheses because each has its own ORDER BY and LIMIT.
(SELECT make, model, engine_hp FROM ex6.cars WHERE year = 2017 AND engine_hp IS NOT NULL ORDER BY engine_hp DESC LIMIT 1)
UNION ALL
(SELECT make, model, engine_hp FROM ex6.cars WHERE year = 2017 AND engine_hp IS NOT NULL ORDER BY engine_hp ASC  LIMIT 1);

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 3.1  The cheapest and the most expensive car of 2017 (two rows, the order does not matter).
--    Columns: make, model, msrp
SELECT check_task('3.1', $$

$$);

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 3.2  All cars of 2017 that use less than 5 l/100 km, the most economical one on top.
--    If two cars use the same amount, sort them by make and then by model.
--    Columns: make, model, fuel_l_100km
SELECT check_task('3.2', $$

$$);

-- ✏️ QUESTION 3.3  Look at the first row of 3.2. Is that believable?
-- Answer:



-- #####################################################################################
-- 4. Outliers in SQL: IQR and Z-score   (≈ 15 min)
-- #####################################################################################
--   IQR method:  Q1 = 25th percentile, Q3 = 75th percentile, IQR = Q3 − Q1
--                outlier if value < Q1 − 1.5·IQR  or  value > Q3 + 1.5·IQR      (the whiskers of a boxplot)
--   Z-score:     z = (value − mean) / standard deviation;  outlier if |z| > 3
--   In SQL: percentile_cont(0.25) WITHIN GROUP (ORDER BY column) is the 25th percentile.
--   An outlier is a QUESTION, not a verdict: an error (fix it), or a real but rare value (keep it)?

-- ▶️ EXAMPLE 4.a  Five-number summary of highway_mpg (what a boxplot draws) and the mean.
SELECT min(highway_mpg)                                           AS minimum,
       percentile_cont(0.25) WITHIN GROUP (ORDER BY highway_mpg) AS q1,
       percentile_cont(0.50) WITHIN GROUP (ORDER BY highway_mpg) AS median,
       percentile_cont(0.75) WITHIN GROUP (ORDER BY highway_mpg) AS q3,
       max(highway_mpg)                                           AS maximum,
       round(avg(highway_mpg), 1)                                 AS mean
FROM ex6.cars;

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 4.1  IQR bounds for highway_mpg.
--    Columns: q1, q3, iqr, lower_bound, upper_bound
--    Tip: percentile_cont returns double precision; round(x, 1) needs numeric → round(x::numeric, 1) (or no rounding).
SELECT check_task('4.1', $$

$$);

-- ▶️ EXAMPLE 4.b  Which cars are outside the bounds? (Write your bounds from 4.1 instead of 10 and 42 if they differ.)
SELECT make, model, year, engine_fuel_type, highway_mpg, city_mpg
FROM ex6.cars
WHERE highway_mpg < 10 OR highway_mpg > 42
ORDER BY highway_mpg DESC;

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 4.2  How many outliers (outside the bounds from 4.1) are there for each engine fuel type?
--    Most outliers first; if two types have the same number, sort by the type name.
--    Columns: engine_fuel_type, outliers
SELECT check_task('4.2', $$

$$);

-- ▶️ EXAMPLE 4.c  Z-score: how many standard deviations a value is away from the mean.
--    avg(…) OVER () and stddev(…) OVER () compute the mean of the whole table next to every row (window functions – Week 11).
SELECT *
FROM (SELECT make, model, year, engine_fuel_type, highway_mpg,
             round((highway_mpg - avg(highway_mpg) OVER ()) / stddev(highway_mpg) OVER (), 2) AS z
      FROM ex6.cars) AS t
WHERE abs(z) > 3
ORDER BY z DESC;

-- ▶️ EXAMPLE 4.d  A blind IQR on popularity: which makes would we throw away?
--    (popularity is a score of the MAKE, so every Ford has the same value.)
SELECT make, count(*) AS flagged_rows
FROM ex6.cars
WHERE popularity > (SELECT percentile_cont(0.75) WITHIN GROUP (ORDER BY popularity)
                         + 1.5 * (percentile_cont(0.75) WITHIN GROUP (ORDER BY popularity)
                                  - percentile_cont(0.25) WITHIN GROUP (ORDER BY popularity))
                    FROM ex6.cars)
GROUP BY make;

-- ✏️ QUESTION 4.3  Look at the results of 4.b, 4.2 and 4.d.
--    a) Which highway_mpg outlier is an error, and which ones are real cars? (Hint: what does "electric" mean for MPG?)
--    b) What would happen to the data if we deleted every IQR outlier of popularity?
-- Answer:

-- -------------------------------------------------------------------------------------
-- ⭐ TASK 4.4  (optional) IQR per group: compute Q1 and Q3 separately for each engine fuel type,
--    and count the outliers of each type against its OWN bounds. Show only types with at least one outlier,
--    ignore cars with an unknown fuel type. Most outliers first, then by type name.
--    Columns: engine_fuel_type, outliers
--    Tip: a subquery with GROUP BY engine_fuel_type gives the bounds per type – JOIN it to ex6.cars.
SELECT check_task('4.4', $$

$$);



-- #####################################################################################
-- 5. Treating outliers inside transactions – ACID   (≈ 13 min)
-- #####################################################################################
--   A transaction = a unit of work that happens completely or not at all.
--     BEGIN;  …statements…  COMMIT;     → all changes are saved
--     BEGIN;  …statements…  ROLLBACK;   → all changes are undone
--   Without BEGIN every statement is its own transaction and is committed at once (pgAdmin: auto-commit).
--   A – Atomicity:   all or nothing                    (5.c, 5.2–5.3)
--   C – Consistency: rules (constraints) always hold   (5.b, 5.1)
--   I – Isolation:   others don't see unfinished work  (5.d)
--   D – Durability:  after COMMIT the change survives a crash or a restart
--   If you see "current transaction is aborted, commands ignored until end of transaction block": run  ROLLBACK;

-- ▶️ EXAMPLE 5.a  The suspicious Audi A6 next to its "twin" (same engine, same drive, same city MPG).
SELECT make, model, year, engine_hp, driven_wheels, highway_mpg, city_mpg, fuel_l_100km, msrp
FROM ex6.cars
WHERE make = 'Audi' AND model = 'A6' AND year = 2017
ORDER BY driven_wheels, engine_hp;

-- ▶️ EXAMPLE 5.b  Consistency: a rule that no car does more than 150 MPG on the highway.
--    PostgreSQL refuses to add it – one row already breaks it. (Read the error.)
ALTER TABLE ex6.cars ADD CONSTRAINT chk_cars_highway_mpg CHECK (highway_mpg BETWEEN 5 AND 150);

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 5.1  Fix the error and add the rule – in ONE transaction.
--    The twin row says 34 – the 354 is a typing error (an extra 4). Fix highway_mpg to 34 AND
--    fuel_l_100km to round(235.215 / 34, 1). Run the statements one by one (select → F5) and look at Messages.
BEGIN;

UPDATE ex6.cars
SET ...
WHERE ...;

ALTER TABLE ex6.cars ADD CONSTRAINT chk_cars_highway_mpg CHECK (highway_mpg BETWEEN 5 AND 150);

COMMIT;

SELECT check_task('5.1');

-- ▶️ EXAMPLE 5.c  Atomicity: one failing statement takes the whole transaction down.
--    Run the lines one by one: the UPDATE works, the INSERT breaks the rule from 5.1,
--    the SELECT is refused, ROLLBACK ends the transaction, and the Tesla prices are unchanged.
BEGIN;
UPDATE ex6.cars SET msrp = msrp + 1000 WHERE make = 'Tesla';
INSERT INTO ex6.cars (make, model, year, highway_mpg) VALUES ('Test', 'Typo', 2026, 354);
SELECT make, model, msrp FROM ex6.cars WHERE make = 'Tesla' LIMIT 3;
ROLLBACK;
SELECT make, model, msrp FROM ex6.cars WHERE make = 'Tesla' LIMIT 3;

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 5.2  Quantile-based flooring and capping (Week 6, Video 1) – but only "to try it out".
--    Inside a transaction: set every price above the 90th percentile TO the 90th percentile (capping, given below)
--    and every price below the 10th percentile to the 10th percentile (flooring – you write it).
--    Then run the check INSIDE the transaction. Do NOT commit.
BEGIN;

UPDATE ex6.cars
SET msrp = (SELECT percentile_cont(0.9) WITHIN GROUP (ORDER BY msrp) FROM ex6.cars)
WHERE msrp > (SELECT percentile_cont(0.9) WITHIN GROUP (ORDER BY msrp) FROM ex6.cars);

UPDATE ex6.cars
SET msrp = ...
WHERE ...;

SELECT min(msrp), max(msrp) FROM ex6.cars;        -- inside the transaction we see the capped prices

SELECT check_task('5.2');

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 5.3  We don't want a Bugatti priced like a family car. Undo both UPDATEs, then check.
...

SELECT check_task('5.3');

-- ▶️ EXAMPLE 5.d  (instructor demo) Isolation – needs two Query Tool tabs (two connections):
--    tab 1:  BEGIN;  UPDATE ex6.cars SET msrp = 1 WHERE make = 'Bugatti';
--    tab 2:  SELECT make, model, msrp FROM ex6.cars WHERE make = 'Bugatti';   → still the old prices
--    tab 1:  ROLLBACK;   (with COMMIT tab 2 would see msrp = 1 from now on)
--    Durability: what was committed in 5.1 is still there after you stop and start the SQL pod.

-- ✏️ QUESTION 5.4  Why did we fix the Audi with COMMIT, but only tried the capping and rolled it back?
-- Answer:



-- #####################################################################################
-- 6. Indexes and EXPLAIN ANALYZE   (≈ 12 min)
-- #####################################################################################
--   Without an index PostgreSQL reads the whole table (Seq Scan) to find the rows you asked for.
--   An index is a separate sorted structure (a B-tree) with the values of one column and pointers to the rows:
--   the database finds the value quickly and jumps to the row (Index Scan).
--   Price: an index takes disk space and makes every INSERT / UPDATE a little slower.
--   EXPLAIN ANALYZE runs the query and shows HOW it was executed and how long it took.

-- ▶️ EXAMPLE 6.a  A big table: 1 000 000 refuellings of 200 000 cars (takes a few seconds).
DROP TABLE IF EXISTS ex6.fuel_log;
CREATE TABLE ex6.fuel_log (
    id_fuel_log  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    plate        text          NOT NULL,          -- licence plate, e.g. ZG-2469-AT
    fill_date    date          NOT NULL,
    litres       numeric(5,2)  NOT NULL,
    price_eur    numeric(7,2)  NOT NULL
);
INSERT INTO ex6.fuel_log (plate, fill_date, litres, price_eur)
SELECT (ARRAY['ZG', 'ST', 'RI', 'OS', 'ZD'])[1 + p % 5] || '-' || lpad((p / 5 % 10000)::text, 4, '0') || '-'
           || chr(65 + p / 50000) || chr(65 + (p / 5 * 7) % 26)                                  AS plate,
       DATE '2024-01-01' + (g * 7 % 1000)                                                         AS fill_date,
       20 + (g * 37 % 4000) / 100.0                                                               AS litres,
       round((20 + (g * 37 % 4000) / 100.0) * 1.45, 2)                                            AS price_eur
FROM generate_series(1, 1000000) AS g
CROSS JOIN LATERAL (SELECT (g * 7919::bigint % 200000)::integer AS p) AS x;     -- every plate gets exactly 5 rows
ANALYZE ex6.fuel_log;

-- ▶️ EXAMPLE 6.b  Find all refuellings of one car. Look at the plan: "Seq Scan" and the "Execution Time".
--    (pgAdmin can also draw the plan: Explain Analyze button / Shift+F7.)
EXPLAIN ANALYZE
SELECT * FROM ex6.fuel_log WHERE plate = 'ZG-2469-AT';

-- -------------------------------------------------------------------------------------
-- 🧩 TASK 6.1  Create an index on the column this query searches by, then run the check.
--    Syntax: CREATE INDEX index_name ON schema.table (column);     Name tip: idx_<table>_<column>
...

SELECT check_task('6.1');

-- ▶️ EXAMPLE 6.c  The same query again: "Index Scan" (or "Bitmap Index Scan") – compare the Execution Time with 6.b.
EXPLAIN ANALYZE
SELECT * FROM ex6.fuel_log WHERE plate = 'ZG-2469-AT';

-- ▶️ EXAMPLE 6.d  The price of the index: disk space.
SELECT pg_size_pretty(pg_table_size('ex6.fuel_log'))                   AS table_size,
       pg_size_pretty(pg_relation_size('ex6.idx_fuel_log_plate'))      AS plate_index_size;

-- ✏️ QUESTION 6.3  How many times faster was the query with the index? Would an index on ex6.cars(make)
--    help as much? (ex6.cars has 11 914 rows – try EXPLAIN ANALYZE SELECT * FROM ex6.cars WHERE make = 'Audi';)
-- Answer:

-- -------------------------------------------------------------------------------------
-- ⭐ TASK 6.2  (optional) The index is ignored when the query changes the column:
--    run the EXPLAIN ANALYZE below – it is a Seq Scan again. Create an index ON THE EXPRESSION lower(plate),
--    run the check, and run the EXPLAIN ANALYZE again.
EXPLAIN ANALYZE
SELECT * FROM ex6.fuel_log WHERE lower(plate) = 'zg-2469-at';

...

SELECT check_task('6.2');



-- #####################################################################################
-- 7. Tips for the Week 6 assignment (Fragile States Index 2023)
-- #####################################################################################
--   • Download the 2023 Excel file and save it as CSV UTF-8. Open the CSV in Notepad: delimiter? decimal comma?
--   • Create a raw table with one text column per Excel column (count them!) and import it like in 2.1.
--     Your own short snake_case names are easier than "S1: Demographic Pressures" (that one needs "double quotes").
--   • Convert into a typed table like in 2.2. Which columns are numbers with decimals? Which one is text that only
--     looks like a number (2.e)?
--   • "First and last place": two rows in one result – see 3.b. Make sure the order is by the number, not the text.
--   • "Less than 7" must compare numbers, not text (2.e: '10,0' < '7' is true!).
--   • The index: on a column your queries search or filter by often (6.1).
--   To clean up after this exercise:  DROP SCHEMA ex6 CASCADE;   (the shop data in schema public stays)
