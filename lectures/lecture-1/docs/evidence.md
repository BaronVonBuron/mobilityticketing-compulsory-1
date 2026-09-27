# Evidence

This file contains representative output from the Lecture 1 relational model and queries.

## Seed verification

The seed data contains:

- Route `LINE-M2`
- Route `LINE-5C`
- Route `LINE-EMPTY`
- Two trips for `LINE-M2`
- Two trips for `LINE-5C`
- No trips for `LINE-EMPTY`

This allows the query for route trip counts to demonstrate that routes with zero trips are still included.

## Query 1: upcoming trips for a route

Executed with:

- `route_id = LINE-M2`
- `after_utc = 2026-09-28 07:30:00+00`

Result:

```text
          id           | scheduled_departure_utc |  status
-----------------------+-------------------------+-----------
 TRIP-M2-20260928-0800 | 2026-09-28 08:00:00+00 | Scheduled
 TRIP-M2-20260928-0900 | 2026-09-28 09:00:00+00 | Scheduled
```

This shows that only trips for the requested route after the supplied timestamp are returned, ordered by departure time.

## Query 2: ordered route stops

Executed with:

- `route_id = LINE-M2`

Result:

```text
 stop_sequence |       stop_id       |     stop_name
---------------+---------------------+--------------------
             1 | STOP-NORREPORT      | Nørreport
             2 | STOP-KONGENS-NYTORV | Kongens Nytorv
             3 | STOP-AIRPORT        | Copenhagen Airport
```

This demonstrates that `stop_sequence` defines the order of stops on a route.

## Query 3: routes with trip counts

Executed with:

- `service_date = 2026-09-28`

Representative result:

```text
     id     | short_name | trip_count
------------+------------+-----------
 LINE-5C    | 5C         | 2
 LINE-EMPTY | X1         | 0
 LINE-M2    | M2         | 2
```

The important case is:

```text
LINE-EMPTY | X1 | 0
```

`LINE-EMPTY` has no trips, but is still returned because the query starts from `routes` and uses a `LEFT JOIN` to `trips`.

## Reproduction

From `lectures/lecture-1`:

```cmd
docker compose down -v
docker compose up -d
```

Then run:

```cmd
docker compose exec -T postgres psql -U mobility -d mobility -v route_id=LINE-M2 -v "after_utc=2026-09-28 07:30:00+00" -v service_date=2026-09-28 < database\postgres\queries\003_queries.sql
```