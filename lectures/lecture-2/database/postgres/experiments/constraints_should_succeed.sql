-- Valid trip update
update trips
set capacity = 120,
    reserved_seats = 20
where id = 'TRIP-M2-20260429-0800';

-- Valid ticket
insert into tickets (
    id,
    user_id,
    trip_id,
    ticket_code,
    status,
    product_code,
    valid_from_utc,
    valid_to_utc,
    price,
    currency
)
values (
    'TICKET-VALID-1',
    'USER-1',
    'TRIP-M2-20260429-0800',
    'VALID-CODE-001',
    'Active',
    'SINGLE',
    '2026-04-29 07:30:00+00',
    '2026-04-29 09:30:00+00',
    36,
    'DKK'
);

-- Valid payment
insert into payments (
    id,
    user_id,
    ticket_id,
    external_payment_reference,
    amount,
    currency,
    status,
    created_utc
)
values (
    'PAYMENT-VALID-1',
    'USER-1',
    'TICKET-VALID-1',
    'gateway-valid-001',
    36,
    'DKK',
    'Captured',
    now()
);

-- Valid validation
insert into validations (
    id,
    ticket_id,
    ticket_code,
    stop_id,
    result,
    validated_utc
)
values (
    'VALIDATION-VALID-1',
    'TICKET-VALID-1',
    'VALID-CODE-001',
    'STOP-NORREPORT',
    'Accepted',
    now()
);