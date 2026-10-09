# GCP Cloud Run — IAM & permissions

Cloud Run uses three identities:

| Identity | Purpose |
|---|---|
| **Operator** | The credentials that run `gcloud` and Terraform commands. |
| **Runner service account** | The identity attached to pool instances with `--service-account`. |
| **Invoker service account** | The identity Temporal impersonates to read and update the pool's instance count. |

Temporal reaches the invoker through `roles/iam.serviceAccountTokenCreator`. The Terraform module described below creates the invoker and applies its grants.

**The two service accounts are not interchangeable.** The runner runs the pool and never scales it; the invoker scales the pool and never runs it.

## Runner service account

The runtime identity the pool's instances use to reach other Google Cloud services. Set in `setup.md` Step 4 with `gcloud run worker-pools deploy --service-account`. It may be an account that already exists; a dedicated one is preferred.

**It needs no baseline role to run the Worker.** Cloud Run collects `stdout` and `stderr` into Cloud Logging through its own infrastructure, and the Cloud Run *service agent* — not the runner — pulls the container image. Grant only what your code actually reaches:

- `roles/secretmanager.secretAccessor` on each secret you mount, including the Temporal API key.
- `roles/logging.logWriter` **only if** the Worker writes through the Cloud Logging API rather than stdout/stderr.
- `roles/monitoring.metricWriter` and `roles/telemetry.tracesWriter` **only if** the optional OpenTelemetry Collector in `observability.md` exports metrics and traces to Google Cloud.
- Whatever else your Workflows and Activities call.

The Collector uses the runner's Application Default Credentials. If its configuration is mounted from Secret Manager, the runner also needs `roles/secretmanager.secretAccessor` on that configuration secret. These observability grants belong to the runner, not the invoker.

## Invoker service account

The identity Temporal Cloud impersonates to read and scale the pool. Two grants make it work:

- Temporal's identity receives **`roles/iam.serviceAccountTokenCreator`** on the invoker, so it can impersonate it.
- The invoker receives a project-level Cloud Run role with at least **`run.workerPools.get`** (read) and **`run.workerPools.update`** (scale). `roles/run.developer` includes both.

The invoker also needs **`roles/iam.serviceAccountUser` on the runner service account**, which Cloud Run requires in order to attach that identity when it scales the pool. The Terraform module applies this.

### Validate Connection checks read access only

`run.workerPools.get` alone is enough for the UI's **Validate Connection** action to pass, but version registration and scaling also require `run.workerPools.update`. Passing Validate Connection therefore does not prove that the invoker can scale the pool. See `diagnostics.md` for registration and scaling checks.

## The Terraform module

