#!/bin/bash
set -e

apt-get update
apt-get upgrade -y
apt-get install -y docker.io
usermod -aG docker ubuntu
systemctl start docker
systemctl enable docker

mkdir -p /home/ubuntu/output
chown ubuntu:ubuntu /home/ubuntu/output

docker pull joaolfms/contador-eventos:latest
docker run -d --name contador \
  -v /home/ubuntu/output:/app \
  --restart unless-stopped \
  joaolfms/contador-eventos:latest