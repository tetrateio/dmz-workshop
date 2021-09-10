#!/usr/bin/env bash
: ${PREFIX?"Need to set PREFIX environment variable"}
echo Env Prefix: $PREFIX

export PRIVATE_EAST=default/api-oc-ms-demo-east-cx-tetrate-info:6443/kube:admin
export PRIVATE_WEST=default/api-oc-ms-demo-west-cx-tetrate-info:6443/kube:admin
export CLOUD_EAST=gke_abz-env_us-east4_public-east-4
export CLOUD_WEST=gke_abz-env_us-west1_public-west-4
export DMZ=gke_abz-env_us-east4_dmz

# TSB
tctl login --org tetrate --tenant tetrate --username admin --password admin
envsubst < 01-Tenancy/01-tenant.yaml | tctl delete -f -

# Apps
kubectx $DMZ
envsubst < 00-App-Deployment/dmz/cluster-t1.yaml | kubectl delete -f -
kubectx $CLOUD_EAST
envsubst < 00-App-Deployment/cloud-east/cluster-ingress-gw.yaml | kubectl delete -f -
envsubst < 00-App-Deployment/cloud-east/app.yaml | kubectl delete -f -
kubectx $CLOUD_WEST
envsubst < 00-App-Deployment/cloud-west/cluster-ingress-gw.yaml | kubectl delete -f -
envsubst < 00-App-Deployment/cloud-west/app.yaml | kubectl delete -f -
kubectx $PRIVATE_EAST
envsubst < 00-App-Deployment/private-east/cluster-ingress-gw.yaml | kubectl delete -f -
envsubst < 00-App-Deployment/private-east/app.yaml | kubectl delete -f -
envsubst < 00-App-Deployment/private-east/bookinfo-multicluster.yaml | kubectl delete -f -
kubectx $PRIVATE_WEST
envsubst < 00-App-Deployment/private-west/cluster-ingress-gw.yaml | kubectl delete -f -
envsubst < 00-App-Deployment/private-west/app.yaml | kubectl delete -f -
envsubst < 00-App-Deployment/private-west/bookinfo-multicluster.yaml | kubectl delete -f -