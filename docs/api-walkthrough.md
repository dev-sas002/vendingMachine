# Captured API walkthrough

Everything below was recorded against the Compose stack -
`docker compose up --build`, which migrates, loads `db/seeds.rb` and serves
the API on port 8400 - on Ruby 3.4.12 and Rails 7.2. It is pasted unedited
except that the issued `access-token` and `client` values are cut to their
first six characters, and that the three auth headers are shown as `…` on
the calls after the sign-in that produced them. Only the response headers
that matter to each call are kept.

The seeded buyer starts with a deposit of 100, `Cola` costs 70 and
`Chewing Gum` is stocked at zero.

## Health

### Liveness, with a database round trip

```console
$ curl -i http://127.0.0.1:8400/health
HTTP/1.1 200 OK
{
  "status": "ok",
  "database": "ok"
}
```

## Registration

### Register as a buyer

```console
$ curl -i -X POST http://127.0.0.1:8400/api/v1/users -H 'Content-Type: application/json' -d '{"user": {"email": "dana@example.com", "password": "abcd1234", "first_name": "Dana", "last_name": "Demo", "role": "buyer"}}'
HTTP/1.1 200 OK
uid: dana@example.com
{
  "user": {
    "id": 4,
    "first_name": "Dana",
    "last_name": "Demo",
    "email": "dana@example.com",
    "locale": null,
    "role": "buyer",
    "created_at": "2026-11-08T12:59:02.548-05:00",
    "updated_at": "2026-11-08T12:59:02.572-05:00"
  }
}
```

### A role is required

```console
$ curl -i -X POST http://127.0.0.1:8400/api/v1/users -H 'Content-Type: application/json' -d '{"user": {"email": "nora@example.com", "password": "abcd1234"}}'
HTTP/1.1 422 Unprocessable Content
{
  "attributes_errors": {
    "role": [
      "must be one of: seller, buyer"
    ]
  }
}
```

## Session

### Sign in as the seeded buyer

```console
$ curl -i -X POST http://127.0.0.1:8400/api/v1/users/sign_in -H 'Content-Type: application/json' -d '{"user": {"email": "buyer@example.com", "password": "password123"}}'
HTTP/1.1 200 OK
access-token: sDemqD...
token-type: Bearer
client: hHVxwq...
expiry: 1806253142
uid: buyer@example.com
{
  "user": {
    "id": 2,
    "first_name": "Bea",
    "last_name": "Buyer",
    "email": "buyer@example.com",
    "locale": null,
    "role": "buyer",
    "created_at": "2026-11-08T12:58:27.916-05:00",
    "updated_at": "2026-11-08T12:59:02.746-05:00"
  },
  "must_change_password": false
}
```

### Every other endpoint needs the token trio

```console
$ curl -i http://127.0.0.1:8400/api/v1/products
HTTP/1.1 401 Unauthorized
{
  "errors": [
    "Authentication is required to perform this action"
  ]
}
```

### Products, three to a page

```console
$ curl -i http://127.0.0.1:8400/api/v1/products?items=3 -H 'access-token: …' -H 'client: …' -H 'uid: buyer@example.com'
HTTP/1.1 200 OK
link: <http://127.0.0.1:8400/api/v1/products?items=3&page=1>; rel="first", <http://127.0.0.1:8400/api/v1/products?items=3&page=2>; rel="next", <http://127.0.0.1:8400/api/v1/products?items=3&page=2>; rel="last"
current-page: 1
page-items: 3
total-pages: 2
total-count: 6
[
  {
    "id": 1,
    "name": "Sparkling Water",
    "price": 55,
    "available_count": 12,
    "available_amount": 12,
    "seller_id": 1,
    "seller": {
      "id": 1,
      "email": "seller@example.com"
    },
    "created_at": "2026-11-08T12:58:27.935-05:00",
    "updated_at": "2026-11-08T12:58:27.935-05:00"
  },
  {
    "id": 2,
    "name": "Cola",
    "price": 70,
    "available_count": 8,
    "available_amount": 8,
    "seller_id": 1,
    "seller": {
      "id": 1,
      "email": "seller@example.com"
    },
    "created_at": "2026-11-08T12:58:27.940-05:00",
    "updated_at": "2026-11-08T12:59:02.277-05:00"
  },
  {
    "id": 3,
    "name": "Salted Crisps",
    "price": 45,
    "available_count": 6,
    "available_amount": 6,
    "seller_id": 1,
    "seller": {
      "id": 1,
      "email": "seller@example.com"
    },
    "created_at": "2026-11-08T12:58:27.947-05:00",
    "updated_at": "2026-11-08T12:58:27.947-05:00"
  }
]
```

## Buying

### Insert a 50

```console
$ curl -i -X POST http://127.0.0.1:8400/api/v1/deposit -H 'Content-Type: application/json' -d '{"deposit_amount": 50}' -H 'access-token: …' -H 'client: …' -H 'uid: buyer@example.com'
HTTP/1.1 200 OK
{
  "message": "Amount Deposited Successfully",
  "deposit_amount": 150
}
```

### The machine takes no 7s

```console
$ curl -i -X POST http://127.0.0.1:8400/api/v1/deposit -H 'Content-Type: application/json' -d '{"deposit_amount": 7}' -H 'access-token: …' -H 'client: …' -H 'uid: buyer@example.com'
HTTP/1.1 422 Unprocessable Content
{
  "error": "Invalid Amount"
}
```

