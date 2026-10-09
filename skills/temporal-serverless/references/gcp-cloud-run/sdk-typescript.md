# TypeScript SDK on GCP Cloud Run


Use this reference for TypeScript-specific Worker construction, versioning behavior, connection configuration, image packaging, and scale-in safety. For shared Cloud Run execution constraints, deployment lifecycle, permissions, versioning, observability, and diagnostics, see `constraints.md`, `setup.md`, `iam.md`, `versioning.md`, `observability.md`, and `diagnostics.md`. Scoping (Namespace, GCP project, region), the API-key hand-off, IAM, registration, and verification are the same for every SDK and are defined once in `SKILL.md` and `setup.md`; do not vary them per SDK. This guide's sample is one Workflow that takes a string and returns `Hello, <name>!`, which is what `setup.md` Step 8 verifies.

## Install and scaffold

Initialize the project and pin the SDK and compiler versions validated for this guide:

```bash
npm init -y
npm install --save-exact @temporalio/activity@1.24.0 @temporalio/client@1.24.0 @temporalio/worker@1.24.0 @temporalio/workflow@1.24.0
npm install --save-exact --save-dev typescript@7.0.2 @types/node@22.20.4
npx tsc --init --rootDir src --outDir dist --module commonjs --target es2022 --esModuleInterop --verbatimModuleSyntax false --types node
npm pkg set scripts.build='tsc' scripts.start='node dist/worker.js'
```

The start script and the image's `CMD` run `dist/worker.js`, and the Worker loads `./workflows` and `./activities`, so use these file names:

```text
<APP_DIR>/
  package.json  package-lock.json  tsconfig.json
  Dockerfile  .gcloudignore
  src/worker.ts       # versioned Worker
  src/workflows.ts    # Workflows
  src/activities.ts   # Activities
```

## Inspect the versioning API before generating code

```bash
npm ls @temporalio/worker
grep -rn "workerDeploymentOptions\|WorkerDeploymentOptions" node_modules/@temporalio/worker/lib/*.d.ts
```

## Versioned Worker

Pass `workerDeploymentOptions` to `Worker.create()`. The Worker reads its connection settings and Task Queue from the environment so one image runs against any Namespace:

```ts
import { NativeConnection, Worker } from '@temporalio/worker';
import * as activities from './activities';

function requiredEnv(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`${name} must be set`);
  return value;
}

async function main(): Promise<void> {
  const deploymentName = requiredEnv('TEMPORAL_DEPLOYMENT_NAME');
  const buildId = requiredEnv('TEMPORAL_BUILD_ID');
  const taskQueue = requiredEnv('TEMPORAL_TASK_QUEUE');
  const connection = await NativeConnection.connect({
    address: requiredEnv('TEMPORAL_ADDRESS'),
    apiKey: requiredEnv('TEMPORAL_API_KEY'),
    tls: true,
  });

  const worker = await Worker.create({
    connection,
    namespace: requiredEnv('TEMPORAL_NAMESPACE'),
    taskQueue,
    workflowsPath: require.resolve('./workflows'),
    activities,
    workerDeploymentOptions: {
      version: { deploymentName, buildId },
      useWorkerVersioning: true,
      defaultVersioningBehavior: 'PINNED',
    },
    shutdownGraceTime: '8s',
    shutdownForceTime: '9s',
  });

  console.info(`Worker started deployment=${deploymentName} build=${buildId} taskQueue=${taskQueue}`);
  await worker.run();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
```

`deploymentName` and `buildId` must match the version created with `temporal worker deployment create-version` exactly, or the Worker polls under a version the WCI does not manage. → `setup.md` Step 6.

Cloud Run needs no `workflowBundle` — `workflowsPath` is sufficient because the instance is long-lived and bundling only improves startup time.

## Versioning behavior

Every Workflow needs `'PINNED'` or `'AUTO_UPGRADE'`. With `useWorkerVersioning: true`, `defaultVersioningBehavior` is required: `tsc` rejects the options without it, and untyped code fails `Worker.create()` with `Unknown versioning behavior: undefined`. To override the default for one Workflow, use `setWorkflowOptions()` from `@temporalio/workflow`.

```ts
import { setWorkflowOptions } from '@temporalio/workflow';

setWorkflowOptions({ versioningBehavior: 'PINNED' }, myWorkflow);
export async function myWorkflow(name: string): Promise<string> {
  // ...
}
```

