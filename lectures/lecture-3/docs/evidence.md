# Evidence

This file contains representative evidence from the Lecture 3 SQL programmability and reporting experiment.

## Reporting baseline

The reference reporting query reads directly from the base tables:

- `payments`
- `tickets`
- `trips`
- `routes`

Only payments with status `Captured` are included.

Initial baseline:

```text
 operator_id | revenue_date | captured_amount | captured_payments
-------------+--------------+-----------------+-------------------
 OP-BUS      | 2026-04-29   | 36              | 1
 OP-METRO    | 2026-04-29   | 36              | 1
```

The SQL function returned the same result for `OP-METRO`:

```sql
select *
from captured_revenue_for_day(
    'OP-METRO',
    date '2026-04-29'
);
```

Result:

```text
 captured_amount | captured_payments
-----------------+-------------------
 36              | 1
```

The materialized view was then refreshed:

```sql
refresh materialized view daily_captured_revenue;
```

After refresh, the materialized view matched the base-table result.

---

## Stale materialized view example

A new captured payment was inserted for `OP-METRO`:

```sql
insert into payments (
    id,
    user_id,
    ticket_id,
    external_payment_reference,
    amount,
    currency,
    status,
    created_utc
) values (
    'PAY-CASE-CAPTURED',
    'USER-1',
    'TICKET-1',
    'gateway-case-captured',
    36,
    'DKK',
    'Captured',
    '2026-04-29 10:00:00+00'
);
```

The SQL function immediately reflected the new base-table state:

```sql
select *
from captured_revenue_for_day(
    'OP-METRO',
    date '2026-04-29'
);
```

Result:

```text
 captured_amount | captured_payments
-----------------+-------------------
 72              | 2
```

The materialized view still returned the old result:

```text
 captured_amount | captured_payments
-----------------+-------------------
 36              | 1
```

This demonstrates a stale reporting result:

```text
SQL function:      72 / 2
Materialized view: 36 / 1
```

The disagreement exists because the SQL function reads current base-table state, while the materialized view stores the result from its previous refresh.

---

## Correcting the stale result

After running:

```sql
refresh materialized view daily_captured_revenue;
```

the materialized view returned:

```text
 captured_amount | captured_payments
-----------------+-------------------
 72              | 2
```

The materialized view was therefore synchronized with the authoritative base data again.

---

## Trigger-maintained summary observation

The supplied trigger is defined for:

```sql
AFTER INSERT ON payments
```

and only adds a payment when its new status is `Captured`.

This gives immediate summary updates for supported captured inserts, but it does not automatically handle all correction paths.

For example, a payment inserted as `Failed` and later updated to `Captured` is an `UPDATE`, not an `INSERT`. The supplied trigger therefore does not update the summary for that correction.

The trigger-maintained summary also starts without historical data unless an explicit backfill or rebuild operation is performed.

---

## Side-effect trace for one captured payment insert

A captured payment insert can cause the following work:

```text
INSERT into payments
    ->
AFTER INSERT trigger fires
    ->
trigger checks payment status
    ->
ticket/trip/route data is read to determine operator
    ->
daily_revenue_by_operator is inserted or updated
    ->
payment write and summary write complete in the same transaction
```

The direct query and SQL function cause no additional write-side effect.

The materialized view is not updated by the payment insert and only changes when explicitly refreshed.

---

## Reproduction

From `lectures/lecture-3`:

```cmd
docker compose down -v
docker compose up -d
```

Apply the reporting function:

```cmd
docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U mobility -d mobility < database\postgres\migrations\020_reporting_function.sql
```

Apply the trigger-maintained summary:

```cmd
docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U mobility -d mobility < database\postgres\migrations\021_daily_revenue_trigger.sql
```

Apply the materialized view:

```cmd
docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U mobility -d mobility < database\postgres\migrations\022_daily_captured_revenue.sql
```

The reference query is located at:

```text
database/postgres/queries/base_revenue.sql
```