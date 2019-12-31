##################
# Dockerfile.build
##################
# FROM elixir:alpine as builder
FROM bitwalker/alpine-elixir:1.9.2 as builder

ENV MIX_ENV=prod

# Install hex and rebar
RUN mix local.hex --force && \
  mix local.rebar --force

# Create the application build directory
WORKDIR /opt/app

# Copy over all the necessary application files and directories
COPY ./backend/config ./backend/config
COPY ./backend/lib ./backend/lib
COPY ./backend/rel ./backend/rel
COPY ./backend/priv ./backend/priv
COPY ./backend/mix.exs ./backend
COPY ./backend/mix.lock ./backend

COPY ./dbstore ./dbstore
COPY ./auth ./auth
COPY ./accounts ./accounts
COPY ./notebooks ./notebooks

RUN apk update
# RUN apk add postgresql
# RUN apk add postgresql-contrib
RUN apk add --no-cache --upgrade bash
RUN apk add --no-cache make gcc libc-dev argon2
# RUN apk add gcc
# RUN apk add make
WORKDIR ./backend
# Fetch the application dependencies and build the application
RUN mix deps.get
RUN mix deps.compile
RUN mix phx.digest
RUN mix release

########################
# Dockerfile.release
########################
# FROM elixir:alpine
FROM bitwalker/alpine-elixir:1.9.2

# For debugging purposes only
# RUN apk add bash && \
#   apk add curl

# Install openssl (Really though?)
# RUN apt-get update && apt-get install -y openssl

# Copy over the build artifact from the previous step and switch to non root user
WORKDIR /opt/app/
COPY --from=builder /opt/app/backend/_build .
RUN chown -R default: ./prod
USER default

EXPOSE 4000

# Run the Phoenix app
CMD ["./prod/rel/backend/bin/backend", "start"]