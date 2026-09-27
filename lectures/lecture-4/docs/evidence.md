# Evidence

This file contains representative evidence from the Lecture 4 schema migration from `tickets.product_code` to `tickets.product_id`.

## Baseline before migration

The baseline contained at least two products and at least three tickets using more than one product.

Representative ticket state before migration:

```text
TICKET-1 | SINGLE | 36.00 | DKK
TICKET-2 | SINGLE | 36.00 | DKK
TICKET-3 | DAY    | 65.00 | DKK
```

The baseline integrity check:

```sql
select t.id, t.product_code
from tickets t
left join products p on p.code = t.product_code
where t.product_code is null or p.code is null;
```

returned:

```text
(0 rows)
```

This verified that every existing ticket referenced a real product before the migration started.

---

## Unsafe migration experiment

A deliberately unsafe migration was tested first:

```sql
begin;

alter table tickets
    drop column product_code;

alter table tickets
    add column product_id uuid not null;

rollback;
```

This fails because existing ticket rows do not yet have values for the new required `product_id`.

The experiment demonstrates why a populated database cannot safely replace an old required reference with a new required reference in one destructive step.

It would also break old readers and writers that still expect `tickets.product_code`.

The database was reset before continuing with the proper migration.

---

## Expand migration

The first real migration added a stable UUID identity to products and introduced `tickets.product_id` without removing `product_code`.

After the migration:

```text
products:
code + id

tickets:
product_code + nullable product_id
```

Every product received a UUID.

Existing tickets still had their original `product_code`, while `product_id` remained nullable until backfill.

This allowed old code to continue working during the migration.

---

## Compatibility overlap

During the overlap period, both old and new access patterns were tested.

### Old writer

The old writer inserted a ticket using only:

```text
product_code
```

The insert succeeded.

### Old reader

The old reader continued to read tickets through `product_code`.

### New reader

The new reader resolved a product using:

```sql
coalesce(p_new.id, p_old.id)
```

This allowed it to read:

- new tickets that already had `product_id`
- old tickets that still only had `product_code`

### New writer

The new writer accepted a `product_id` and derived the corresponding `product_code` from the same `products` row during the overlap period.

This prevented the writer from accepting an unrelated product code from the caller.

The test also highlighted an important distinction:

- the writer logic prevented mismatched code/id values;
- separate database foreign keys did not automatically guarantee that both references described the same product row.

---

## Backfill

Existing tickets were migrated with:

```sql
update tickets t
set product_id = p.id
from products p
where t.product_id is null
  and p.code = t.product_code;
```

The first run updated the existing old-style rows.

The second run returned:

```text
UPDATE 0
```

This demonstrated that the backfill is safe to rerun.

---

## Late old-writer ticket

After the first backfill, the old writer was used again to create:

```text
LAB04-OLD-LATE
```

The row initially had:

```text
product_code = SINGLE
product_id   = NULL
```

The backfill was run again and returned:

```text
UPDATE 1
```

The late ticket then received the correct `product_id`.

This demonstrates why a migration backfill should be rerunnable while old application instances may still be writing old-style rows.

---

## Verification before requiring product_id

The verification query checked for:

- missing `product_id`
- unknown product IDs
- mismatch between `product_code` and the product referenced by `product_id`

```sql
select t.id, t.product_code, t.product_id
from tickets t
left join products p on p.id = t.product_id
where t.product_id is null
   or p.id is null
   or t.product_code is distinct from p.code;
```

When the migration was ready to continue, this returned:

```text
(0 rows)
```

---

## Deliberate NOT NULL failure

Before making `product_id` required, a blocker ticket was deliberately created without `product_id`.

The migration:

```sql
alter table tickets
    validate constraint tickets_product_id_fk;

alter table tickets
    alter column product_id set not null;
```

failed as expected because a row still had `product_id = NULL`.

The row was then repaired by rerunning the backfill.

Verification again returned:

```text
(0 rows)
```

The migration was rerun successfully, making:

```text
tickets.product_id NOT NULL
```

This demonstrates that the database prevented the contract phase while invalid data still existed.

---

## Dependency checks before removing product_code

Before dropping `tickets.product_code`, the database was checked for active views and functions using the column.

The view check returned:

```text
(0 rows)
```

The function check returned:

```text
(0 rows)
```

Repository searches still found `product_code` in historical migration scripts, old readers/writers, baseline checks and documentation. These files are intentionally retained as migration evidence.

No `CASCADE` was used when removing the old column.

---

## Removing the legacy reference

After readers and writers were moved to the new product identity, the old ticket reference was removed:

```sql
alter table tickets
    drop column product_code;
```

The operation completed successfully.

`products.code` remains available as a business-facing catalogue code, but tickets now reference products only through:

```text
tickets.product_id -> products.id
```

---

## Final verification

The final verification query joined tickets to products only through `product_id`.

Representative output:

```text
       id       |              product_id              | product_code | price | currency
----------------+--------------------------------------+--------------+-------+----------
 LAB04-BLOCKER  | e71122f1-a15b-4c9d-9864-8a62adfff043 | SINGLE       | 36.00 | DKK
 LAB04-NEW-1    | e71122f1-a15b-4c9d-9864-8a62adfff043 | SINGLE       | 36    | DKK
 LAB04-OLD-1    | e71122f1-a15b-4c9d-9864-8a62adfff043 | SINGLE       | 36.00 | DKK
 LAB04-OLD-LATE | e71122f1-a15b-4c9d-9864-8a62adfff043 | SINGLE       | 36.00 | DKK
 TICKET-1       | e71122f1-a15b-4c9d-9864-8a62adfff043 | SINGLE       | 36.00 | DKK
 TICKET-2       | e71122f1-a15b-4c9d-9864-8a62adfff043 | SINGLE       | 36.00 | DKK
 TICKET-3       | f41464fe-fa13-49af-8f03-472e3d21b3c9 | DAY          | 65.00 | DKK
```

All tickets that reference `SINGLE` share the same `product_id`, while `TICKET-3`, which references `DAY`, has a different product ID.

The original ticket values were preserved:

```text
TICKET-1 -> SINGLE -> 36.00 DKK
TICKET-2 -> SINGLE -> 36.00 DKK
TICKET-3 -> DAY    -> 65.00 DKK
```

The migration changed how tickets identify products, but did not change historical ticket prices or currencies.

---

## Migration result

The complete migration path demonstrated:

```text
old schema
    ->
expand with product_id
    ->
old and new readers/writers overlap
    ->
backfill existing tickets
    ->
late old-writer ticket
    ->
rerun backfill
    ->
verification
    ->
require product_id
    ->
dependency checks
    ->
remove product_code
    ->
final verification
```

The final authority relationship is:

```text
tickets.product_id -> products.id
```

while `products.code` remains available as a business-facing code.