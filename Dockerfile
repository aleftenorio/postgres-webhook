FROM alpine:3.7 as builder

LABEL description="Build container"

RUN apk add --update --no-cache \
  binutils \
  file \
  gcc \
  g++ \
  libgcc \
  make \
  pkgconf \
  curl-dev \
  postgresql-dev

COPY ./src /postgres-webhook/src
COPY Makefile /postgres-webhook/
WORKDIR /postgres-webhook
RUN make

FROM alpine:3.7

LABEL maintainer="alex.3.dj@gmail.com"
LABEL description="PostgreSql notify webhook"

RUN apk add --update --no-cache --virtual .build-deps \
  tzdata \
  libcurl \
  libpq

ENV DBNAME "iglobal"
ENV PGUSER "postgres"
ENV PGPASS "MasterKey!!"
ENV PGHOST "201.55.174.50"
ENV PGPORT 5432
ENV WEBHOOKURL "http://localhost:5000"
ENV LOG_LEVEL "2"
ENV TIMEZONE "America/Sao_Paulo"

RUN cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
  && echo "${TIMEZONE}" >  /etc/timezone \
  && apk del tzdata

COPY --from=builder /postgres-webhook/build/postgres-webhook /usr/bin/postgres-webhook

COPY Makefile /postgres-webhook/

WORKDIR /postgres-webhook

CMD "postgres-webhook" "host=${PGHOST} port=${PGPORT} dbname=${DBNAME} user=${PGUSER} password=${PGPASS}" "${WEBHOOKURL}" "${LOG_LEVEL}"
