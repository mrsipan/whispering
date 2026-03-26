# Llamita Cluster Deployment in Kubernetes

This deployment installs/upgrades *Llamita*, an internal *Large Language
Model (LLM)* endpoint for use within Kubernetes.

## The Chart

There is a *helm chart* available under the name *docinsights* in the *Nexus
Helm Repository*.

### Verify that the kubernetes manifests render correctly

``` {.bash org-language="sh"}
helm template docinsights <nexus-chart> \
     -f values.yaml
```

### Deploy the chart

``` {.bash org-language="sh"}
helm -n llm upgrade --install docinsights <nexus-chart> \
     -f values.yaml
```

## The Source

The *source code* for the project is located here:

<https://stash.synchronoss.net/projects/BDA/repos/docinsights/browse>

From the deployment point of view the most important file is the
*values.yaml* file:

<https://stash.synchronoss.net/projects/BDA/repos/docinsights/browse/charts/docinsights/values.yaml>

## The Server Configuration

The configuration is driven by environment variables set in a kubernetes
*configmap*. Take a look at the `values.yaml` file for details on the
entry that generates such a *configmap*:

``` yaml
envvars:
  LLAMA_ARG_CTX_SIZE: 4096
  LLAMA_ARG_ENDPOINT_METRICS: 1
  LLAMA_ARG_ENDPOINT_SLOTS: 1
  LLAMA_ARG_HOST: 0.0.0.0
  LLAMA_ARG_TIMEOUT: 900
  LLAMA_ARG_THREADS: 6
  LLAMA_ARG_MODEL_URL: https://huggingface.co/bartowski/Meta-Llama-3.1-8B-Instruct-GGUF/resolve/main/Meta-Llama-3.1-8B-Instruct-Q8_0.gguf
  LLAMA_ARG_N_PARALLEL: 6
  LLAMA_ARG_PORT: 80
  LLAMA_API_KEY: some-api-key

```

Generally, the values that may need to be updated are:

-   The llama API key, `LLAMA_API_KEY`.
-   The model URL if we need to use a different model from the default
    model, `LLAMA_ARG_MODEL_URL`.
-   The *context size* `LLAMA_ARG_CTX_SIZE`.

Most likely, the default values would be enough for any deployment.

## The Ingress Endpoint

This service will only be available for internal clients, therefore the
internal *service* address should be used by the internal clients:

However, the *values.yaml* file contains a *ingress* entry that allows
exposing a public domain name address which can be whitelisted. The
section follows the standard *Synchronoss\'* ingress definition:

``` yaml
ingress:
  enabled: true
  className: ""
  annotations:
    cert-manager.io/cluster-issuer: sncr-letsencrypt-clusterissuer
    external-dns.alpha.kubernetes.io/hostname: docinsights.use.eks.mcap.sip.dev.cloud.synchronoss.net
    external-dns.alpha.kubernetes.io/target: sip-eks-mcap-use-dev-dft-nlb-6ef2d80b0cc8f2d3.elb.us-east-1.amazonaws.com
    ingress.kubernetes.io/whitelist-source-range: 68.170.18.0/24, 68.170.19.0/24,38.142.107.248/29, 87.198.172.216/30, 87.198.165.116/30, 87.198.172.222/31, 210.80.199.176/28, 113.29.10.240/28, 103.231.232.0/24, 59.154.176.112/25, 50.237.213.130/32
    kubernetes.io/ingress.class: nginx
    kubernetes.io/tls-acme: "true"
  hosts:
    - host: docinsights.use.eks.mcap.sip.dev.cloud.synchronoss.net
      paths:
        - backend:
            service:
              name: docinsights
              port:
                number: 80
          path: /
          pathType: ImplementationSpecific
  tls:
    - hosts:

```

Make the necessary updates to match the kubernetes cluster and
environment.