Temporal publishes [`serverless-workers/gcp/cloud-run`](https://github.com/temporalio/terraform-modules/tree/main/modules/serverless-workers/gcp/cloud-run), which creates the invoker service account and applies the grants.

Apply the module block below. Temporal Cloud's UI template is the source of the account-specific `impersonator_service_account_emails` only; see [Where `impersonator_service_account_emails` comes from](#where-impersonator_service_account_emails-comes-from). For a standalone root module, declare the Google provider constraint expected by the module and configure the project explicitly; reconcile any existing root constraint before running `terraform init`:

```hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = "<YOUR_GCP_PROJECT>"
}

module "serverless-worker-cloud-run" {
  source = "github.com/temporalio/terraform-modules//modules/serverless-workers/gcp/cloud-run"

  project_id         = "<YOUR_GCP_PROJECT>"
  invoker_account_id = "<PREFIX>-invoker"

  impersonator_service_account_emails = [
    "<every email from the Temporal Cloud Access template>",
  ]

  runner_service_account_email = "<RUNNER_SERVICE_ACCOUNT_ID>@<YOUR_GCP_PROJECT>.iam.gserviceaccount.com"
}

output "invoker_email" {
  value = module.serverless-worker-cloud-run.invoker_email
}
```

The `output` block is required: a module's outputs are not visible from the root module unless it re-exports them, and Step 6 needs `invoker_email`.

| Variable | Required | Description |
|---|---|---|
| `project_id` | Yes | Project hosting the pool and the invoker. |
| `invoker_account_id` | Yes | Name for the invoker the module creates; email becomes `<invoker_account_id>@<project_id>.iam.gserviceaccount.com`. The template supplies one. |
| `impersonator_service_account_emails` | Yes | Temporal Cloud's service accounts, granted `serviceAccountTokenCreator` on the invoker. **From the UI template.** For self-hosted, the GCP identity the server runs as. |
| `runner_service_account_email` | Yes | The runner from `setup.md` Step 4. The module grants the invoker `roles/iam.serviceAccountUser` on it. |
| `invoker_display_name` | No | Defaults to `Temporal Serverless Worker Pool Invoker`. |
| `deploy_roles` | No | Project-level Cloud Run roles for the invoker. Defaults to `roles/run.developer`. A substitute must include `run.workerPools.get` and `run.workerPools.update`. |

Keep the root module in its own directory, `<TF_DIR>`, **outside the app directory**, so `gcloud builds submit` does not upload its state and provider binaries to Cloud Build. Pass `-chdir` instead of changing directory. Plan first, check the plan against the approved resource list, then apply exactly that plan:

```bash
terraform -chdir=<TF_DIR> init
terraform -chdir=<TF_DIR> plan -out=tfplan
terraform -chdir=<TF_DIR> show tfplan
terraform -chdir=<TF_DIR> apply tfplan
terraform -chdir=<TF_DIR> output -raw invoker_email
```

Applying a saved plan cannot create anything the reviewed plan did not show. **If the apply fails partway with `Error 400: Service account <invoker> does not exist`** on the invoker's `actAs` binding to the runner, the new invoker had not propagated yet. Run `plan -out=tfplan` and `apply tfplan` again; do not destroy, because the resources already created are correct. If the agent's environment blocks the apply, have the user run `terraform -chdir=<TF_DIR> apply tfplan` in their own terminal; the plan file keeps it identical to what was reviewed.

Use the **`invoker_email`** output as `--gcp-cloud-run-service-account` when registering the version, after allowing for IAM propagation (below).

### Where `impersonator_service_account_emails` comes from

The values are Temporal Cloud's identities for **your Temporal Cloud account**, of the form `serverless-<account>@…`. The authoritative source is the UI template.

**From the UI:** ask the user to open **Workers → Create Worker Deployment**, select **GCP Cloud Run**, open **Access**, and paste the whole Terraform block shown there into the conversation. It holds identities, not credentials. From the pasted block, take only the `impersonator_service_account_emails = [ … ]` list and put it in place of the placeholder in the module above, check that each entry has the `serverless-<account>@…` form for this Temporal Cloud account, and show the list back to the user to confirm. Do not apply the template itself: its other values, such as the invoker name, are replaced by this file's module block, which uses the agreed prefix and the runner from `setup.md`.

When the agent cannot see the UI and an invoker created for the same Temporal Cloud account already exists in the project, read the identities from its policy:

```bash
gcloud iam service-accounts get-iam-policy <EXISTING_INVOKER_EMAIL> \
  --project <YOUR_GCP_PROJECT> \
  --flatten='bindings[].members' \
  --filter='bindings.role:roles/iam.serviceAccountTokenCreator' \
  --format='value(bindings.members)'
```

Strip the `serviceAccount:` prefix before using the values. Use only identities whose `serverless-<account>` part matches the Temporal Cloud account, which in practice is the suffix after the last `.` of its Namespace names; a project can also hold invokers for other accounts and for Temporal's test environment. Show the list to the user and get explicit confirmation that these are their account's identities. Never take them from an invoker that belongs to another Temporal Cloud account, and never hard-code them in reusable files.

### Check for an existing shared invoker

**Default to a dedicated invoker named with the run's prefix**, such as `<PREFIX>-invoker`; service-account IDs are 6–30 characters. Reuse an existing invoker only when the user names it and confirms they own its Terraform state, because an agent cannot establish that ownership itself. Before creating, check that the chosen name is free. **Do not `terraform destroy` state you did not create.** The module's default `invoker_account_id`, `temporal-worker-pool-invoker`, may already belong to an earlier deployment in the project.

```bash
gcloud iam service-accounts list \
  --project <YOUR_GCP_PROJECT> \
  --filter='email:<INVOKER_ACCOUNT_ID>@<YOUR_GCP_PROJECT>.iam.gserviceaccount.com' \
  --format='value(email)'

gcloud iam service-accounts get-iam-policy \
  <INVOKER_ACCOUNT_ID>@<YOUR_GCP_PROJECT>.iam.gserviceaccount.com \
  --project <YOUR_GCP_PROJECT>
```

Do not infer that an account is safe to reuse from its name alone. When the user does name one to reuse, confirm that its project-level Cloud Run role covers the new pool.

## Operator GCP permissions

The identity running the `gcloud`/Terraform commands needs, at minimum:

| Step | Operator needs |
|---|---|
| Submit the image build (`setup.md` Step 3) | `cloudbuild.builds.create`; permission to use the selected build service account when one is specified |
| Push the built image | The Cloud Build execution service account needs Artifact Registry Writer on the repository when it is user-specified, cross-project, or lacks the same-project default access |
| Create the Worker Pool (Step 4) | `run.workerPools.create`/`update`, and `iam.serviceAccounts.actAs` on the **runner** to attach it |
| Create secrets | Secret Manager admin on the secrets used |
| Apply the Terraform module (Step 5) | Service-account creation plus IAM policy binding on the project and on the runner |
| Read pool state and logs (verify, diagnose) | `run.workerPools.get`, Cloud Logging read |

The operator needs `iam.serviceAccounts.actAs` on the runner to attach it to the pool. Without it, pool creation is denied even when the operator otherwise has Cloud Run permissions.

### Preflight

Run before anything that creates or modifies GCP resources. Confirm the required APIs appear in the enabled-service output, then inspect the names the deployment intends to use:

```bash
gcloud auth list                                   # which identity
gcloud config get-value project                    # which project
gcloud projects describe <YOUR_GCP_PROJECT> --format='value(projectId)'
gcloud auth application-default print-access-token >/dev/null && echo "terraform ADC: ok"
gcloud services list --enabled --project <YOUR_GCP_PROJECT> --format='value(config.name)'
gcloud run worker-pools list --region <REGION> >/dev/null && echo "cloud run: ok"
gcloud iam service-accounts list >/dev/null && echo "iam read: ok"
gcloud artifacts repositories describe <REPOSITORY> --location <REGION> --project <YOUR_GCP_PROJECT>
gcloud iam service-accounts describe <RUNNER_SERVICE_ACCOUNT_EMAIL> --project <YOUR_GCP_PROJECT>
gcloud secrets describe <SECRET_NAME> --project <YOUR_GCP_PROJECT>
terraform version
```

Required services: `run.googleapis.com`, `artifactregistry.googleapis.com`, `cloudbuild.googleapis.com`, `secretmanager.googleapis.com`, `iam.googleapis.com`, `iamcredentials.googleapis.com`, and `cloudresourcemanager.googleapis.com`. When the optional Collector path in `observability.md` is enabled, also enable `monitoring.googleapis.com` and `telemetry.googleapis.com`. A `describe` returning Not Found is acceptable for a clean project; record that the named resource will be created and include it in the approval list. A permission error is not the same as absence—stop and resolve access before creating anything. One exception: a recently deleted service account can return a permission error from `describe`; check service accounts with `gcloud iam service-accounts list --filter='email:<EMAIL>'` instead.

For a same-project build using Cloud Build's default service account, Artifact Registry access is normally provided automatically. If the build uses a user-specified service account, the repository is in another project, or an organization policy removed the default grant, inspect that account and grant `roles/artifactregistry.writer` on this repository before submitting the build.

**Classify an authentication failure before acting on it.** An absent or expired credential may require `gcloud auth login`, or `gcloud auth application-default login` for Terraform; an authenticated identity that is denied a specific action has an authorization problem. Never collect credentials in conversation and never ask the user to paste a service account key — Google recommends against long-lived keys outright.

**Confirm the project explicitly before creating anything.** `gcloud config get-value project` is ambient state that is easy to be wrong about. Name the project in the approval list and verify it rather than trusting the default.

**Allow for IAM propagation.** A newly created service account can return `404` on an immediate IAM-policy binding even though creation succeeded. Re-describe the exact account and retry the same binding after a short wait; do not create a replacement account or rewrite the policy in response to this transient state. The same applies to the grants the Terraform module applies: Temporal's impersonation of the invoker can fail with a 403 on `iam.serviceAccounts.getAccessToken` for a minute or more after `apply`, and `create-version` then reports the pool as not found. → `setup.md` Steps 5 and 6.
