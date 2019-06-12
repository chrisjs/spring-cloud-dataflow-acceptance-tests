#!/usr/bin/env bash

set -o errexit

[ -z "$GCLOUD_PROJECT" ] && { echo "Environment variable GCLOUD_PROJECT must be set"; exit 1; }
[ -z "$GCLOUD_COMPUTE_ZONE" ] && { echo "Environment variable GCLOUD_COMPUTE_ZONE must be set"; exit 1; }
[ -z "$GCLOUD_CONTAINER_CLUSTER" ] && { echo "Environment variable GCLOUD_CONTAINER_CLUSTER must be set"; exit 1; }
[ -z "$GCLOUD_CLUSTER_VERSION" ] && { echo "Environment variable GCLOUD_CLUSTER_VERSION must be set"; exit 1; }

function gcp_authenticate_and_target() {
  echo "Connecting to kubernetes cluster: $GCLOUD_CONTAINER_CLUSTER in project: $GCLOUD_PROJECT, zone: $GCLOUD_COMPUTE_ZONE"

  gcloud config set compute/zone $GCLOUD_COMPUTE_ZONE
  gcloud config set container/cluster $GCLOUD_CONTAINER_CLUSTER
  gcloud container clusters get-credentials $GCLOUD_CONTAINER_CLUSTER --zone $GCLOUD_COMPUTE_ZONE --project $GCLOUD_PROJECT
}

if ! command_exists gcloud; then
  echo "You don't have the 'Google Cloud SDK' installed, please visit https://cloud.google.com/sdk/downloads to download it first"
  exit 1
fi

if ! command_exists kubectl; then
  echo "You don't have the 'kubectl' command line tool installed, please visit https://kubernetes.io/docs/tasks/tools/install-kubectl to install it first"
  exit 1
fi

# odd to filter then grep, but gcloud return codes arent very useful...
if [ ! "$(gcloud container clusters list --filter name=${GCLOUD_CONTAINER_CLUSTER} | grep ${GCLOUD_CONTAINER_CLUSTER})" ]; then
  echo "Creating cluster"

  gcloud container --project ${GCLOUD_PROJECT} clusters create ${GCLOUD_CONTAINER_CLUSTER} --zone ${GCLOUD_COMPUTE_ZONE} --machine-type "custom-4-4096" --cluster-version ${GCLOUD_CLUSTER_VERSION} --num-nodes "5" --image-type "COS" --disk-size "25" --network "default" --enable-cloud-logging --enable-cloud-monitoring --no-enable-autoupgrade --scopes "https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append"

  gcp_authenticate_and_target

  kubectl create clusterrolebinding --user system:serviceaccount:default:default default-admin --clusterrole cluster-admin
else
  echo "Cluster ${GCLOUD_CONTAINER_CLUSTER} exists, re-using"

  gcp_authenticate_and_target
fi

if [ -z "$KUBERNETES_NAMESPACE" ]; then
  export KUBERNETES_NAMESPACE='default'
fi

echo "Using namespace $KUBERNETES_NAMESPACE"
