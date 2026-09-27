# Modelling notes

## Modelling choice: route stop identity

We model each occurrence of a stop on a route using the composite primary key:

`(route_id, stop_sequence)`

This means that the same physical stop may appear more than once on the same route, as long as it appears at different positions.

We chose this instead of `(route_id, stop_id)`, because the latter would prevent a route from visiting the same stop more than once.

Example:

`ROUTE-X -> Stop A -> Stop B -> Stop C -> Stop A`

This may be relevant for loop or circular routes.

## Functional dependency

For `route_stops`, the following dependency holds:

`(route_id, stop_sequence) -> stop_id`

Within one route, a given sequence position identifies exactly one stop occurrence.

The model therefore assumes that two stops cannot occupy the same sequence number on the same route.

## How the query uses the model

The ordered route-stops query uses `stop_sequence` directly:

```sql
select
    rs.stop_sequence,
    s.id as stop_id,
    s.name as stop_name
from route_stops rs
join stops s
    on s.id = rs.stop_id
where rs.route_id = :'route_id'
order by rs.stop_sequence;

Because (route_id, stop_sequence) is unique, ordering by stop_sequence gives one deterministic stop occurrence per route position.

Assumption / possible limitation

The current model represents only the order of stops on a route.
It does not yet model route-specific arrival/departure times for individual stops, distance between stops, or direction/variant information.
If MobilityTicketing later needs multiple route variants or different stop patterns under the same route identifier, the current model may need an additional entity such as a route pattern or journey pattern.

