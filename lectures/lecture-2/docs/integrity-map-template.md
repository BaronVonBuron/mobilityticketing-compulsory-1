# Integrity map

| Invariant | Affected tables and columns | Current protection | Missing protection or limitation | Expected failure behaviour | Evidence |
| --- | --- | --- | --- | --- | --- |
| Trip capacity cannot be negative | `trips.capacity` | `CHECK (capacity >= 0)` | Does not handle concurrent booking races | Invalid update/insert is rejected | `constraints_should_fail.sql` |
| Reserved seats must be between 0 and capacity | `trips.reserved_seats`, `trips.capacity` | `CHECK (reserved_seats BETWEEN 0 AND capacity)` | Does not prevent two concurrent purchases from overselling | Invalid update is rejected | `constraints_should_fail.sql` |
| Product and ticket prices cannot be negative | `products.price`, `tickets.price` | `CHECK (price >= 0)` | Does not guarantee that ticket price still matches current product price | Invalid insert/update is rejected | Migration + fail tests |
| Payment amount cannot be negative | `payments.amount` | `CHECK (amount >= 0)` | Does not guarantee that payment amount equals ticket price | Invalid payment is rejected | Migration + fail tests |
| Currency must use a consistent representation | `products.currency`, `tickets.currency`, `payments.currency` | `NOT NULL` and three-uppercase-letter format check | Does not verify that the currency is an actually supported ISO currency | Missing/malformed value is rejected | Migration |
| Ticket codes must be unique | `tickets.ticket_code` | `UNIQUE (ticket_code)` | Does not define lifecycle/reuse rules for old ticket codes | Duplicate code is rejected | Fail test |
| Ticket must refer to an existing user, trip and product | `tickets.user_id`, `tickets.trip_id`, `tickets.product_code` | Foreign keys | Does not determine whether the user is allowed to purchase or whether the product is valid for that trip | Unknown references are rejected | Positive + negative tests |
| Ticket validity must not end before it starts | `tickets.valid_from_utc`, `tickets.valid_to_utc` | `CHECK (valid_to_utc >= valid_from_utc)` | Does not decide maximum/minimum validity duration | Invalid validity interval is rejected | Fail test |
| Ticket status must come from the known set | `tickets.status` | `CHECK` constraint | New domain statuses require a schema migration | Unknown status is rejected | Fail test |
| Payment must refer to an existing ticket and user | `payments.ticket_id`, `payments.user_id` | Foreign keys | Does not guarantee that the payment user matches the ticket user | Unknown references are rejected | Positive + negative tests |
| External payment reference must not be duplicated | `payments.external_payment_reference` | `UNIQUE` constraint | Assumes one external reference identifies one logical payment globally | Duplicate reference is rejected | Fail test |
| Payment status must come from the known set | `payments.status` | `CHECK` constraint | Allowed status transitions are not enforced | Unknown status is rejected | Migration |
| Validation must refer to a real stop | `validations.stop_id` | Foreign key | `stop_id` may be nullable depending on domain requirements | Unknown stop is rejected when supplied | Migration |
| Validation must refer to the same ticket by both id and code | `validations.ticket_id`, `validations.ticket_code` | Composite FK to `tickets(id, ticket_code)` | Requires the additional unique key on `(id, ticket_code)` | Mismatched id/code pair is rejected | Fail test |
| Validation result must come from the known set | `validations.result` | `CHECK` constraint | Does not define the workflow that produces the result | Unknown result is rejected | Migration |

## Issue register

### Issue 1

- Evidence: `reserved_seats <= capacity` is enforced only within a single trip row.
- Problem: Two concurrent purchase transactions may both observe available capacity and attempt to reserve the same final seat.
- Consequence: Row-level integrity rules alone do not define the complete booking workflow.
- Specific improvement: Use transaction-level locking or an atomic seat-reservation operation in the transaction design.
- Open question: Should overselling always be prevented, or can some transport products intentionally allow it?

### Issue 2

- Evidence: `payments.ticket_id` and `payments.amount` are constrained individually.
- Problem: The database does not currently guarantee that a payment amount and currency match the referenced ticket price and currency.
- Consequence: A structurally valid payment could still represent the wrong commercial amount.
- Specific improvement: Define the payment capture workflow and decide whether this relationship belongs in database logic, transaction logic, or reconciliation.
- Open question: How should partial payments, discounts, refunds and currency conversion be represented?

## State-transition trace

### Ticket purchase

1. The referenced `users`, `trips` and `products` rows must already exist.
2. A new `tickets` row is inserted with valid status, validity period, price, currency and references.
3. A `payments` row may then be inserted referencing the ticket and user; its external payment reference must be unique.

The database currently protects row shape and referential integrity, but it does not by itself define the complete external payment workflow or solve concurrent capacity allocation.

### Ticket validation

1. The ticket must already exist and have a valid `(id, ticket_code)` combination.
2. If a stop is recorded, the referenced stop must exist.
3. A `validations` row is inserted with a known validation result.

The composite foreign key prevents a validation from combining the ID of one ticket with the code of another.