## Connection configuration

Read the Namespace, address, and Task Queue from environment variables set on the pool, and mount the API key or TLS material from Secret Manager rather than passing it in plaintext. → `setup.md` Step 4.

To load them through the shared config format and profiles instead, use `loadClientConnectConfig()` from `@temporalio/envconfig` and pass its `connectionOptions` and `namespace` to `NativeConnection.connect()` and `Worker.create()`.

## Image packaging

Three things, all of which fail at startup rather than at build time:

- **Install `ca-certificates` in the runtime stage.** The Rust core reads TLS roots from the OS store and the slim Node images ship without one; on `node:22-slim` a TLS connection fails with `TransportError: tonic::transport::Error(Transport, NativeCertsNotFound)`.
- **Use a glibc image such as `node:22-slim`, not Alpine.** Alpine's musl is unsupported by the Rust core.
- **Leave headroom for native memory.** The instance limit covers both V8 and Temporal's Rust core. Set `NODE_OPTIONS=--max-old-space-size=<MB>` only when measurements justify it. A pool defaults to 512 MiB per instance, so raise `--memory` if the Worker needs more.

→ `setup.md` Step 2, `diagnostics.md`.

Use this multi-stage image and `.gcloudignore`:

```dockerfile
FROM node:22-slim AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY tsconfig.json ./
COPY src ./src
RUN npm run build

FROM node:22-slim
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev
COPY --from=build /app/dist ./dist
CMD ["node", "dist/worker.js"]
```

```gitignore
.git
.gitignore
.idea
node_modules
dist
npm-debug.log
terraform/
.terraform/
*.tfstate*
```

Cloud Run Worker Pools run this image as `linux/amd64`.

## Graceful shutdown on scale-in

The versioned Worker example uses `await worker.run()`. The TypeScript SDK Runtime registers `SIGINT`, `SIGTERM`, `SIGQUIT`, and `SIGUSR2` as shutdown signals by default, so Cloud Run's `SIGTERM` starts the Worker's normal shutdown without an application-level signal handler. `shutdownGraceTime` gives received Activities eight seconds before cancellation; `shutdownForceTime` prevents a non-cooperative Activity from keeping the process alive until Cloud Run kills it. If the application installs a custom Runtime, preserve `SIGTERM` in its `shutdownSignals`.

## Keep Activities safe across scale-in

Apply the Heartbeat-resume invariant from `constraints.md`. This is the sample's only Workflow: it takes one string and calls one Activity with Heartbeat and retry options.

```ts
import { proxyActivities } from '@temporalio/workflow';
import type * as activities from './activities';

const { myActivity } = proxyActivities<typeof activities>({
  startToCloseTimeout: '10m',
  heartbeatTimeout: '10s',
  retry: {
    initialInterval: '1s',
    maximumAttempts: 5,
  },
});

export async function myWorkflow(name: string): Promise<string> {
  return myActivity(name);
}
```

The Activity records the next step to run, so a retry after scale-in resumes there instead of starting over. Each step must be safe to repeat:

```ts
import { activityInfo, heartbeat } from '@temporalio/activity';

export async function myActivity(name: string): Promise<string> {
  const steps = ['validate', 'compose', 'record'];
  const startIndex = (activityInfo().heartbeatDetails as number | undefined) ?? 0;

  for (let i = startIndex; i < steps.length; i++) {
    // ... run steps[i] for name
    heartbeat(i + 1);
  }
  return `Hello, ${name}!`;
}
```

→ `constraints.md` for what else follows from the pool model.

## Observability

The TypeScript SDK has no Cloud Run-specific OpenTelemetry helper. Use the TypeScript SDK's standard OpenTelemetry configuration and point its OTLP exporter at the Collector sidecar on `http://localhost:4317`.

Use the multi-container topology and IAM in `observability.md`, keep telemetry optional, and preserve the Worker's existing shutdown handling. If the application shuts down the OpenTelemetry SDK on exit, bound that shutdown to about one second: with `shutdownForceTime` at nine seconds, little more remains of Cloud Run's roughly ten-second termination window. Do not substitute a helper from another SDK or claim that one is required. For the SDK configuration, see `docs/develop/typescript/platform/observability`.
