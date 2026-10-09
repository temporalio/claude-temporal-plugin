# AWS Lambda — Diagnostics & troubleshooting


## Invocation flow (when working correctly)

When a Serverless Worker invocation works correctly, the following sequence happens:

1. You deploy the Worker function on Lambda.
2. You configure a Worker Deployment Version with a compute provider. This starts a Worker Controller Instance (WCI) Workflow and a validation invocation of the Lambda function.
3. The Lambda polls the Temporal Service successfully, binding the Task Queue configured on the Worker to the Worker Deployment Version.
4. The WCI continuously monitors the associated Task Queue on a schedule. The Matching Service also notifies the WCI Workflow of sync match failures immediately as they happen.
5. A Task arrives on the Task Queue and the WCI detects the backlog.
6. The WCI invokes the Lambda function.
7. The Lambda function starts, the Worker connects to Temporal and polls the Task Queue.
8. The Worker processes Tasks and shuts down gracefully.

## Diagnostic decision tree

Start by determining whether the Lambda function is being invoked at all, then narrow down from there.

Check the Lambda function's CloudWatch metrics or invocation logs. In the AWS Console, go to **Lambda > Functions > your function > Monitor**. Look for recent invocations in the **Invocations** graph. You can also check **CloudWatch > Log groups > /aws/lambda/your-function-name** for execution logs.

