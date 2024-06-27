#!/bin/bash

Help()
{
   # Display Help
   echo "Dell EMC PowerVault ME4 API system information JSON retriever"
   echo
   echo "Syntax: $(basename $0) [-h|i|u|p|m]"
   echo
   echo "Options:"
   echo "-h     Print this Help."
   echo "-i     Management IP address of the PowerVault ME4"
   echo "-u     PowerVault ME4 username"
   echo "-p     PowerVault ME4 username's password"
   echo "-m     Module to fetch from the storage array."
   echo
}


# -------------------------------------------------------------------

if [[ $? -ne 0 ]]; then
    exit 1;
fi

if [[ $# -eq 0 ]]; then
    Help
    exit 1;
fi


if [ -z $2]; then
        address=$( echo $1 | grep -oP "(\-i\s)(\S+)" | sed -e 's/-i\s//' )
        user=$( echo $1 | grep -oP "(\-u\s)(\S+)" | sed -e 's/-u\s//' )
        pass="$( echo $1 | grep -oP "(\-p\s)(\S+)" | sed -e 's/-p\s//' )"
        module=$( echo $1 | grep -oP "(\-m\s)(\S+)" | sed -e 's/-m\s//' )
fi

if [ -z "$address" ]; then
        echo "No address specified."
        echo
        Help
        exit 1
elif [ -z "$user" ]; then
        echo "No username specified."
        echo
        Help
        exit 1
elif [ -z "$pass" ]; then
        echo "No password specified."
        echo
        Help
        exit 1
elif [ -z "$module" ]; then
        echo "No modules specified."
        echo
        Help
        exit 1
fi


function Connect()
{
        auth_token=$( echo $user:$pass | base64 )
        sessionkey=$( curl -sS -X GET -H "Authorization: Basic $auth_token" -H "Datatype: json"  -k https://$address/api/login | jq '.status[].response' | sed -e 's/"//g' )
        echo $sessionkey
}


sessionkey=$(Connect)

# Validate connection status
if [[ $sessionkey == "Authentication Unsuccessful" ]]; then
        echo "Invalid username and/or password"
        exit 1
fi

if [ -z $module ]; then
        echo "No module specified"
        exit 1
fi

if [[ $module == "system" ]]; then
        curl -sS -X GET -H "sessionKey: $sessionkey" -H "Datatype: json" -k https://$address/api/show/system
elif [[ $module == "service-tag" ]]; then
        curl -sS -X GET -H "sessionKey: $sessionkey" -H "Datatype: json" -k https://$address/api/show/service-tag-info
elif [[ $module == "disks" ]]; then
        curl -sS -X GET -H "sessionKey: $sessionkey" -H "Datatype: json" -k https://$address/api/show/disks | jq -M '.drives' | perl -pe 's/-(?=[^"]*"\s*:)//g'

elif [[ $module == "disk-groups" ]]; then
        curl -sS -X GET -H "sessionKey: $sessionkey" -H "Datatype: json" -k https://$address/api/show/disk-groups | jq -M '."disk-groups"' | perl -pe 's/-(?=[^"]*"\s*:)//g'

elif [[ $module == "disk-group-statistics" ]]; then
        curl -sS -X GET -H "sessionKey: $sessionkey" -H "Datatype: json" -k https://$address/api/show/disk-group-statistics | jq -M '."disk-group-statistics"' | perl -pe 's/-(?=[^"]*"\s*:)//g'

elif [[ $module == "pools" ]]; then
        curl -sS -X GET -H "sessionKey: $sessionkey" -H "Datatype: json" -k https://$address/api/show/pools | jq -M '.pools' | perl -pe 's/-(?=[^"]*"\s*:)//g'

elif [[ $module == "pool-statistics" ]]; then
        curl -sS -X GET -H "sessionKey: $sessionkey" -H "Datatype: json" -k https://$address/api/show/pool-statistics | jq -M '."pool-statistics"' | perl -pe 's/-(?=[^"]*"\s*:)//g' | jq -M 'del( .[].tierstatistics[])'

elif [[ $module == "volumes" ]]; then
        curl -sS -X GET -H "sessionKey: $sessionkey" -H "Datatype: json" -k https://$address/api/show/volumes | jq -M '.volumes' | perl -pe 's/-(?=[^"]*"\s*:)//g'
elif [[ $module == "volume-statistics" ]]; then
        curl -sS -X GET -H "sessionKey: $sessionkey" -H "Datatype: json" -k https://$address/api/show/volume-statistics | jq -M '."volume-statistics"' | perl -pe 's/-(?=[^"]*"\s*:)//g'
fi
