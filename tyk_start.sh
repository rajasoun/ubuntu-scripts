#! /bin/bash

# This script will set up a full tyk environment on your machine
# and also create a demo user for you with one command

# USAGE
# -----
#
# $> ./tyk_quickstart.sh {IP ADDRESS OF DOCKER VM}

# OSX users will need to specify a virtual IP, linux users can use 127.0.0.1

docker0_ip=`ip addr show dev docker0 | awk -F'[ /]*' '/inet /{print $3}'`
if [ -z "$1" ]
then
        echo "Please specify the docker IP Address (e.g. ./quickstart $docker0_ip)"
        exit
fi

LOCALIP=$1 
#RANDOM_USER=$(env LC_CTYPE=C tr -dc "a-z0-9" < /dev/urandom | head -c 10)
USER="rajasoun"
PASS="Cisco@123"

echo "Clean up (ignore any errors)"
docker stop tyk_mongo && docker rm tyk_mongo
docker stop tyk_redis && docker rm tyk_redis
docker stop tyk_nginx && docker rm tyk_nginx
docker stop tyk_dashboard && docker rm tyk_dashboard
docker stop tyk_gateway && docker rm tyk_gateway

echo "Pulling latest containers"
docker pull redis:latest
docker pull mongo:latest
docker pull tykio/tyk-gateway:latest
docker pull tykio/tyk-dashboard:latest
docker pull tykio/tyk-host-manager:latest

echo "Setting up Mongo and Redis"
docker run --dns=$docker0_ip --hostname="redis-server"   -d --name tyk_redis redis
docker run --dns=$docker0_ip --hostname="mongo-server"   -d --name tyk_mongo mongo --smallfiles

echo "Setting up Tyk gateway"
docker run --dns=$docker0_ip --hostname="tyk-gateway"    -d --name tyk_gateway -p 8080:8080 --link tyk_redis:redis --link tyk_mongo:mongo tykio/tyk-gateway

echo "Setting up Tyk dashboard"
docker run --dns=$docker0_ip --hostname="tyk-dashboard"  -d --name tyk_dashboard -p 3000:3000 --link tyk_redis:redis --link tyk_mongo:mongo --link tyk_gateway:tyk_gateway tykio/tyk-dashboard

echo "Setting up NginX and Host Manager"
docker run --dns=$docker0_ip --hostname="tyk-nginx"   -d --name tyk_nginx -p 8888:80 --link tyk_gateway:tyk_gateway --link tyk_dashboard:tyk_dashboard --link tyk_mongo:tyk_mongo --link tyk_redis:tyk_redis -e DOMAINALIAS=tyk.docker tykio/tyk-host-manager

sleep 2

echo "Creating Organisation"
ORGDATA=$(curl --silent --header "admin-auth: 12345" --header "Content-Type:application/json" --data '{"owner_name": "EaaS API Mgmt","owner_slug": "Cisco-CK"}' http://$LOCALIP:3000/admin/organisations 2>&1)
#echo $ORGDATA
ORGID=$(echo $ORGDATA | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["Meta"]')
echo "ORGID: $ORGID" 

echo "Adding new user"
USER_DATA=$(curl --silent --header "admin-auth: 12345" --header "Content-Type:application/json" --data '{"first_name": Raja","last_name": "Soundaramourty","email_address": "'$USER'@cisco.com","active": true,"org_id": "'$ORGID'"}' http://$LOCALIP:3000/admin/users 2>&1)
#echo $USER_DATA
USER_CODE=$(echo $USER_DATA | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["Message"]')
echo "USER AUTH: $USER_CODE" 

USER_LIST=$(curl --silent --header "authorization: $USER_CODE" http://$LOCALIP:3000/api/users 2>&1)
#echo $USER_LIST

USER_ID=$(echo $USER_LIST | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["users"][0]["id"]')
echo "NEW ID: $USER_ID"

echo "Setting password"
OK=$(curl --silent --header "authorization: $USER_CODE" --header "Content-Type:application/json" http://$LOCALIP:3000/api/users/$USER_ID/actions/reset --data '{"new_password":"'$PASS'"}')

echo ""

echo "DONE"
echo "===="
echo "Login at http://$LOCALIP:3000/"
echo "User: $USER"
echo "Pass: $PASS"
echo ""
