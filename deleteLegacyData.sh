#!/bin/bash

# 2020-06-04

# local test
HOST=localhost
USER=postgres
DB=postgres
export PGPASSWORD=

DATE_STR=`date -d '-3 month' "+%Y%m%d"`
NOW=`date`
YEAR=${DATE_STR:0:4}
MONTH=${DATE_STR:4:2}
DATE=${DATE_STR:6:2}
query="delete from  where blabla_date < '${YEAR}-${MONTH}-${DATE} 00:00:00'"

psql -h $HOST -U $USER -d $DB -c "select 1" -o /dev/null
query_response=`echo $?`
if [ ${query_response} != "0" ]; then
	echo "[ERROR]$NOW cannot connect $USER@$HOST:5432/$DB; EXIT_CODE:$query_response; try: 1" >> csvBatch_error.log
	echo "[ERROR]$NOW cannot connect $USER@$HOST:5432/$DB; EXIT_CODE:$query_response; try: 1"
	sleep 5s
	psql -h $HOST -U $USER -d $DB -c "select 1" -o /dev/null
	query_response=`echo $?`
	if [ ${query_response} != "0" ]; then
		echo "[ERROR]$NOW cannot connect $USER@$HOST:5432/$DB; EXIT_CODE:$query_response; try: 2" >> csvBatch_error.log
		echo "[ERROR]$NOW cannot connect $USER@$HOST:5432/$DB; EXIT_CODE:$query_response; try: 2"
		sleep 5s
		psql -h $HOST -U $USER -d $DB -c "select 1" -o /dev/null
		query_response=`echo $?`
		if [ ${query_response} != "0" ]; then
			echo "[ERROR]$NOW cannot connect $USER@$HOST:5432/$DB; EXIT_CODE:$query_response; try: 3; EXIT" >> csvBatch_error.log
			echo "[ERROR]$NOW cannot connect $USER@$HOST:5432/$DB; EXIT_CODE:$query_response; try: 3; EXIT"
			query_test="F"
			#exit $query_response
		fi
	fi
fi

psql -h $HOST -U $USER -d $DB -c "$query" -o /dev/null
echo "[DELETE]$NOW "$YEAR"-"$MONTH"-"$DATE" 이전의 레거시 데이터 삭제 blabla" >> csvBatch.log
