terraform {
  required_providers {

     mongodbatlas = {
      source = "mongodb/mongodbatlas"
      version = "1.15.3"
     }
    confluent = {
      source  = "confluentinc/confluent"
      version = "1.65.0"
    }

  }
}
provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

provider "mongodbatlas" {
  public_key = var.mongodbatlas_public_key
  private_key  = var.mongodbatlas_private_key
}

data "confluent_organization" "main" {}

resource "confluent_environment" "environment" {
  display_name = "${var.prefix}-environment"
}

# Stream Governance and Kafka clusters can be in different regions as well as different cloud providers,
# but you should to place both in the same cloud and region to restrict the fault isolation boundary.
data "confluent_schema_registry_region" "essentials" {
  cloud   = "AWS"
  region  = "${var.sr_region}"
  package = "ESSENTIALS"
}

resource "confluent_schema_registry_cluster" "essentials" {
  package = data.confluent_schema_registry_region.essentials.package
  environment {
    id = confluent_environment.environment.id
  }

  region {
    # See https://docs.confluent.io/cloud/current/stream-governance/packages.html#stream-governance-regions
    id = data.confluent_schema_registry_region.essentials.id
  }
}


resource "confluent_kafka_cluster" "cluster" {
 environment {
    id = confluent_environment.environment.id
  }
  display_name = "${var.prefix}-cluster"
  cloud        = "GCPs"
  region       = "${var.region}"
  availability = "SINGLE_ZONE"
  basic {
  }

}

// 'app-manager' service account is required in this configuration to create 'orders' topic and grant ACLs
// to 'app-producer' and 'app-consumer' service accounts.
resource "confluent_service_account" "app-manager" {
  display_name = "${var.prefix}-sduran-app-manager"
  description  = "Service account to manage 'inventory' Kafka cluster"
}

resource "confluent_role_binding" "app-manager-kafka-cluster-admin" {
  principal   = "User:${confluent_service_account.app-manager.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.cluster.rbac_crn
}

resource "confluent_api_key" "app-manager-kafka-api-key" {
  display_name = "${var.prefix}-app-manager-kafka-api-key"
  description  = "Kafka API Key that is owned by 'app-manager' service account"
  owner {
    id          = confluent_service_account.app-manager.id
    api_version = confluent_service_account.app-manager.api_version
    kind        = confluent_service_account.app-manager.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.cluster.id
    api_version = confluent_kafka_cluster.cluster.api_version
    kind        = confluent_kafka_cluster.cluster.kind

    environment {
      id = confluent_environment.environment.id
    }
  }
}



resource "confluent_service_account" "app-general" {
  display_name = "${var.prefix}-sduran-app-general"
  description  = "Service account to produce/consume topics'in Kafka cluster"
}

resource "confluent_api_key" "app-general-kafka-api-key" {
  display_name = "${var.prefix}-app-general-kafka-api-key"
  description  = "Kafka API Key that is owned by 'app-general' service account"
  owner {
    id          = confluent_service_account.app-general.id
    api_version = confluent_service_account.app-general.api_version
    kind        = confluent_service_account.app-general.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.cluster.id
    api_version = confluent_kafka_cluster.cluster.api_version
    kind        = confluent_kafka_cluster.cluster.kind

    environment {
      id = confluent_environment.environment.id
    }
  }
}


resource "confluent_kafka_acl" "app-general-write-on-topic" {
  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }
  resource_type = "TOPIC"
  resource_name = "*"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app-general.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }

   depends_on = [
    confluent_role_binding.app-manager-kafka-cluster-admin,
    confluent_api_key.app-general-kafka-api-key
  ]
}

// Note that in order to consume from a topic, the principal of the consumer ('app-general' service account)
// needs to be authorized to perform 'READ' operation on both Topic and Group resources:
// confluent_kafka_acl.app-general-read-on-topic, confluent_kafka_acl.app-general-read-on-group.
// https://docs.confluent.io/platform/current/kafka/authorization.html#using-acls
resource "confluent_kafka_acl" "app-general-read-on-topic" {
  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }
  resource_type = "TOPIC"
  resource_name = "*"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app-general.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
   depends_on = [
    confluent_role_binding.app-manager-kafka-cluster-admin,
    confluent_api_key.app-general-kafka-api-key
  ]
}

