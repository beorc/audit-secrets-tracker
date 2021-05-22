# Secrets

## Test suite

    $ mix deps.get
    $ MIX_ENV=test make setup
    $ createdb -h postgres -U postgres -W dummy
    $ mix test

## Set up users for the app

    $ export RDSHOST=xxxxx.xxxxxxxxx.us-east-1.rds.amazonaws.com
    $ psql "host=$RDSHOST dbname=postgres user=postgres sslrootcert=/etc/rds/tls/rds-combined-ca-bundle.pem sslmode=verify-full port=5432"
    > CREATE USER secrets WITH LOGIN CREATEROLE; 
    > GRANT rds_iam TO secrets;
    > GRANT rds_superuser TO secrets;
