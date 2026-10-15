resource "snowflake_warehouse" "task_warehouse" {
  name                = var.env_name == "PROD" ? "TF_DEMO_WH" : "TF_DEMO_WH_${var.env_name}"
  warehouse_size      = "XSMALL" # kept small on purpose: this is a trial account
  auto_resume         = "true"
  auto_suspend        = 60
  initially_suspended = true
}
