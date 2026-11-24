# GCP Cloud Run — versioning, updates, and rollback

## One Worker Pool per Build ID

**The compute configuration names a project, region, and Worker Pool — it does not name a [revision](https://cloud.google.com/run/docs/managing/revisions).** Temporal runs whichever revision the pool serves, so durable isolation requires a separate pool per build. Carry the Build ID in the pool name (`my-worker-pool-build-1`) to keep that mapping visible. A pool-level instance split can temporarily hold a revision, but the split remains mutable state outside Temporal.

## The hazard: redeploying into a live pool

A normal `gcloud run worker-pools deploy` creates a new revision and promotes it to every instance by default. The Temporal version still points to the same pool, so the code changes underneath it. Replay-unsafe changes can cause non-determinism errors for in-flight Workflows, including Pinned ones, because pinning selects a Temporal version rather than a Cloud Run revision. Use a new pool for durable isolation; `--no-promote` is only a same-pool guardrail.

## Guardrail and recovery when a pool is reused

Pool-per-build remains the production rule because Temporal identifies a Worker Pool, not one of its revisions. If an exceptional workflow must deploy a new revision into a pool that still serves a live version, `--no-promote` prevents the new revision from receiving the pool's instances automatically:

```bash
gcloud run worker-pools deploy <POOL_NAME> \
  --image <REGION>-docker.pkg.dev/<YOUR_GCP_PROJECT>/<REPOSITORY>/<IMAGE>@sha256:<DIGEST> \
  --region <REGION> \
  --project <YOUR_GCP_PROJECT> \
  --no-promote
```

This is a guardrail, not immutable versioning: the pool's revision split remains mutable state outside Temporal. If a new revision was already promoted accidentally, send all instances back to the known-good revision explicitly:

```bash
gcloud run worker-pools update-instance-split <POOL_NAME> \
  --to-revisions=<KNOWN_GOOD_REVISION>=100 \
  --region <REGION> \
  --project <YOUR_GCP_PROJECT>
```

`--to-latest` is **not** that rollback: it assigns instances to the current and future `LATEST` revision. Use it only when deliberately removing the sticky `--no-promote` behavior and restoring automatic promotion of future revisions:

```bash
gcloud run worker-pools update-instance-split <POOL_NAME> \
  --to-latest \
  --region <REGION> \
  --project <YOUR_GCP_PROJECT>
```

After emergency recovery, return to one pool per Build ID for the next release so Temporal version routing and deployed code cannot drift independently.

## Rolling out a new build

1. Choose the new build ID first, pass it into the Worker through the SDK guide's required environment variable or build argument, and build and push an image tagged with that ID. Do not only retag an image whose embedded Worker identity still names the previous build.
2. **Create a new Worker Pool** at zero instances for that build ID, with the same runner service account.
3. Register a new Worker Deployment Version pointing at the new pool, with a build ID matching the new Worker code.
4. Confirm registration bootstrapped the pool: the expected Task Queue types are bound, the deployed image digest matches the intended artifact, and the Worker startup log announces the new build ID. `lastModifier` showing the invoker proves only that Temporal wrote the pool's requested count. Treat the separate UI Validate Connection action as a read-only check. → `diagnostics.md`.
5. Set the new version current, or ramp to it.
6. **Leave the old pool in place** while Pinned Workflows still run on it. It can sit at zero instances; its WCI scales it back up when a Task arrives for that version.

Only the invoker's permissions are shared across pools, so a new pool usually needs no IAM change — provided the invoker's `deploy_roles` are project-level, which is the module's default. Check `iam.md` if you scoped them to individual pools instead.

## Rollback

Before rolling back, confirm the previous version still exists in the deployment:

```bash
temporal --profile <PROFILE> worker deployment describe \
  --namespace <NS> --name my-app -o json \
  | jq -e --arg b '<PREVIOUS_BUILD_ID>' '[.versionSummaries[]?.BuildID] | index($b) != null'
```

CLI v1.8.2 spells the field `BuildID`, and `worker deployment list` returns `versionSummaries` as `null`, so read versions from `describe`. Then confirm the version can take traffic. Take its pool, region, image digest, and Task Queue from the recorded deployment inventory or committed release inputs; Temporal does not return the pool a version targets. Run the [Task Queue binding check](diagnostics.md#start-here-did-the-expected-worker-bind), and confirm the pool still exists, its instance split contains exactly one revision, and that revision serves the recorded digest as in [audit items 2 and 3](diagnostics.md#audit-an-existing-pool). If the record is missing or any check fails or cannot be confirmed, stop before changing routing and tell the user.

Set the previous version current again, then read the routing back as in [`setup.md`](setup.md#step-7-set-the-version-current) Step 7. The previous version's existing pool scales up on the next Task without rebuilding or reverting an image. If you reused the same pool, setting the previous Temporal version current is not enough because both versions address mutable pool state. Restore the known-good Cloud Run revision split as described above; if that revision was deleted, redeploy the old image deliberately.

## Managing pools with Terraform

Create pools with `gcloud` as in `setup.md` Step 4. Declare them in Terraform only when the user asks, and then:

- **Give each build its own pool and never update it.** Pin each pool's image by digest. Any change to a pool's template, including a value shared by every pool such as an environment variable, creates a new revision and replaces that pool's running instances: the [redeploy hazard](#the-hazard-redeploying-into-a-live-pool). A release plan should only create the new build's pool; stop if it updates or replaces a pool a version still points at.
- **Leave the instance count to Temporal.** Temporal writes only `scaling.manual_instance_count`. Create the pool with manual scaling at `0` and set `ignore_changes = [scaling[0].manual_instance_count]`.
- **Keep pools in their own root.** The invoker module requires the Google provider `~> 4.0` (`iam.md`); use `>= 7.18.0` for `google_cloud_run_v2_worker_pool`. One root resolves one provider version.
- **Keep registration out of Terraform.** Register versions and change routing with the `temporal` CLI as in [Rolling out a new build](#rolling-out-a-new-build).
- **Treat the pools as shared infrastructure.** Use remote state with locking, and apply only from reviewed, committed inputs that list every build still in use.

## Cost of the discipline

A pool per build means pools accumulate. They cost nothing while at zero instances, but they are real resources with real names, and stale ones make the project harder to reason about. Delete a pool once its version is deleted and no Pinned Workflow can route to it — that ordering is in `setup.md`'s teardown section.
