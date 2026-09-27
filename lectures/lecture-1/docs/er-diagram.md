# ER diagram

```mermaid
erDiagram

    OPERATORS ||--o{ ROUTES : operates
    CITIES ||--o{ ROUTES : contains
    CITIES ||--o{ STOPS : contains

    ROUTES ||--o{ ROUTE_STOPS : has
    STOPS ||--o{ ROUTE_STOPS : appears_at

    ROUTES ||--o{ TRIPS : schedules

    OPERATORS {
        text id PK
        text name
    }

    CITIES {
        text id PK
        text name
    }

    ROUTES {
        text id PK
        text operator_id FK
        text city_id FK
        text mode
        text short_name
    }

    STOPS {
        text id PK
        text city_id FK
        text name
    }

    ROUTE_STOPS {
        text route_id PK, FK
        int stop_sequence PK
        text stop_id FK
    }

    TRIPS {
        text id PK
        text route_id FK
        date service_date
        timestamptz scheduled_departure_utc
        text status
    }

Important modelling choice
ROUTE_STOPS uses the composite primary key:
(route_id, stop_sequence)
This means that a route position is uniquely identified by the route and its sequence number.
The same physical stop may therefore appear more than once on the same route, provided it appears at different sequence positions.