#!/bin/bash
readonly BASENAME="$(basename "${0}")"
readonly SQLS=(`find /docker-entrypoint-initdb.d -name *.sql | sort`)
for SQL in "${SQLS[@]}" ; do
    echo "${BASENAME}:${SQL}"
    mysql -u ${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_PASSWORD} <${SQL}
done
