resource "snowflake_grant_privileges_to_account_role" "database_usage" {
  privileges        = ["USAGE"]
  account_role_name = snowflake_account_role.reader.name
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.tf_demo_database.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "schema_usage" {
  privileges        = ["USAGE"]
  account_role_name = snowflake_account_role.reader.name
  on_schema {
    schema_name = snowflake_schema.tf_demo_schema.fully_qualified_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "future_tables_select" {
  privileges        = ["SELECT"]
  account_role_name = snowflake_account_role.reader.name
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = snowflake_schema.tf_demo_schema.fully_qualified_name
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "future_views_select" {
  privileges        = ["SELECT"]
  account_role_name = snowflake_account_role.reader.name
  on_schema_object {
    future {
      object_type_plural = "VIEWS"
      in_schema          = snowflake_schema.tf_demo_schema.fully_qualified_name
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "warehouse_usage" {
  privileges        = ["USAGE"]
  account_role_name = snowflake_account_role.reader.name
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.task_warehouse.name
  }
}
