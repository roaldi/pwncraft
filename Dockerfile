FROM alpine:3.6 AS wget
RUN apk add --no-cache ca-certificates wget tar

FROM wget AS docker
ARG DOCKER_VERSION=18.06.3-ce
RUN wget -qO- https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz | \
  tar -xvz --strip-components=1 -C /bin

FROM beevelop/base as cuberite

ENV ADMIN_USERNAME=admin \
    ADMIN_PASSWORD=Swordfish \
    MAX_PLAYERS=30

COPY webadmin.ini.tpl /srv/

WORKDIR /srv
RUN apt-get update && apt-get install -y curl gettext-base && \
    mkdir cuberite && cd cuberite && \
    curl -sSfL https://download.cuberite.org | sh


FROM golang:1.9 AS dockercraft
WORKDIR /go/src/github.com/docker/dockercraft
COPY . .
RUN go install

FROM debian:buster 
RUN apt-get update; apt-get install -y ca-certificates
COPY --from=dockercraft /go/bin/dockercraft /bin
COPY --from=docker /bin/docker /bin
COPY --from=cuberite /srv /srv

# Copy Dockercraft config and plugin
COPY ./config /srv/cuberite
COPY ./docs/img/logo64x64.png /srv/cuberite/Server/favicon.png
COPY ./Docker /srv/cuberite/Plugins/Docker

EXPOSE 25565
ENTRYPOINT ["/srv/cuberite/start.sh"]

