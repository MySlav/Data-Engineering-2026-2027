-- =====================================================================================
--  Data Engineering – Exercise 6: PREPARATION   (run ONCE, in database transactional)
-- =====================================================================================
--  pgAdmin: Servers → Algebra Bernays - Data Engineering → Databases → transactional
--           → right-click → Query Tool → paste this whole file → F5.
--  Result: the message "✅ Schema ex6 and function check_task are ready."
--
--  Creates
--    • schema ex6 – all tables of this exercise go here (the online shop in schema public is not touched),
--    • function check_task(task, query) – runs your query or looks at your tables and tells you
--      whether the task is solved. Only summaries (md5) are compared – the solutions are not stored here.
--  Running it again does no harm. To start the exercise from scratch:  DROP SCHEMA ex6 CASCADE;  and run this file again.
-- =====================================================================================

DO $$
BEGIN
    IF current_database() <> 'transactional' THEN
        RAISE EXCEPTION 'You are connected to database "%". Open the Query Tool on database transactional and run this file again.', current_database();
    END IF;
END
$$;

CREATE SCHEMA IF NOT EXISTS ex6;
COMMENT ON SCHEMA ex6 IS 'Exercise 6 – data types, loading data, outliers, transactions and indexes';

CREATE OR REPLACE FUNCTION public.check_task(task text, query text DEFAULT NULL)
RETURNS text
LANGUAGE plpgsql
AS $fn$
DECLARE
    t        text := trim(coalesce(task, ''));
    q        text;
    n        bigint;
    h        text;
    hr       text;
    e        record;
    msg      text;
    in_tx    boolean := pg_current_xact_id_if_assigned() IS NOT NULL;   -- true = you changed data in a transaction that is still open
    col      record;
    typ      text;
    v_n      bigint;
    v_a      numeric;
    v_b      numeric;
    v_c      numeric;
    v_d      numeric;
