#!/bin/bash

#integration-test.sh

sleep 5s

PORT=$(kubectl -n default get svc ${serviceName} -n ${namespaceName} -o json | jq .spec.ports[].nodePort)

echo $PORT
echo $applicationURL$applicationURI

if [[ ! -z "$PORT" ]];
then

    response=$(curl -s -K $applicationURL$applicationURI)
    http_code=$(curl -s -o /dev/null -w -K "%{http_code}" $applicationURL$applicationURI)

    if [[ "$response" == 100 ]];
        then
            echo "Increment Test Passed"
        else
            echo "Increment Test Failed"
            exit 1;
    fi;

    if [[ "$http_code" == 200 ]];
        then
            echo "HTTP Status Code Test Passed"
        else
            echo "HTTP Status code is not 200"
            exit 1;
    fi;

else
        echo "The Service does not have a NodePort"
        exit 1;
fi;
