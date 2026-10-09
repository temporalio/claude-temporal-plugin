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

Set the previous version current again. Its existing pool scales up on the next Task without rebuilding or reverting an image. If you reused the same pool, setting the previous Temporal version current is not enough because both versions address mutable pool state. Restore the known-good Cloud Run revision split as described above; if that revision was deleted, redeploy the old image deliberately.

## Cost of the discipline

A pool per build means pools accumulate. They cost nothing while at zero instances, but they are real resources with real names, and stale ones make the project harder to reason about. Delete a pool once its version is deleted and no Pinned Workflow can route to it — that ordering is in `setup.md`'s teardown section.
