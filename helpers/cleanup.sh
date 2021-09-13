#!/usr/bin/env bash
: ${PREFIX?"Need to set PREFIX environment variable"}
echo Env Prefix: $PREFIX

export PRIVATE_EAST=private-east
export PRIVATE_WEST=private-west
export CLOUD_EAST=public-east
export CLOUD_WEST=public-west
export DMZ=dmz

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