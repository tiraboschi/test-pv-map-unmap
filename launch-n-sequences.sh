#!/bin/bash
# Namespace to contain test objects
NAMESPACE=${NAMESPACE:-default}
# Number of jobs to be executed in parallel (one PVC for each job)
NUMPARALLEL=${NUMPARALLEL:-150}
# Number of seconds between a (fake) write pod and the next one for the same PVC
SLEEPSECONDS=${SLEEPSECONDS:-900}
# Minimum number of seconds elapsed in a (fake) write task
MINWRITESECONDS=${MINWRITESECONDS:-120}
# Maximum number of seconds elapsed in a (fake) write task
MAXWRITESECONDS=${MAXWRITESECONDS:-300}
# PVC Access Mode
PVCACCESSMODE=${PVCACCESSMODE:-ReadWriteMany}
# Number of iteration (write->sleep) for each PVC
ITERATIONS=${ITERATIONS:-10}

echo "##########"
echo "This script will create ${NUMPARALLEL} parallel jobs."
echo "Each job will create a ${PVCACCESSMODE} PVC and it will iterate ${ITERATIONS} times the creation of a pod to keep the PVC busy followed by another pod that is not going to use it."
echo "Each \"diskwriter\" pod will keep the PV busy (mounted) for a random number of seconds between ${MINWRITESECONDS} and ${MAXWRITESECONDS}, the following \"sleeper\" pod will simply sleep for ${SLEEPSECONDS} seconds."
EXPELAPSED=$(( (($MINWRITESECONDS + $MAXWRITESECONDS)/2 + $SLEEPSECONDS) * $ITERATIONS ))
echo "The test is expected to be executed in around $EXPELAPSED seconds ($(($EXPELAPSED/3600)) hours)."
echo "The test is expected to perform $(( $NUMPARALLEL * 3600 / ((($MINWRITESECONDS + $MAXWRITESECONDS)/2 + $SLEEPSECONDS) ))) map/unmap cycles/hour."
echo "##########"
echo
echo "Deleting leftovers..."
oc delete job -n ${NAMESPACE} -l=name=pv-sequence-job
oc wait --for=delete -n ${NAMESPACE} pvc -l=type=pvc-sequence --timeout=180s
echo "Creating resources..."
oc apply -n ${NAMESPACE} -f pod-templates-configmap.yaml
oc apply -n ${NAMESPACE} -f serviceaccount.yaml
oc apply -f clusterrole.yaml
oc apply -n ${NAMESPACE} -f rolebinding.yaml

echo "Launching $NUMPARALLEL sequences..."

for instance in $(seq -w 0001 $NUMPARALLEL); do
  sed "s/{{INSTANCE}}/$instance/g" sequence-job.yaml | sed "s/{{NAMESPACE}}/$NAMESPACE/g" | sed "s/{{SLEEPSECONDS}}/$SLEEPSECONDS/g" | sed "s/{{MINWRITESECONDS}}/$MINWRITESECONDS/g" | sed "s/{{MAXWRITESECONDS}}/$MAXWRITESECONDS/g" | sed "s/{{PVCACCESSMODE}}/$PVCACCESSMODE/g" | sed "s/{{ITERATIONS}}/$ITERATIONS/g" | oc apply -n ${NAMESPACE} -f -
  sleep 1
done

echo
echo "##########"
echo "All the jobs got launched!"
echo "Please continue monitoring pod creation times"
