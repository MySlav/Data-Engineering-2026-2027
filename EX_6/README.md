# Exercise 6 – Data types, loading data, outliers, transactions and indexes

Related to the Week 6 videos: **Outliers: detection and treatment**, **OLAP/OLTP, transactions, ACID and indexing**, **Introduction to SQL and SQL data types**.
Duration: 80 minutes. Environment: **SQL pod** (PostgreSQL 18 + pgAdmin 4), database **`transactional`**, schema **`ex6`**.

The exercise prepares you for the Week 6 assignment: you load an Excel file into PostgreSQL step by step,
query it, and create an index – on different data (cars instead of the Fragile States Index).

## After this exercise you will be able to

* tell the SQL command types apart (DDL, DML, DQL, TCL, DCL) and choose data types for a table (`smallint`, `integer`, `numeric(p,s)`, `text` …),
* load an Excel file into PostgreSQL: Excel → CSV → a raw table with text columns (pgAdmin import) → a typed table (`INSERT … SELECT` with casts),
* recognise the usual traps: delimiter `;` vs `,`, decimal comma, header row, empty cells, text that only looks like a number (`'1st'`),
* write simple queries with `WHERE`, `ORDER BY` and `LIMIT`, including "the first and the last place" in one result,
* find outliers in SQL with the IQR method and Z-scores, and decide whether an outlier is an error or a real value,
* use transactions (`BEGIN`, `COMMIT`, `ROLLBACK`) and explain the ACID properties with examples,
* create an index and measure its effect with `EXPLAIN ANALYZE`.

## Folder contents

| File / folder | Description |
|---|---|
| `EX_6_prep.sql` | creates schema `ex6` and the function `check_task` in database `transactional` – run it **once** |
| `EX_6_tasks.sql` | examples and tasks, section by section |
| `data/cars.xlsx` | the cars as an Excel file – the starting point, like the Excel file of the assignment |
| `data/cars_from_excel.csv` | the same file already saved as CSV (what Excel with Croatian regional settings writes: `;` and decimal comma) – for those without Excel |

## How to start

1. **Start the SQL pod**: Podman Desktop → **Pods** → `postgres-pgadmin-pod` → **Start**.
   If you don't have it yet: [`environment/README.md`](../environment/README.md#starting-the-sql-pod).
2. Open **pgAdmin** at <http://localhost:8081> (login `admin@admin.com` / `admin`).
   Servers → *Algebra Bernays - Data Engineering* (database password: `mypassword`) → Databases → **`transactional`** → right-click → **Query Tool**.
3. **Preparation (once):** on GitHub open [`EX_6_prep.sql`](EX_6_prep.sql) → button **Copy raw file** (above the code) →
   paste into the Query Tool → **F5**. You must see `✅ Schema ex6 and function check_task are ready.`
