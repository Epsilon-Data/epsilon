#!/bin/bash
# TODO: collabse this script with other init/setup scripts
function faketty { script -qfc "$(printf "%q " "$@")" /dev/null ; }

if [[ -z "$START_TIMEOUT" ]]; then
    START_TIMEOUT=900
fi

start_timeout_exceeded=false
count=0
step=30
start=`date +%s`
echo "Setting up Atlas..."

runtime=$((end-start))
while netstat -lnt | awk '$4 ~ /:21000$/ {exit 1}'; do
   sleep $step;
   check=`date +%s`
   runtime=`date -d@$((check-start)) -u +%H:%M:%S`
   echo "Waiting for Atlas Web-UI to be ready. Runtime $runtime"
   count=$(expr $count + $step)
   if [ $count -gt $START_TIMEOUT ]; then
       start_timeout_exceeded=true
       break
   fi
done

if [ "$start_timeout_exceeded" = "false" ]; then
    # Setup atlas types
    printf "Creating achetype-asset type... \n"
    curl -i -X POST -H 'Content-Type: application/json' -H 'Accept: application/json' -u admin:${ATLAS_ADMIN_PASSWORD} ${ATLAS_URI}'/api/atlas/v2/types/typedefs' -d @/tmp/model/typedef-archetype-asset.json
    printf "\nachetype-asset created\n"

    # Setup atlas classification defs
    printf "Creating classifications type... \n"
    curl -i -X POST -H 'Content-Type: application/json' -H 'Accept: application/json' -u admin:${ATLAS_ADMIN_PASSWORD} ${ATLAS_URI}'/api/atlas/v2/types/typedefs' -d @/tmp/model/typedef-classification.json
    printf "\nclassifications type created\n"
    
    touch ${ATLAS_HOME}/.setupDone

    sleep 15
    echo "Done setting up Atlas types "

else
    echo "Waited too long for Atlas to start, skipping setup..."
fi
