# Create a Flink compute pool to execute a Flink SQL statement.
resource "confluent_flink_compute_pool" "my_compute_pool" {
  display_name = "${var.prefix}-pool"
  cloud        = var.cloud
  region       = var.region
  max_cfu      = 10

  environment {
    id = confluent_environment.environment.id
  }

  depends_on = [
    confluent_environment.environment,
    confluent_role_binding.app-manager-kafka-cluster-admin
  ]
}

# Create a Flink-specific API key that will be used to submit statements.
data "confluent_flink_region" "my_flink_region" {
  cloud  = var.cloud
  region = var.region
}

// https://docs.confluent.io/cloud/current/access-management/access-control/rbac/predefined-rbac-roles.html#flinkadmin

resource "confluent_role_binding" "app-manager-flink-admin" {
  principal   = "User:${confluent_service_account.app-manager.id}"
  role_name   = "FlinkAdmin"
  crn_pattern = confluent_environment.environment.resource_name
}

resource "confluent_role_binding" "app-manager-flink-developer" {
  principal   = "User:${confluent_service_account.app-manager.id}"
  role_name   = "FlinkDeveloper"
  crn_pattern = confluent_environment.environment.resource_name
}

resource "confluent_role_binding" "app-general-flink-admin" {
  principal   = "User:${confluent_service_account.app-general.id}"
  role_name   = "FlinkAdmin"
  crn_pattern = confluent_environment.environment.resource_name
}

resource "confluent_role_binding" "app-general-flink-developer" {
  principal   = "User:${confluent_service_account.app-general.id}"
  role_name   = "FlinkDeveloper"
  crn_pattern = confluent_environment.environment.resource_name
}

resource "confluent_role_binding" "app-general-environment-admin" {
  principal   = "User:${confluent_service_account.app-general.id}"
  role_name   = "EnvironmentAdmin"
  crn_pattern = confluent_environment.environment.resource_name
}


resource "confluent_role_binding" "app-manager-assigner" {
  principal   = "User:${confluent_service_account.app-manager.id}"
  role_name   = "Assigner"
  crn_pattern = "${data.confluent_organization.main.resource_name}/service-account=${confluent_service_account.app-general.id}"
}


resource "confluent_api_key" "my_flink_api_key" {
  display_name = "my_flink_api_key"

  owner {
    id          = confluent_service_account.app-manager.id
    api_version = confluent_service_account.app-manager.api_version
    kind        = confluent_service_account.app-manager.kind
  }

  managed_resource {
    id          = data.confluent_flink_region.my_flink_region.id
    api_version = data.confluent_flink_region.my_flink_region.api_version
    kind        = data.confluent_flink_region.my_flink_region.kind

    environment {
      id = confluent_environment.environment.id
    }
  }

  depends_on = [
    confluent_environment.environment,
    confluent_role_binding.app-manager-kafka-cluster-admin
  ]
}