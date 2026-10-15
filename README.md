# CI/CD pipeline with Snowflake (Entra ID auth, no key pair)
Demo of a CI/CD pipeline that deploys Snowflake objects with Terraform from GitHub Actions.

Adapted from the original key-pair/AWS demo so that **no secret is stored anywhere**:

| Concern | Original | This version |
| --- | --- | --- |
| Snowflake login | RSA key pair (`SNOWFLAKE_PRIVATE_KEY` secret) | Entra ID access token via Snowflake **External OAuth** |
| Terraform state | AWS S3 + AWS access keys | **Azure Blob Storage**, reached with the job's Entra identity (OIDC) |
| Provider | `Snowflake-Labs/snowflake` 0.63 | `snowflakedb/snowflake` ~> 2.22 |

## How a run logs in
1. GitHub gives the job a signed OIDC token ("this repo, this branch / PR").
2. `azure/login` exchanges it with Entra through a **federated credential** on the `gh-terraform-snowflake` app.
3. `az account get-access-token` gets a ~1-hour token for the `snowflake-oauth-resource` app, carrying `session:role:TF_DEPLOY_ROLE`.
4. Terraform passes the token to Snowflake (`authenticator = "OAUTH"`). Snowflake's External OAuth integration validates it and maps `sub` to user `TF_DEPLOY_SVC`.
5. The azurerm backend uses the same GitHub OIDC token to read and write state in Azure Storage.

## Pipelines
| Workflow | Trigger | Does |
| --- | --- | --- |
| `snowflake-terraform-demo-prod.yml` | PR into `main` | plan, posted as a PR comment |
| `snowflake-terraform-demo-prod.yml` | push / merge to `main` | apply to PROD |
| `snowflake-terraform-demo-staging.yml` | push to `staging` (or manual) | plan + apply to STAGING |

## What gets created (per environment)
- Database `TERRAFORM_DEMO_PROD` / `TERRAFORM_DEMO_STAGING`, schema `TF_DEMO`, table `DEMO_TABLE`
- Warehouse `TF_DEMO_WH` / `TF_DEMO_WH_STAGING` (XSMALL, auto-suspend 60 s)
- Role `TF_DEMO_READER` / `TF_DEMO_READER_STAGING` (granted to SYSADMIN) with USAGE on the database, schema and warehouse, and SELECT on future tables and views

## One-time setup

### 1. Entra ID (already done if you followed the Entra PoC)
- App `snowflake-oauth-resource`: Application ID URI `api://<id>`, app role `session:role:TF_DEPLOY_ROLE` (Applications)
- App `gh-terraform-snowflake`: Application permission to that role, admin consent granted
- **Federated credentials on `gh-terraform-snowflake` for THIS repo.** Each one matches exactly one entity:

| Name | Entity type | Value |
| --- | --- | --- |
| `demo-main` | Branch | `main` |
| `demo-pr` | Pull request | (none) |
| `demo-staging` | Branch | `staging` |

Fill in Organization ID and Repository ID in the form so Entra builds GitHub's ID-based subject.

### 2. Snowflake (already done if you followed the Entra PoC)
`TF_DEPLOY_ROLE` (with SYSADMIN + SECURITYADMIN), user `TF_DEPLOY_SVC` with `LOGIN_NAME = <service principal object id>`, and an `EXTERNAL_OAUTH` security integration of type AZURE.

### 3. Azure Storage for Terraform state
1. Create a resource group, e.g. `rg-tfstate-poc`.
2. Create a storage account (Standard, LRS), e.g. `sttfstate<unique>`.
3. Create a private container named `tfstate`.
4. On the storage account, open **Access control (IAM)** → add role **Storage Blob Data Contributor** → assign it to the `gh-terraform-snowflake` service principal.

### 4. GitHub repository variables
Settings → Secrets and variables → Actions → **Variables**. These are all identifiers, not secrets.

| Variable | Value |
| --- | --- |
| `AZURE_TENANT_ID` | Entra tenant ID |
| `AZURE_CLIENT_ID` | Application (client) ID of `gh-terraform-snowflake` |
| `AZURE_SUBSCRIPTION_ID` | Subscription that holds the storage account |
| `SF_RESOURCE_APP_ID` | Application (client) ID of `snowflake-oauth-resource` |
| `SNOWFLAKE_ORGANIZATION_NAME` | Snowflake organization name |
| `SNOWFLAKE_ACCOUNT_NAME` | Snowflake account name |
| `SNOWFLAKE_USER` | `LOGIN_NAME` of `TF_DEPLOY_SVC` (the Entra object ID, not the user name) |
| `TFSTATE_STORAGE_ACCOUNT` | Storage account name from step 3 |

No repository **secrets** are needed. Delete `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` and `SNOWFLAKE_PRIVATE_KEY` if they exist.

## Local development
Install Terraform, then run `terraform fmt -recursive` and `terraform -chdir=staging init -backend=false && terraform -chdir=staging validate` before pushing.
