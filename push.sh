#!/bin/bash

for i in "$@"; do
    case $i in
        -r=*|--registry=*)
        REGISTRY="${i#*=}"
        shift
        ;;
        -u=*|--username=*)
        USERNAME="${i#*=}"
        shift
        ;;
        -p=*|--password=*)
        PASSWORD="${i#*=}"
        shift
        ;;
        -i=*|--imageName=*)
        IMAGE_NAME="${i#*=}"
        shift
        ;;
    esac
    shift
done

echo "logging into registry ${REGISTRY}"
docker login -u $USERNAME -p $PASSWORD $REGISTRY

IMAGE_FQDN="${REGISTRY}/${IMAGE_NAME}"

docker tag $IMAGE_NAME $IMAGE_FQDN

echo "pushing ${IMAGE_FQDN}"
docker push $IMAGE_FQDN
