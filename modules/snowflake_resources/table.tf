resource "snowflake_table" "demo_table" {
  database = snowflake_schema.tf_demo_schema.database
  schema   = snowflake_schema.tf_demo_schema.name
  name     = "DEMO_TABLE"
  comment  = "An empty table for the Terraform demo"

  # Created after the future grant, so the reader role can SELECT it at once.
  depends_on = [snowflake_grant_privileges_to_account_role.future_tables_select]

  column {
    name     = "ID"
    type     = "NUMBER(38,0)"
    nullable = true
  }

  column {
    name     = "DATA"
    type     = "VARCHAR(16777216)"
    nullable = false
  }

  column {
    name = "CREATED_AT"
    type = "TIMESTAMP_NTZ(9)"
  }
}
