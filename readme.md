## Features included
    - Authentication/sessions
    - User registration and crud
    - Products crud
    - Buy Products
    - Deposit Amount
    - Reset Deposit Amount
    - Swagger for Api Docs
    - Handled api errors gracefully.

## Getting Started
1.  Make sure that you have Rails 6, PostgreSQL, Redis, git cli, and bundle installed.
3.  Update the values of the `.env.sample` file to match your app
4.  Create your `.env` file. You have an example at `.env.sample`.
5.  Run `bundle install`
6.  Run `bundle exec rake db:create`
7.  Run `bundle exec rake db:migrate`
8.  Run `gem install foreman`
    _At this point you can run `foreman start`  and start making your REST API calls at `http://localhost:5000`_

## Tests

You can run the unit tests with `rspec` or `rspec` followed by a specific test file or directory.

# Curl

put the curl command to get user access token and client

```bash
curl -v -X POST -H "Content-Type: application/json" -d '{"user": {"email":"admin@example.com","password":"password123"}}' http://localhost:5000/api/v1/users/sign_in

```

to get all issues 

```bash
curl -X GET -H 'Content-Type: application/json' -H 'access-token: DJt2eWSBjbmjNAxbOvkFfw' -H 'client: g8Gp3j7mYkKxOHyNGgluXA' -H "uid: admin@example.com" http://localhost:5000/api/v1/issues
```
replace the access-token and client with the one that you got in headers