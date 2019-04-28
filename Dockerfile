FROM elixir:latest

RUN mix local.hex --force \
 && mix archive.install --force hex phx_new 1.4.3 \
 && apt-get update \
 && curl -sL https://deb.nodesource.com/setup_11.x | bash \
 && apt-get install -y apt-utils \
 && apt-get install -y nodejs \
 && apt-get install -y build-essential \
 && apt-get install -y inotify-tools \
 && mix local.rebar --force

ENV APP_HOME /app
RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME

ADD mix.exs mix.lock ./
RUN mix do deps.get, deps.compile

ADD . .
RUN mix do compile

EXPOSE 4000

CMD ["mix", "phx.server"]