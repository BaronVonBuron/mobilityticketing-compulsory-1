# Compulsory assignment 1 - review guide
This repository contains our work from the first four database lectures. Each lecture folder contains the SQL implementation, experiments, documentaion and evidence for the corresponding week.

## Setup and reset instructions
Each lecture contains its own compose.yml and can be run separately.
Run docker compose down -v and docker compose up -d from the relevant folder.
PostgreSQL is available on localhost:5432 using: Database: mobility
                                                 Username: mobility
                                                 Password: mobility

The docs/evidence.md file for each lecture contains results from the implementation and instructions for reproducing the relevant experiments.

## Where to find the work

### Lecture 1 - Into to db
[Workloadmap](lectures/lecture-1/docs/workload-map.md)
[ER diagram](lectures/lecture-1/docs/er-diagram.md)
[Relational schema](lectures/lecture-1/database/postgres/001_relational_baseline.sql)
[Seed data](lectures/lecture-1/database/postgres/002_seed.sql)
[Workload queries](lectures/lecture-1/database/postgres/queries/003_queries.sql)
[Evidence and query results](lectures/lecture-1/docs/evidence.md)
[Modeling notes](lectures/lecture-1/docs/notes.md)

The workload queries include upcoming trips for a route, ordered stops for a route and trip counts per route, including routes with no trips.

### Lecture 2 - SQL operations
[Integrity map](lectures/lecture-2/docs/integrity-map-template.md)
[Constraint migration](lectures/lecture-2/database/postgres/migrations/011_ticketing_integrity.sql)
[Successful write tests](lectures/lecture-2/database/postgres/experiments/constraints_should_succeed.sql)
[Rejected write tests](lectures/lecture-2/database/postgres/experiments/constraints_should_fail.sql)
[Evidence](lectures/lecture-2/docs/evidence.md)

The experiments demonstrate both accepted and rejected writes and identify the database constraints responsible for enforcing the rules.

### LEcture 3 - SQL programmability
[Base reposrting query](lectures/lecture-3/database/postgres/queries/base_revenue.sql)
[Reporting migrations](lectures/lecture-3/database/postgres/migrations)
[Reporting experiments](lectures/lecture-3/database/postgres/experiments/reporting_cases.sql)
[Reporting evidence](lectures/lecture-3/docs/evidence.md)
[Responsibility decision](lectures/lecture-3/docs/responsibility-decision.md)

The experiments compare a base-table query, SQL function, materialised view and trigger-maintained summary. They also demonstrate how derived reporting data can become stale or incorrect and how it can be refreshed or rebuilt.

### Lecture 4 - Schema migration
[Product identity migrations](lectures/lecture-4/database/postgres/migrations)
[Old and new reader/writer scripts](lectures/lecture-4/database/postgres/experiments/lecture04)
[Migration evidence](lectures/lecture-4/docs/evidence.md)

The migration demonstrates the transition from product_code to product_id using a compatibility period, backfill and verification before removing the old reference. The evidence also verifies that historical ticket prices and currencies remain unchanged.

## Two decisions worth discussing

### Identity of a stop on a route
We chose (route_id, stop_sequence) as the primary key for route_stops rather than (route_id, stop_id).

This means the identity represents a position on a route rather than simply a route/stop combination. It allows the same physical stop to occur multiple times on the same route, for example on a circular route.

Relevant files:
[Schema](lectures/lecture-1/database/postgres/001_relational_baseline.sql)
[Modelling notes](lectures/lecture-1/docs/notes.md)
[Ordered stops query](lectures/lecture-1/database/postgres/queries/003_queries.sql)

### Authoritative data for reporting
We chose to keep payments as the authoritative source for captured revenue instead of treating the trigger-maintained reporting table as authoritative.

The reporting experiments showed that an insert-only trigger can correctly handle newly inserted captured payments but does not automatically cover every later change, such as a payment changing from Failed to Captured, refunds or deletes.

Keeping the base payment data authoritative means reporting data can be recalculated or rebuilt when necessary.

Relevant files:
[Reporting experiment](lectures/lecture-3/database/postgres/experiments/reporting_cases.sql)
[Evidence](lectures/lecture-3/docs/evidence.md)
[Responsibility decision](lectures/lecture-3/docs/responsibility-decision.md)

## One limitation
Our database constraints enforce many important invariants, but they do not guarantee the complete ticket-purchase workflow.

For example, the database can enforce that reserved_seats does not exceed a trip's capacity, but this alone does not define how simultaneous attempts to reserve the remaining seats should be coordinated.

A next step would therefore be to test concurrent ticket purchases and investigate which transaction isolation or locking strategy should be used to protect the remaining capacity.