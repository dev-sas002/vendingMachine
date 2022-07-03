# syntax=docker/dockerfile:1

################################################################################
# Stage 1 - build: compiles the native extensions (pg, bootsnap) and resolves
# the bundle. Nothing from this stage ships except vendor/bundle.
################################################################################
FROM ruby:2.7.2-slim-bullseye AS build

# Pass BUNDLE_WITHOUT="development:test" for a production image. The default
# installs every group so the compose demo stack can boot in development mode
# with the Swagger UI and the seed data available.
ARG BUNDLE_WITHOUT=""

ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=${BUNDLE_WITHOUT} \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3

RUN apt-get update -qq \
 && apt-get install --no-install-recommends -y \
      build-essential \
      libpq-dev \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copied on their own so a change to application code does not invalidate the
# bundle layer.
COPY Gemfile Gemfile.lock ./
RUN bundle install \
 && rm -rf "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY . .

# Precompile bootsnap caches so the first request does not pay for them.
RUN bundle exec bootsnap precompile --gemfile app/ lib/ || true

################################################################################
# Stage 2 - runtime: no compilers, no headers, no build cache.
################################################################################
FROM ruby:2.7.2-slim-bullseye AS runtime

ENV BUNDLE_PATH=/usr/local/bundle \
    RAILS_LOG_TO_STDOUT=true \
    PORT=3000

RUN apt-get update -qq \
 && apt-get install --no-install-recommends -y \
      curl \
      libpq5 \
      postgresql-client \
      procps \
      tzdata \
 && rm -rf /var/lib/apt/lists/*

# Unprivileged runtime user.
RUN groupadd --system --gid 1000 vending \
 && useradd --system --uid 1000 --gid vending --create-home vending

WORKDIR /app

COPY --from=build --chown=vending:vending "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build --chown=vending:vending /app /app

# Writable at runtime; everything else stays owned by root and read-only.
RUN mkdir -p log tmp/pids storage && chown -R vending:vending log tmp storage

USER vending

EXPOSE 3000

HEALTHCHECK --interval=15s --timeout=5s --start-period=45s --retries=5 \
  CMD curl -fsS "http://localhost:${PORT}/health" || exit 1

ENTRYPOINT ["bin/docker-entrypoint"]
CMD ["web"]