- If there are no invocations: see [Lambda is not being invoked](#lambda-not-invoked).
- If the Lambda is being invoked but Workflows are not progressing: see [Lambda is invoked but Tasks are not completing](#lambda-invoked-not-completing).

---

## Lambda is not being invoked {#lambda-not-invoked}

Work through the following checks in order.

### 1. Validate the connection to Lambda

Go to **Workers > Deployments > select your deployment**, open the **Actions** menu on the version, and click **Validate Connection**.

A successful validation confirms that:
- The Worker Deployment Version has a compute provider configured.
- Temporal can assume the invocation role.
- The Lambda function can be invoked.

If validation fails:
- Verify the Lambda function ARN and invocation role ARN in the Worker Deployment Version configuration are correct.
- Verify the invocation role was created using the CloudFormation template and that the External ID matches the value in the Worker Deployment Version configuration.

**Not every validation failure is on your side.** If the error is Temporal failing to obtain its **own** base AWS credentials (for example, `no EC2 IMDS role found`) while assuming the `wci-lambda-invoke` role, that is a Temporal-Cloud-side credential problem occurring *before* Temporal ever reaches your invocation role or Lambda. Signature: it reproduces identically no matter what you change on the AWS side, and (for Cloud) is independent of your trust policy or External ID. Do not keep editing your AWS config — verify your artifacts once (Lambda `Active` with the correct runtime; trust policy lists all five `wci-lambda-invoke` principals plus the `sts:ExternalId` condition; invoke permissions scoped to the function ARN), then escalate to Temporal support. Expect infrastructure-side rough edges while the feature is in Public Preview.

If the Worker Deployment Version does not have a compute provider configured, no WCI Workflow exists and the Lambda is never automatically invoked.

**Common cause:** Manually invoking the Lambda function before creating the Worker Deployment Version in the UI or CLI. When the Lambda runs, the Worker connects to Temporal and polls the Task Queue. That polling registers the Worker Deployment Version and binds the Task Queue on the server, but the version has no compute provider. To fix, create or update the Worker Deployment Version with the compute provider flags.

**Recovering a provider-less version via the CLI.** In practice there is no `update-provider` command, and `describe-version` does **not** show whether a compute provider is attached, so you cannot confirm the provider-less state by inspecting the version — you infer it because `create-version` reports the version already exists. Re-running `create-version` fails for the same reason. The reliable fix is to **delete the provider-less version and recreate it** with the compute-provider flags. This is clean as long as the version was never set as current.

```bash
temporal worker deployment delete-version \
  --deployment-name <DEPLOYMENT_NAME> \
  --build-id <BUILD_ID>
# then re-run: temporal worker deployment create-version --aws-lambda-function-arn ... (see setup.md, Step 4)
```
`delete-version` requires the version to not be Current, Ramping, or have active pollers; add `--skip-drainage` to ignore the draining restriction.

### 2. Check that the version is set as current

The Worker Deployment Version must be set as the current version for new Tasks to route to it. If you created the version through the CLI, you need to set it as current.

Verify the current version with:

```bash
temporal worker deployment describe --name <DEPLOYMENT_NAME>
```

**A `set-current-version` that ran without `--yes` may have done nothing.** The command prompts for confirmation; run non-interactively (script, CI, agent shell) it exits without applying the change, which is easy to mistake for success. If `describe` does not show your build as current, re-run `set-current-version` with `--yes` rather than looking for a deeper cause.

### 3. Check that the WCI is detecting Tasks

If the connection validates successfully but the Lambda is still not being invoked, the WCI may not be detecting Tasks on the Task Queue.

Check which Task Queues are bound to the Worker Deployment Version and whether there is a backlog:

```bash
temporal worker deployment describe-version \
  --namespace <NAMESPACE> \
  --deployment-name <DEPLOYMENT_NAME> \
  --build-id <BUILD_ID> \
  --report-task-queue-stats
```

If no Task Queues are listed, the binding has not been established. The server binds a Task Queue to a Worker Deployment Version when a Worker with that deployment version successfully connects and polls the Task Queue.

**What a healthy version looks like.** The inverse of the check above is the single most useful positive signal in the whole setup: the Task Queue appearing here, for both workflow and activity task types, proves that Temporal assumed the invocation role, invoked the Lambda, the package loaded, the env vars were right, the Worker authenticated to the Namespace, and the timeout was long enough to reach a poll. Getting this output means every remaining failure is downstream (routing, versioning-behavior, or application code), so check it immediately after `create-version` and before touching anything else. `describe-version` still does **not** report whether a compute provider is attached, so it cannot rule that in or out.

#### Failed first invocation

A common cause of missing Task Queue bindings is a failed first invocation. When you create a Worker Deployment Version, the WCI invokes the Lambda to validate the configuration. If that first invocation fails (for example, due to missing environment variables, incorrect TLS configuration, missing dependencies, or a Lambda timeout that is too short), the Worker never connects to Temporal and never polls. Without a successful poll, the Task Queue binding is never created.

Pay particular attention to the Lambda timeout. AWS Lambda functions default to a 3-second timeout, which is often too short for the Worker to start, connect to Temporal, and register the Task Queue before AWS terminates the invocation. If the function times out during this initial invocation, the binding is never established and the Lambda is not invoked again.

To diagnose: invoke the Lambda function manually from the AWS Console. The console displays the execution result and any errors directly, making it easier to identify configuration issues than searching through CloudWatch logs. Once the Lambda runs successfully and the Worker connects to Temporal, the Task Queue binding is established.

**A manual invoke runs for nearly the whole timeout.** A serverless Worker keeps polling until its shutdown-deadline buffer, so a synchronous manual invoke runs for roughly the full Lambda timeout (e.g. ~590s of a 600s timeout), not a few seconds. From the AWS CLI (`aws lambda invoke`) this trips the default **60-second client read timeout** with a "Read timeout on endpoint" error — that is expected, **not** a Worker crash. Add `--cli-read-timeout 0` (or use `--invocation-type Event` for an async invoke), and judge health from the CloudWatch startup logs (Worker connected + polling), not from the CLI's exit. Remember this successful poll also auto-registers a provider-less version — see "Common cause" above.

---

## Lambda is invoked but Tasks are not completing {#lambda-invoked-not-completing}

If CloudWatch shows Lambda invocations but Workflows are not progressing, the problem is in the Worker's execution within the Lambda function.

### Check Lambda execution logs

Check CloudWatch logs for errors during Worker startup. In the AWS Console, go to **CloudWatch > Log groups > /aws/lambda/your-function-name** and look for recent error messages.

Common errors include:

- **Connection failures**: The Worker cannot reach the Temporal Service. Check that the `TEMPORAL_ADDRESS` and `TEMPORAL_API_KEY` environment variables (or `temporal.toml` config file) are correctly set on the Lambda function. For self-hosted deployments, verify network reachability.
- **TLS errors**: The TLS certificate or key is missing, expired, or does not match the Namespace.
- **Authentication errors**: The API key is invalid or does not have access to the Namespace.

### Language-specific signatures

**No application logs at all, but the Worker clearly ran.** SDK-specific logging configuration can suppress application logs even when the Worker is healthy. Diagnose invocation health from Lambda's runtime markers (`INIT_START`/`START`/`END`/`REPORT`) and CloudWatch metrics.

For the exact logging cause and fix, see the selected SDK reference.

### Check for Lambda timeout

If the Lambda function reaches its configured timeout before the Worker finishes processing, AWS terminates the invocation.

The Worker begins graceful shutdown before the Lambda deadline. If Activities take longer than the available execution window, the Activities are abandoned mid-execution and retried on the next invocation.

For long-running Activities, increase the Lambda timeout and the Worker's shutdown buffer together.

### Check that the deployment name and build ID match

If CloudWatch shows rapid, repeated invocations with no Workflow progress, the deployment name or build ID in the Worker code may not match the Worker Deployment Version configuration.

The deployment name and build ID in your Lambda function code must exactly match the values you used when creating the Worker Deployment Version. Compare the values in your code against the WCI Workflow ID (`temporal-sys-worker-controller-instance:<deployment-name>:<build-id>`) and the output of `temporal worker deployment describe`.

A mismatch causes an invocation loop: the WCI invokes the Lambda, the Worker starts and polls with a different deployment version than the WCI expects, the Task is not processed, and the WCI invokes the Lambda again.

To fix the loop, update the deployment name and build ID in the Worker code to match the Worker Deployment Version, then redeploy the Lambda function.

---

## WCI and version inspection

Use [Worker Controller Instance (WCI)](../wci.md#inspect-the-wci) to find the WCI, inspect its Activity results, and interpret its Running state before changing AWS resources.

Describe a Worker Deployment Version and check Task Queue stats:

```bash
temporal worker deployment describe-version \
  --namespace <NAMESPACE> \
  --deployment-name <DEPLOYMENT_NAME> \
  --build-id <BUILD_ID> \
  --report-task-queue-stats
```
