# Overview
 Although containers and Kubernetes are widely used, there are still many services deployed on virtual machines (VM) and APIs outside of the Kubernetes cluster that needs to be managed by TSB. It is possible to bring this VM into the Istio mesh. To successfully extend an Istio/Kubernetes cluster with a VM, the following steps must be taken:

- **Authentication:** The VM must establish an authenticated encrypted session to the control plane. The VM must prove that it is allowed to join the cluster.
- **Routing:** The VM must be aware of the services defined in the Kubernetes cluster and vice-versa. If the VM runs a service, it must be visible to pods running inside the cluster.

Onboarding a Virtual Machine (VM) into a TSB managed Istio service mesh can be broken down into the following steps:

- Registering the VM `workload` with the Istio control plane (WorkloadEntry)
- Obtaining a bootstrap security token and seed configuration for the Istio Proxy that will run on the VM
- Transferring the bootstrap security token and seed configuration to the VM
- Starting Istio Proxy on the VM

To improve the user experience with VM onboarding, TSB comes with `tctl` CLI that automates most of these tasks. At a high level, `tctl` aims to streamline VM onboarding flow down to a single command:

```sh
tctl x sidecar-bootstrap
```

The registration of the VM workload with the service mesh is driven by the configuration inside the `WorkloadEntry` resource. `tctl` sidecar bootstrap allows you to onboard VMs in various network and deployment scenarios to your service mesh on Kubernetes. The `tctl` sidecar bootstrap also allows VM onboarding to be reproduced at any point from any context, by a developer machine, or a CI/CD pipeline.

## Onboarding a VM
We will onboard our backend and frontend applications into our Mesh to demonstrate the following scenarios:
- Traffic originating from the Global Service mesh routing the application on the VM
- Application on the VM routing making requests to containerized apps via the Global Service Mesh.

For simplicity's sake, we'll utilize our jumpbox to run our VM applications; in other workds our jumpbox will be onboarded into the Global Service Mesh.

### Containerized apps making request(s) to legacy app
xxxxxx


Set env vars
source ./vm-env.sh

Create SA
kubectl create sa vm-sa -n $PREFIX-demo-secure

Create WorkloadEntry, Sidecar, Service
envsubst < 01-backend-vm.yaml | kubectl apply -f -

bootstrap
tctl x sidecar-bootstrap backend-vm -n $PREFIX-demo-secure --start-istio-proxy --ssh-key abz.pem

Start backend
source ./backend-env.sh
./backend &

Contrigure entries...
envsubst < 04-VM/01a-backend-tsb.yaml | tctl apply -f -  

Test...
frontend west --> $PREFIX-vm.secure.private.mesh

2021/09/07 19:07:29 CatHandler: request received from 127.0.0.1:54658

docker logs
[2021-09-07T19:05:18.424Z] "GET / HTTP/1.1" 200 - "-" 0 1750 1 0 "10.130.4.1" "Go-http-client/1.1" "73f8aeb3-e1a6-97c0-8e1c-1d18eb050a66" "abz-vm.secure.private.mesh" "127.0.0.1:8888" inbound|8888|| 127.0.0.1:54652 10.0.93.162:8888 10.130.4.1:0 outbound_.80_._.backend-vm.abz-demo-secure.svc.cluster.local default


Cleanup
fg   control+c
docker stop istio-proxy
docker rm istio-proxy
rm /etc/istio-proxy/*

### Legacy app making request(s) to containerized apps
ssss


Create WorkloadEntry, Sidecar, Service
envsubst < 02-frontend-vm.yaml | kubectl apply -f -

bootstrap
tctl x sidecar-bootstrap frontend-vm -n $PREFIX-demo-secure --start-istio-proxy --ssh-key abz.pem

Start frontend
source ./frontend-env.sh
./frontend &

Contrigure entries...
envsubst < 04-VM/02a-frontend-tsb.yaml | tctl apply -f -  

Test...
Browser URL... backend:8888



