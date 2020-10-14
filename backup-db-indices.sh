#!/bin/bash

## All needs to be in lower case

### /data01/snapshot/netbackup_stat/02mar2019
### /data01/snapshot/netbackup_stat --> snapshot dir
### 02mar2019 --> backup name, but you won't see that name on linux prompt anywhere, sorry it is confusing, took me while to figure out.

### We will do two backup a week and remove older backup then 7 days.
### each backup will be name like
### /data01/snapshot/<indice_name>/<today_date>

### remove, /data01/snapshot/<indice_name>/<eight_day_old_date>
### I am using Indice name as snapshot name that way all the indice are on different dirs.


#### Variable setup
### hopefully nothing else needs to be set after changing variables
URL=
storage_path="/data01/snapshot"
HOSTNAME=`hostname`
today=`date +%d%b%Y | tr '[:upper:]' '[:lower:]'`
eight_days_ago=`date --date="8 days ago" +%d%b%Y |tr '[:upper:]' '[:lower:]'`
########

## Get list of index except kibana,metricbeat and monitor index.
## we will do kibana later
curl -XGET ${URL}/_cat/indices |egrep -v 'monitor|kibana|metric' |grep -v Speed |awk '{print $3}' > /tmp/list_indices
## Remove some unwanted index
sed -i '/--/d' /tmp/list_indices

     # echo "Now delete snapshot older then 7 days
for indice in `cat /tmp/list_indices`
do
   echo "Delete backup of $indice named/location ${storage_path}/$indice/${eight_days_ago}"
   curl -XDELETE "${URL}/_snapshot/${indice}/${eight_days_ago}"
   sleep 60
   echo
done

###  Register snapshot repository now
###  This is not actual backup just register repository
### /data01/snapshot/<snapshot name> , $indice = snapshot name here

for indice in `cat /tmp/list_indices`
do
   echo "Creating snapshot repository for $indice at ${storage_path}/${indice}/"
   curl -XPUT "${URL}/_snapshot/${indice}/" -H "Content-Type: application/json" -d"
 {
  \"type\": \"fs\",
  \"settings\": {
    \"location\": \"${storage_path}/${indice}/\"
  }
}"
  sleep 5
   echo
done

### echo " Now doing actual backup"
### /data01/snapshot/hou_netbackup_stat/02mar2019 ( backup name will be recognize like this )
# GET /_snapshot/hou_netbackup_stat/07mar2019/_status?pretty  ---> if you want to know status of one backup

### $today = backup name in to /data01/snapshot/<indicename> dir.

for indice in `cat /tmp/list_indices`
do
   echo "Actual backup of $indice to ${storage_path}/$indice/$today"
curl -XPUT "${URL}/_snapshot/${indice}/${today}?wait_for_completion=true" -H "Content-Type: application/json" -d"
{
    \"indices\": \"${indice}\",
     \"ignore_unavailable\": true
}"
   echo
   sleep 6
done

#### Enjoy automatic backup.
