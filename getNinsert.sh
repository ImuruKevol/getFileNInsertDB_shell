#!/bin/bash

# 2020-06-04

# local test
HOST=localhost
USER=postgres
DB=postgres

# your postgre password
export PGPASSWORD=

# input your info
query="insert into [SCHEMA].[TABLE_NAME] ([COLUMNS]) values "


BASE_URL='https://[SERVER_URL]'
DATE_STR=`date -d '-1 day' "+%Y%m%d"`
NOW=`date`
YEAR=${DATE_STR:0:4}
MONTH=${DATE_STR:4:2}
DATE=${DATE_STR:6:2}
FILE_NAME='[WISH_GET_FILE_NAME]_'$YEAR'-'$MONTH'-'$DATE
CSV_FILE=$FILE_NAME'.csv'
SQL_FILE=$FILE_NAME'.sql'
CSV_GET_URL=$BASE_URL'/'$YEAR-$MONTH'/'$CSV_FILE

curl_test="T"
query_test="T"

# curl test
response=`curl -L -k -s -o /dev/null -w "%{http_code}\n" $CSV_GET_URL`
if [ ${response} != "200" ]; then
	echo "[ERROR]$NOW cannot get $CSV_FILE; HTTP_STATUS:$response; try: 1" >> csvBatch_error.log
	echo "[ERROR]$NOW cannot get $CSV_FILE; HTTP_STATUS:$response; try: 1"
	sleep 10s
	response=`curl -L -k -s -o /dev/null -w "%{http_code}\n" $CSV_GET_URL`
	if [ ${response} != "200" ]; then
		echo "[ERROR]$NOW cannot get $CSV_FILE; HTTP_STATUS:$response; try: 2" >> csvBatch_error.log
		echo "[ERROR]$NOW cannot get $CSV_FILE; HTTP_STATUS:$response; try: 2"
		sleep 10s
		response=`curl -L -k -s -o /dev/null -w "%{http_code}\n" $CSV_GET_URL`
		if [ ${response} != "200" ]; then
			echo "[ERROR]$NOW cannot get $CSV_FILE; HTTP_STATUS:$response; try: 3; EXIT" >> csvBatch_error.log
			echo "[ERROR]$NOW cannot get $CSV_FILE; HTTP_STATUS:$response; try: 3; EXIT"
			curl_test="F"
			#exit $response
		fi
	fi
fi

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

if [ $query_test == "T" ] && [ $curl_test == "T" ]; then
	# -k: ssl 인증 무시
  # if you want, delete option "-k"
	curl -k -s -O $CSV_GET_URL

	cnt=0
	while read line
	do
		if [ ${cnt} -eq 0 ]; then
			cnt=$((cnt+1))
			continue
		fi

		IFS=',' read -ra params <<< "$line"
		id=${params[0]}
		created=${params[1]}
    # file body splited ','

		if [ ${cnt} -gt 1 ]; then
			query=$query', '
		fi
		cnt=$((cnt+1))
		query=${query}"('"${params[2]}"','"${params[3]}"' ...[COLUMNS...])"
	done < $CSV_FILE

	echo $query > $SQL_FILE
  # -c로 하면 길이가 길다고 명령어 에러뜸
	psql -h $HOST -U $USER -d $DB -f $SQL_FILE -o /dev/null
	rm $SQL_FILE
	rm $CSV_FILE
	echo "[INSERT]$NOW "$YEAR"-"$MONTH"-"$DATE" [LOG_TXT]" >> csvBatch.log
fi

