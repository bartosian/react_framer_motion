#!/bin/bash
source /usr/share/rvm/scripts/rvm

export PGPASSWORD=%env.POSTGRES_PASSWORD%


if  [ "%dep.Healthmatters_UpdateAWSAsg.SET_DB_FROM_TEMPLATE%" = "true" ]
then
  # create databases using template
  for DB in $(seq %PARALLEL_TESTS_CONCURRENCY% $END)
  do
    # generate knapsack node index for database
    DB_INDEX=$(primary_id=$(( $DB - 1 + ($PARALLEL_TESTS_CONCURRENCY * $KNAPSACK_PRO_CI_NODE_INDEX) )); printf -v primary_id "%02d" $primary_id; echo $primary_id)

    export POSTGRES_DB=%POSTGRES_DB%$DB_INDEX

    # skip if it is template database
    if [ $POSTGRES_DB = %dep.Healthmatters_UpdateAWSAsg.env.DATABASE_TEMPLATE% ]; then continue; fi

    # configure database for testing
    cp config/database.yml.team-city config/database.yml

    # delete old database
    RAILS_ENV=test bundle exec rake db:drop

    # delay for RDS to finish deletion step
    sleep 2

    # create new database as copy of template database
    createdb -h %env.POSTGRES_HOST% -p %env.POSTGRES_PORT% -U %env.POSTGRES_USER% -T %env.DATABASE_TEMPLATE% $POSTGRES_DB

    echo "-=-=-=- DATABASE $POSTGRES_DB CREATED USING TEMPLATE: %env.DATABASE_TEMPLATE% -=-=-=-"
  done
else
  # create databases using template
  for DB in $(seq %PARALLEL_TESTS_CONCURRENCY% $END)
  do
    # generate knapsack node index for database
    DB_INDEX=$(primary_id=$(( $DB - 1 + ($PARALLEL_TESTS_CONCURRENCY * $KNAPSACK_PRO_CI_NODE_INDEX) )); printf -v primary_id "%02d" $primary_id; echo $primary_id)

    export POSTGRES_DB=%POSTGRES_DB%$DB_INDEX
         
    # configure database for testing
    cp config/database.yml.team-city config/database.yml

    # apply migrations to existing databases
    RAILS_ENV=test bundle exec rake db:migrate

    echo "-=-=-=- DATABASE $POSTGRES_DB CREATED USING TEMPLATE: %env.DATABASE_TEMPLATE% -=-=-=-"
  done
