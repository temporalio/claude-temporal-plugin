# AWS Lambda — Setup (happy path)

<!-- Sources:
  docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx
  docs/production-deployment/worker-deployments/serverless-workers/index.mdx
  docs/develop/environment-configuration.mdx
-->

This is the end-to-end golden path: connect, write the Worker, package and deploy, register a Worker Deployment Version, set it current, and verify. For the operator permissions and preflight, execution/invocation roles, and CloudFormation, see `iam.md`. For production build versioning (`publish-version`, qualified ARNs, rollback), see `versioning.md`. For self-hosted server enablement, see `self-hosted.md`. If it doesn't work, see `diagnostics.md`.

## Prerequisites

- A Temporal Cloud account with an AWS-hosted Namespace, or a self-hosted Temporal Service v1.31.0 or later. <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:37 -->
- The Namespace's cloud provider must match the serverless compute provider. <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:37-38 -->
- For self-hosted deployments, complete the self-hosted setup before following the deployment guide. <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:39-41 -->
- Every Workflow must declare a versioning behavior, or the Worker must set a default versioning behavior. <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:42-43 -->
- An AWS account with permissions to create and invoke Lambda functions and create IAM roles. For the exact operator actions and a preflight check, see `iam.md`. <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:44 -->
- The AWS-specific steps require the `aws` CLI installed and configured with your AWS credentials. You may also use the AWS Console or the AWS SDKs. <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:45-46 -->
- The Go SDK, Python SDK, TypeScript SDK, Java SDK, or .NET SDK, depending on your language. <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:48-49 -->
- The `temporal` CLI, authenticated to the target Temporal Service — Steps 4–6 and the CLI troubleshooting paths use it. See "Temporal CLI and Cloud connection" below.

The selected SDK reference links its maintained sample project.

## Temporal CLI and Cloud connection

Steps 4–6 and the CLI troubleshooting paths use the `temporal` CLI. Install it and authenticate it to the target Temporal Service before those steps, or commands default to `localhost:7233` and fail against Temporal Cloud. The serverless `worker deployment create-version` subcommand and its `--aws-lambda-*` flags also require a recent CLI build — see "Check the CLI version" in Step 4. <!-- docs/develop/environment-configuration.mdx -->

**Authenticate to Temporal Cloud (API key).** Export environment variables (the CLI and the serverless Worker packages both read these):

```bash
export TEMPORAL_ADDRESS="<namespace_id>.<account_id>.tmprl.cloud:7233"
export TEMPORAL_NAMESPACE="<namespace_id>.<account_id>"
export TEMPORAL_API_KEY="<your-api-key>"
```

or configure a profile and pass `--profile prod` on each command:

```bash
temporal --profile prod config set --prop address --value "<namespace_id>.<account_id>.tmprl.cloud:7233"
temporal --profile prod config set --prop namespace --value "<namespace_id>.<account_id>"
temporal --profile prod config set --prop api_key --value "<your-api-key>"
```
<!-- docs/develop/environment-configuration.mdx:122-131 -->

or configure an environment and pass `--env prod` (or set `TEMPORAL_ENV`):

```bash
temporal env set --env prod --key address --value "<namespace_id>.<account_id>.tmprl.cloud:7233"
temporal env set --env prod --key namespace --value "<namespace_id>.<account_id>"
temporal env set --env prod --key api-key --value "<your-api-key>"
```

**Do not assume which of the three a user has, and do not migrate them.** `--env` (YAML, `temporal env`) is the long-standing mechanism; `--profile` (TOML, `temporal config`) is newer and the CLI still marks it EXPERIMENTAL. Both are supported — work with whichever is already configured. Read the existing values rather than asking the user to re-enter them:

```bash
temporal env get --env prod          # --env mechanism
temporal config get --prop address   # --profile mechanism
```

- For Temporal Cloud the Namespace is the fully-qualified `<namespace_id>.<account_id>`, not the bare name. <!-- docs/develop/environment-configuration.mdx:128-129 -->
- Supplying an API key auto-enables TLS; no cert flags are needed for API-key auth. <!-- docs/develop/environment-configuration.mdx:70 -->
- The `temporal ...` commands in Steps 4–6 assume this is configured. To create an API key, see `skill-temporal-ops`.

