#!/bin/bash

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
echo "#                        Building Custom EMR Image                                      #"
echo "#########################################################################################"

# aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin 895885662937.dkr.ecr.us-west-2.amazonaws.com

echo "${DOCKER_FILE}" | base64 --decode > Dockerfile
