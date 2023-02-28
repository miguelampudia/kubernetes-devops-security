#!/bin/bash

#k8s-deployment-rollout-status.sh

sleep 60s

if [[ $(kubectl -n ${namespaceName} rollout status deploy ${deploymentName} --timeout 5s) != *"successfully rolled out"* ]]; 
then     
	echo "Deployment ${deploymentName} Rollout has Failed"
    kubectl -n ${namespaceName} rollout undo deploy ${deploymentName}
    exit 1;
else
	echo "Deployment ${deploymentName} Rollout is Success"
fi