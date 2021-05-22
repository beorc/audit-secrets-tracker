FROM elixir:1.11-alpine

ENV TERM=xterm

RUN apk --no-cache add postgresql curl jq sudo &&\
    rm -rf /var/cache/apk/*

RUN addgroup docker -g 1000 && \
adduser docker -u 1000 -s /bin/ash -SDG docker && \
echo "docker ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

ENV USER docker
ENV APP app
ENV HOME=/home/$USER
ENV HEX_HTTP_CONCURRENCY 1
ENV HEX_HTTP_TIMEOUT 120


USER $USER
WORKDIR $HOME/$APP/apps/secrets

RUN mix local.hex --force && \
    mix local.rebar --force

ENV SHELL=/bin/sh

CMD mix run --no-halt
