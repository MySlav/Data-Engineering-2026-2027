-- Gold layer: the number of sign-ups per country and channel – a business-ready aggregate.
--
-- 🧩 TASK 4: replace the placeholder query below with your own SELECT:
--    * columns country, channel, signups (the number of sign-ups) – in this order,
--    * one row per country and channel,
--    * read from the Silver model with  ref('customer_signup')  in double curly braces
--      (like source(...) in the Silver model) – never from raw.customer_signup directly.

select null::text   as country,
       null::text   as channel,
       0::bigint    as signups
where false   -- placeholder: returns no rows
