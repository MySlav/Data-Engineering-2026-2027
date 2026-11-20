-- Silver layer: cleaned sign-ups – the same as the view silver.customer_signup of Exercise 4.
-- A dbt model is only a SELECT. dbt itself wraps it into
--     CREATE VIEW ex8_silver.customer_signup AS <this SELECT>
-- and source('bronze', 'customer_signup') below tells dbt where the data comes from (raw.customer_signup).

select
       -- 🧩 TASK 3a (uniqueness): a few rows were loaded twice – keep each row only once
       regexp_replace(trim(full_name), '\s+', ' ', 'g') as full_name,
       lower(trim(email))                               as email,
       initcap(trim(city))                              as city,
       -- 🧩 TASK 3b (consistency): Croatia is written as Croatia, croatia, HR, Hrvatska and CRO – make it always 'Croatia'
       initcap(trim(country))                           as country,
       lower(channel)                                   as channel,
       signup_date                                      as signup_date_raw   -- dates are parsed later in the course
from {{ source('bronze', 'customer_signup') }}
-- 🧩 TASK 3c (validity, completeness): keep only rows with a valid e-mail and a name, and drop the test record
