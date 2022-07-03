# Captured API walkthrough

Everything below was recorded against a real, running instance of this
application - `bundle exec rails server -p 8400` with the demo data from
`db/seeds.rb` loaded. It is pasted here unedited except that the issued
`access-token` and `client` values are truncated, and that the three auth
headers are shown as `...` on the calls after the sign-in that produced them.

Reproduce it yourself:

```bash
bundle exec rake db:create db:migrate db:seed
PORT=8400 bundle exec rails server -p 8400
```

The seeded buyer starts with a deposit of 100 and `Cola` costs 70.

---

## Session

```console
$ curl -i -X POST http://127.0.0.1:8400/api/v1/users/sign_in -H 'Content-Type: application/json' -d '{"user":{"email":"buyer@example.com","password":"password123"}}'
HTTP/1.1 200 OK
access-token: ywSH_s...
token-type: Bearer
client: g6I4ba...
expiry: 1802321353
uid: buyer@example.com
{
    "user": {
        "id": 2,
        "first_name": "Bea",
        "last_name": "Buyer",
        "email": "buyer@example.com",
        "locale": null,
        "role": "buyer",
        "created_at": "2026-09-23T23:31:34.204-04:00",
        "updated_at": "2026-09-23T23:49:13.962-04:00"
    },
    "must_change_password": false
}

$ curl -i http://127.0.0.1:8400/api/v1/products
HTTP/1.1 401 Unauthorized
{
    "errors": [
        "Authentication is required to perform this action"
    ]
}

$ curl -i "http://127.0.0.1:8400/api/v1/products?items=3" -H 'access-token: …' -H 'client: …' -H 'uid: buyer@example.com'
HTTP/1.1 200 OK
Link: <http://127.0.0.1:8400/api/v1/products?items=3&page=1>; rel="first", <http://127.0.0.1:8400/api/v1/products?items=3&page=2>; rel="next", <http://127.0.0.1:8400/api/v1/products?items=3&page=2>; rel="last"
Current-Page: 1
Page-Items: 3
Total-Pages: 2
Total-Count: 6
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
        "created_at": "2026-09-23T23:31:34.218-04:00",
        "updated_at": "2026-09-23T23:31:34.218-04:00"
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
        "created_at": "2026-09-23T23:31:34.223-04:00",
        "updated_at": "2026-09-23T23:49:13.615-04:00"
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
        "created_at": "2026-09-23T23:31:34.227-04:00",
        "updated_at": "2026-09-23T23:31:34.227-04:00"
    }
]

$ curl -X POST http://127.0.0.1:8400/api/v1/deposit -H 'Content-Type: application/json' -H 'access-token: …' … -d '{"deposit_amount": 100}'
{
    "message": "Amount Deposited Successfully",
    "deposit_amount": 200
}

$ curl -i -X POST http://127.0.0.1:8400/api/v1/deposit … -d '{"deposit_amount": 7}'
HTTP/1.1 422 Unprocessable Entity
{
    "error": "Invalid Amount"
}

$ curl -X POST http://127.0.0.1:8400/api/v1/buy … -d '{"product_id": 2, "quantity": 2}'
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
        "created_at": "2026-09-23T23:31:34.223-04:00",
        "updated_at": "2026-09-23T23:49:14.403-04:00"
    },
    "remaining_amount": 60,
    "change": {
        "coins": {
            "50": 1,
            "10": 1
        },
        "remainder": 0
    }
}

$ curl -i -X POST http://127.0.0.1:8400/api/v1/buy … -d '{"product_id": 2, "quantity": 99}'
HTTP/1.1 422 Unprocessable Entity
{
    "error": "Order Amount exceeded your current Amount"
}

$ curl -i -X POST http://127.0.0.1:8400/api/v1/products … -d '{"name": "Contraband", "price": 1, "available_count": 1}'
HTTP/1.1 403 Forbidden
{
    "error": "Only sellers can manage products"
}

$ curl -X POST http://127.0.0.1:8400/api/v1/reset -H 'access-token: …' -H 'client: …' -H 'uid: buyer@example.com'
{
    "message": "Deposit Amount Reset Successfully",
    "returned_amount": 60,
    "change": {
        "coins": {
            "50": 1,
            "10": 1
        },
        "remainder": 0
    }
}

$ curl http://127.0.0.1:8400/health
{
    "status": "ok",
    "database": "ok"
}
```

---

## Test suite

```console
$ bundle exec rspec
...................................................................................................................................................................................................................................................................................................................................................................................

Finished in 5.63 seconds (files took 1.63 seconds to load)
371 examples, 0 failures

Randomized with seed 2807

Coverage report generated for RSpec to /Users/dev/Documents/Projects/WAMO/githubs/all_projects/vendingMachine/coverage. 1693 / 1716 LOC (98.66%) covered.
```

## No-oversell proof

Four threads on four database connections race for a product that has two units
of stock, and separately for one wallet holding 30 units. Exactly two and
exactly three purchases succeed - never more.

```console
$ bundle exec rspec spec/services/vending/purchase_concurrency_spec.rb --format documentation
Database 'vending_machine-test' already exists

Randomized with seed 2793

Vending::Purchase
  when one buyer spends the same balance from several connections
    never lets the balance go below zero
    refuses the purchase that had no money behind it
    sells only what the balance covered
    removes exactly the stock it sold
  when more buyers than there is stock race for the last items
    tells the losers the product is sold out
    leaves the money of refused buyers alone
    sells exactly as many units as it had
    never drives the stock negative
    refuses the buyers it could not serve
    charges exactly the buyers it served

Finished in 0.46916 seconds (files took 0.97333 seconds to load)
10 examples, 0 failures

Randomized with seed 2793

Coverage report generated for RSpec to /Users/dev/Documents/Projects/WAMO/githubs/all_projects/vendingMachine/coverage. 177 / 189 LOC (93.65%) covered.
```

Replacing `Product#decrement_stock!` with a naive read-modify-write
(`update(available_count: available_count - quantity)`) and re-running makes 7
of these 10 examples fail: all four buyers are served from two units of stock,
and the committed `available_count` settles at 1.
