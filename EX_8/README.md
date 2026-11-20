# Exercise 8 – Introduction to dbt: Bronze → Silver → Gold as code

In Exercise 4 you built a small medallion pipeline by hand: the view `silver.customer_signup` over the raw table
`raw.customer_signup`, and the view `gold.signups_by_country` over Silver.
Today you build **the same pipeline with dbt** (data build tool) and see what the tool adds:
the order of the steps (dependencies), data quality tests, documentation and a lineage graph – all from plain `SELECT` statements.

Duration: about 45 minutes. Environment: **Jupyter pod** (where dbt runs, in a terminal) + **SQL pod** (the database `transactional`, and pgAdmin to look at the results).
dbt is material for **outcome 3** of the midterm (newer technologies for data preparation).

## After this exercise you will be able to

* explain what a dbt **model** is (a `SELECT` saved in a `.sql` file) and what dbt does with it (`CREATE VIEW` / `CREATE TABLE` in the right order),
* use `source()` and `ref()` instead of table names, and explain why that gives dbt the dependencies and the lineage graph,
* write a model for the Silver and the Gold layer,
* add **tests** and say which **data quality dimension** each one checks (`not_null` – completeness, `unique` – uniqueness, `accepted_values` – consistency, a custom test – validity),
* run `dbt run`, `dbt test`, `dbt build` and `dbt docs generate`, and read their output,
* judge what dbt changes compared to SQL scripts run by hand – and what it does not do.

## Folder contents

