# Audit/Secrets/Tracker

## Umbrella apps description

    Audit -- PostgreSQL-backed audit log support
    Secrets -- PostgreSQL roles management
    Tracker -- PostgreSQL-backed locks for providing uniqueness for recurring tasks in case of multiple instances of apps
    SharedModules -- Utility modules shared between multiple applications

## Setup test environment:

    $ docker-compose run --rm app sh
    $ MIX_ENV=test make setup
