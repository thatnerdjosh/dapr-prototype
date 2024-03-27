# Tracing
[Dapr Docs](https://docs.dapr.io/operations/observability/tracing/tracing-overview/)

## Method 1 - OTLP (preferred)
[Dapr OTLP Docs](https://docs.dapr.io/operations/observability/tracing/otel-collector/open-telemetry-collector/)

### Setup Jaeger
[Dapr Jaeger Docs](https://docs.dapr.io/operations/observability/tracing/otel-collector/open-telemetry-collector-jaeger/)

## Method 2 - Zipkin
[Dapr Zipkin Docs](https://docs.dapr.io/operations/observability/tracing/zipkin/)

```bash
kubectl create deployment zipkin --image openzipkin/zipkin
kubectl expose deployment zipkin --type ClusterIP --port 9411
```

Apply this configuration:

TODO: Check why this is in default namespace - seems less than ideal given rest of observability stack is in dapr-monitoring

```bash
kubectl apply -f deploy/dapr/tracing.yaml
```

# Metrics
[Dapr Docs](https://docs.dapr.io/operations/observability/metrics/metrics-overview/)

Following the instructions on [Dapr Prometheus Docs](https://docs.dapr.io/operations/observability/metrics/prometheus/) worked out of the box somehow - wasn't expecting that as typically there is more configuration.

TODO: Investigate how the scraping is happening - or, is dapr using pushgateway?

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install dapr-prom prometheus-community/prometheus -n dapr-monitoring --set alertmanager.persistence.enabled=false --set pushgateway.persistentVolume.enabled=false --set server.persistentVolume.enabled=false
```

# Logging
[Dapr Docs](https://docs.dapr.io/operations/observability/logging/fluentd/)

TODO: Debug why persistence isn't working properly with elasticsearch
TODO: Debug why elasticsearch sometimes does not launch

To clear out existing logging stack (currently, relaunching the stack doesn't work.)
```bash
kubectl delete ns dapr-monitoring
kubectl delete -f "deploy/dapr/fluentd-*.yaml"
```

```bash
kubectl create ns dapr-monitoring
helm install elasticsearch elastic/elasticsearch -n dapr-monitoring --set replicas=1
helm install kibana elastic/kibana -n dapr-monitoring
```

Currently, the manifests need to be patched to include the correct password:

In `./deploy/dapr/fluentd-dapr-with-rbac.yaml`, update `FLUENT_ELASTICSEARCH_PASSWORD` to the value below:

```bash
kubectl get secrets --namespace=dapr-monitoring elasticsearch-master-credentials -ojsonpath='{.data.password}' | base64 -d
```

Then apply the manifests
```bash
kubectl apply -f "deploy/dapr/fluentd-*.yaml"
```

With your dapr app running, open a port-forward, and configure kibana:

```bash
kubectl port-forward svc/kibana-kibana 5601 -n dapr-monitoring
```

1. User: elastic
2. Password: <value from previous step>
3. Create data view
  a. name - `dapr`
  b. index pattern - `dapr*`
  c. timestamp - `@timestamp`
