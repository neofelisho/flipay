# Flipay

Flipay is a RESTful API service based on [Elixir](https://elixir-lang.org/) and [Phoenix Framework](https://phoenixframework.org/).
This service provides functions to calculate best buying/selling price according to Exchange order book, and uses [JWT](https://jwt.io/) as basic authentication.

## Setup

This project provides docker support. If you have docker, reference section [Setup with Docker](#setup-with-docker).
Otherwise, please reference section [Setup without Docker](#setup-without-docker).

### Setup with Docker

0. Before starting, make sure the [Docker Compose](https://docs.docker.com/compose/) is installed.

1. Inside project folder, use follow commands to `create` and `migrate` database:

    ```zsh
    > docker-compose run flipay mix ecto.create
    > docker-compose run flipay mix ecto.migrate
    ```
    Because the dependency setting in `docker-compose.yml`, the command will run postgres database first. So the `create` and `migrate` can be executed correctly like this:
    ```zsh
    Starting postgres ... done
    The database for Flipay.Repo has been created
    ```
    ```zsh
    Starting postgres ... done
    [info] Already up
    ```

2. Use docker-compose up to start the service:

    ```zsh
    > docker-compose up -d
    ```
    ```zsh
    postgres is up-to-date
    Creating flipay   ... done
    Creating pgadmin4 ... done
    ```

    Remove `-d` if we want to track the execution logs. Also we can use log command if anything wrong.

    ```zsh
    > docker container logs flipay
    ```
    ```zsh
    [info] Running FlipayWeb.Endpoint with cowboy 2.6.3 at 0.0.0.0:4000 (http)
    [info] Access FlipayWeb.Endpoint at http://localhost:4000
    ```

    Now we can test it in browser by [http://localhost:4000/](http://localhost:4000/), and we can see this:

    ![001](https://github.com/neofelisho/flipay/tree/master/static/img/001.PNG)

3. This docker-compose file also bring a database management tool for [PostgreSQL](https://www.postgresql.org/): [pgAdmin 4](https://www.pgadmin.org/). We could access this tool by browsing [http://localhost/](http://localhost/). We can modify the login user name, password and exposing port in the `docker-compose.yml` file.

    ```dockerfile
    pgadmin4:
      container_name: pgadmin4
      image: dpage/pgadmin4
      restart: always
      ports: 
        - [assign host port here]:80 
      environment:
        - PGADMIN_DEFAULT_EMAIL=[assign login email]
        - PGADMIN_DEFAULT_PASSWORD=[assign login password]
      networks: 
        - backend
      depends_on:
        - postgres
    ```

### Setup without Docker

0. Before starting, make sure [Elixir](https://elixir-lang.org/install.html), [Phoenix](https://hexdocs.pm/phoenix/installation.html), and [PostgreSQL](https://www.postgresql.org/download/) are already installed.

1. Configure PostgreSQL for development environment, edit `./flipay/config/dev.exs`:

    ```elixir
    # Configure your database
    config :flipay, Flipay.Repo,
      username: ["login user name"],
      password: ["login password"],
      database: "flipay_dev",
      hostname: ["localhost" or "database ip"],
      pool_size: 10
    ```
2. Create and migrate database:

    ```zsh
    > mix ecto.create
    > mix ecto.migrate
    ```

3. Start the service and test it:

    ```zsh
    > mix phx.server
    ```

    We can also test it by browsing [http://localhost:4000/](http://localhost:4000/), and we should get the same result with docker setup:

    ![001](https://github.com/neofelisho/flipay/blob/master/static/img/001.PNG)
    
## Usage

Flipay service provides basic authenticaion by JWT.

### Create user

```zsh
curl -X POST \
  http://localhost:4000/api/v1/sign_up \
  -H 'Content-Type: application/json' \
  -H 'cache-control: no-cache' \
  -d '{
        "user": {
            "email": "hello@world.com",
            "password": "some_password",
            "password_confirmation": "some_password"
          }
      }'
```

If succeed, we can get a token:

```json
{"jwt": "token content"}
```

### Sign in user

```zsh
curl -X POST \
  http://localhost:4000/api/v1/sign_in \
  -H 'Content-Type: application/json' \
  -H 'cache-control: no-cache' \
  -d '{
        "email": "hello2@world.com",
        "password": "some_password"
      }'
```

If succeed, we can get a token:

```json
{"jwt":"token content"}
```

### Get user info by token

```zsh
curl -X GET \
  http://localhost:4000/api/v1/my_user \
  -H 'Authorization: Bearer [valid token]' \
  -H 'cache-control: no-cache'
```

If token is valid, we can get the user's information:

```json
{
    "data": {
        "email": "hello@world.com",
        "id": 1,
        "password_hash": "[the hashed password]"
    }
}
```

### Calculate best buying/selling price

```zsh
curl -X GET \
  'http://localhost:4000/api/v1/quote/coinbase?input_asset=USD&input_amount=10500&output_asset=BTC' \
  -H 'Authorization: Bearer [valid token]' \
  -H 'Content-Type: application/json' \
  -H 'cache-control: no-cache'
```

The result depends on the request parameters, in above example, we will get:

```json
{"best_rate": "2.083333333333333333333333333"}
```

### More about code modules and functions

For more information, we can check the [online documentation](https://neofelisho.github.io/flipay/api-reference.html).

## Troubleshooting

### Docker for Windows

Due to [Golang and Moby's issue], if we execute `docker-compose` or `docker build` when `_build` folder exists in the project folder, it occurs error.

### (Mix) "nmake" not found in the path

Occurs when we don't have C compiler, or when we are using Windows and Visual Studio with C++ compiler tool installed. [Here](https://elixirforum.com/t/on-windows-i-got-could-not-compile-dependency-bcrypt-elixir/13289) is a solution, but using [WSL](https://en.wikipedia.org/wiki/Windows_Subsystem_for_Linux) will be a better development environment on Windows. [Here](https://medium.com/@colinrubbert/installing-elixir-phoenix-in-windows-10-w-bash-postgresql-ead9c1ce595c) is a good reference.

### Why not using alpine image in Docker

Because this service uses [bcrypt_elixir](https://hex.pm/packages/bcrypt_elixir). This package needs C++ compiler to build. We can add gcc to alpine like this:

```zsh
apk add --no-cache gcc musl-dev
```

But sometimes it still occurs problem, and so does in our project.