resource "confluent_kafka_topic" "prueba1" {
  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }
  topic_name    = "prueba1"
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


resource "confluent_kafka_topic" "prueba2" {
  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }
  topic_name    = "prueba2"
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


# --------------------------------------------------------
# Create Kafka topics for the DataGen Connectors
# --------------------------------------------------------
resource "confluent_kafka_topic" "product-updates" {
  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }
  topic_name    = "product_updates"
  partitions_count   = 1
  rest_endpoint = confluent_kafka_cluster.cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
  lifecycle {
    prevent_destroy = false
  }
 depends_on = [
    confluent_environment.environment,
    confluent_role_binding.app-manager-kafka-cluster-admin
  ]

}