**Temporal-side preflight.** Confirm the CLI can reach the Namespace before deploying — this is the Temporal side of the pre-deploy access check. It should list (empty is fine) without an auth or connection error:

```bash
temporal worker deployment list
```

If this fails with an auth error, note first that this is a **frontend** call — it needs address, Namespace, and an API key. A control-plane login does not provide any of them; the two planes are separate:

| | Control plane (accounts, Namespaces, API keys) | Namespace frontend (Workflows, Worker Deployments) |
|---|---|---|
| Interactive | `tcld login` | `temporal ...` with address + namespace |
| Headless | `--api-key` / `TEMPORAL_CLOUD_API_KEY` | `TEMPORAL_API_KEY` |

**Use `tcld` for every Temporal Cloud control-plane operation** — accounts, Namespaces, API keys, users, service accounts. Do not use the unified CLI's `temporal cloud …` subcommands for them.

**Worker Deployments and Workflows are not control-plane operations.** They live on the Namespace frontend and have no `tcld` equivalent: Steps 4–6 use `temporal worker deployment …`, authenticated with address, Namespace, and `TEMPORAL_API_KEY`.

The two API-key variables are **different**: `TEMPORAL_CLOUD_API_KEY` authenticates `tcld`, `TEMPORAL_API_KEY` authenticates the frontend and is the one the Worker needs. Do not set one expecting the other.

Two `tcld` mechanics worth knowing before you run it in an agent shell:

- `tcld login --disable-pop-up` prints the URL instead of opening a browser. Auto-open is unreliable over SSH, in containers, and in remote sessions, and the user needs the URL in the conversation either way.
- `tcld` prompts for confirmation before mutating operations. Non-interactively, pass the global `--auto_confirm` (note the underscore) or set `AUTO_CONFIRM=true`, then read the resulting state back — without it the command exits clean having changed nothing.

**Go to the API key first.** It requires no CLI login, no browser handshake, and works on every account type:

```bash
export TEMPORAL_ADDRESS="<namespace_id>.<account_id>.tmprl.cloud:7233"
export TEMPORAL_NAMESPACE="<namespace_id>.<account_id>"
export TEMPORAL_API_KEY="<created in the Cloud UI>"
```

Have the user create the key in the Cloud UI, signing in however they normally do, and confirm the address against the endpoint shown on the Namespace page — some Namespaces have regional endpoints that do not follow the pattern above. Never ask them to paste the key into the conversation.

**A control-plane login is a convenience, not a prerequisite.** When it is available it saves asking:

```bash
tcld namespace list             # full Namespace objects — every name with its region and endpoint
tcld namespace get -n <ns>      # one Namespace
tcld apikey create --name <name> --duration <d>
```

`apikey create` mints a key for the calling user and creates a long-lived credential in their account — offer it and get explicit approval, never silently. `tcld` is not guaranteed present: check `command -v tcld`, and read `tcld <group> --help` for the flags you are about to pass.

**When a control-plane login fails, stop — do not debug it, retry it, or install another CLI.** Some accounts cannot complete a `tcld` login at all, and no flag, plugin upgrade, or alternate CLI changes that. Retrying burns turns without converging, and the browser path below reaches the same end state anyway.

**Then put the choice to the user rather than deciding for them:** fix the CLI, or work in the browser while you give the instructions. Only the control-plane steps move — the frontend work needs address, Namespace, and an API key, and no control-plane login at all, so it continues either way. In the Cloud UI, the control-plane steps are Namespace names, regions, and endpoints, and API key creation; the frontend steps are creating the Worker Deployment Version with its compute provider, and setting a version current, which the UI does automatically and the CLI does not. Where the login cannot complete, say so plainly instead of sending the user back to retry it.

Do not proceed to Steps 4–6 on the assumption auth will work — re-run this command and confirm.

## Step 1: Write Worker code

The Worker handles the per-invocation lifecycle: connecting to Temporal, polling for tasks, and gracefully shutting down before the invocation deadline. <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:62-63 -->

Load the reference for the selected SDK alongside this shared deployment guide:

| SDK | Reference |
|---|---|
| Go | `sdk-go.md` |
| Python | `sdk-python.md` |
| TypeScript | `sdk-typescript.md` |
| Java | `sdk-java.md` |
| .NET | `sdk-dotnet.md` |

Complete the selected SDK reference before continuing.