### Chewing gum is sold out

```console
$ curl -i -X POST http://127.0.0.1:8400/api/v1/buy -H 'Content-Type: application/json' -d '{"product_id": 6, "quantity": 1}' -H 'access-token: …' -H 'client: …' -H 'uid: buyer@example.com'
HTTP/1.1 422 Unprocessable Content
{
  "error": "Product is sold out"
}
```

### Two colas at 70 from a balance of 150

```console
$ curl -i -X POST http://127.0.0.1:8400/api/v1/buy -H 'Content-Type: application/json' -d '{"product_id": 2, "quantity": 2}' -H 'access-token: …' -H 'client: …' -H 'uid: buyer@example.com'
HTTP/1.1 200 OK
{
  "total_bill": 140,
  "product": {
    "id": 2,
    "name": "Cola",
    "price": 70,
    "available_count": 6,
    "available_amount": 6,
    "seller_id": 1,
    "seller": {
      "id": 1,
      "email": "seller@example.com"
    },
    "created_at": "2026-11-08T12:58:27.940-05:00",
    "updated_at": "2026-11-08T12:59:02.879-05:00"
  },
  "remaining_amount": 10,
  "change": {
    "coins": {
      "10": 1
    },
    "remainder": 0
  }
}
```

### 10 left will not buy an 85 chocolate bar

```console
$ curl -i -X POST http://127.0.0.1:8400/api/v1/buy -H 'Content-Type: application/json' -d '{"product_id": 4, "quantity": 1}' -H 'access-token: …' -H 'client: …' -H 'uid: buyer@example.com'
HTTP/1.1 422 Unprocessable Content
{
  "error": "Order Amount exceeded your current Amount"
}
```

### Reset: the balance comes back as coins

```console
$ curl -i -X POST http://127.0.0.1:8400/api/v1/reset -H 'access-token: …' -H 'client: …' -H 'uid: buyer@example.com'
HTTP/1.1 200 OK
{
  "message": "Deposit Amount Reset Successfully",
  "returned_amount": 10,
  "change": {
    "coins": {
      "10": 1
    },
    "remainder": 0
  }
}
```

### Buyers cannot stock the machine

```console
$ curl -i -X POST http://127.0.0.1:8400/api/v1/products -H 'Content-Type: application/json' -d '{"product": {"name": "Pretzels", "price": 40, "available_count": 5}}' -H 'access-token: …' -H 'client: …' -H 'uid: buyer@example.com'
HTTP/1.1 403 Forbidden
{
  "error": "Only sellers can manage products"
}
```

## Users

### Other users, public fields only, paginated

```console
$ curl -i http://127.0.0.1:8400/api/v1/user/all?items=2 -H 'access-token: …' -H 'client: …' -H 'uid: buyer@example.com'
HTTP/1.1 200 OK
total-pages: 2
total-count: 3
[
  {
    "id": 1,
    "first_name": "Sam",
    "last_name": "Seller",
    "email": "seller@example.com",
    "locale": null,
    "role": "seller",
    "created_at": "2026-11-08T12:58:27.790-05:00",
    "updated_at": "2026-11-08T12:59:02.111-05:00"
  },
  {
    "id": 2,
    "first_name": "Bea",
    "last_name": "Buyer",
    "email": "buyer@example.com",
    "locale": null,
    "role": "buyer",
    "created_at": "2026-11-08T12:58:27.916-05:00",
    "updated_at": "2026-11-08T12:59:02.918-05:00"
  }
]
```

### Dana closes her account

```console
$ curl -i -X DELETE http://127.0.0.1:8400/api/v1/user -H 'access-token: …' -H 'client: …' -H 'uid: dana@example.com'
HTTP/1.1 204 No Content
```

### Her token died with it

```console
$ curl -i http://127.0.0.1:8400/api/v1/user -H 'access-token: …' -H 'client: …' -H 'uid: dana@example.com'
HTTP/1.1 401 Unauthorized
{
  "errors": [
    "Authentication is required to perform this action"
  ]
}
```

## Test suite

Run inside the image the stack is built from:

```console
$ docker compose run --rm -e RAILS_ENV=test web bundle exec rspec
Finished in 5.81 seconds (files took 1.24 seconds to load)
398 examples, 0 failures
Line Coverage: 98.91% (1820 / 1840)
```

## Concurrency proofs

Real committed rows, four threads on four connections released together.
Without the buyer row lock, the deposit race credited 10 instead of 40 and
all four resets reported the full 100 as handed back.

```console
$ bundle exec rspec spec/services/vending/*_concurrency_spec.rb --format documentation --order defined
Vending::Purchase
  when more buyers than there is stock race for the last items
    sells exactly as many units as it had
    refuses the buyers it could not serve
    tells the losers the product is sold out
    never drives the stock negative
    charges exactly the buyers it served
    leaves the money of refused buyers alone
  when one buyer spends the same balance from several connections
    never lets the balance go below zero
    sells only what the balance covered
    removes exactly the stock it sold
    refuses the purchase that had no money behind it
Vending::Deposit
  accepts every coin
  credits every coin
Vending::Refund
  hands the balance back exactly once
  leaves the wallet empty
Finished in 1.08 seconds (files took 0.98404 seconds to load)
14 examples, 0 failures
```
