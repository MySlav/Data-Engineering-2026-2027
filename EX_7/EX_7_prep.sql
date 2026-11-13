-- =====================================================================================
--  Data Engineering – Exercise 7: PREPARATION   (run ONCE, in database transactional)
-- =====================================================================================
--  pgAdmin: Servers → Algebra Bernays - Data Engineering → Databases → transactional
--           → right-click → Query Tool → paste this whole file → F5.
--  Result: the message "✅ Schema ex7 and function ex7.check_task are ready."
--
--  Creates
--    • schema ex7 – for the function and for the small table of section 7 (the shop in schema public is not touched),
--    • function ex7.check_task(task, query) – runs your query and compares its result with the expected one.
--      Only summaries (md5) are compared – the solutions are not stored here. The function only reads data.
--  The function check_task of Exercise 6 (schema public) is a different one and keeps working.
--  Running this file again does no harm. To remove everything:  DROP SCHEMA ex7 CASCADE;
-- =====================================================================================

DO $$
BEGIN
    IF current_database() <> 'transactional' THEN
        RAISE EXCEPTION 'You are connected to database "%". Open the Query Tool on database transactional and run this file again.', current_database();
    END IF;
    IF to_regclass('public.customer') IS NULL OR to_regclass('public.customer_order') IS NULL THEN
        RAISE EXCEPTION 'The shop tables (customer, customer_order …) are missing in schema public. Is this the SQL pod of the course? See environment/README.md.';
    END IF;
END
$$;

CREATE SCHEMA IF NOT EXISTS ex7;
COMMENT ON SCHEMA ex7 IS 'Exercise 7 – SQL basics';

CREATE OR REPLACE FUNCTION ex7.check_task(task text, query text)
RETURNS text
LANGUAGE plpgsql
AS $fn$
DECLARE
    t    text := trim(coalesce(task, ''));
    q    text;
    n    bigint;
    h    text;
    hr   text;
    e    record;
BEGIN
    SELECT * INTO e
    FROM (VALUES
        ('0', 1, '38ea01c685fc40086150aa5dd65e7b79', NULL),
        ('1.1', 50, '76471a1409fce18e9de81b4f4121ca6a', NULL),
        ('1.2', 3, '64ae4f24956d7fa1c131100e60cdcab2', NULL),
        ('1.3', 11, 'ef665ea8a627f57a241b447b87d869e7', NULL),
        ('2.1', 11, 'ac844c498f65771cbe3efbf5df87d19e', NULL),
        ('2.2', 61, '28cbd129ecee96dc753f9c6a11e81fa4', NULL),
        ('2.3', 16, 'bfd6abc012e0476e21b25cd762ac1398', NULL),
        ('2.4', 25, '9052020eafaa6b7cb1a932fb74643fa5', NULL),
        ('3.1', 11, '5ceaa21510c0d92e2ef1f9a8b6c60009', NULL),
        ('3.2', 6, '8dec9ab10f2577e73db64c4f5af25d29', NULL),
        ('3.3', 34, '6d266b632dc01cefb0059f124a9102b6', NULL),
        ('3.4', 9, 'b73e0d1caa20ee0d70b8cc393d78d266', NULL),
        ('3.5', 19, '09623c994ab45c4635707b0352f83f76', NULL),
        ('3.6', 51, '7541539f0ed7bc15ab8cfeb13831fc4b', NULL),
        ('4.1', 4, 'a618b83cd82757c49ebff1189225bc7d', 'b50395b311cfd09a8935159238a81fcf'),
        ('4.2', 5, '7a0255631ee199fe1ae40af9e3380a57', '1fdd15a1a6d1521a00d90d9d48c709a2'),
        ('4.3', 10, '5749215595022cdb4f91773722289c85', '1813f1ef53f0c6ede36c0232bd40ba0f'),
        ('4.4', 27, '24bc910a464ea773f3ac61981c25a0d5', '5dabe02915f21319143ed7bbcb78f122'),
        ('5.1', 1, '30e287b4840e867a328192575dd3b754', NULL),
        ('5.2', 1, '014cd1c62a0b15f113e77e3ddfac85b2', NULL),
        ('5.3', 1, '96524a14953cadf72fcad807cc34cfcd', NULL),
        ('5.4', 1, '6d2d266a47b5fc0a1dea0f4e597d023b', NULL),
        ('6.1', 3, '0ce2271d66b6ceaa2243ef5ae6f0a184', NULL),
        ('6.2', 9, 'd6dfe015ce9b1054b014c98b559adcbf', '3cf2951b36b5baeea141cafc81d348e0'),
        ('6.3', 7, 'd30d457fa2a57280bbbc3c25022adcf0', NULL),
        ('6.4', 3, '67ebb2b3d60f7e03db9fa777746698a6', '67ebb2b3d60f7e03db9fa777746698a6'),
        ('6.5', 4, '483d27b03cef57ca8d944cd6cb467e03', '1e0d0606a5ae9ed4f76a964c1183e01b'),
        ('6.6', 1, '8f484fe6b800237a09663095998e5a4c', NULL),
        ('6.7', 4, '62fa22cb10d70027306c60be4e660b5b', NULL),
        ('8.1', 14, 'f1feb41a96885327daa1d0be5f9e5749', '0f8e190b1e8960c25ac092890b9084d5'),
        ('8.2', 1, 'ce2f598c391afb936596284b1f1a0f6b', NULL),
        ('8.3', 4, 'afe07737a718e703a46c3cafea7a121e', NULL),
        ('8.4', 3, 'a311693699863442c161c372ed6ef1dc', '7646e92659d56ad536fc56fc3dcdec64'),
        ('8.5', 17, '12a708b84f466f64fc7b7178707f5dd0', '6cb491b6d0c04375c739b8f13532e6e6')
    ) AS v(label, n_rows, hash_sorted, hash_ordered)
    WHERE v.label = t;

    IF NOT FOUND THEN
        RETURN '⚠️ There is no task ' || coalesce(task, 'NULL') || '. Labels look like ''2.1''.';
    END IF;

    q := regexp_replace(coalesce(query, ''), ';\s*$', '');          -- a semicolon at the end is fine
    IF btrim(regexp_replace(q, '--[^\n]*', '', 'g'), E' \t\r\n') = '' THEN
        RETURN '✏️ Task ' || t || ': there is no query between $$ and $$ yet.';
    END IF;

    BEGIN
        -- numbers are compared without trailing zeros (22.50 = 22.5, 3.0 = 3), so the rounding style does not matter
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
        RETURN format('❌ Task %s: the query returns %s rows, expected %s. Check the conditions (WHERE, HAVING), DISTINCT and LIMIT.',
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

SELECT '✅ Schema ex7 and function ex7.check_task are ready.' AS message;
