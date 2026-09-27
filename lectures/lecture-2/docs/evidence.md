# Evidence

This file contains representative evidence from the Lecture 2 integrity work.

## Successful writes

The integrity migration was applied successfully and the positive test script completed without constraint violations.

Executed from `lectures/lecture-2`:

```cmd
docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U mobility -d mobility < database\postgres\experiments\constraints_should_succeed.sql
```

Representative output:

```text
UPDATE 1
INSERT 0 1
INSERT 0 1
INSERT 0 1
```

This verifies that valid trip, ticket, payment and validation operations are accepted after the constraints are introduced.

---

## Rejected writes

The negative test suite was executed with:

```cmd
docker compose exec -T postgres psql -U mobility -d mobility < database\postgres\experiments\constraints_should_fail.sql
```

All 10 intentionally invalid writes were rejected by the database.

The tests cover:

1. Negative trip capacity
2. Reserved seats greater than capacity
3. Ticket referencing an unknown trip
4. Ticket validity ending before it starts
5. Duplicate ticket code
6. Unknown ticket status
7. Negative product price
8. Payment referencing an unknown ticket
9. Duplicate external payment reference
10. Validation using a ticket id and ticket code that belong to different tickets

---

## Rule 1: validation must identify one real ticket

A validation contains both:

- `ticket_id`
- `ticket_code`

It is not enough for both values to exist independently. They must belong to the same ticket.

The rule is enforced with:

```sql
unique (id, ticket_code)
```

on `tickets`, together with:

```sql
foreign key (ticket_id, ticket_code)
references tickets(id, ticket_code)
```

on `validations`.

### Valid write

A validation using the correct id/code pair is accepted.

```text
INSERT 0 1
```

### Rejected write

A validation that combines the id of one ticket with the code of another is rejected by the composite foreign key.

This prevents a structurally valid but semantically inconsistent ticket reference.

---

## Rule 2: external payment references must be unique

The payment gateway reference is protected by:

```sql
unique (external_payment_reference)
```

### Valid write

A payment with a new external payment reference is accepted.

```text
INSERT 0 1
```

### Rejected write

A second payment using the same external payment reference is rejected by the unique constraint.

This protects against duplicate delivery of the same logical external payment.

---

## Boundary: what the constraints do not guarantee

The database guarantees:

```text
reserved_seats <= capacity
```

for a stored trip row.

However, this does not by itself guarantee that two concurrent purchase transactions cannot race when reserving the final available seat.

For example:

```text
Transaction A reads 1 seat available
Transaction B reads 1 seat available
```

A complete solution may require transaction-level locking or an atomic seat-reservation operation.

This is therefore a transaction/workflow concern in addition to a row-level integrity concern.

---

## Reproduction

Rebuild the database:

```cmd
docker compose down -v
docker compose up -d
```

Apply the integrity migration:

```cmd
docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U mobility -d mobility < database\postgres\migrations\011_ticketing_integrity.sql
```

Run successful writes:

```cmd
docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U mobility -d mobility < database\postgres\experiments\constraints_should_succeed.sql
```

Run rejected writes:

```cmd
docker compose exec -T postgres psql -U mobility -d mobility < database\postgres\experiments\constraints_should_fail.sql
```