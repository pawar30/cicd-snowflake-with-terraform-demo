terraform {
  required_version = ">= 1.5.0"

  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "~> 2.22"
    }
  }

  # State lives in Azure Blob Storage. The pipeline reaches it with its Entra
  # identity via GitHub OIDC, so no storage keys are needed. The storage
  # account name is passed in by the workflow (-backend-config).
  backend "azurerm" {
    container_name   = "tfstate"
    key              = "snowflake-demo-staging.tfstate"
    use_oidc         = true
    use_azuread_auth = true
  }
}

# Logs in to Snowflake with an Entra access token (External OAuth).
# The pipeline sets these environment variables before running Terraform:
#   SNOWFLAKE_TOKEN             - fresh token from Entra, valid ~1 hour
#   SNOWFLAKE_USER              - LOGIN_NAME of the deploy user (Entra object ID)
#   SNOWFLAKE_ORGANIZATION_NAME - Snowflake organization name
#   SNOWFLAKE_ACCOUNT_NAME      - Snowflake account name
provider "snowflake" {
  authenticator            = "OAUTH"
  role                     = "TF_DEPLOY_ROLE"
  preview_features_enabled = ["snowflake_table_resource"]
}

module "snowflake_resources" {
  source              = "../modules/snowflake_resources"
  time_travel_in_days = 1
  database            = var.database
  env_name            = var.env_name
}
