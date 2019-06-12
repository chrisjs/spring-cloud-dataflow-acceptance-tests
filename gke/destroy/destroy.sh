#!/usr/bin/env bash

echo "Deleting LoadBalancers.."

kubectl delete $(kubectl get svc | grep LoadBalancer | awk '{print "service/"$1}')

while [ $(kubectl get svc | grep LoadBalancer | wc -l) != 0 ]; do
  echo -n "."
done

echo "Destroying cluster"

gcloud container clusters delete ${GCLOUD_CONTAINER_CLUSTER} --zone ${GCLOUD_COMPUTE_ZONE} --project ${GCLOUD_PROJECT} --quiet