BEGIN
    -- ---------------------------------------------------------------- tasks checked by looking at your tables
    IF t = '1.1' THEN
        IF to_regclass('ex6.cars') IS NULL THEN
            RETURN '❌ Task 1.1: table ex6.cars does not exist yet. Fill in the types and run the whole CREATE TABLE statement.';
        END IF;
        msg := '';
        FOR col IN
            SELECT x.c, x.kind, x.maxv, i.data_type, i.character_maximum_length AS len, i.numeric_precision AS prec, i.numeric_scale AS scale
            FROM (VALUES ('make', 'text', 13), ('model', 'text', 35), ('year', 'int', 2017), ('engine_fuel_type', 'text', 44),
                         ('engine_hp', 'int', 1001), ('engine_cylinders', 'int', 16), ('transmission_type', 'text', 16),
                         ('driven_wheels', 'text', 17), ('number_of_doors', 'int', 4), ('market_category', 'text', 54),
                         ('vehicle_size', 'text', 7), ('vehicle_style', 'text', 19), ('highway_mpg', 'int', 354),
                         ('city_mpg', 'int', 137), ('popularity', 'int', 5657), ('msrp', 'int', 2065902),
                         ('fuel_l_100km', 'dec', 20)) AS x(c, kind, maxv)
            LEFT JOIN information_schema.columns i
                   ON i.table_schema = 'ex6' AND i.table_name = 'cars' AND i.column_name = x.c
        LOOP
            IF col.data_type IS NULL THEN
                msg := msg || format(E'\n   • column %s is missing (did you rename it?)', col.c);
            ELSIF col.kind = 'text' AND col.data_type NOT IN ('text', 'character varying') THEN
                msg := msg || format(E'\n   • %s is %s – use text or varchar(n)', col.c, col.data_type);
            ELSIF col.kind = 'int' AND col.data_type NOT IN ('smallint', 'integer', 'bigint') THEN
                msg := msg || format(E'\n   • %s is %s – the values are whole numbers, use an integer type (smallint, integer, bigint)', col.c, col.data_type);
            ELSIF col.c = 'msrp' AND col.data_type = 'smallint' THEN
                msg := msg || E'\n   • msrp is smallint – smallint only goes up to 32 767, but the most expensive car costs 2 065 902';
            ELSIF col.kind = 'dec' AND col.data_type IN ('smallint', 'integer', 'bigint') THEN
                msg := msg || format(E'\n   • %s is %s – an integer type would lose the decimals (9.4 → 9)', col.c, col.data_type);
            ELSIF col.kind = 'dec' AND col.data_type NOT IN ('numeric', 'real', 'double precision') THEN
                msg := msg || format(E'\n   • %s is %s – use a number type with decimals, e.g. numeric(4,1)', col.c, col.data_type);
            ELSIF col.kind = 'dec' AND col.data_type = 'numeric' AND col.scale IS NOT NULL AND (col.scale < 1 OR col.prec - col.scale < 2) THEN
                msg := msg || format(E'\n   • %s is numeric(%s,%s) – it must hold values like 20.0: at least 2 digits before and 1 after the decimal point', col.c, col.prec, col.scale);
            ELSIF col.kind = 'text' AND col.len IS NOT NULL AND col.len < col.maxv THEN
                msg := msg || format(E'\n   • %s is varchar(%s), but the longest value has %s characters', col.c, col.len, col.maxv);
            END IF;
        END LOOP;
        IF msg <> '' THEN
            RETURN '❌ Task 1.1: not all types are right yet:' || msg ||
                   E'\n   Fix it with  DROP TABLE ex6.cars;  and run your CREATE TABLE again.';
        END IF;
        SELECT data_type INTO typ FROM information_schema.columns
        WHERE table_schema = 'ex6' AND table_name = 'cars' AND column_name = 'fuel_l_100km';
        IF typ <> 'numeric' THEN
            RETURN '🟡 Task 1.1: works, but fuel_l_100km is ' || typ || ' – an approximate type (remember 0.1 + 0.2). numeric(4,1) stores 9.4 exactly.';
        END IF;
        RETURN '✅ Task 1.1: correct! Table ex6.cars has sensible types.';

    ELSIF t = '2.1' THEN
        IF to_regclass('ex6.cars_raw') IS NULL THEN
            RETURN '❌ Task 2.1: table ex6.cars_raw does not exist – run the CREATE TABLE in ▶️ 2.b first, then import the file.';
        END IF;
        EXECUTE 'SELECT count(*), count(*) FILTER (WHERE make LIKE ''%Make''), count(model), count(fuel_l_100km) FROM ex6.cars_raw'
           INTO v_n, v_a, v_b, v_c;
        IF v_n = 0 THEN
            RETURN '❌ Task 2.1: ex6.cars_raw is empty – the import has not run yet (or it failed: look at the Processes tab in pgAdmin).';
        ELSIF v_a > 0 OR v_n = 11914 + 1 THEN
            RETURN '❌ Task 2.1: the header row was loaded as data (there is a car called "Make"). Empty the table with  TRUNCATE ex6.cars_raw;  and import again with Header switched ON.';
        ELSIF v_b = 0 THEN
            RETURN '❌ Task 2.1: everything landed in the first column – the delimiter is wrong. Open the CSV in Notepad: is it ; or , ?  TRUNCATE ex6.cars_raw;  and import again.';
        ELSIF v_n = 2 * 11914 THEN
            RETURN '❌ Task 2.1: every car is there twice – you imported the file two times.  TRUNCATE ex6.cars_raw;  and import once.';
        ELSIF v_n <> 11914 THEN
            RETURN format('❌ Task 2.1: the table has %s rows, the file has %s. TRUNCATE ex6.cars_raw; and import again (whole file, Header ON).', v_n, 11914);
        ELSIF v_c <> 11914 THEN
            RETURN '❌ Task 2.1: the last column (fuel_l_100km) is empty in some rows – did you use the file from the data/ folder? TRUNCATE ex6.cars_raw; and import again.';
        END IF;
        RETURN format('✅ Task 2.1: correct! %s rows imported, header skipped, all columns filled.', v_n);

    ELSIF t = '2.2' THEN
        IF to_regclass('ex6.cars') IS NULL THEN
            RETURN '❌ Task 2.2: table ex6.cars does not exist – solve task 1.1 first.';
        END IF;
        EXECUTE 'SELECT count(*), count(engine_hp), sum(highway_mpg), sum(fuel_l_100km), sum(msrp::numeric) FROM ex6.cars'
           INTO v_n, v_a, v_b, v_c, v_d;
        IF v_n = 0 THEN
            RETURN '❌ Task 2.2: ex6.cars is empty – the INSERT has not run yet (or it ended with an error).';
        ELSIF v_n = 2 * 11914 THEN
            RETURN '❌ Task 2.2: every car is there twice – the INSERT ran two times.  TRUNCATE ex6.cars;  and run it once.';
        ELSIF v_n <> 11914 THEN
            RETURN format('❌ Task 2.2: ex6.cars has %s rows, ex6.cars_raw has %s. Did you add a WHERE? TRUNCATE ex6.cars; and run the INSERT again.', v_n, 11914);
        ELSIF v_a <> 11845 THEN
            RETURN format('❌ Task 2.2: engine_hp has %s filled values, expected %s. Empty cells must stay NULL (unknown) – do not turn them into 0.', v_a, 11845);
        END IF;
        -- after task 5.1 (Audi A6: 354 → 34, 0.7 → 6.9) the sums are allowed to differ by exactly that fix
        IF v_b = 317359 - 354 + 34 AND v_c = 112742.7 - 0.7 + 6.9 THEN
            v_b := 317359;
            v_c := 112742.7;
        END IF;
        IF v_c IS DISTINCT FROM 112742.7 THEN
            RETURN '❌ Task 2.2: fuel_l_100km is not right. The CSV may contain 9,4 – replace the comma with a dot before the cast.';
        ELSIF v_b IS DISTINCT FROM 317359 OR v_d IS DISTINCT FROM 483645697 THEN
            RETURN '❌ Task 2.2: the numbers in highway_mpg or msrp do not match the file. Is every column taken from the right raw column?';
        ELSIF in_tx THEN
            RETURN '🟡 Task 2.2: the data is right, but you are inside an open transaction – run COMMIT; so that it is saved.';
        END IF;
        RETURN format('✅ Task 2.2: correct! %s cars with proper types – empty cells stayed NULL.', v_n);

    ELSIF t = '5.1' THEN
        IF to_regclass('ex6.cars') IS NULL THEN
            RETURN '❌ Task 5.1: table ex6.cars does not exist – solve tasks 1.1 and 2.2 first.';
        END IF;
        EXECUTE 'SELECT count(*) FILTER (WHERE highway_mpg > 150),
                        count(*) FILTER (WHERE make = ''Audi'' AND model = ''A6'' AND year = 2017 AND driven_wheels = ''front wheel drive''
                                           AND highway_mpg = 34 AND fuel_l_100km = 6.9),
                        count(*)
                 FROM ex6.cars' INTO v_a, v_b, v_n;
        SELECT count(*) INTO v_c
        FROM pg_constraint
        WHERE conrelid = 'ex6.cars'::regclass AND contype = 'c' AND pg_get_constraintdef(oid) LIKE '%highway_mpg%';
        IF v_a > 0 THEN
            RETURN '❌ Task 5.1: there is still a car with highway_mpg above 150. Did the UPDATE find the row (look at "UPDATE 1" in Messages)?';
        ELSIF v_b <> 2 THEN
            RETURN '❌ Task 5.1: the Audi A6 row is not fixed as expected: highway_mpg should be 34 (like its twin row) and fuel_l_100km 6.9 (235.215 / 34, rounded to 1 decimal).';
        ELSIF v_n <> 11914 THEN
            RETURN format('❌ Task 5.1: ex6.cars has %s rows instead of %s – fix the value, do not delete the row.', v_n, 11914);
        ELSIF v_c = 0 THEN
            RETURN '❌ Task 5.1: the value is fixed, but the CHECK constraint on highway_mpg is missing – run the ALTER TABLE … ADD CONSTRAINT.';
        ELSIF in_tx THEN
            RETURN '🟡 Task 5.1: everything is right, but the transaction is still open – run COMMIT; (until then nobody else sees the fix).';
        END IF;
        RETURN '✅ Task 5.1: correct! The error is fixed, the rule is in place and the transaction is committed.';

    ELSIF t IN ('5.2', '5.3') THEN
        IF to_regclass('ex6.cars') IS NULL THEN
            RETURN '❌ Task ' || t || ': table ex6.cars does not exist – solve tasks 1.1 and 2.2 first.';
        END IF;
        EXECUTE 'SELECT count(*), min(msrp), max(msrp) FROM ex6.cars' INTO v_n, v_a, v_b;
        IF t = '5.2' THEN
            IF NOT in_tx THEN
                IF v_b = 2065902 THEN
                    RETURN '❌ Task 5.2: no open transaction with changes. Run BEGIN; and both UPDATEs first – in this same Query Tool.';
                END IF;
                RETURN '❌ Task 5.2: the prices are changed, but there is no open transaction – they were committed! Restore the data: TRUNCATE ex6.cars; run the INSERT from task 2.2 and the fix from 5.1 again.';
            ELSIF v_n <> 11914 THEN
                RETURN format('❌ Task 5.2: ex6.cars has %s rows – capping changes values, it does not delete rows. Run ROLLBACK; and try again.', v_n);
            ELSIF v_b = 2065902 THEN
                RETURN '❌ Task 5.2: the most expensive car still costs ' || 2065902 || ' – the capping UPDATE (90th percentile) has not run yet.';
            ELSIF v_b <> 65080 THEN
                RETURN format('❌ Task 5.2: after capping the highest price should be the 90th percentile (%s), it is %s.', 65080, v_b);
            ELSIF v_a = 2000 THEN
                RETURN '❌ Task 5.2: the capping is right, but the flooring UPDATE (10th percentile) has not run yet.';
            ELSIF v_a NOT IN (floor(2254.6), ceil(2254.6)) THEN
                RETURN format('❌ Task 5.2: after flooring the lowest price should be the 10th percentile (%s, rounded to a whole number), it is %s.', 2254.6, v_a);
            END IF;
            RETURN format('✅ Task 5.2: correct! Inside the transaction prices run from %s to %s. Now go on to 5.3 – do NOT commit.', v_a, v_b);
        ELSE
            IF in_tx THEN
                RETURN '❌ Task 5.3: the transaction is still open – run ROLLBACK; first.';
            ELSIF v_n = 11914 AND v_a = 2000 AND v_b = 2065902 THEN
                RETURN '✅ Task 5.3: correct! ROLLBACK undid both UPDATEs – the original prices are back (atomicity).';
            END IF;
            RETURN '❌ Task 5.3: the prices are not the original ones – the capping was committed. Restore the data: TRUNCATE ex6.cars; run the INSERT from task 2.2 and the fix from 5.1 again.';
        END IF;

    ELSIF t IN ('6.1', '6.2') THEN
        IF to_regclass('ex6.fuel_log') IS NULL THEN
            RETURN '❌ Task ' || t || ': table ex6.fuel_log does not exist – run ▶️ 6.a first.';
        END IF;
        IF t = '6.1' THEN
            SELECT count(*) INTO v_n
            FROM pg_index i
            JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = i.indkey[0]
            WHERE i.indrelid = 'ex6.fuel_log'::regclass AND a.attname = 'plate';
            IF v_n = 0 THEN
                SELECT string_agg(pg_get_indexdef(indexrelid), E'\n   ') INTO msg
                FROM pg_index WHERE indrelid = 'ex6.fuel_log'::regclass AND NOT indisprimary;
                IF msg IS NOT NULL THEN
                    RETURN E'❌ Task 6.1: there is an index, but not on the column the queries search by (WHERE plate = …):\n   ' || msg;
                END IF;
                RETURN '❌ Task 6.1: there is no index on ex6.fuel_log(plate) yet. Hint: CREATE INDEX name ON table (column);';
            END IF;
            RETURN '✅ Task 6.1: correct! There is an index on plate – run ▶️ 6.c and compare the plans.';
        ELSE
            SELECT count(*) INTO v_n
            FROM pg_index
            WHERE indrelid = 'ex6.fuel_log'::regclass AND pg_get_indexdef(indexrelid) ILIKE '%lower(plate)%';
            IF v_n = 0 THEN
                RETURN '❌ Task 6.2: no index on lower(plate) yet. An index on an expression needs extra parentheses: ON table ((lower(column)));';
            END IF;
            RETURN '✅ Task 6.2: correct! There is an index on lower(plate) – run the EXPLAIN ANALYZE again.';
        END IF;
    END IF;

    -- ---------------------------------------------------------------- tasks checked by comparing your query's result
    SELECT * INTO e
    FROM (VALUES
        ('0', 1, '1b8304b52df9c4def66b259b67cbabe6', NULL),
        ('3.1', 2, '54c084944c43792c036526340ec26047', NULL),
        ('3.2', 18, '089c7c8c9f1bc363505235b5f871deb8', '2ad165c04d659b844584cce05659d50d'),
        ('4.1', 1, 'dd486d8f98569f3614af4fa9101f44ef', NULL),
        ('4.2', 5, '814b47ce291d11684f158047f9c3dc19', '11ea4aa1349780268341bf3e998b58b1'),
        ('4.4', 5, '03a7ad88ea279546cc6c73462939066c', '3b18d28c2e5b13b3027ea1f2ea6eab41')
    ) AS v(label, n_rows, hash_sorted, hash_ordered)
    WHERE v.label = t;

    IF NOT FOUND THEN
        RETURN '⚠️ There is no task ' || coalesce(task, 'NULL') || '. Labels look like ''3.1''.';
    END IF;

    q := regexp_replace(coalesce(query, ''), ';\s*$', '');          -- a semicolon at the end is fine
    IF btrim(regexp_replace(q, '--[^\n]*', '', 'g'), E' \t\r\n') = '' THEN
        RETURN '✏️ Task ' || t || ': there is no query between $$ and $$ yet.';
    END IF;

    BEGIN
        -- numbers are compared without trailing zeros (22.0 = 22, 9.40 = 9.4), so integer / numeric / rounding style does not matter
        EXECUTE format($q$SELECT count(*), md5(coalesce(string_agg(r, E'\n' ORDER BY r COLLATE "C"), '')),
       md5(coalesce(string_agg(r, E'\n' ORDER BY rn), ''))
FROM (SELECT regexp_replace(regexp_replace(t::text, '(\.[0-9]*?)0+(?=[^0-9]|$)', '\1', 'g'), '([0-9])\.(?=[^0-9]|$)', '\1', 'g') AS r,
             row_number() OVER () AS rn
      FROM (%s
) t) x$q$, q) INTO n, h, hr;
    EXCEPTION WHEN OTHERS THEN
        RETURN '❌ Task ' || t || ': the query returns an error – ' || SQLERRM;
    END;

    IF n <> e.n_rows THEN
        RETURN format('❌ Task %s: the query returns %s rows, expected %s. Check the conditions (WHERE) and LIMIT.',
                      t, n, e.n_rows);
    ELSIF h <> e.hash_sorted THEN
        RETURN format('❌ Task %s: the number of rows is right (%s), but the values are not. Check the columns (exactly those from the task, in that order), the conditions and the rounding.',
                      t, n);
    ELSIF e.hash_ordered IS NOT NULL AND hr <> e.hash_ordered THEN
        RETURN '🟡 Task ' || t || ': the rows are right, but the order is not. Check ORDER BY (ASC / DESC, and the second sort column).';
    END IF;
    RETURN '✅ Task ' || t || ': correct!';
END
$fn$;

SELECT '✅ Schema ex6 and function check_task are ready.' AS message;
