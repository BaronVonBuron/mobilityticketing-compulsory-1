# Responsibility decision

This document compares the four reporting approaches used for daily captured revenue and records the chosen responsibility model.

## Responsibility matrix

| Dimension | Direct query | SQL function | Materialized view | Trigger-maintained summary |
| --- | --- | --- | --- | --- |
| Correctness | Reads authoritative base data directly | Same correctness model as direct query | Correct as of last refresh | Correct only if every relevant write/correction path is handled |
| Freshness | Current transaction snapshot | Current transaction snapshot | Refresh-dependent and may become stale | Immediate for write paths handled by the trigger |
| Write cost | No extra reporting write cost | No extra reporting write cost | No extra cost for each payment write | Extra lookup and summary write on payment write path |
| Read cost | Higher for repeated joins and aggregation | Similar to direct query | Low because aggregate is stored | Low because aggregate is stored |
| Hidden side effects | None | None beyond read execution | Refresh happens separately and explicitly | High: a payment write can cause additional reads and writes |
| Rebuildability | Not applicable | Not applicable | Strong: refresh rebuilds from base data | Must be designed explicitly with a backfill/rebuild path |
| Operational complexity | Low | Low | Medium | High |

## Authority

`payments` remains the authoritative source for payment state.

Daily captured revenue is derived from payment state and must therefore be reproducible from the transactional tables.

The reporting function centralises the calculation rule without storing another copy of the result.

## Current recommendation

For the current MobilityTicketing reporting workload, the SQL function is the preferred primary reporting interface.

The reasons are:

1. It reads current transactional state, so corrections are reflected immediately.
2. It centralises the captured-revenue calculation in one database object.
3. It does not introduce another stored copy that can drift from the authoritative payment data.
4. The current workload does not demonstrate a requirement for sub-second aggregate reads at a scale that would justify additional write-path complexity.

The trigger-maintained summary is therefore not the preferred primary design for the current case.

The supplied trigger demonstrates why: it handles captured inserts, but corrections such as `Failed -> Captured`, refunds, deletes and historical backfill require additional logic. A robust trigger design would also need an explicit rebuild and verification path.

## Materialized view as a performance option

If reporting volume later makes repeated aggregation too expensive, a materialized view is the preferred stored optimisation.

Its responsibility would be:

```text
payments
    -> authoritative transactional data

captured_revenue_for_day(...)
    -> central reporting definition

daily_captured_revenue
    -> rebuildable reporting cache
```

The materialized view may be stale between refreshes, so its freshness policy must be explicit and observable.

Its main advantage is that it can be deterministically rebuilt from authoritative data using:

```sql
refresh materialized view daily_captured_revenue;
```

## Why not make the trigger summary authoritative?

The trigger-maintained summary must remain derived data rather than a second source of truth.

If the summary becomes inconsistent, the system must be able to reconstruct it from `payments`.

A design where the summary cannot be rebuilt would make payment correctness dependent on historical trigger execution, which increases recovery and operational risk.

## Decision

For the current workload:

```text
Authority:
payments

Primary reporting interface:
captured_revenue_for_day(...)

Optional future optimisation:
daily_captured_revenue materialized view

Trigger-maintained summary:
not selected as the primary reporting design
```

This decision is based on workload, correction behaviour, rebuildability and operational complexity rather than personal preference.