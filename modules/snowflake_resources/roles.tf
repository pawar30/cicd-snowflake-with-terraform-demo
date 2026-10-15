# Read-only role for the demo objects, one per environment.
resource "snowflake_account_role" "reader" {
  name    = var.env_name == "PROD" ? "TF_DEMO_READER" : "TF_DEMO_READER_${var.env_name}"
  comment = "Read-only access to the Terraform demo objects (${var.env_name})"
}

# Best practice: custom roles roll up to SYSADMIN.
resource "snowflake_grant_account_role" "reader_to_sysadmin" {
  role_name        = snowflake_account_role.reader.name
  parent_role_name = "SYSADMIN"
}
