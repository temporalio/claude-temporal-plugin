# Serverless Workers — Concepts


## Shared serverless concepts

### Release status

**AWS Lambda — Public Preview since July 30, 2026.** Open to all Temporal Cloud customers. There is no access request, no support ticket, and no manual toggle to enable: a customer selects "AWS Lambda (Public Preview)" as the compute provider in the UI and sets up their Worker Deployment directly. Never route a user to support to "get access" for Lambda.

**GCP Cloud Run — Public Preview.** Open to all Temporal Cloud customers with a GCP-hosted Namespace. There is no access request, support ticket, or manual toggle to enable: select GCP Cloud Run as the compute provider and proceed. Never route a user to support to "get access" for Cloud Run either.

These are the two compute providers this skill supports. Do not adapt either provider's material to another provider. For provider-specific execution models, scaling behavior, lifecycle, and limits, read [AWS Lambda constraints](aws-lambda/constraints.md) or [GCP Cloud Run constraints](gcp-cloud-run/constraints.md).

Public Preview is not General Availability. APIs are still evolving and may be subject to backwards-incompatible changes between versions — pin SDK and CLI versions for anything long-lived, and read the installed package's real API surface rather than writing from memory.

### What is a Serverless Worker?

A Serverless Worker is a Temporal Worker whose compute lifecycle is managed by Temporal through a configured compute provider. It registers Workflows and Activities with the normal Temporal SDK APIs, while the provider-specific execution model determines how compute starts, scales, and stops. Read the selected provider's `constraints.md` for those lifecycle rules.

### Compute providers

A compute provider is the configuration that tells Temporal how to start or scale compute for a Worker Deployment Version. It is set on the Worker Deployment Version and specifies the provider type, the compute target, and the identity Temporal uses to act on that target.

For example, an AWS Lambda compute provider includes the Lambda function ARN and the IAM role that Temporal assumes to invoke the function.

A GCP Cloud Run compute provider names the Worker Pool and the invoker service account that Temporal impersonates to resize it.

Compute providers are only needed for Serverless Workers. Traditional long-lived Workers do not require a compute provider because the Worker process lifecycle is not managed by the Temporal server.

#### Supported providers


| Provider | Description |
|---|---|
| AWS Lambda | Temporal assumes an IAM role in your AWS account to invoke a Lambda function. |
| GCP Cloud Run | Temporal impersonates an invoker service account in your GCP project to resize a Cloud Run Worker Pool. |

### Worker Versioning

Serverless Workers require Worker Versioning: each Worker Deployment Version must point its compute provider at a stable, immutable build. → `references/<provider>/versioning.md`.

### Worker Controller Instance (WCI)

Temporal coordinates serverless scaling through the WCI. See [Worker Controller Instance (WCI)](wci.md) for its lifecycle, Task Queue inputs, Workflow ID pattern, and inspection commands.
