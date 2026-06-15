# Base Config
# -----------

ARG ERLANG_VERSION=27.3.4
ARG ELIXIR_VERSION=1.18.4
ARG ALPINE_VERSION=3.21.3

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${ERLANG_VERSION}-alpine-${ALPINE_VERSION}"
ARG RUNNER_IMAGE="alpine:${ALPINE_VERSION}"

ARG MIX_ENV


# Stage 1: Build App
# ------------------

FROM ${BUILDER_IMAGE} AS builder

ARG MIX_ENV
ENV MIX_ENV=${MIX_ENV}

WORKDIR /src

# Install build dependencies
RUN apk add --no-cache --update \
  build-base linux-headers \
  git npm

# Make unistd.h available for picosat
RUN mkdir -p /usr/include/sys
RUN ln -s /usr/include/unistd.h /usr/include/sys/unistd.h

# Install Hex + Rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Install & compile elixir dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only=$MIX_ENV
RUN mix deps.compile

# # Install Node.js dependencies
RUN mkdir assets
COPY assets/package.json assets/package-lock.json assets/
RUN npm ci --prefix assets

# Recompile deps based on app configs
RUN mkdir config
COPY config/config.exs config/$MIX_ENV.exs config/
RUN mix deps.compile

# Compile assets and app
COPY priv priv
COPY assets assets
COPY lib lib
RUN mix assets.deploy
RUN mix compile

# Build release
COPY config/runtime.exs config/
COPY rel rel
RUN mix release


# Stage 2: Serve App
# ------------------

FROM ${RUNNER_IMAGE}

ARG MIX_ENV
ENV MIX_ENV=${MIX_ENV}

# Install runtime dependencies
RUN apk add --no-cache --update \
    bash vim curl openssl libstdc++ \
    imagemagick postgresql16-client

# Set directory, user, permissions
WORKDIR /app
RUN chown nobody /app

# Copy app release
COPY --from=builder --chown=nobody:root /src/_build/${MIX_ENV}/rel/*/ ./

USER nobody

ENV HOME=/app
CMD ["/app/bin/server"]
