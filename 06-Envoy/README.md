# Overview
Every single application within the mesh runs with an Envoy proxy sidecar, whether it is a Kubernetes pod or a legacy VM.  Envoy provides an extensible framework for altering the configuration and behavior of the Envoy proxy in the form of filters.  Though there are a few options for creating Envoy filters, [WebAssembly (WASM)](https://www.tetrate.io/blog/wasm-outside-the-browser/) provides a high-performance option with a SDK that allows you to author your code in a number of languages, compiling down to WASM binaries.  In this lab we will configure a simple filter that modifies HTTP request/response headers.

## Configure the Envoy Filter
It is beyond the scope of this workshop to explain the ins and outs of creating extensions in WASM.  We will use a fairly trivial extension in this example.  You can view the source code in the `06-Envoy/wasm/header-filter` folder (see `main.go`).  For this example we already have a precompiled WASM binary available for us to use: `06-Envoy/wasm/header-filter/main.wasm`

There are a few ways to load a binary into the Envoy proxy, for instance from a remote download location.  However, for simplicity we will use a `ConfigMap` that gets mounted into a volume on the Envoy sidecar proxy.

- First we need to create the `ConfigMap` that contains our binary.  We will be configuring this in the `public-east` cluster, our insecure application.  Use the kubectl CLI to create the config map from a file:

```bash
kubectl --context public-east create cm http-filter-example -n $PREFIX-demo-insecure --from-file=06-Envoy/wasm/header-filter/main.wasm
```
- Next we will patch our frontend deployment to load data in the config map into a container volume:

```bash
kubectl --context public-east patch deployment frontend -n $PREFIX-demo-insecure --patch "$(cat 06-Envoy/patch.yaml)" 
```

This will force a rolling restart of our frontend pod.  Inspect the file `06-Envoy/patch.yaml`.  You'll note that patch is adding a few annotations to the Envoy sidecar pods this deployment creates that will create a userVolume at a specific location, `/var/local/lib/wasm-filters`, that contains the binary data of our `ConfigMap`.

```yaml
spec:
  template:
    metadata:
      annotations:
        sidecar.istio.io/userVolume: '[{"name":"wasmfilters-dir","configMap": {"name":"http-filter-example"}}]'
        sidecar.istio.io/userVolumeMount: '[{"mountPath":"/var/local/lib/wasm-filters","name":"wasmfilters-dir"}]'
```

- Lastly, we need to create the `EnvoyFilter`, which is the configuration object that loads the extension into Envoy and places it in a specific location in the filter chain execution.
```bash
envsubst < 06-Envoy/filter.yaml | kubectl --context public-east apply -f -
```

If you inspect the file `06-Envoy/filter.yaml` you'll be able to gather the general gist of what is taking place.  First, we are instructing Envoy to execute our filter to the sidecar's `http_connection_manager`.

```yaml
spec:
  configPatches:
  - applyTo: HTTP_FILTER
    match:
      context: SIDECAR_INBOUND
      listener:
        filterChain:
          filter:
            name: envoy.filters.network.http_connection_manager
```

Next we'll see the actual extension configuration.  Though fairly verbose, this configuration is simply telling Envoy to load a WASM extension named `headers-extension` from the local volume `/var/local/lib/wasm-filters/main.wasm`.  This is the volume that we previously mounted using the annotations we *patched* into our deployment.  This extension adds an arbitrary set of response headers to all requests which are configured in the `configuration` section of our filter.  In our case it is a single header named `Tetrate` with a value of `This came from my custom EnvoyFilter!!!!`.

```yaml
patch:
  operation: INSERT_BEFORE
  value:
    name: headers-extension
    typed_config:
      "@type": type.googleapis.com/udpa.type.v1.TypedStruct
      type_url: type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm
      value:
        config:
          vm_config:
            vm_id: headers-extension-vm
            runtime: envoy.wasm.runtime.v8
            code:
              local:
                filename: /var/local/lib/wasm-filters/main.wasm
          configuration:
            "@type": type.googleapis.com/google.protobuf.StringValue
            value: |
              Tetrate=This came from my custom EnvoyFilter!!!!
```

- Now we can test using a simple `curl` command to the frontend application running in the insecure cluster:

```bash
curl -v -X HEAD https://insecure.public.$PREFIX.cloud.zwickey.net/  
```

You'll note in the verbose response you see the request and response headers in the HTTP `HEAD` request, and we now see our new `tetrate` header added by the `EnvoyFilter`:
```bash
< HTTP/2 200 
< date: Fri, 10 Sep 2021 03:19:26 GMT
< content-type: text/html; charset=utf-8
< x-envoy-upstream-service-time: 2
< tetrate: This came from my custom EnvoyFilter!!!!
< server: istio-envoy
< 
* Connection #0 to host insecure.public.test.cloud.zwickey.net left intact
* Closing connection 0
```