- **You do not construct a client.** Connection details (address, namespace, API key) load automatically from the process environment, so `TEMPORAL_*` variables set on the function flow straight through with no client code. In a Lambda that means the `--environment` block at deploy time: no config file is bundled unless you put one there, and the operator's own CLI configuration never reaches the function (see "Operator CLI config does not reach the function" below).

## Step 2: Deploy Lambda function

### Build and package

See the selected SDK reference's **Build and package** section.

### Deploy the Lambda function

**A freshly created execution role may not be assumable immediately.** `create-function` can fail with an assume-role / "cannot be assumed by Lambda" error because of IAM propagation delay. Wait a few seconds and retry; it is not a policy error, so do not start rewriting the trust policy.

**Operator CLI config does not reach the function.** All three CLI mechanisms above — exported `TEMPORAL_*` variables, `--profile`, and `--env` — configure the `temporal` CLI on the operator's machine only. The function reads its own environment, set by the `--environment` block below (or a secret store). A user with a working `--env prod` or `--profile prod` still needs every value written into that block; nothing is inherited. Treat their CLI configuration as the *source* of the values, not a substitute for setting them.

**Resolve the values before building the block, and check they are not empty.** The heredoc below expands shell variables, which hold values only under the env-var mechanism. Under `--env` or `--profile` they are unset, and an unset variable expands to an empty string: the JSON stays valid, `create-function` succeeds, and the function deploys with `"TEMPORAL_ADDRESS":""` — failing at first invocation with a connection error that looks nothing like its cause. Populate them from whichever mechanism the user actually has (`temporal env get --env prod`, `temporal config get --prop address`), then guard:

```bash
: "${TEMPORAL_ADDRESS:?resolve this before deploying}"
: "${TEMPORAL_NAMESPACE:?resolve this before deploying}"
: "${TEMPORAL_API_KEY:?resolve this before deploying}"
```

**Pass the API key through a file or shell variable, not inline in the shell history.** Building the `--environment` block inline puts the API key into shell history and into any command echo. Reference it from the environment and pass the block via a file instead:

```bash
cat > /tmp/lambda-env.json <<EOF
{"Variables":{"HOME":"/tmp",
  "TEMPORAL_ADDRESS":"${TEMPORAL_ADDRESS}",
  "TEMPORAL_NAMESPACE":"${TEMPORAL_NAMESPACE}",
  "TEMPORAL_API_KEY":"${TEMPORAL_API_KEY}"}}
EOF
aws lambda create-function ... --environment file:///tmp/lambda-env.json
rm /tmp/lambda-env.json
```

This is still a plaintext env var on the function — acceptable for a development walkthrough only, and only if you say so explicitly. See "Environment variables" below for the production pattern.

Run the selected SDK reference's deployment command before continuing.

### Wait for the function to become Active

`create-function` returns immediately with `"State": "Pending"`. The function cannot be invoked and `publish-version` fails while it is pending, so block on the state transition before the next step rather than sleeping a guessed interval:

```bash
aws lambda wait function-active-v2 --function-name my-temporal-worker
```

Use `aws lambda wait function-updated-v2` after `update-function-code` for the same reason (see `versioning.md`). The `-v2` suffix is the AWS CLI v2 waiter name; on AWS CLI v1 the waiters are `function-active` and `function-updated`. If neither resolves, poll instead:

```bash
aws lambda get-function --function-name my-temporal-worker \
  --query 'Configuration.[State,LastUpdateStatus]' --output text
```

### Common parameters (all SDKs)

<!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:315-320 -->

| Parameter | Description |
|---|---|
| `--role` | ARN of the Lambda execution role, which grants the function permission to run (trusted principal: `lambda.amazonaws.com`). This is separate from the role Temporal uses to invoke the function. The role must have at least the `AWSLambdaBasicExecutionRole` managed policy attached. (See `iam.md` for the execution role.) |
| `--zip-file` | Path to your packaged deployment zip. |
| `--timeout` | Invocation deadline in seconds. Maximum time each Lambda invocation can run before AWS terminates it. Set high enough for the Worker to start, process Tasks, and shut down gracefully. |
| `--memory-size` | Memory in MB allocated to each invocation. |

**Caution:** AWS Lambda functions default to a 3-second timeout, which is too short for the Worker to start, connect to Temporal, and register the Task Queue. If the first invocation times out before the Worker polls, the Task Queue binding is never created and the Lambda is never invoked again. Always set `--timeout` high enough for the Worker to start, process Tasks, and shut down gracefully. <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:328-337 -->

