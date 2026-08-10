# End-to-End Implementation & Troubleshooting Guide: Kubernetes Monitoring and Slack Alerting

This document details the configuration, architecture, and troubleshooting procedures for the Kubernetes alerting pipeline implemented for the `sillypets` application using **Prometheus Operator**, **Alertmanager**, **Helm**, and **Slack**.

---

## 1. System Architecture & Flow

```
+------------------+     PromQL Scrape     +-------------------+
| Kubernetes Pods  | <------------------- |    Prometheus     |
| (sillypets, etc.)|                      |    (Monitoring)   |
+------------------+                      +---------+---------+
                                                    |
                                    Evaluates Rules | (PrometheusRule CRD)
                                                    v
+------------------+   Webhook Delivery    +-------------------+
|  Slack Channel   | <------------------- |   Alertmanager    |
| (#devops-alerts) |                      | (AlertmanagerConfig)|
+------------------+                      +-------------------+

```

1. **Prometheus** scrapes container metrics (`container_memory_working_set_bytes`) from cAdvisor/kubelet.
2. **PrometheusRule CRD** defines threshold evaluations (e.g., memory usage > 50 MB for 2 minutes).
3. **Alertmanager** receives active alert payloads from Prometheus, matches routing rules, and dispatches JSON payloads.
4. **Kubernetes Secret (`slack-webhook-secret`)** stores the Incoming Webhook URL used by Alertmanager to send formatted alerts to Slack (`#devops-alerts`).

---

## 2. Comprehensive Troubleshooting & Error Resolution Matrix

### Issue 1: Slack Delivery Fails with `404 no_service`

* **Symptom:** Alerts fire in Prometheus, but no notifications reach Slack. Alertmanager logs display:
```text
level=ERROR msg="Notify for alerts failed" err="... channel \"#devops-alerts\": unexpected status code 404: no_service"

```


* **Root Cause:** The Slack Webhook URL saved in the Kubernetes secret `slack-webhook-secret` was malformed, truncated, or revoked by Slack.
* **Resolution Steps:**
1. **Test the URL manually** using `curl` from your workstation:
```bash
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Testing webhook URL"}' \
  https://hooks.slack.com/services/YOUR/ACTUAL/WEBHOOK

```


* If output is **`ok`**, the URL is valid.
* If output is **`no_service`**, generate a new Incoming Webhook in Slack (**Workspace Settings** $\rightarrow$ **Integrations** $\rightarrow$ **Incoming Webhooks**).


2. **Update the Kubernetes Secret:**
```bash
kubectl create secret generic slack-webhook-secret \
  --from-literal=api-url='https://hooks.slack.com/services/YOUR/VERIFIED/WEBHOOK' \
  -n monitoring \
  --dry-run=client -o yaml | kubectl apply -f -

```


3. **Force Alertmanager Reload:**
```bash
kubectl rollout restart statefulset -n monitoring -l app.kubernetes.io/name=alertmanager

```





---

### Issue 2: Alert Fires in Prometheus but Routes to `null` Receiver

* **Symptom:** Inspecting Alertmanager alerts via API reveals:
```json
"receivers":[{"name":"null"}]

```


* **Root Cause:** **Namespace Scoping in Prometheus Operator.** An `AlertmanagerConfig` created in the `monitoring` namespace only processes alerts that explicitly contain the label `namespace: monitoring`. Aggregation expressions like `sum(...) by (pod)` strip all original labels except `pod`, causing Alertmanager to drop the alert into the fallback `null` sink.
* **Resolution Steps:**
Explicitly append `namespace: monitoring` under the `labels` block in `prometheusrule.yaml`:
```yaml
      labels:
        severity: warning
        namespace: monitoring

```



---

### Issue 3: `helm lint` Fails with `undefined variable "$labels"`

* **Symptom:** GitHub Actions CI or manual `helm lint` execution fails with:
```text
[ERROR] templates/: parse error at (sillypets-chart/templates/prometheusrule.yaml:28): undefined variable "$labels"

```


