# TypeScript SDK on AWS Lambda

<!-- Source: docs/develop/typescript/workers/serverless-workers/aws-lambda.mdx -->

Use this reference for TypeScript SDK-specific package, entry-point, Worker configuration, tuned defaults, and observability details. For shared AWS Lambda deployment and observability infrastructure, see `setup.md` and `observability.md`.

## Package

Import: `import { runWorker } from '@temporalio/lambda-worker'` <!-- docs/develop/typescript/workers/serverless-workers/aws-lambda.mdx:45 -->

Install: `npm install @temporalio/lambda-worker` — a separate npm package from `@temporalio/worker`, versioned independently.

- TypeScript: [TypeScript Lambda Worker sample](https://github.com/temporalio/samples-typescript/tree/main/lambda-worker) <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:56 -->

Check the installed version, then read its type declarations:

```bash
npm ls @temporalio/lambda-worker
```

**Ordering when sources disagree:** the installed artifact first, the SDK's maintained samples second (they are built in CI, so they cannot reference a method that does not exist), the prose docs last. Entry-point names are not consistent across SDKs, so check rather than pattern-match from another language.

## Entry point

`runWorker` — creates a Lambda handler that runs a Temporal Worker. Pass a deployment version and a configure callback. <!-- docs/develop/typescript/workers/serverless-workers/aws-lambda.mdx:39-40 -->

## Configure callback

Set Worker options via `config.workerOptions`. For Workflow code, use `workflowBundle` with pre-bundled code instead of `workflowsPath` to avoid webpack bundling overhead on Lambda cold starts. <!-- docs/develop/typescript/workers/serverless-workers/aws-lambda.mdx:68-69 -->

Go, Python and TypeScript invoke it per invocation.

Python and TypeScript pass Workflow and Activity collections into the worker config.

## Pre-bundling Workflow code

Build the bundle as a separate build step: <!-- docs/develop/typescript/workers/serverless-workers/aws-lambda.mdx:71 -->

```typescript
import { bundleWorkflowCode } from '@temporalio/worker';
import { writeFile } from 'fs/promises';

const { code } = await bundleWorkflowCode({
  workflowsPath: require.resolve('./workflows'),
});
await writeFile('./workflow-bundle.js', code);
```
<!-- docs/develop/typescript/workers/serverless-workers/aws-lambda.mdx:73-81 -->

Then reference the bundle in your handler with `workflowBundle: { codePath: require.resolve('./workflow-bundle.js') }`. <!-- docs/develop/typescript/workers/serverless-workers/aws-lambda.mdx:83 -->

## Versioning behavior

Set per-Workflow with `setWorkflowOptions` in the Workflow file, or set a default for all Workflows with `defaultVersioningBehavior` in the configure callback. <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:172-174 -->
Values are `'PINNED'` or `'AUTO_UPGRADE'`. The default versioning behavior is `PINNED`. <!-- docs/develop/typescript/workers/serverless-workers/aws-lambda.mdx:63-64 -->

Access via: `config.workerOptions.workerDeploymentOptions!.defaultVersioningBehavior = 'PINNED'` <!-- docs/develop/typescript/workers/serverless-workers/aws-lambda.mdx:64 (full expression at docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:165) -->

**Worker Versioning is always on.** The run-worker entry point enables it, so the only remaining decision is `Pinned` vs `AutoUpgrade` per Workflow (or a Worker-level default).

## Handler example

Use the `@temporalio/lambda-worker` package. <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:153 -->

```typescript
import { runWorker } from '@temporalio/lambda-worker';
import * as activities from './activities';

export const handler = runWorker({ deploymentName: 'my-app', buildId: 'build-1' }, (config) => {
  config.workerOptions.taskQueue = 'my-task-queue';
  config.workerOptions.workflowBundle = {
    codePath: require.resolve('./workflow-bundle.js'),
  };
  config.workerOptions.activities = activities;
  config.workerOptions.workerDeploymentOptions!.defaultVersioningBehavior = 'PINNED';
});
```
<!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:155-167 -->

Use `workflowBundle` with pre-bundled code instead of `workflowsPath` to avoid webpack bundling overhead on Lambda cold starts. <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:169-170 -->

Versioning behavior: set per-Workflow with `setWorkflowOptions` in the Workflow file, or set a default for all Workflows with `defaultVersioningBehavior` in the configure callback. Values are `'AUTO_UPGRADE'` or `'PINNED'`. <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:172-174 -->

## Lambda-tuned defaults

<!-- docs/develop/typescript/workers/serverless-workers/aws-lambda.mdx:104-115 -->

| Setting | Lambda default |
|---|---|
| `maxConcurrentActivityTaskExecutions` | 2 |
| `maxConcurrentWorkflowTaskExecutions` | 10 |
| `maxConcurrentLocalActivityExecutions` | 2 |
| `maxConcurrentNexusTaskExecutions` | 5 |
| `workflowTaskPollerBehavior` | `SimpleMaximum(2)` |
| `activityTaskPollerBehavior` | `SimpleMaximum(1)` |
| `nexusTaskPollerBehavior` | `SimpleMaximum(1)` |
| `shutdownGraceTime` | 5 seconds |
| `maxCachedWorkflows` | 30 |
| `shutdownDeadlineBufferMs` | 7000 |

Eager Activities are not supported. Lambda invocations don't maintain persistent connections. <!-- docs/develop/typescript/workers/serverless-workers/aws-lambda.mdx:117 -->

`shutdownDeadlineBufferMs` is specific to the `@temporalio/lambda-worker` package. It controls how much time before the Lambda deadline the Worker begins its graceful shutdown. The default is `shutdownGraceTime` (5s) + 2s. <!-- docs/develop/typescript/workers/serverless-workers/aws-lambda.mdx:119-121 -->

If your Worker handles long-running Activities, increase `shutdownGraceTime`, `shutdownDeadlineBufferMs`, and the Lambda invocation deadline (`--timeout`) together. <!-- docs/develop/typescript/workers/serverless-workers/aws-lambda.mdx:123-124 -->

## Connection configuration

The `@temporalio/lambda-worker` package automatically loads Temporal client configuration from a TOML config file and environment variables (see the Environment Configuration docs, `/develop/environment-configuration`). <!-- docs/develop/typescript/workers/serverless-workers/aws-lambda.mdx:87 -->

TOML config file resolution order: <!-- docs/develop/typescript/workers/serverless-workers/aws-lambda.mdx:89-93 -->

1. `TEMPORAL_CONFIG_FILE` environment variable, if set.
2. `temporal.toml` in `$LAMBDA_TASK_ROOT` (typically `/var/task`).
3. `temporal.toml` in the current working directory.

The file is optional. If absent, only environment variables are used. <!-- docs/develop/typescript/workers/serverless-workers/aws-lambda.mdx:95 -->

## Build and package

Build the Workflow bundle and compile the project: <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:226 -->

```bash
npx ts-node src/scripts/build-workflow-bundle.ts
npx tsc
```
<!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:229-230 -->

Install production dependencies and package everything: <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:233 -->

```bash
npm install --omit=dev
zip -r function.zip lib/ node_modules/ workflow-bundle.js
```
<!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:236-237 -->

## Deploy the Lambda function

```bash
aws lambda create-function \
  --function-name my-temporal-worker \
  --runtime nodejs22.x \
  --handler lib/index.handler \
  --role <EXECUTION_ROLE_ARN> \
  --zip-file fileb://function.zip \
  --timeout 600 \
  --memory-size 256 \
  --environment '{"Variables":{"HOME":"/tmp","TEMPORAL_ADDRESS":"<your-temporal-address>:7233","TEMPORAL_NAMESPACE":"<your-namespace>","TEMPORAL_API_KEY":"<your-api-key>"}}'
```
<!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:292-302 -->

- `--runtime`: `nodejs22.x` (or another supported Node.js version, 20+). <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:307 -->
- `--handler`: `lib/index.handler` (entry point in `module.export` format, must point to the handler exported by `runWorker`). <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:308 -->

| Variable | Description |
|---|---|
| `HOME` | Set to `/tmp` in the Go and TypeScript examples above. Lambda's filesystem is read-only outside `/tmp`, so anything the runtime or config loader resolves relative to the home directory needs a writable target. The docs omit it from the Python example; including it there is harmless. |

## Observability

Import: `import { applyDefaults } from '@temporalio/lambda-worker/otel'` <!-- docs/develop/typescript/workers/serverless-workers/aws-lambda.mdx:138 -->

- `applyDefaults` — registers Temporal SDK interceptors for tracing and configures the Core SDK to export metrics via OTLP. <!-- docs/develop/typescript/workers/serverless-workers/aws-lambda.mdx:148,153 -->
- `makeOtelPlugin` — returns a plugin for pre-bundling Workflow code that includes Workflow interceptor modules. <!-- docs/develop/typescript/workers/serverless-workers/aws-lambda.mdx:222,226 -->

Usage in the configure callback: <!-- docs/develop/typescript/workers/serverless-workers/aws-lambda.mdx:142-149 -->

```typescript
export const handler = runWorker({ deploymentName: 'sdk-demo', buildId: 'v1' }, (config) => {
  config.workerOptions.taskQueue = TASK_QUEUE;
  config.workerOptions.workflowBundle = {
    codePath: require.resolve('./workflow-bundle.js'),
  };
  config.workerOptions.activities = activities;
  applyDefaults(config);
});
```

When pre-bundling Workflow code, pass the plugin from `makeOtelPlugin()` so that Workflow interceptor modules are included in the bundle: <!-- docs/develop/typescript/workers/serverless-workers/aws-lambda.mdx:222 -->

```typescript
import { bundleWorkflowCode } from '@temporalio/worker';
import { makeOtelPlugin } from '@temporalio/lambda-worker/otel';

const { plugin } = makeOtelPlugin();
const { code } = await bundleWorkflowCode({
  workflowsPath: require.resolve('./workflows'),
  plugins: [plugin],
});
```

By default, telemetry is sent to `localhost:4317`, which is the ADOT Lambda layer's default collector endpoint. <!-- docs/develop/typescript/workers/serverless-workers/aws-lambda.mdx:154 -->

Attach two ADOT Lambda layers: <!-- docs/develop/typescript/workers/serverless-workers/aws-lambda.mdx:156 -->

1. The ADOT JavaScript layer for Node.js-side auto-instrumentation and trace export. <!-- docs/develop/typescript/workers/serverless-workers/aws-lambda.mdx:158 -->
2. The ADOT Collector layer (`aws-otel-collector-amd64`) to run the OTel Collector as a Lambda extension, receiving telemetry via OTLP on `localhost:4317` and forwarding traces to X-Ray and metrics to CloudWatch. <!-- docs/develop/typescript/workers/serverless-workers/aws-lambda.mdx:159 -->

`OPENTELEMETRY_COLLECTOR_CONFIG_URI=/var/task/otel-collector-config.yaml` <!-- docs/develop/typescript/workers/serverless-workers/aws-lambda.mdx:208 -->

For the shared Collector configuration, X-Ray enablement, and execution-role permissions, see `observability.md`.
