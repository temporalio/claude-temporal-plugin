# Capacity, Throttling and Lock Contention

Use these metrics to interpret provisioned capacity and diagnose throttling or lock contention.

- **Provisioned capacity:** `temporal_cloud_v1_provisioned_capacity_tru_count` reports the TRU count per Namespace; `0` means the Namespace is not in provisioned capacity mode.
- **Throttle > 0 while count < limit:** rates are averaged over a minute, so a sub-minute burst can throttle without crossing the limit. For spiky or latency-sensitive workloads, alert on the throttle metric (> 0) directly for Actions, service requests and operations.
- **Lock contention** (BusyWorkflow; `ResourceExhausted`, logged as `Workflow is busy.`): use `temporal_cloud_v1_resource_exhausted_error_count` by the `operation` label. Rule out account throttling first; raising APS/RPS/OPS limits does not fix lock contention.

For capacity provisioning, billing calculations, or Id reuse policy, hand off to `skill-temporal-cloud` or `skill-temporal-ops` with the metric evidence gathered so far.
