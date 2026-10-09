# Worker Controller Instance (WCI)


## Role and lifecycle

The Worker Controller Instance (WCI) is a Temporal system Workflow that scales compute for a Worker Deployment Version from Task Queue conditions. One WCI runs for each Worker Deployment Version that has a compute provider configured, in the same Namespace as the Worker Deployment.

Temporal creates and manages the WCI automatically. Never create, start, or manage it yourself.

## Inputs

The WCI responds to sync match failures and Task Queue backlog or rate information. The selected provider's constraints and diagnostics references describe how those inputs become compute changes, along with the provider-specific lifecycle and failure signatures.

## Inspect the WCI

Run these with the CLI connection the version was registered with: on Cloud Run, add `--profile <PROFILE>` (the profile the API-key hand-off writes); on AWS Lambda, use the connection configured in `aws-lambda/setup.md`.

List WCI Workflows in the Namespace:

```bash
temporal workflow list \
  --namespace <NAMESPACE> \
  --query 'TemporalNamespaceDivision = "TemporalWorkerControllerInstance" AND WorkflowId = "temporal-sys-worker-controller-instance:<DEPLOYMENT_NAME>:<BUILD_ID>"'
```

WCI Workflow IDs follow this pattern:

```text
temporal-sys-worker-controller-instance:<deployment-name>:<build-id>
```

Inspect the WCI Workflow history for recent Activity results:

```bash
temporal workflow show \
  --namespace <NAMESPACE> \
  --workflow-id 'temporal-sys-worker-controller-instance:<DEPLOYMENT_NAME>:<BUILD_ID>' \
  --detailed
```

The default table shows event types but hides the payloads needed for diagnosis. Use `--detailed` as above or `-o json`. During registration, look for `ValidateSpec` and the `InvokeWorkersToRegisterTaskQueues` bootstrap. A result such as `worker_count: 1` means the WCI requested bootstrap capacity; it does not mean that an instance started or that the expected Worker registered and polled. Provider-specific scaling later appears through the provider action described in its diagnostics guide.

`SignalExternalWorkflowExecutionFailed` with `NOT_FOUND` can appear in healthy Cloud Run deployments, but do not classify it from the event name alone. Correlate it with the surrounding signal target and confirm that registration, polling, and the provider action succeeded before treating it as benign.

## Interpret what you find

**A Running WCI is not evidence that its scaling Activities work.** The Workflow continues-as-new and remains Running while those Activities fail. Read its history and look for Activity failures.

Start with the selected provider's `diagnostics.md`; it defines the decisive health check and the order in which to correlate WDV, WCI, and provider state. Do not enumerate compute resources across regions to reverse-engineer state. Use this history to distinguish a failed WCI Activity from capacity that the provider accepted but never became a polling Worker.
