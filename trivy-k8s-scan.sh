#!/bin/bash


echo $imageName #getting Image name from env variable

docker run --rm -v $WORKSPACE:/root/.cache/ aquasec/trivy -q image --exit-code 0 --severity LOW,MEDIUM,HIGH --scanners vuln --timeout 30m $imageName
docker run --rm -v $WORKSPACE:/root/.cache/ aquasec/trivy -q image --exit-code 0 --severity CRITICAL --scanners vuln  --timeout 30m $imageName

    # Trivy scan result processing
    exit_code=$?
    echo "Exit Code : $exit_code"

    # Check scan results
    if [[ ${exit_code} == 1 ]]; then
        echo "Image scanning failed. Vulnerabilities found"
        exit 1;
    else
        echo "Image scanning passed. No vulnerabilities found"
    fi;
