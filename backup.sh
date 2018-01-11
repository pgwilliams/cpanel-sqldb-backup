#!/bin/bash

serverUrl="https://address:port"
loginUrl="${serverUrl}/login/"
username="<Your Username Here>"
password="<Your cPanel Password Here"
dbName="<databaseName here>"
tempFile=login_result.tmp
storageRoot="/tmp"
extension=".sql.gz"

#Log in and recover the session cookie and location
echo "Logging in to $loginUrl"
sessionLocation=`curl -s -i -F "user=$username" -F "pass=$password" $loginUrl | \
tee $tempFile | \
grep "Location" | cut -d "/" -f2`

sessionCookie=`grep cpsession $tempFile | sed 's/Set-Cookie:.\([^;]*\).*/\1/'`

echo "Recovered Location: $sessionLocation and cookie: $sessionCookie"

today=`date +%Y%m%d`
saveFilename="${dbName}_${today}${extension}"
dailyRoot="${storageRoot}/daily"
weeklyRoot="${storageRoot}/weekly"
monthyRoot="${storageRoot}/monthly"
yearlyRoot="${storageRoot}/yearly"
saveLocation="${dailyRoot}/${saveFilename}"

if [ ! -d "${dailyRoot}" ]; then
  mkdir -p ${dailyRoot}
fi

if [ ! -d "${weeklyRoot}" ]; then
  mkdir -p ${weeklyRoot}
fi

if [ ! -d "${monthlyRoot}" ]; then
  mkdir -p ${monthlyRoot}
fi

if [ ! -d "${yearlyRoot}" ]; then
  mkdir -p ${yearlyRoot}
fi

backupUrl="${serverUrl}/${sessionLocation}/getsqlbackup/${dbName}${extension}"
echo "Recovering database backup from: $backupUrl"
echo "Saving to: ${saveLocation}"
curl -o ${saveLocation} --cookie ${sessionCookie} $backupUrl > download_result.tmp
echo "Download complete"

dayOfWeek=`date +%u`
if [[ $dayOfWeek == "1" ]]; then
	echo "First day of week, copying to ${weeklyRoot}"
	cp "${saveLocation}" "${weeklyRoot}/${saveFilename}"
fi

dayOfMonth=`date +%d`
if [[ $dayOfMonth == "01" ]]; then
	echo "First day of month, copying to ${monthlyRoot}"
        cp "${saveLocation}" "${monthlyRoot}/${saveFilename}"
fi

dayOfYear=`date +%j`
if [[ $dayOfYear == "001" ]]; then
        echo "First day of year, copying to ${yearlyRoot}"
        cp "${saveLocation}" "${monthlyRoot}/${saveFilename}"
fi

#Now delete files that have been copied out
find ${dailyRoot} -type f -mtime +7 -name '*.gz' -execdir rm -- '{}' \;
find ${weeklyRoot} -type f -mtime +35 -name '*.gz' -execdir rm -- '{}' \;