Set it from three constraints:

1. **> cold start + connect + Task Queue registration.** The binding requirement, and what rules out the 3s default.
2. **> longest Activity + shutdown deadline buffer.** An Activity still running when the Worker drains is abandoned and retried.
3. **Beyond those, pure cost.** Longer: fewer invocations and cold starts, warmer sticky cache, room for longer Activities. Shorter: a smaller idle tail — when work stops the Worker polls on until its deadline, so the waste is one deadline's worth.

Lambda bills **GB-seconds** — allocated memory × billed duration, however idle the Worker was.

### Environment variables

<!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:321-326 -->

| Variable | Description |
|---|---|
| `TEMPORAL_ADDRESS` | Temporal frontend address (e.g., `<namespace>.<account>.tmprl.cloud:7233`). |
| `TEMPORAL_NAMESPACE` | Temporal Namespace. For Temporal Cloud, the fully-qualified `<namespace_id>.<account_id>`, not the bare name. |
| `TEMPORAL_TASK_QUEUE` | Task Queue name. Overrides the value set in code. |
| `TEMPORAL_TLS_CLIENT_CERT_PATH` | Path to the TLS client certificate file for mTLS authentication. |
| `TEMPORAL_TLS_CLIENT_KEY_PATH` | Path to the TLS client key file for mTLS authentication. |
| `TEMPORAL_API_KEY` | API key for API key authentication. Supplying it auto-enables TLS; mTLS cert paths are not needed. |

The serverless Worker packages read environment variables and configuration files automatically at startup. For the full list of supported environment variables, config file format, and profiles, see the Environment configuration docs (`/develop/environment-configuration`). <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:339-341 -->

Sensitive values like TLS keys and API keys should be encrypted at rest. <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:343-344 -->

For updating the function code and publishing immutable versions, see `versioning.md`.

## Step 3: Configure IAM for Temporal invocation

Step 3 (execution role, Temporal invocation role, and CloudFormation for Temporal Cloud and self-hosted) lives in `iam.md`. Complete it before Step 4.

## Step 4: Create Worker Deployment Version

Create a Worker Deployment Version with a compute provider that points to your Lambda function. The compute configuration tells Temporal how to invoke your Worker: the provider type (`aws-lambda`), the Lambda function ARN, and the IAM role to assume. The deployment name and build ID must match the values in your Worker code. <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:529-532 -->

### Using Temporal UI

<!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:539-553 -->

1. In the Temporal UI, open your Namespace.
2. In the left pane, select **Workers**.
3. Click **Create Worker Deployment** in the upper right corner.
4. Under **Configuration**, enter a **Name** and **Build ID** (must match `DeploymentName` and `BuildID` in your Worker code).
5. Under **Compute**, select **AWS Lambda** and provide:
   - **Lambda ARN**: the ARN of your Lambda function.
   - **IAM Role ARN**: the ARN of the role Temporal assumes to invoke your Lambda function (the `RoleARN` output from the CloudFormation stack). This is not the Lambda execution role or your own IAM user/role.
   - **External ID**: the same value passed to the CloudFormation template.
6. Click **Save**.

When you create a version through the UI, the version is automatically set as current. <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:552 -->

### Using Temporal CLI

Use the CLI for manual setup, shell scripts, and CI/CD pipelines. When you create a version through the CLI, you must set the version as current as a separate step. <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:558-559 -->

**Check the CLI version before relying on these commands.** The `worker deployment create-version` subcommand and its `--aws-lambda-*` flags only exist in recent Temporal CLI builds, and a CLI old enough to lack them fails in a way that looks like a syntax mistake:

```bash
temporal --version
temporal worker deployment create-version --help
```

If the subcommand or the flags are missing, upgrade. Observed bounds: v1.5.0 (Homebrew) lacked `create-version` entirely; v1.8.0 (standalone) had the serverless flags. The exact minimum version is unconfirmed against the CLI changelog, so treat those as bounds rather than a threshold. A current standalone build can be installed alongside a package-managed one without disturbing it — worth doing rather than upgrading a CLI the user may depend on elsewhere.

First, create the Worker Deployment if it does not already exist: <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:561 -->

