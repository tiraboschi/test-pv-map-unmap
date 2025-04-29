# test-pv-map-unmap
Stress test PV map/unmap behavior on k8s.

This repo provides a test script to stress test the impact of map/unmap cycles
caused by pods with block volumes on the underlying storage array.

## Execution
```bash
$ ./launch-n-sequences.sh 
##########
This script will create 150 parallel jobs.
Each job will create a ReadWriteMany PVC and it will iterate 10 times the creation of a pod to keep the PVC busy followed by another pod that is not going to use it.
Each "diskwriter" pod will keep the PV busy (mounted) for a random number of seconds between 120 and 300, the following "sleeper" pod will simply sleep for 900 seconds.
The test is expected to be executed in around 11100 seconds (3 hours).
The test is expected to perform 486 map/unmap cycles/hour.
##########

Deleting leftovers...
No resources found
Creating resources...
configmap/pod-templates created
serviceaccount/test-map-unmap created
clusterrole.rbac.authorization.k8s.io/test-map-unmap unchanged
rolebinding.rbac.authorization.k8s.io/test-map-unmap created
Launching 150 sequences...
job.batch/sequence-0001 created
job.batch/sequence-0002 created
job.batch/sequence-0003 created
...
job.batch/sequence-0149 created
job.batch/sequence-0150 created

##########
All the jobs got launched!
Please continue monitoring pod creation times
```

## Customization
The execution can be customized with the following environmental variables:

| Name             | Description                                                                    | Default value |
|------------------|--------------------------------------------------------------------------------|---------------|
| NAMESPACE        | Namespace to contain test objects                                              | default       |
| NUMPARALLEL      | Number of jobs to be executed in parallel (one PVC for each job)               | 150           |
| SLEEPSECONDS     | Number of seconds between a (fake) write pod and the next one for the same PVC | 900           |
| MINWRITESECONDS  | Minimum number of seconds elapsed in a (fake) write task                       | 120           |
| MAXWRITESECONDS  | Maximum number of seconds elapsed in a (fake) write task                       | 300           |
| PVCACCESSMODE    | PVC Access Mode                                                                | ReadWriteMany |
| ITERATIONS       | Number of iteration (write->sleep) for each PVC                                | 10            |
| STORAGECLASSNAME | Name of the Storage Class to create volumes                                    | ""            |


