#!/bin/bash

docker rmi ci-server-base
docker build -t ci-server-base:latest .