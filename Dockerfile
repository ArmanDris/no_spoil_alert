ARG ERLANG_VERSION=28.2
ARG GLEAM_VERSION=v1.14.0

FROM ghcr.io/gleam-lang/gleam:${GLEAM_VERSION}-scratch AS gleam

FROM erlang:${ERLANG_VERSION}-alpine AS build
COPY --from=gleam /bin/gleam /bin/gleam
COPY . ./app/
RUN cd /app && gleam export erlang-shipment

FROM erlang:${ERLANG_VERSION}-alpine
ARG GIT_SHA
ARG BUILD_TIME
ENV GIT_SHA=${GIT_SHA}
ENV BUILD_TIME=${BUILD_TIME}
COPY healthcheck.sh /app/healthcheck.sh
RUN \
  chmod +x /app/healthcheck.sh \
  && addgroup --system webapp \
  && adduser --system webapp -g webapp
USER webapp
COPY --from=build /app/build/erlang-shipment /app
COPY ./assets/ ./app/assets/
WORKDIR /app
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]