| File / folder | Description |
|---|---|
| `requirements.txt` | dbt versions to install (the same for everyone) |
| `signups_dbt/` | the dbt project – **copy it first** (see below) and work in the copy |
| `signups_dbt/dbt_project.yml` | project settings: name, folders, every model is a view, Silver → schema `ex8_silver`, Gold → `ex8_gold` |
| `signups_dbt/profiles.yml` | connection to the database (host `postgres-pgadmin-pod`, port `5432`, database `transactional`) |
| `signups_dbt/models/sources.yml` | the source: Bronze = `raw.customer_signup` |
| `signups_dbt/models/silver/` | Silver model `customer_signup.sql` 🧩 and its tests in `silver.yml` 🧩 |
| `signups_dbt/models/gold/` | Gold models `signups_by_country.sql` 🧩, `countries_with_many_signups.sql` ⭐ and `gold.yml` |
| `signups_dbt/tests/` | `assert_valid_email.sql` (a data quality test) and `check_task*.sql` (✅ checks of your tasks – don't edit) |

## How to start

1. **Start both pods**: Podman Desktop → **Pods** → `postgres-pgadmin-pod` → **Start**, and `jupyter-notebook-anaconda` → **Start**.
   Open Jupyter (address with the token from the container **Logs**) and pgAdmin (<http://localhost:8081>).
2. In **Jupyter** (in the browser): **New → Terminal**. The prompt is only `#`.
   Type `bash` first – then the arrow keys bring back earlier commands, which you will need for running dbt again and again. Then pull the news:
   ```bash
   bash
   cd /opt/notebooks/Data-Engineering-2026-2027
   git pull
   ```
3. **Install dbt** (once, about a minute) – into its own Python environment, so it doesn't clash with Anaconda.
   Write Python with its full path: the Jupyter terminal does not find the command `python` on its own (`python: not found`).
   ```bash
   /opt/conda/bin/python -m venv /opt/dbt-venv
   /opt/dbt-venv/bin/pip install -r EX_8/requirements.txt
   ```
4. **Activate dbt** – in **every new terminal** (you then see `(dbt-venv)` at the start of the line).
   The command is a dot, a space and the path:
   ```bash
   . /opt/dbt-venv/bin/activate
   ```
5. **Your own copy** of the project, and the connection test:
   ```bash
   cd /opt/notebooks/Data-Engineering-2026-2027/EX_8
   cp -r signups_dbt signups_dbt_my_work
   cd signups_dbt_my_work
   dbt debug
   ```
   At the end you must see `Connection test: [OK connection ok]` and `All checks passed!`.

> **Run every `dbt` command in the folder `signups_dbt_my_work`** – dbt looks for `dbt_project.yml` and `profiles.yml` in the current folder.
> Edit the files in the Jupyter file browser (double-click a `.sql` or `.yml` file, save with **Ctrl+S**), run dbt in the terminal next to it.
>
> If the pod was deleted and created again, `/opt/dbt-venv` is gone – repeat step 3. Your copy of the project is on the pod's volume and stays.

## Tasks

| # | What | ≈ min |
|---|---|---|
| 0 | Setup: install dbt, copy the project, `dbt debug` | 8 |
| 1 | Look around: source, model, `dbt run` | 6 |
| 2 | `dbt test` – what is wrong with the data? | 4 |
| 3 | 🧩 Fix the Silver model | 10 |
| 4 | 🧩 Write the Gold model | 6 |
| 5 | 🧩 Add a test | 3 |
| 6 | Documentation and the lineage graph | 5 |
| 7 | ⭐ Optional: an exam-style model with `HAVING` | at home |
| 8 | ✏️ Questions | at home |

### 1. Look around

* Open `models/sources.yml`: the table `raw.customer_signup` is declared as the source `bronze`. dbt does not build sources – it only reads them.
* Open `models/silver/customer_signup.sql`. It is **only a `SELECT`** – there is no `CREATE VIEW`. Instead of the table name it uses `{{ source('bronze', 'customer_signup') }}`.
* Run all models:
  ```bash
  dbt run
  ```
  dbt reads the models, finds out which depends on which, and creates them in the right order.
  In pgAdmin (database `transactional` → Schemas → refresh) you now see the schemas **`ex8_silver`** and **`ex8_gold`** with views.
* See what dbt really sent to the database: open `target/run/signups/models/silver/customer_signup.sql` – the `CREATE VIEW` that dbt wrote around your `SELECT`.
  (`target/compiled/…` has the `SELECT` alone, with `source(...)` replaced by `"transactional"."raw"."customer_signup"`.)

### 2. `dbt test`

```bash
dbt test
```

Most tests **fail** – that is expected: the Silver model is a first draft and the raw data is dirty.
Read the `ERROR` lines and match them with the tests in `models/silver/silver.yml` and `tests/assert_valid_email.sql`:

| Failing test | Dimension | What is wrong |
|---|---|---|
| `unique_customer_signup_email` | uniqueness | a few rows were loaded twice |
| `not_null_customer_signup_email`, `not_null_customer_signup_full_name` | completeness | a sign-up without an e-mail, one without a name |
| `accepted_values_customer_signup_country__…` | consistency | Croatia written in five ways |
| `assert_valid_email` | validity | e-mails like `ivan at gmail.com` |
| `check_task3_silver`, `check_task4_gold`, `check_task7_star` | – | ✅ checks of tasks 3, 4 and 7 – they pass when your models are right |

A test is just a `SELECT` that returns the **bad rows** – it passes when it returns none.
To see the rows: open the test's file in `target/compiled/…` (the path is in the output), copy the query into pgAdmin and run it.

### 3. 🧩 Fix the Silver model

Edit `models/silver/customer_signup.sql` – the three 🧩 comments say what to do:

* **3a** uniqueness – remove duplicate rows,
* **3b** consistency – `Croatia`, `croatia`, `HR`, `Hrvatska` and `CRO` must all become `'Croatia'` (hint: `CASE WHEN … IN (…)`),
* **3c** validity and completeness – keep only rows whose e-mail matches `'^[^@\s]+@[^@\s]+\.[a-z]{2,}$'` (operator `~*`),
  that have a name (not `NULL`, not empty), and are not the test record (`test@…`).

Everything you need is in the Silver view of Exercise 4 (`EX_4-lakehouse_lab.sql`) – the point today is not the SQL, but what dbt does with it.
Save and run only this model and its tests:

```bash
dbt build --select customer_signup
```

`dbt build` = `run` + `test` in the order of the dependencies. Repeat until all Silver tests and `check_task3_silver` say `PASS` (expected: **36 rows**).

### 4. 🧩 Write the Gold model

Replace the placeholder in `models/gold/signups_by_country.sql` with your query:
columns `country`, `channel`, `signups` (the number of sign-ups), one row per country and channel,
reading from Silver with `{{ ref('customer_signup') }}` – never from `raw` directly.

```bash
dbt build
```

Expected: `check_task4_gold` → `PASS` (**6 rows**). Look at the view `ex8_gold.signups_by_country` in pgAdmin.

> Try it: break the Silver model on purpose (e.g. remove the `DISTINCT`) and run `dbt build` again.
> The `unique` test fails – and dbt **skips** the Gold models that depend on it (`SKIP`). Bad data does not reach the report. Then repair it.

### 5. 🧩 Add a test

In `models/silver/silver.yml`, add an `accepted_values` test for the column `channel`
(allowed values: `newsletter`, `web shop`, `trade fair`) – copy the one of `country` and watch the indentation.
Run `dbt test` – the new test appears in the output and passes. Which data quality dimension does it check?

### 6. Documentation and the lineage graph

```bash
dbt docs generate --static
```

dbt writes the whole documentation – models, columns, descriptions from the `.yml` files, tests, the SQL and the lineage graph – into **one file**:
`target/static_index.html`.

1. In the Jupyter file browser go to `signups_dbt_my_work/target/`, right-click `static_index.html` → **Download**.
2. Open the downloaded file on your computer (double-click – it opens in your browser).
3. Click the round button at the bottom right: the **lineage graph** `bronze.customer_signup → customer_signup → signups_by_country`.
   Under *resources* you can hide the tests to see only the models.

> Don't open the file directly in Jupyter: Jupyter shows HTML files in a restricted mode and the graph stays empty.

Compare with Exercise 4: there you wrote the catalog (`COMMENT ON …`) and read the lineage from `information_schema.view_table_usage` by hand.
Here both come from the project itself.

### 7. ⭐ Optional: countries with at least 3 sign-ups

`models/gold/countries_with_many_signups.sql`: columns `country`, `signups`, only countries with **3 or more** sign-ups (all channels together),
reading from a model of this project with `ref(...)`. Check: `dbt build` → `check_task7_star` → `PASS`.
Exam-style: can you explain why the condition goes into `HAVING` and not into `WHERE`, and which model you read from and why?

### 8. ✏️ Questions (at home, not submitted)

1. In Exercise 4 the views had to be created in the right order by hand. How does dbt know that `signups_by_country` must be built after `customer_signup`?
2. For each test in `silver.yml` and `assert_valid_email.sql`, name the data quality dimension it checks.
3. Your team cleans data with SQL scripts that someone runs one after another every morning. What would change with dbt (order, tests, documentation, version control, repeatability)?
   And what does dbt **not** do – where do the data come from, who runs dbt every morning, where is the data stored and computed?

## Useful commands

| Command | What it does |
|---|---|
| `dbt debug` | checks the project and the connection |
| `dbt run` | creates all models (views) in the order of the dependencies |
| `dbt run --select customer_signup` | only one model |
| `dbt test` | runs all tests |
| `dbt build` | `run` + `test`, model by model – a model whose tests fail stops the models after it |
| `dbt docs generate --static` | documentation and lineage in `target/static_index.html` |

## When something goes wrong

| Message | Cause |
|---|---|
| `python: not found` | the Jupyter terminal does not find `python` on its own – write `/opt/conda/bin/python` (step 3) |
| `dbt: command not found` | dbt is not activated in this terminal: `. /opt/dbt-venv/bin/activate` |
| `source: not found` | the terminal is `sh`, which has no `source` – use a dot: `. /opt/dbt-venv/bin/activate` (or type `bash` first) |
| `No dbt_project.yml found` | you are in the wrong folder: `cd /opt/notebooks/Data-Engineering-2026-2027/EX_8/signups_dbt_my_work` |
| `could not translate host name "postgres-pgadmin-pod"` / `Connection refused` | the SQL pod is not running – start it in Podman Desktop |
| `Compilation Error … depends on a node named '…' which was not found` | a typo in `ref('…')` or `source('…', '…')` |
| `Parsing Error` in a `.yml` file | the indentation is wrong – YAML uses spaces, and the levels must line up exactly |
| `check_task…` → `ERROR` | a column is missing or named differently – read the comment at the top of the check file |

**Cleaning up:** `DROP SCHEMA ex8_silver, ex8_gold CASCADE;` in pgAdmin removes the views. The table `raw.customer_signup` is never changed – dbt only reads it.