```bash
temporal worker deployment create \
  --namespace <YOUR_NAMESPACE> \
  --name my-app
```
<!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:563-567 -->

Then create the version with the compute provider configuration: <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:569 -->

```bash
temporal worker deployment create-version \
  --namespace <YOUR_NAMESPACE> \
  --deployment-name my-app \
  --build-id build-1 \
  --aws-lambda-function-arn <LAMBDA_FUNCTION_ARN> \
  --aws-lambda-assume-role-arn <INVOCATION_ROLE_ARN> \
  --aws-lambda-assume-role-external-id <EXTERNAL_ID>
```
<!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:571-579 -->

| Flag | Description |
|---|---|
| `--deployment-name` | Worker Deployment name. Must match `DeploymentName` in your Worker code. |
| `--build-id` | Worker Deployment Version build ID. Must match `BuildID` in your Worker code. |
| `--aws-lambda-function-arn` | Qualified versioned ARN of the Lambda function Temporal invokes for this version (for example, `function:my-worker:5`). An unqualified ARN is also accepted for development. |
| `--aws-lambda-assume-role-arn` | IAM role Temporal assumes to invoke the function. This is the `RoleARN` output from the CloudFormation stack. This is not the Lambda execution role or your own IAM user/role. |
| `--aws-lambda-assume-role-external-id` | External ID configured in the IAM role trust policy. |
<!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:581-587 -->

### Validate connection

Go to **Workers** > **Deployments** > select your deployment > open the **Actions** menu on the version and click **Validate Connection**. This checks that Temporal can assume the IAM role and invoke the function. <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:592-594 -->

### Checkpoint: confirm the validation invocation actually bound the Task Queue

**Do this before Step 5.** Creating the version triggers one validation invocation of the Lambda. If it succeeded, the Worker connected and registered its Task Queue, and `describe-version` lists that Task Queue for both workflow and activity types:

```bash
temporal worker deployment describe-version \
  --deployment-name my-app --build-id build-1 --report-task-queue-stats
```

Task Queues listed = the invocation role, the Lambda package, the env vars, and the timeout are all working end-to-end. This is the cheapest early signal in the whole setup, and it isolates a first-invocation failure to Step 2/3 *before* current-version routing adds another variable. If no Task Queues are listed, stop here and go to `diagnostics.md` ("Failed first invocation") — setting the version current will not fix it.

## Step 5: Set version as current

If you created the version through the Temporal UI, the version is already current — skip this step. <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:598 -->

If you used the CLI, set the version as current. Without this step, tasks on the Task Queue will not route to the version, and Temporal will not invoke the Lambda function. <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:600-601 -->

```bash
temporal worker deployment set-current-version \
  --deployment-name my-app \
  --build-id build-1 \
  --yes
```
<!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:603-607 -->

**`set-current-version` asks for interactive confirmation.** Without `--yes` (`-y`) it prompts, and run non-interactively (scripts, CI, or an agent shell) it exits without applying the change — which reads as a silent no-op: the command appears to succeed but the version never becomes current. Pass `--yes` for any non-interactive use. `set-ramping-version` behaves the same way. Note that `delete-version` does *not* take `--yes` — its gating flag is `--skip-drainage`. <!-- docs/cli/command-reference/worker.mdx:349-391 -->

Confirm it took effect before moving on:

```bash
temporal worker deployment describe --name my-app
```

## Step 6: Verify deployment

Start a Workflow on the same Task Queue to confirm that Temporal invokes your Lambda Worker. <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:611 -->

```bash
temporal workflow start \
  --task-queue my-task-queue \
  --type MyWorkflow \
  --input '"Hello, serverless!"'
```
<!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:613-618 -->

Verify the invocation by checking: <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:623 -->

- **Temporal UI:** The Workflow execution should show task completions in the event history. <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:625 -->
- **AWS CloudWatch Logs:** The Lambda function's log group (`/aws/lambda/my-temporal-worker`) should show invocation logs with the Worker startup, task processing, and graceful shutdown. Requires the execution role to have CloudWatch Logs permissions (included in `AWSLambdaBasicExecutionRole`). <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:626-630 -->

If the Workflow does not progress or the Lambda is not invoked, see `diagnostics.md`. <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:632-633 -->

## Teardown

