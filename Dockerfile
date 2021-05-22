FROM elixir:1.11-alpine

ENV TERM=xterm

RUN mkdir /app
WORKDIR /app

RUN apk add --update --no-cache bash less git make curl wget jq ca-certificates tmux musl libgcc libstdc++ &&\
    rm -rf /var/cache/apk/*

ENV DOCKER_CONTAINER_NAME=secrets \
    MIX_DEPS_PATH=/opt/mix \
    MIX_BUILD_PATH=/opt/mix 

RUN mkdir -p /opt/mix && \ 
    mix do local.hex --force, local.rebar --force

ENV PORT=4000 SHELL=/bin/bash
CMD ["sh", "-c", "tail -f /dev/null"]
