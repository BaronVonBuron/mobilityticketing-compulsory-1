\set product_id 'PUT-PRODUCT-UUID-HERE'

\set ticket_id 'LAB04-NEW-FINAL'
\set ticket_code 'LAB04-CODE-NEW-FINAL'
\set agreed_price '36'
\set agreed_currency 'DKK'

insert into tickets (
    id,
    user_id,
    trip_id,
    ticket_code,
    status,
    product_code,
    product_id,
    valid_from_utc,
    valid_to_utc,
    price,
    currency
)
select
    :'ticket_id',
    template.user_id,
    template.trip_id,
    :'ticket_code',
    template.status,
    p.code,
    p.id,
    template.valid_from_utc,
    template.valid_to_utc,
    :'agreed_price'::numeric,
    :'agreed_currency'
from tickets template
join products p
    on p.id = :'product_id'::uuid
where template.id = 'TICKET-1';