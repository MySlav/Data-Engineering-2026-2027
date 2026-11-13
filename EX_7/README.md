# Exercise 7 – SQL basics: SELECT, WHERE, NULL, ORDER BY, GROUP BY, HAVING

Related to the Week 7 videos: **SQL Basics Part 1** (SELECT, WHERE, logical operators), **Part 2** (NULL handling, pattern matching, sorting)
and **Part 3** (aggregate functions, GROUP BY, HAVING).
Duration: 80 minutes. Environment: **SQL pod** (PostgreSQL 18 + pgAdmin 4), database **`transactional`** (the online shop).

The exercise prepares you for the Week 7 assignment: the same kinds of queries (a filter, a pattern, groups with `HAVING`),
on different data – and section 7 shows how to build a small table of your own to query.

## After this exercise you will be able to

* write queries with `SELECT`, `FROM`, `WHERE`, `ORDER BY` and `LIMIT`, rename columns with `AS` and remove repeated rows with `DISTINCT`,
* combine conditions with `AND`, `OR`, `NOT` and parentheses – and explain what goes wrong without the parentheses,
* handle `NULL` correctly (`IS NULL`, `IS NOT NULL`) and use `LIKE` / `ILIKE`, `IN` (list and subquery) and `BETWEEN`, including the date trap,
* summarise data with `COUNT`, `SUM`, `AVG`, `MIN`, `MAX` and nested functions,
* group with `GROUP BY`, filter groups with `HAVING`, and tell when a condition belongs in `WHERE` and when in `HAVING`,
* use these queries as data-quality checks: missing values, inconsistent spelling, duplicate candidates.

## Folder contents

| File | Description |
|---|---|
| `EX_7_prep.sql` | creates schema `ex7` and the function `ex7.check_task` in database `transactional` – run it **once** |
| `EX_7_tasks.sql` | examples and tasks, section by section |

## How to start

1. **Start the SQL pod**: Podman Desktop → **Pods** → `postgres-pgadmin-pod` → **Start**.
   If you don't have it yet: [`environment/README.md`](../environment/README.md#starting-the-sql-pod).
2. Open **pgAdmin** at <http://localhost:8081> (login `admin@admin.com` / `admin`).
   Servers → *Algebra Bernays - Data Engineering* (database password: `mypassword`) → Databases → **`transactional`** → right-click → **Query Tool**.
3. **Preparation (once):** on GitHub open [`EX_7_prep.sql`](EX_7_prep.sql) → button **Copy raw file** (above the code) →
   paste into the Query Tool → **F5**. You must see `✅ Schema ex7 and function ex7.check_task are ready.`
4. **Tasks:** copy [`EX_7_tasks.sql`](EX_7_tasks.sql) the same way into a (new) Query Tool and save it right away as
   **`EX_7_tasks_my_work.sql`** (disk icon → Save As). The file is saved in pgAdmin (in the pod's volume) and stays there after a restart.

> You don't need to clone the repository for this exercise – pgAdmin runs in the browser, so copying the scripts from GitHub is the fastest way.
> If you work with a clone on your computer, you can open the script in pgAdmin too: Query Tool → **Open File** → **Upload**.

## How to solve the tasks

* **▶️ EXAMPLE** – select the statement with the mouse and press **F5**. F5 without a selection runs the whole script – don't do that here.
* **🧩 TASK** – write your query between `$$` and `$$`:
  ```sql
  SELECT ex7.check_task('3.1', $$

      SELECT first_name, last_name, email
      FROM customer
      WHERE …

  $$);
  ```
  * result only: select **only your query** (the lines between `$$` and `$$`) → F5,
  * check: select **the whole block** from `SELECT ex7.check_task(` to `$$);` → F5.
* The check prints `✅ correct`, `❌` with an explanation (wrong number of rows, wrong values, an error in the query),
  or `🟡` if the rows are right but the order is not. If the message is cut off, widen the column (drag the edge of its header).
  Column names (`AS`) do not matter, but the columns must be **exactly those from the task, in that order**.
  The order of the rows is checked only in tasks that ask for a sort.
* **✏️ QUESTION** – write the answer in a comment (a line that starts with `--`).

`ex7.check_task` only reads data and compares summaries (md5) of the results – the solutions are not stored in the database.
It is a different function from `check_task` of Exercise 6, which keeps working.

## Sections

| # | Section | Tasks | ≈ min |
|---|---|---|---|
| 0 | Setup – connection and function `ex7.check_task` | 0 | 5 |
| 1 | `SELECT`, column aliases (`AS`) and `DISTINCT` | 1.1 – 1.3 | 7 |
| 2 | `WHERE`, comparison operators, `AND` / `OR` / `NOT` | 2.1 – 2.4 | 11 |
| 3 | `NULL`, `LIKE`, `IN` and `BETWEEN` | 3.1 – 3.6 | 14 |
| 4 | `ORDER BY` and `LIMIT` | 4.1 – 4.4 | 10 |
| 5 | Aggregate functions and nested functions | 5.1 – 5.4 | 9 |
| 6 | `GROUP BY`, `HAVING` and table aliases | 6.1 – 6.7 | 19 |
| 7 | Warm-up for the Week 7 assignment: your own table | examples + tips | 5 |
| 8 | ⭐ Optional tasks | 8.1 – 8.5 | for the fast ones, or at home |

The tasks do not depend on each other – if you get stuck, go on. Tasks marked ⭐ are optional.
Nothing is submitted or graded – the checks tell you whether each query is right.
The graded Week 7 assignment is on Moodle; section 7 of the script has tips for it.
Tasks 4.4, 6.5 and 6.7 are marked or built as **exam-style**: on the exam you write such queries without a database to try them on, so after the check says ✅, make sure you can explain every clause.

## Database `transactional`

Generated data of an online shop (the same for everyone): 10 categories, 50 products, 104 customers, 512 orders
(January 2024 – September 2026), 1 333 order lines, payments and shipments.
Part of the data is "dirty" on purpose (countries and cities written in several ways, missing e-mails and phones, a customer entered twice) –
you will meet it in the tasks, and clean it properly in the data standardisation weeks.

| Table | Columns |
|---|---|
| `category` | `id_category` PK, `category_name` |
| `product` | `id_product` PK, `category_id` FK, `sku`, `product_name`, `price`, `active`, `created_at` |
| `customer` | `id_customer` PK, `first_name`, `last_name`, `email`, `phone`, `address`, `city`, `country`, `created_at`, `updated_at` |
| `customer_order` | `id_customer_order` PK, `customer_id` FK, `order_date`, `status` |
| `order_item` | `id_order_item` PK, `customer_order_id` FK, `product_id` FK, `quantity`, `unit_price` |
| `payment` | `id_payment` PK, `customer_order_id` FK, `payment_date`, `payment_method`, `amount`, `status` |
| `shipment` | `id_shipment` PK, `customer_order_id` FK, `shipment_date`, `delivery_date`, `carrier`, `tracking_number`, `status` |

Today every query reads one table; joining tables comes with SQL Advanced. Tasks 4.4, 6.7 and ⭐ 8.3 use `raw.customer_signup` (`full_name`, `email`, `phone`, `city`, `country`, `signup_date`, `channel` – all text), a table of unvalidated CSV imports in schema `raw`: the "Bronze" data of Exercise 4.

**Cleaning up:** `DROP SCHEMA ex7 CASCADE;` removes the function and the table of section 7. The shop data in schema `public` is never changed.
