-- ⭐ TASK 7 (optional, exam-style): countries with at least 3 sign-ups.
--    * columns country, signups – in this order,
--    * only countries with 3 or more sign-ups (all channels together),
--    * read from a model of this project with ref(...) – which one is your choice; can you explain it?

select null::text   as country,
       0::bigint    as signups
where false   -- placeholder: returns no rows
