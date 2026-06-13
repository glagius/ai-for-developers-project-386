# Use the official Elixir image as the base
FROM elixir:1.20-slim AS build

RUN apt-get update \
  && apt-get install -y build-essential curl git \
  && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
  && apt-get install -y nodejs \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN mix local.hex --force && mix local.rebar --force

WORKDIR /app

# Install dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mix deps.compile

# Compile the application
COPY . .
RUN mix compile

# Build the release
RUN mix release

# Runtime stage
FROM ubuntu:22.04-slim

RUN apt-get update \
  && apt-get install -y libodbc1 libpq5 libstdc++6 openssl \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=build /app/_prod/rel/scheduling ./

CMD ["bin/scheduling", "start"]