4. **Tasks:** copy [`EX_6_tasks.sql`](EX_6_tasks.sql) the same way into a (new) Query Tool and save it right away as
   **`EX_6_tasks_my_work.sql`** (disk icon → Save As). The file is saved in pgAdmin (in the pod's volume) and stays there after a restart.
5. **The data file:** on GitHub open [`data/cars.xlsx`](data/cars.xlsx) → **Download raw file** (or `data/cars_from_excel.csv` if you have no Excel).
   You need it on your own computer, because you upload it to pgAdmin in task 2.1.

> You don't need to clone the repository for this exercise – pgAdmin runs in the browser, so copying the scripts from GitHub is the fastest way.
> If you work with a clone on your computer, you can open the script in pgAdmin too: Query Tool → **Open File** → **Upload**.

## How to solve the tasks

* **▶️ EXAMPLE** – select the statement with the mouse and press **F5**. F5 without a selection runs the whole script – don't do that here.
* **🧩 TASK** with a query – write it between `$$` and `$$`:
  ```sql
  SELECT check_task('3.1', $$

      SELECT make, model, msrp
      FROM ex6.cars
      WHERE …

  $$);
  ```
  * result only: select **only your query** (the lines between `$$` and `$$`) → F5,
  * check: select **the whole block** from `SELECT check_task(` to `$$);` → F5.
* **🧩 TASK** that creates or changes tables (1.1, 2.1, 2.2, 5.x, 6.x) – run your statement(s), then the line `SELECT check_task('…');`.
* The check prints `✅ correct`, `❌` with an explanation, or `🟡` if the result is right but something is missing (order, COMMIT …).
  If the message is cut off, widen the column (drag the edge of its header).
  Column names (`AS`) do not matter, but the columns must be **exactly those from the task, in that order**.
* **✏️ QUESTION** – write the answer in a comment (a line that starts with `--`).

`check_task` only reads your tables and compares summaries (md5) of the results – the solutions are not stored in the database.

## Importing a CSV with pgAdmin (task 2.1)

**1. Excel → CSV.** Open `cars.xlsx` in Excel → **File → Save As** → type **CSV UTF-8 (Comma delimited) (\*.csv)**.
Open the new CSV in **Notepad** and look at the first lines:

* the delimiter between the columns – with Croatian regional settings Excel writes **`;`**, with English settings **`,`**,
* decimal numbers – `9,4` or `9.4`,
* the first line is the **header** (column names).

LibreOffice: File → Save As → *Text CSV (.csv)* → tick *Edit filter settings* and choose the field delimiter.

**2. Import into `ex6.cars_raw`** (the table from ▶️ 2.b – refresh the tree if you don't see it: right-click *Tables* → Refresh):

1. Object Explorer: transactional → Schemas → ex6 → Tables → click **cars_raw** →
   menu **Tools → Import/Export Data…** (also in the right-click menu of the table).
2. Tab **General**
   * Import/Export: **Import** (default),
   * Filename: click the **folder icon** → in the *Select file* window click **…** (Options, top right) → **Upload** →
     drag your CSV into the box (or click it and choose the file) → close the upload box with **×** →
     double-click your file (or select it → **Select**),
   * Format: **csv**, Encoding: **UTF8**.
3. Tab **Options**
   * **Header: ON** – it is OFF by default, and then the column names would become a row of data,
   * **Delimiter:** the character you saw in Notepad – the default is `,`, for the Croatian Excel file choose **`;`**,
   * Quote `"` – leave the rest as it is.
4. **OK**. Bottom right you see *Process started* and then **Process completed**.
5. Run `SELECT check_task('2.1');`

**If it says *Process failed*:** click **View Processes** → in the row of the import click the details icon to read the error.

| Error | Cause | Fix |
|---|---|---|
| `missing data for column "engine_hp"` (or another column) | wrong delimiter – the whole line ended up in one column | Options → Delimiter: the one from Notepad |
| `extra data after last expected column` | the file has more columns than the table | check the file: is it really the cars file? |
| the check says *the header row was loaded as data* | Header was OFF | `TRUNCATE ex6.cars_raw;` and import again with Header ON |
| the check says *every car is there twice* | you imported twice | `TRUNCATE ex6.cars_raw;` and import once |

The uploaded file stays in pgAdmin (**Tools → Storage Manager**), so you don't have to upload it again.

## Transactions in pgAdmin (section 5)

* The Query Tool works in **auto-commit** mode: every statement without `BEGIN` is committed at once.
  After `BEGIN` the transaction stays open until `COMMIT` or `ROLLBACK` – also when you run the statements one by one with F5.
* `check_task` notices an open transaction: in 5.1 it reminds you to `COMMIT`, in 5.2 it must run *inside* the transaction.
* After an error inside a transaction PostgreSQL refuses everything else
  (*current transaction is aborted, commands ignored until end of transaction block*) – run **`ROLLBACK;`**.
* Each Query Tool tab has its own connection – that is how you see **isolation** in ▶️ 5.d.
* Committed the capping in 5.2 by mistake? `TRUNCATE ex6.cars;`, run the `INSERT` from 2.2 and the fix from 5.1 again.

## Sections

| # | Section | Tasks | ≈ min |
|---|---|---|---|
| 0 | Setup – connection and function `check_task` | 0 | 5 |
| 1 | SQL command types and data types, `CREATE TABLE` | 1.1 – 1.2 | 8 |
| 2 | Loading data: Excel → CSV → raw table → typed table | 2.1 – 2.2 | 17 |
| 3 | First queries: `SELECT`, `WHERE`, `ORDER BY`, `LIMIT` | 3.1 – 3.3 | 10 |
| 4 | Outliers in SQL: IQR and Z-score | 4.1 – 4.3, ⭐ 4.4 | 15 |
| 5 | Treating outliers inside transactions – ACID | 5.1 – 5.4 | 13 |
| 6 | Indexes and `EXPLAIN ANALYZE` | 6.1, 6.3, ⭐ 6.2 | 12 |
| 7 | Tips for the Week 6 assignment | – | – |

Sections 1 and 2 create the tables, so do them first; after that the tasks do not depend on each other.
Tasks marked ⭐ are optional. Nothing is submitted or graded – the checks tell you whether each step is right.
The graded Week 6 assignment is on Moodle; section 7 of the script has tips for it.

## Tables (schema `ex6`)

| Table | Created in | Columns |
|---|---|---|
| `cars_raw` | ▶️ 2.b | 17 × `text`, in the order of the file |
| `cars` | 🧩 1.1 | `make`, `model`, `year`, `engine_fuel_type`, `engine_hp`, `engine_cylinders`, `transmission_type`, `driven_wheels`, `number_of_doors`, `market_category`, `vehicle_size`, `vehicle_style`, `highway_mpg`, `city_mpg`, `popularity`, `msrp`, `fuel_l_100km` |
| `fuel_log` | ▶️ 6.a | `id_fuel_log` PK, `plate`, `fill_date`, `litres`, `price_eur` – 1 000 000 generated rows |

**Starting over:** `DROP SCHEMA ex6 CASCADE;` and run `EX_6_prep.sql` again. The online shop in schema `public` is not touched.

## Data sources

* Cars – [Kaggle: Car Features and MSRP](https://www.kaggle.com/datasets/CooperUnion/cardataset), CooperUnion (the same data as in Exercise 5).
  The column *Highway fuel consumption (l/100 km)* was added for this exercise: 235.215 / highway MPG, rounded to 1 decimal.
* `fuel_log` is generated in the script (`generate_series`); the licence plates are made up.