* **Root Cause:** Helm interprets Go template delimiters (`{{ ... }}`) during chart rendering. It attempts to evaluate Prometheus runtime variables (`$labels.pod` and `$value`) as Helm values, failing because `$labels` is undefined in Helm.
* **Resolution Steps:**
Escape the double curly braces using Helm string rendering syntax `{{ "{{" }}` and `{{ "}}" }}`:
```yaml
annotations:
  summary: "High memory usage on pod {{ "{{" }} $labels.pod {{ "}}" }}"
  description: "Pod {{ "{{" }} $labels.pod {{ "}}" }} is consuming over 50 MB of memory (current value: {{ "{{" }} $value {{ "}}" }} bytes)."

```



---

### Issue 4: Alert Flapping (`[FIRING]` and `[RESOLVED]` Toggling Rapidly)

* **Symptom:** Slack receives alternating `[FIRING]` and `[RESOLVED]` notifications every 15–30 seconds without actual application changes.
* **Root Cause:** Setting `for: 0s` eliminates hysteresis. Brief metric scrape misses from cAdvisor (due to garbage collection, network latency, or pod restarts) temporarily return empty vector data. Prometheus treats an empty vector as resolved (`0`), then re-fires on the next successful scrape.
* **Resolution Steps:**
1. Enforce a minimum stabilization window using `for: 2m` (or at least `1m`).
2. Set alert thresholds above transient noise (e.g., `50000000` bytes / 50 MB).



---

### Issue 5: CI/CD Pipeline Build Failure (`TLS handshake timeout`)

* **Symptom:** GitHub Actions deployment job fails during Docker layer extraction:
```text
failed to copy: ... net/http: TLS handshake timeout

```


* **Root Cause:** Transient packet loss or network throttling between the GitHub runner and the container registry CDN.
* **Resolution Steps:**
Re-run the workflow job in GitHub Actions. For production pipelines, implement retries around `docker pull`:
```bash
for i in {1..3}; do docker pull myrepo/app:latest && break || sleep 5; done

```



---

## 3. Useful Diagnostic Commands Reference

| Operation | Command |
| --- | --- |
| **Check Alertmanager Configuration Logs** | `kubectl logs -n monitoring -l app.kubernetes.io/name=alertmanager -c alertmanager --tail=50` |
| **Inspect Active Alerts in Alertmanager** | `kubectl exec -it -n monitoring alertmanager-prometheus-stack-kube-prom-alertmanager-0 -c alertmanager -- wget -qO- http://localhost:9093/api/v2/alerts` |
| **Inspect Active Alerts in Prometheus** | `kubectl exec -it -n monitoring prometheus-prometheus-stack-kube-prom-prometheus-0 -c prometheus -- wget -qO- http://localhost:9090/api/v1/alerts` |
| **Verify Decoded Webhook Secret** | `kubectl get secret slack-webhook-secret -n monitoring -o jsonpath='{.data.api-url}' | base64 -d` |
| **Validate Chart Formatting** | `helm lint sillypets-chart/` |

---

## 4. Production Golden State Manifest

File path: `sillypets-chart/templates/prometheusrule.yaml`

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: sillypets-alerts
  namespace: monitoring
  labels:
    release: prometheus-stack
spec:
  groups:
  - name: sillypets.alerts
    rules:
    - alert: SillypetsHighMemoryUsage
      expr: sum(container_memory_working_set_bytes{namespace="default", pod=~"sillypets.*"}) by (pod) > 50000000
      for: 2m
      labels:
        severity: warning
        namespace: monitoring
      annotations:
        summary: "High memory usage on pod {{ "{{" }} $labels.pod {{ "}}" }}"
        description: "Pod {{ "{{" }} $labels.pod {{ "}}" }} is consuming over 50 MB of memory (current value: {{ "{{" }} $value {{ "}}" }} bytes)."
```

