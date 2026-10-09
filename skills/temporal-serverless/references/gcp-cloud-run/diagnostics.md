# GCP Cloud Run — Diagnostics & troubleshooting

For the WCI lifecycle, inputs, Workflow ID pattern, and inspection commands, see [Worker Controller Instance (WCI)](../wci.md).

**A Running WCI does not prove that pool resizing works.** Inspect its Activity results before changing GCP resources. This guide interprets the Cloud Run-specific state and Activity failures.

## Scaling flow (when working correctly)


1. You deploy the Worker image to a Worker Pool at zero instances.
2. You create a Worker Deployment Version pointing at that pool. This starts a WCI Workflow.
3. An instance starts, the Worker polls, and the server **binds the Task Queue** to the version.
4. The WCI monitors that Task Queue; the Matching Service also signals it when a Task arrives with no free Worker.
5. As work arrives the WCI raises the instance count through the Cloud Run admin API; as it drains, lowers it, possibly to zero.

**Temporal does not invoke your Worker per Task** — it changes how many instances run. Diagnose accordingly: "was it invoked?" is the wrong first question here.

## Start here: did the expected Worker bind?

```bash
temporal --profile <PROFILE> worker deployment describe-version \
  --namespace <NS> --deployment-name <NAME> --build-id <BUILD_ID> \
  --report-task-queue-stats -o json \
  | jq -e --arg tq '<TASK_QUEUE>' '
      [.taskQueuesInfos[]? | select(.name == $tq) | .type] as $types
      | (($types | index("workflow")) != null and
         ($types | index("activity")) != null)'
```

The decisive registration signal is `taskQueuesInfos` containing the expected Task Queue with lowercase `workflow` and `activity` types. The field is absent until a Worker identifying as this deployment and build ID polls. If the Worker intentionally polls only one type, adjust the predicate to require only that type. Provider writes, requested capacity, and a Running WCI support the diagnosis but do not replace this check.

First registration can take several minutes because Cloud Run must provision and start the pool's first instance before the Worker can poll. Treat this as operational guidance, not a timeout or service guarantee.

