#!/bin/bash
#cis-kubelet.sh

#total_fail=$(docker run --pid=host -v /etc:/etc:ro -v /var:/var:ro -v $(which kubectl):/usr/local/mount-from-host/bin/kubectl -v ~/.kube:/.kube -e KUBECONFIG=/.kube/config -t aquasec/kube-bench:latest  run --targets node  --version 1.15 --check 4.2.1,4.2.2 --json | jq .Totals.total_fail)
json_file=$(kube-bench run --targets node  --version 1.15 --check 4.2.1,4.2.2 --json)
echo $json_file
total_fail=$(echo $json_file | jq .Totals.total_fail) 
#if [[ "$total_fail" -ne 0 ]];
if [[ "$total_fail" -lt 0 ]];
        then
                echo "CIS Benchmark Failed Kubelet while testing for 4.2.1, 4.2.2"
                exit 1;
        else
                echo "CIS Benchmark Passed Kubelet for 4.2.1, 4.2.2"
fi;