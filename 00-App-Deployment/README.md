# Overview
The first step will be to deploy all our sample applications. As a reminder, we'll be working with 3 applications:
1. Insecure App
2. Secure App
3. Bookinfo App

The steps to deploy the applications are largely identical; the main change will be ensuring that you are targeting the correct kubernetes cluster in your kube context file.

## Application Deployment
Prior to installing ensure you have set an environment variable in the shell you are using named `PREFIX`.  This will be used to prefix common objects, such as namespaces, dns entries, TSB tenants and workspaces, etc such that your appliations and configuration will not collide with others running this workshop on shared infrastructure.

You will also want to ensure that your `tctl` CLI is targeted and logged into the TSB management plane.

```bash
export PREFIX=abz

tctl config clusters set default --bridge-address <TSB-MGMT-PLANE-ADDRESS>:443
tctl login --org tetrate --tenant $PREFIX-tetrate --username <TSB-USER> --password <TSB-PWD>
```

### Insecure Application
The insecure application is comprised of a frontend and a backend service plus an Istio IngressGateway, all deployed to a dedicated namespace.  Ensure your kube context is targeted the `public cloud east` cluster.  Deploy the application the appliction and Istio IngressGateway using `kubectl`.

```bash
envsubst < 00-App-Deployment/cloud-east/app.yaml | kubectl apply -f -
envsubst < 00-App-Deployment/cloud-east/cluster-ingress-gw.yaml | kubectl apply -f -
```

While the application starts up, lets inspect the 2 items that introduce this application into the global service mesh.  
1. Inspect the file `00-App-Deployment/cloud-east/app.yaml`.  You'll note our namespace has a label enabling Istio for any application pods.
```yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: $PREFIX-demo-insecure  
  labels:
    istio-injection: enabled # This label will causes our application pods to receive an envoy sidecar container
...
```

2. Inspect the file `00-App-Deployment/cloud-east/cluster-ingress-gw.yaml`.  This is a Tetrate-specific `CustomResourceDefinition` that will deploy and optimally configure a dedicated Istio `IngressGateway` for the applictions in this namespace.
```yaml
---
apiVersion: install.tetrate.io/v1alpha1
kind: IngressGateway
metadata:
  name: $PREFIX-tsb-gateway
  namespace: $PREFIX-demo-insecure
spec:
  kubeSpec:
    service:
      type: LoadBalancer
      annotations:
        "external-dns.alpha.kubernetes.io/hostname": "$PREFIX-insecure.public.cloud.zwickey.net."
...
```

Though this YAML file is fairly terse and simple, a lot was configured under the covers.  The Tetrate platform will translate this request into an `IstioOperator` deployment of an Istio `IngressGateway`.  You can view this configuration by executing:
```bash
kubectl get istiooperator -n istio-gateway tsb-gateways -o yaml
```

By now our application should be running and pods/services introduced into the global service mesh.  We even have an Istio `IngressGateway` bound to an external load balancer and DNS entry (via `external-dns`).  However, we have not deployed any mesh configuration yet so our application will not be accessible external from the mesh.  For now we can verify our application is running and functioning properly in the mesh by port-forwarding.  
```bash
kubectl port-forward -n $PREFIX-demo-insecure $(kubectl get po --output=jsonpath={.items..metadata.name} -l app=frontend) 8888:8888
```

Open your browser and navigate to localhost:8888.  Enter `backend` in the Backend HTTP URL text box and submit the request.  This will cause the frontend microservice to call to the backend microservice over the service mesh and return the display the response via the frontend app.

![Base Diagram](../images/01-app.png)

### Secure Application
The secure application is identical to the secure application, with the exceeption that it is deployed to 3 different kubernetes clusters that are part of a different trust domain.  

1 - Ensure your kube context is targeted the `public cloud west` cluster.  Deploy the application the appliction and Istio IngressGateway using `kubectl`.
```bash
envsubst < 00-App-Deployment/cloud-west/app.yaml | kubectl apply -f -
envsubst < 00-App-Deployment/cloud-west/cluster-ingress-gw.yaml | kubectl apply -f -
```

2 - Ensure your kube context is targeted the `private east` cluster.  Deploy the application the appliction and Istio IngressGateway using `kubectl`.
```bash
envsubst < 00-App-Deployment/private-east/app.yaml | kubectl apply -f -
envsubst < 00-App-Deployment/private-east/cluster-ingress-gw.yaml | kubectl apply -f -
```

3 - Ensure your kube context is targeted the `private west` cluster.  Deploy the application the appliction and Istio IngressGateway using `kubectl`.
```bash
envsubst < 00-App-Deployment/private-west/app.yaml | kubectl apply -f -
envsubst < 00-App-Deployment/private-west/cluster-ingress-gw.yaml | kubectl apply -f -
```

You can verify the secure verison of the application utilizing the same method of `kubectl port-forward` described in the previous section.

### Bookinfo Application