#!/bin/bash

#k8s-deployment.sh

sed -i "s#replace#${imageName}#g" k8s_deployment_service.yaml
kubectl -n ${namespaceName} apply -f k8s_deployment_service.yaml