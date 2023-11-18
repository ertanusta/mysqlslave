#!/bin/bash



rm -rf ./storage/master/data/*
rm -rf ./storage/slave_1/data/*
rm -rf ./storage/slave_2/data/*

docker compose up -d

until docker exec mysql_master sh -c 'export MYSQL_PWD=password; mysql -u root -e ";"'
do
    echo "Waiting for mysql_master database connection..."
    sleep 4
done


until docker exec mysql_slave_1 sh -c 'export MYSQL_PWD=password; mysql -u root -e ";"'
do
    echo "Waiting for mysql_slave_1 database connection..."
    sleep 4
done
until docker exec mysql_slave_2 sh -c 'export MYSQL_PWD=password; mysql -u root -e ";"'
do
    echo "Waiting for mysql_slave_2 database connection..."
    sleep 4
done


docker exec mysql_master sh -c "mysql -u root -ppassword -e 'CREATE USER \"slave_user_1\"@\"%\" IDENTIFIED BY \"password\"; GRANT REPLICATION SLAVE ON *.* TO \"slave_user_1\"@\"%\"; FLUSH PRIVILEGES;'"

docker exec mysql_master sh -c "mysql -u root -ppassword -e 'CREATE USER \"slave_user_2\"@\"%\" IDENTIFIED BY \"password\"; GRANT REPLICATION SLAVE ON *.* TO \"slave_user_2\"@\"%\"; FLUSH PRIVILEGES;'"

MS_STATUS=`docker exec mysql_master sh -c 'mysql -u root -ppassword -e "SHOW MASTER STATUS"'`
CURRENT_LOG=`echo $MS_STATUS | awk '{print $6}'`
CURRENT_POS=`echo $MS_STATUS | awk '{print $7}'`

start_slave_stmt="CHANGE MASTER TO MASTER_HOST='mysql_master',MASTER_USER='slave_user_1',MASTER_PASSWORD='password',MASTER_LOG_FILE='$CURRENT_LOG',MASTER_LOG_POS=$CURRENT_POS; START SLAVE;"
start_slave_cmd='mysql -u root -ppassword -e "'
start_slave_cmd+="$start_slave_stmt"
start_slave_cmd+='"'
docker exec mysql_slave_1 sh -c "$start_slave_cmd"

start_slave_stmt="CHANGE MASTER TO MASTER_HOST='mysql_master',MASTER_USER='slave_user_2',MASTER_PASSWORD='password',MASTER_LOG_FILE='$CURRENT_LOG',MASTER_LOG_POS=$CURRENT_POS; START SLAVE;"
start_slave_cmd='mysql -u root -ppassword -e "'
start_slave_cmd+="$start_slave_stmt"
start_slave_cmd+='"'
docker exec mysql_slave_2 sh -c "$start_slave_cmd"

docker exec mysql_master sh -c "mysql -u root -ppassword -e 'CREATE USER '\''haproxy_check'\''@'\''%'\'"
