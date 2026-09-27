# Workload / access-pattern map

MobilityTicketing serves passengers, transport operators and reporting/operations staff across city transport.

The system is expected to support the following main access patterns.

| Access pattern | Actor | Typical operation | Main data involved | Lecture 1 status |
|---|---|---|---|---|
| Search routes and departures | Passenger | Read | Routes, stops, route stops, trips | Partly implemented |
| Show upcoming trips for a route | Passenger / operator | Read | Routes, trips | Implemented |
| Show ordered stops for a route | Passenger / operator | Read | Routes, route stops, stops | Implemented |
| Show routes with trip counts | Operator | Read / reporting | Routes, trips | Implemented |
| Purchase a ticket | Passenger | Write | User, product, ticket, payment | Not implemented yet |
| Validate a ticket | Passenger / validator | Write + read | Ticket, validation | Not implemented yet |
| Update timetable data | Operator | Write | Routes, route stops, trips | Model supports part of this |
| Real-time availability | Passenger / operator | Frequent read/update | Trips, capacity, operational state | Not implemented yet |
| Revenue and operational reporting | Operator / reporting staff | Aggregate read | Tickets, payments, routes, operators | Not implemented yet |

## Implemented workload queries

### 1. Upcoming trips for a route

Given a route and a timestamp, return the next 20 trips ordered by scheduled departure time.

Access path:

`routes -> trips`

Relevant relationship:

One route may have many trips, while each trip belongs to one route.

Implemented in:

`database/postgres/queries/003_queries.sql`

### 2. Ordered stops for a route

Given a route, return all stops in route order.

Access path:

`routes -> route_stops -> stops`

`route_stops.stop_sequence` determines the order.

Implemented in:

`database/postgres/queries/003_queries.sql`

### 3. Routes with trip counts

Given a service date, return every route together with the number of trips on that date, including routes with no trips.

Access path:

`routes -> trips`

A `LEFT JOIN` is used so routes without matching trips are still returned with a count of zero.

Implemented in:

`database/postgres/queries/003_queries.sql`

## Scope

Lecture 1 implements only the relational model needed for route maintenance and timetable queries.

Ticket purchase, validation, payment processing, real-time availability and reporting are identified as expected workloads, but their data structures and implementation are intentionally deferred to later lectures.