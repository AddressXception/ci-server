#!/bin/bash

docker rmi vsts-build-agent
docker build -t vsts-build-agent:latest .