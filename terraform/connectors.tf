# --------------------------------------------------------
# Connectors
# --------------------------------------------------------

# datagen_products
resource "confluent_connector" "datagen_products" {
  environment {
    id = confluent_environment.environment.id
  }
  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }
  config_sensitive = {}
  config_nonsensitive = {
    "connector.class"          = "DatagenSource"
    "name"                     = "${var.prefix}-datagen_products"
    "kafka.auth.mode"          = "SERVICE_ACCOUNT"
    "kafka.service.account.id" = confluent_service_account.app-general.id
    "kafka.topic"              = "product-updates"
    "output.data.format"       = "JSON_SR"
    "schema.string"            = file("${path.module}/productSchema.json")
    "tasks.max"                = "1"
    "max.interval"             = "10000"
  }
  depends_on = [
 confluent_kafka_acl.app-general-create-on-topic,
    confluent_kafka_acl.app-general-write-on-topic,
    confluent_kafka_acl.app-general-read-on-topic,
    confluent_kafka_acl.app-general-read-on-group,
    confluent_kafka_acl.app-general-read-on-connect-lcc-group
  ]
  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_connector" "mongo-db-sink" {
  environment {
    id = confluent_environment.environment.id
  }
  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }

  // Block for custom *sensitive* configuration properties that are labelled with "Type: password" under "Configuration Properties" section in the docs:
  // https://docs.confluent.io/cloud/current/connectors/cc-mongo-db-sink.html#configuration-properties
  config_sensitive = {
    "connection.password" = mongodbatlas_database_user.db-user.password ,
  }

  // Block for custom *nonsensitive* configuration properties that are *not* labelled with "Type: password" under "Configuration Properties" section in the docs:
  // https://docs.confluent.io/cloud/current/connectors/cc-mongo-db-sink.html#configuration-properties
  config_nonsensitive = {
    "connector.class"          = "MongoDbAtlasSink"
    "name"                     = "confluent-mongodb-sink"
    "kafka.auth.mode"          = "SERVICE_ACCOUNT"
    "kafka.service.account.id" = confluent_service_account.app-general.id
    "connection.host"          = replace(mongodbatlas_cluster.atlas-cluster.connection_strings.0.standard_srv, "mongodb+srv://", "") 
    "connection.user"          = mongodbatlas_database_user.db-user.username 
    "input.data.format"        = "AVRO"
    "topics"                   = var.mongodbatlas_collection
    "max.num.retries"          = "3"
    "retries.defer.timeout"    = "5000"
    "max.batch.size"           = "0"
    "database"                 = "${var.mongodbatlas_project_name}-${var.mongodbatlas_environment}"
    "collection"               = var.mongodbatlas_collection
    "tasks.max"                = "1"
  }

  depends_on = [
    confluent_kafka_acl.app-general-create-on-topic,
    confluent_kafka_acl.app-general-write-on-topic,
    confluent_kafka_acl.app-general-read-on-topic,
    confluent_kafka_acl.app-general-read-on-group,
    confluent_kafka_acl.app-general-read-on-connect-lcc-group,
    confluent_flink_statement.product-vector
  ]
}