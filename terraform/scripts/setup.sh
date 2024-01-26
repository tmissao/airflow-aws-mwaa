#!/bin/bash

set -e
set -u
set -o pipefail
# set -x

echo "#########################################################################################"
echo "#                       Starting Installing Docker                                      #"
echo "#########################################################################################"
yum install docker -y
usermod -a -G docker ec2-user

wget https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) 
mv docker-compose-$(uname -s)-$(uname -m) /usr/local/bin/docker-compose
chmod -v +x /usr/local/bin/docker-compose

systemctl enable docker.service
systemctl start docker.service

echo "#########################################################################################"
echo "#                              Setup PosgresDB                                          #"
echo "#########################################################################################"

echo "${DOCKER_COMPOSE}" | base64 --decode > docker-compose.yml
mkdir sql
echo "${SQL_SCRIPT_GENERATE_DATA}" | base64 --decode > sql/generate-data.sql
docker-compose -p postgres up -d