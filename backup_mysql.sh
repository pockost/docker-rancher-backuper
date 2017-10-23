#!/bin/bash

# La variable report dir base contient le dossier de base de destination des backups
BACKUP_DIR=${REPORT_BASE_DIR:-/tmp/backup/mysql}

rm -r $BACKUP_DIR/*

CONTAINER_TO_BACKUP=$( docker ps |grep -e 'mysql\|mariadb\|db' | awk '{ print $1 }' )
for container in $( echo "$CONTAINER_TO_BACKUP" )
do
  # Check if container has mysqldump
  docker exec -it $container which mysqldump &>/dev/null || continue

  # Retreive rancher current stack and service name
  STACK_SERVICE_NAME=$(docker inspect $container --format='{{json .Config.Labels}}'| python  -c "import sys, json; print json.load(sys.stdin)['io.rancher.stack_service.name']")
  if [ "$STACK_SERVICE_NAME" = "" ]
  then
    CONTAINER_NAME=$( docker inspect $container --format='{{json .Name}}' )
    STACK_SERVICE_NAME="no_service/${CONTAINER_NAME}"
  fi
  CURRENT_BACKUP_DIR="${BACKUP_DIR}/${STACK_SERVICE_NAME}"
  mkdir -p $CURRENT_BACKUP_DIR

  # Get list of database to backup
  databases=$( docker exec -it $container bash -c 'echo "show databases;" | mysql -uroot -p$MYSQL_ROOT_PASSWORD' | grep -v '^Database' | grep -v '^information_schema' | grep -v 'performance_schema')

  for database in $( echo ${databases} )
  do
    # prevent space to be store in database name
    database=$( echo $database | tr -d '[:space:]' )
    docker exec -e DATABASE_TO_BACKUP=$database -it $container bash -c 'mysqldump -uroot -p$MYSQL_ROOT_PASSWORD $DATABASE_TO_BACKUP' | gzip > ${CURRENT_BACKUP_DIR}/${database}.sql.gz
  done
done

echo "End of backup."