// Note that in order to consume from a topic, the principal of the consumer ('app-general' service account)
// needs to be authorized to perform 'READ' operation on both Topic and Group resources:
// confluent_kafka_acl.app-general-read-on-topic, confluent_kafka_acl.app-general-read-on-group.
// https://docs.confluent.io/platform/current/kafka/authorization.html#using-acls
resource "confluent_kafka_acl" "app-general-create-on-topic" {
  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }
  resource_type = "TOPIC"
  resource_name = "*"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app-general.id}"
  host          = "*"
  operation     = "CREATE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
   depends_on = [
    confluent_role_binding.app-manager-kafka-cluster-admin,
    confluent_api_key.app-general-kafka-api-key
  ]
}

resource "confluent_kafka_acl" "app-general-read-on-group" {
  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }
  resource_type = "GROUP"
  // The existing values of resource_name, pattern_type attributes are set up to match Confluent CLI's default consumer group ID ("confluent_cli_consumer_<uuid>").
  // https://docs.confluent.io/confluent-cli/current/command-reference/kafka/topic/confluent_kafka_topic_consume.html
  // Update the values of resource_name, pattern_type attributes to match your target consumer group ID.
  // https://docs.confluent.io/platform/current/kafka/authorization.html#prefixed-acls
  resource_name = "confluent_cli_consumer_"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.app-general.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
   depends_on = [
    confluent_role_binding.app-manager-kafka-cluster-admin,
    confluent_api_key.app-general-kafka-api-key
  ]
}

resource "confluent_kafka_acl" "app-general-describe-on-cluster" {
  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }
  resource_type = "CLUSTER"
  resource_name = "kafka-cluster"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app-general.id}"
  host          = "*"
  operation     = "DESCRIBE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
   depends_on = [
    confluent_role_binding.app-manager-kafka-cluster-admin,
    confluent_api_key.app-general-kafka-api-key
  ]
}
resource "confluent_kafka_acl" "app-general-read-on-connect-lcc-group" {
  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }
  resource_type = "GROUP"
  resource_name = "connect-lcc"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.app-general.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
   depends_on = [
    confluent_role_binding.app-manager-kafka-cluster-admin,
    confluent_api_key.app-general-kafka-api-key
  ]
}

# Create a Project
resource "mongodbatlas_project" "atlas-project" {
  org_id = var.mongodbatlas_org_id
  name = var.mongodbatlas_project_name
  
}

resource "mongodbatlas_project_ip_access_list" "ip" {
  project_id = mongodbatlas_project.atlas-project.id
  cidr_block = "0.0.0.0/0"
}


# Create a Database User
resource "mongodbatlas_database_user" "db-user" {
  username = "user-1"
  password = random_password.db-user-password.result
  project_id = mongodbatlas_project.atlas-project.id
  auth_database_name = "admin"
  roles {
    role_name     = "readWriteAnyDatabase"
    database_name = "admin"
  }
}

# Create a Database Password
resource "random_password" "db-user-password" {
  length = 16
  special = false
}


# Create an Atlas Advanced Cluster 
resource "mongodbatlas_cluster" "atlas-cluster" {
  project_id = mongodbatlas_project.atlas-project.id
  name = "${var.mongodbatlas_project_name}-${var.mongodbatlas_environment}-cluster"
  provider_name = "TENANT"
  backing_provider_name = var.mongodbatlas_cloud_provider
  provider_region_name =  var.mongodbatlas_region
  provider_instance_size_name = var.mongodbatlas_cluster_instance_size_name
  
 
}

# Outputs to Display
output "atlas_cluster_connection_string" { value = replace(mongodbatlas_cluster.atlas-cluster.connection_strings.0.standard_srv, "mongodb+srv://", "")  }
output "project_name"      { value = mongodbatlas_project.atlas-project.name }
output "username"          { value = mongodbatlas_database_user.db-user.username } 
output "user_password"     { 
  sensitive = true
  value = mongodbatlas_database_user.db-user.password 
  }