**Record what you create, as you create it.** These are live, billable AWS resources spread across three services plus Temporal Cloud, and their names are only knowable from the run that created them. Keep a running inventory — function name and published version numbers, execution role name, CloudFormation stack name and role name, region, deployment name and build ID — and hand it to the user at the end. Deliver the inventory before offering teardown, and do not write a teardown script until they ask for one. Reconstructing the inventory later means scanning the account, which the skill otherwise tells you not to do.

To remove a serverless Worker deployment (for example, after an evaluation), tear down in this order so nothing is left invoking or being invoked.

**The Lambda function must go before the Worker Deployment Version, not after.** The intuitive order — Temporal first, so nothing is left invoking — deadlocks, because the version refuses to delete while pollers are active and the pollers *are* the still-running Lambda. Deleting the function is what drains them. Expect the Temporal side to be split across the sequence for this reason.

1. Unset the current version. A Current version cannot be deleted, and a Worker Deployment with versions cannot be deleted either — so this deadlock has to be broken first. `--skip-drainage` does not help here; it waives the draining check, not the Current restriction.
   ```bash
   temporal worker deployment set-current-version \
     --deployment-name my-app --unversioned --yes
   ```
   If other versions exist and should keep serving, set one of them current instead of `--unversioned`.
2. Delete the Lambda function. This removes all published versions, and ends the invocation that is still polling:
   ```bash
   aws lambda delete-function --function-name my-temporal-worker
   ```
3. Wait for the version to drain, then delete it. Poller registration is server-side and expires on a TTL after the Worker stops, so `delete-version` can still fail with active pollers for a while after the function is gone — and the poller list can read empty before drainage has actually completed. Poll for `DrainageStatus: drained` rather than retrying blind:
   ```bash
   temporal worker deployment describe-version \
     --deployment-name my-app --build-id build-1
   temporal worker deployment delete-version \
     --deployment-name my-app --build-id build-1
   ```
4. Delete the Worker Deployment itself, once it has no versions left. This stops its WCI (one WCI runs per version with a compute provider); confirm the WCI has moved to `Completed`, and that any *other* deployment's WCI is still `Running`.
   ```bash
   temporal worker deployment delete --name my-app
   ```
   The deployment may still appear in `list` output immediately afterward — index lag, not a failed delete. Confirm with `describe`.
5. Delete the CloudFormation stack that created the Temporal invocation role — **only if this deployment created it.** One invocation role can authorize several Worker Lambdas, so a pre-existing stack may still be in use by another deployment; in that case remove just this function's ARN from its `LambdaFunctionARNs` instead (see `iam.md`).
   ```bash
   aws cloudformation delete-stack --stack-name <STACK_NAME> --region <AWS_REGION>
   ```
6. If you created a dedicated execution role, delete it — **detach its managed policies first**, or `delete-role` fails with `DeleteConflict: Cannot delete entity, must detach all policies first`:
   ```bash
   ROLE=<EXECUTION_ROLE_NAME>
   aws iam list-attached-role-policies --role-name "$ROLE" \
     --query 'AttachedPolicies[].PolicyArn' --output text \
     | tr '\t' '\n' | while read -r P; do aws iam detach-role-policy --role-name "$ROLE" --policy-arn "$P"; done
   aws iam delete-role --role-name "$ROLE"
   ```
   Skip this if the execution role predates your deployment or is shared with other functions.
7. Delete the CloudWatch log group. **`delete-function` does not remove it** — the log group and its retained events survive the function and keep accruing storage charges:
   ```bash
   aws logs delete-log-group --log-group-name /aws/lambda/my-temporal-worker
   ```
8. **Ask whether to revoke the Temporal Cloud API key** — do not revoke it as a matter of course. The key is account-scoped, not deployment-scoped: tearing this deployment down does not mean the user is finished with Temporal Cloud, and if the key was created during this run (see `skill-temporal-ops`) it is the one they now need for their next deploy, for `tcld`, and for every other Worker in the Namespace. Keep it unless they say otherwise. On a yes, revoke it **last** — it is the credential authenticating every Temporal command above it. Like `set-current-version`, `tcld apikey delete` prompts for confirmation and, run non-interactively, exits without deleting anything; the exit code looks clean while the key is still live. Pass `--auto_confirm` and confirm from the `list` output that the key is gone rather than trusting the exit code.
   ```bash
   tcld apikey delete --id <KEY_ID> --auto_confirm
   tcld apikey list
   ```
