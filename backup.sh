#!/bin/bash

bucket=""
s3Key=""
s3Secret=""
# remote S3 folder to upload to
remote_path=""
# file name should end with .gz
file_name="dump.gz"
# public ip address of database server
db_remote_host=""
db_username="postgres"
db_userpassword="postgres"
db_name=""

# ----------------------------------------------

now_date=$(date +"%d%b%Y")
now_time=$(date +"%H%M%S")
contentType="application/gzip"
dateFormatted=`date -R`

function pushToS3()
{
	fname=$1
	echo "$(date +"%s"): Start sending $fname to S3"
	resource="/${bucket}/${remote_path}/${now_date}_${now_time}_${fname}"
	stringToSign="PUT\n\n${contentType}\n${dateFormatted}\n${resource}"
	signature=`echo -en ${stringToSign} | openssl sha1 -hmac ${s3Secret} -binary | base64`
	status_code=$(curl --write-out %{http_code} --silent --output /dev/null -X PUT -T "${fname}" \
	 -H "Host: ${bucket}.s3.amazonaws.com" \
	 -H "Date: ${dateFormatted}" \
	 -H "Content-Type: ${contentType}" \
	 -H "Authorization: AWS ${s3Key}:${signature}" \
	  https://${bucket}.s3.amazonaws.com/${remote_path}/${now_date}_${now_time}_${fname}
	)
	if [[ "$status_code" == 200 ]] ; then
	  echo "$(date +"%s"): $fname has been sent to S3 successfully." 
	else
	  echo "$(date +"%s"): Failed to upload $fname to S3."
	fi
}

function dumpDatabase()
{
	echo "$(date +"%s"): Connecting to database"
	PGPASSWORD=${db_userpassword} pg_dump --format=plain --username=${db_username} --host=${db_remote_host} --port=5432 ${db_name} | gzip > $file_name
}

find . -name ${file_name} -delete
dumpDatabase
pushToS3 $file_name
