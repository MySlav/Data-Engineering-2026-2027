-- Singular test (validity): every e-mail in Silver must look like an e-mail.
-- A test is a SELECT that returns the BAD rows: it passes when it returns no rows.
select email
from {{ ref('customer_signup') }}
where email !~* '^[^@\s]+@[^@\s]+\.[a-z]{2,}$'