| Result | Interpretation | Next check |
|---|---|---|
| `describe-version` reports the version not found | The create was rejected. During IAM propagation this can read `worker pool … not found` even when the pool name is right. | Read the WCI's `ValidateSpec` result (`../wci.md`). A 403 on `iam.serviceAccounts.getAccessToken` means impersonation had not propagated yet; see [Re-run a failed registration bootstrap](#re-run-a-failed-registration-bootstrap). |
| Version not found, but a WCI Workflow for it is still Running | The WCI from the rejected create is still active. It can take over the next `create-version` and scale the pool back to zero before the new version binds. | Read its history before creating the version again; see [Re-run a failed registration bootstrap](#re-run-a-failed-registration-bootstrap). |
| Expected Task Queue types are bound | Registration succeeded for this WDV. | Confirm the version is current, then diagnose Task execution. |
| No binding; `lastModifier` is not the invoker | Temporal may not have written the pool. | Validate the compute fields, WCI Activity results, impersonation, and `run.workerPools.update`. |
| No binding; requested count is at least 1; no container startup logs exist | Cloud Run has accepted the requested capacity but has not started the first instance yet. | Wait and watch the worker-pool logs; do not diagnose the image before a container starts. |
| No binding; the invoker wrote 1 and later 0; no container startup logs ever appeared | Cloud Run did not start an instance before the WCI's registration window ended. Waiting no longer helps. | See [Re-run a failed registration bootstrap](#re-run-a-failed-registration-bootstrap). |
| No binding; invoker wrote a count of at least 1; container logs exist | The provider started capacity, but the intended Worker did not poll. | Compare image digests and read the Worker's startup identity log for deployment, build ID, and Task Queue. |
| Binding exists but Tasks do not progress | Startup and registration worked; the failure is downstream. | Check current-version routing, Workflow history, and Worker Task logs. |

While the first instance is provisioning, watch both surfaces:

```bash
gcloud run worker-pools describe <POOL_NAME> \
  --region <REGION> --project <YOUR_GCP_PROJECT> \
  --format='yaml(status.conditions,status.latestReadyRevisionName)'

gcloud logging read \
  'resource.type="cloud_run_worker_pool" AND resource.labels.worker_pool_name="<POOL_NAME>" AND resource.labels.location="<REGION>"' \
  --project <YOUR_GCP_PROJECT> --freshness=15m --limit=50
```

If the pool's latest revision is not Ready with reason `SecretsAccessCheckFailed`, the pool was deployed before the secret had an `ENABLED` version or before the runner could read it; fix that and re-run the deploy ([`setup.md`](setup.md#step-4-create-the-worker-pool) Step 4).

Only move to image, identity, or Task Queue diagnosis after container startup logs exist. If the requested count returns to `0` before any container startup log appears, registration lost the race; see [Re-run a failed registration bootstrap](#re-run-a-failed-registration-bootstrap). If the count stays at `1` and nothing has started after several minutes, inspect the pool's provisioning state and conditions.

## Read the pool's annotations

Start by describing the pool:

```bash
gcloud run worker-pools describe <POOL_NAME> \
  --region <REGION> --project <YOUR_GCP_PROJECT> --format=yaml
```

Three fields under `metadata.annotations`:

| Field | What it tells you |
|---|---|
| `run.googleapis.com/manualInstanceCount` | The instance count currently requested. It is desired state, not proof of how many processes are still running. |
| `run.googleapis.com/scalingMode` | Should be `manual` — the WCI scales by writing the manual instance count. |
| `serving.knative.dev/lastModifier` | Who most recently changed the pool. The invoker service account means Temporal made the latest change; a later manual update replaces it with the operator's identity. |

Treat `lastModifier` as a current clue, not historical proof:

- The invoker service account → **Temporal successfully updated the pool after its last manual change.** This does not prove the image started, the Worker identity was correct, or a Task Queue bound.
- The account you deployed with → the latest change was manual. To determine whether Temporal has ever updated the pool, inspect the registration Activity in the WCI history and the Task Queue binding below before diagnosing permissions.

For historical writes, query Cloud Audit Logs instead of treating `lastModifier` as history:

```bash
gcloud logging read \
  'protoPayload.methodName="google.cloud.run.v2.WorkerPools.UpdateWorkerPool" AND protoPayload.authenticationInfo.principalEmail="<INVOKER_SERVICE_ACCOUNT>" AND resource.labels.worker_pool_name="<POOL_NAME>" AND resource.labels.location="<REGION>"' \
  --project <YOUR_GCP_PROJECT> --limit 20 \
  --format='table(timestamp,protoPayload.authenticationInfo.principalEmail,resource.labels.worker_pool_name)'
```

## The Worker Pool is not scaling up

### 1. Validate Connection — and know what it does *not* prove

Workers → Deployments → select deployment → Actions → **Validate Connection**. For Cloud Run this impersonates the invoker and reads the pool, confirming three things: the compute configuration names a pool that exists, Temporal can impersonate the invoker, and the invoker can read.

**It starts no instance and does not exercise `run.workerPools.update`.** Version registration is different: its Task Queue bootstrap does update the pool. An invoker with read but not update permission can therefore pass this manual validation, but version registration or a later resize fails. If validation succeeds but registration never changes `lastModifier`, **check the update permission**.

On failure, check each part of the compute configuration against the pool:

- **Project, region, pool name.** Temporal addresses the pool as `projects/<YOUR_GCP_PROJECT>/locations/<REGION>/workerPools/<POOL_NAME>`. **A wrong region reports the pool as not found, identical to a wrong name** — so a "not found" does not tell you which field is wrong. It can also be a permission failure: while the invoker's grants are still propagating, `ValidateSpec` fails with a 403 on `iam.serviceAccounts.getAccessToken` and the CLI reports the pool as not found. Read the WCI's `ValidateSpec` result before changing any names.
- **Impersonation.** Temporal's identity needs `roles/iam.serviceAccountTokenCreator` on the invoker. The Terraform module grants this on Cloud; self-hosted grants it to the server's GCP identity.
- **Invoker permissions.** `run.workerPools.get` to read, `run.workerPools.update` to scale.

→ `iam.md`.

### 2. Did the registration bootstrap bind the Task Queue?

```bash
temporal --profile <PROFILE> worker deployment describe-version \
  --namespace <NS> --deployment-name <NAME> --build-id <BUILD_ID> \
  --report-task-queue-stats -o json
```

The server creates the binding when a Worker running that version connects and polls. **An absent `taskQueuesInfos` field means no Worker has polled successfully under this version.** Use the decision table above rather than interpreting a provider write as registration success.

Registration performs this bootstrap: the WCI reads the pool, updates its manual instance count to at least one, and Cloud Run starts an instance. An absent binding means that sequence failed or the instance started but did not connect under the expected deployment name and build ID. Inspect the WCI's `ValidateSpec`/registration Activity failure, the pool's `lastModifier` and instance count, and then the pool logs. Do not wait for a first Workflow to repair registration.

### Re-run a failed registration bootstrap

Fix the image, configuration, credentials, or IAM cause first. A successful compute-configuration change is expected to run the WCI update path and registration bootstrap, but resubmitting an unchanged configuration has not been verified as an in-place retry mechanism. Do not rely on an unchanged update to repair registration, and do not create a third pool merely to retrigger it.

Two failures look alike from the pool and need different handling:

- **Rejected create.** `create-version` failed `ValidateSpec`, usually with a 403 on `iam.serviceAccounts.getAccessToken` while the invoker's grants propagate. The version does not exist, but the WCI that the attempt started keeps running.
- **Registration race.** The version exists and the WCI raised the pool to one instance, but Cloud Run did not start the instance before the WCI's registration window ended, so the WCI set the count back to zero.

**A retry inherits the remaining time of the earlier WCI.** Re-running `create-version` for a version whose WCI is still running hands the new version to that WCI and to whatever is left of its timer. A retry is therefore neither always safe nor always unsafe; follow these steps in order:

1. **Confirm the version exists** immediately after `create-version`, as in [Confirm the version was created](setup.md#confirm-the-version-was-created).
2. **If the create was rejected with the 403**, wait for IAM propagation, then re-run the identical `create-version` once. Do this only when the pool is dedicated to this build ID. The retry creates the version, which step 4 needs if the race follows.
3. **Watch for the race after registration.** Keep waiting while the requested count stays above zero and no container startup log has appeared. If the count returns to `0` before any startup log appears, the race happened: the invoker wrote `1` and then `0`. If the count stays at `1` and no startup log appears for several minutes, stop waiting and inspect the pool's provisioning state and conditions instead, as in [Start here](#start-here-did-the-expected-worker-bind). Use the audit-log query in [Read the pool's annotations](#read-the-pools-annotations) and the [pool log query](#read-the-pool-logs). Do not keep waiting for a binding once the count is back at zero.
4. **If the race happened, delete and recreate the version**, so a fresh WCI gets a full window. Proceed only when **all** of these hold:
   - the version has never been Current or Ramping;
   - it has no Task Queue binding;
   - no Workflow was started with a versioning override that pins it to this version;
   - the user has approved the deletion.

   Without a binding, and having never been Current or Ramping, the version cannot have received Tasks, so an empty drainage status is acceptable here. **An empty drainage status alone does not make a deletion safe.** Delete the version, then wait until its WCI Workflow is no longer Running before recreating it with the same `create-version` command:

   ```bash
   temporal --profile <PROFILE> worker deployment delete-version \
     --namespace <NS> --deployment-name <NAME> --build-id <BUILD_ID>

   temporal --profile <PROFILE> workflow describe --namespace <NS> \
     --workflow-id 'temporal-sys-worker-controller-instance:<NAME>:<BUILD_ID>'
   ```

   Gate the recreate on the WCI's status, not on elapsed time. After recreating, repeat steps 1 and 3 and then the [binding check](#start-here-did-the-expected-worker-bind). Do not pass `--skip-drainage`: a version that needs it is not covered by these conditions.

### 3. Is the version current?

The registration bootstrap does not make the version current. New traffic routes only after the version is current, and a CLI-created version is not current automatically. Verify with `temporal worker deployment describe`.

**A `set-current-version` run without `--yes` may have done nothing** — it prompts, and non-interactively exits without applying the change, which reads as success.

### 4. Is the pool at its ceiling?

If instances are running but the count stops growing while backlog builds:

- **The maximum defaults to 30.** Raise it in the version's Scaling and Lifecycle settings, or update the existing version from the CLI:

  ```bash
temporal --profile <PROFILE> worker deployment update-version-compute-config \
    --namespace <NS> \
    --deployment-name <NAME> \
    --build-id <BUILD_ID> \
    --gcp-cloud-run-min-instances 0 \
    --gcp-cloud-run-max-instances <NEW_MAX> \
    --gcp-cloud-run-initial-instances 0 \
    --gcp-cloud-run-utilization-target 0.8 \
    --gcp-cloud-run-scale-down-stabilization-duration 90s
  ```

  Choose values appropriate for the version rather than blindly copying this default-shaped example; the initial count must be between the minimum and maximum. Before running it, adapt the complete flag group using the canonical [CLI compatibility and coupled-flag guidance](setup.md#step-6-register-the-worker-deployment-version). Omitting the scaler flags leaves the existing settings unchanged and does not resolve a pool that is already at its ceiling.
- If the count stalls *below the configured maximum*, check the project's [Cloud Run quotas](https://cloud.google.com/run/quotas) for that region. Cloud Run caps instances and CPU per region regardless of what the WCI requests.

## Instances are running but Tasks are not completing

### Read the pool logs

```bash
gcloud logging read \
  'resource.type="cloud_run_worker_pool" AND resource.labels.worker_pool_name="<POOL_NAME>" AND resource.labels.location="<REGION>"' \
  --project <YOUR_GCP_PROJECT> --freshness=1h --limit=50
```

This returns the Worker's container output and the pool's resize audit entries (`UpdateWorkerPool`). `gcloud run worker-pools logs read` shows container output only and also filters on the pool's region; it can return nothing even when the Worker's startup line is present, so prefer the query above.

**A scaled-to-zero pool emits no new logs.** Use `gcloud run worker-pools logs tail` only while an instance is running. An empty result may simply mean the pool has never started.

Common errors:

- **Connection failures** — check `TEMPORAL_ADDRESS` and `TEMPORAL_NAMESPACE` on the pool. Self-hosted: verify network reachability from Cloud Run to the frontend.
- **Missing secrets** — the instance cannot read the API key or TLS material. The **runner** service account needs `roles/secretmanager.secretAccessor` on the secret. That is the account in `spec.template.spec.serviceAccountName`, **not the invoker.**
- **Authentication errors** — key invalid, expired, or without access to the Namespace.
- **`TransportError: … NativeCertsNotFound`** — a Rust-core SDK in a minimal base image with no CA certificates. Install `ca-certificates` in the image. → `setup.md`.

Every sample Worker should emit one startup line containing `deployment`, `build`, and `taskQueue`. Compare those values with the WDV before changing IAM. If they differ, the pool is healthy but is running the wrong artifact.

### Deployment name and build ID

Instances start and poll but no Task is ever processed → the name or build ID in the code does not match the version. The Worker polls under a version the WCI does not manage, **so its polls never satisfy the Tasks the WCI is scaling for.**

This appears as a running pool with healthy-looking logs but no Workflow progress.

## Activities interrupted mid-execution

Activities failing partway and retrying from the beginning, correlated with the pool shrinking, means **scale-in is stopping instances that are still working.** The WCI does not track whether the instance Cloud Run stops is mid-Activity.

This is expected behavior, not a misconfiguration. Confirm the Worker handles `SIGTERM` and has a non-zero graceful-shutdown timeout below Cloud Run's ten-second termination window; this lets short work drain. Long-running work still needs **Activity Heartbeats** so a retry resumes from its last recorded progress. → `constraints.md`.

## Rule out a GCP-side cause

If every check passes, the cause may be in Cloud Run rather than your configuration:

- [Cloud Run known issues](https://cloud.google.com/run/docs/known-issues) — includes issues affecting how long pool operations take.
- [Google Cloud Service Health](https://status.cloud.google.com/) — active incidents by product and region.

If a provider issue is confirmed, wait for recovery or move to another region. **Moving region means creating a new pool and updating the compute configuration**, since Temporal addresses a pool by project, region, and name.
