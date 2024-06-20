# --------------------------------------------------------
# Flink SQL: CREATE Model vector_encoding
# --------------------------------------------------------
resource "confluent_flink_statement" "create_model" {
  depends_on = [
        resource.confluent_environment.environment,
        resource.confluent_schema_registry_cluster.essentials,
        resource.confluent_kafka_cluster.cluster,
        resource.confluent_connector.datagen_products,
        resource.confluent_flink_compute_pool.my_compute_pool,
        resource.confluent_role_binding.app-general-environment-admin
  ]   

  organization {
    id = data.confluent_organization.main.id
  }

   environment {
    id = confluent_environment.environment.id
  }

  compute_pool {
    id = confluent_flink_compute_pool.my_compute_pool.id
  }
  principal {
    id = confluent_service_account.app-general.id
  }
   properties = {
    "sql.current-catalog"  : confluent_environment.environment.display_name
    "sql.current-database" : confluent_kafka_cluster.cluster.display_name
  }
  statement  = "EXECUTE STATEMENT SET BEGIN \n set 'sql.secrets.openaikey' = '${var.openai_key}'; \n CREATE MODEL `vector_encoding` INPUT (input STRING) OUTPUT (vector ARRAY<FLOAT>) WITH( 'TASK' = 'classification','PROVIDER' = 'OPENAI','OPENAI.ENDPOINT' = 'https://api.openai.com/v1/embeddings','OPENAI.API_KEY' = '{{sessionconfig/sql.secrets.openaikey}}');; END;"
 
  rest_endpoint   =  data.confluent_flink_region.my_flink_region.rest_endpoint
  credentials {
    key    = confluent_api_key.my_flink_api_key.id
    secret = confluent_api_key.my_flink_api_key.secret
  }

  lifecycle {
    prevent_destroy = false
  }
}


# --------------------------------------------------------
# Flink SQL: CREATE TABLE product-content
# --------------------------------------------------------
resource "confluent_flink_statement" "product-content" {
  depends_on = [
    resource.confluent_environment.environment,
    resource.confluent_schema_registry_cluster.essentials,
    resource.confluent_kafka_cluster.cluster,
    resource.confluent_connector.datagen_products,
    resource.confluent_flink_compute_pool.my_compute_pool,
    resource.confluent_role_binding.app-general-environment-admin
  ]   

  organization {
    id = data.confluent_organization.main.id
  }

   environment {
    id = confluent_environment.environment.id
  }

  compute_pool {
    id = confluent_flink_compute_pool.my_compute_pool.id
  }
  principal {
    id = confluent_service_account.app-general.id
  }
  statement  = "CREATE TABLE `product-content` ( `store_id` INT, `product_id`   INT, `count`        INT, `articleType`  STRING, `size`         STRING, `fashionType`  STRING, `brandName`    STRING, `baseColor`    STRING, `gender`       STRING, `ageGroup`     STRING, `price`        DOUBLE, `season`       STRING, `content`      STRING );"
  properties = {
    "sql.current-catalog"  : confluent_environment.environment.display_name
    "sql.current-database" : confluent_kafka_cluster.cluster.display_name
  }
  rest_endpoint   =  data.confluent_flink_region.my_flink_region.rest_endpoint
  credentials {
    key    = confluent_api_key.my_flink_api_key.id
    secret = confluent_api_key.my_flink_api_key.secret
  }

  lifecycle {
    prevent_destroy = false
  }
}

# --------------------------------------------------------
# Flink SQL: INSERT INTO product-content
# --------------------------------------------------------
resource "confluent_flink_statement" "insert-product-content" {
  depends_on = [
    resource.confluent_flink_statement.product-content
  ]  

  organization {
    id = data.confluent_organization.main.id
  }

   environment {
    id = confluent_environment.environment.id
  }

  compute_pool {
    id = confluent_flink_compute_pool.my_compute_pool.id
  }
  principal {
    id = confluent_service_account.app-general.id
  }
  statement  = "insert into `product-content` ( `store_id`, `product_id`, `count`, `price`, `size`, `ageGroup`, `gender`, `season`, `fashionType`, `brandName`, `baseColor`, `articleType`, `content` ) select  `store_id`, `product_id`, `count`, `price`, `size`, `ageGroup`, `gender`, `season`, `fashionType`, `brandName`, `baseColor`, `articleType`, INITCAP( concat_ws(' ', size, ageGroup, gender, season, fashionType, brandName, baseColor, articleType, ', price: '||cast(price as string), ', store number: '||cast(store_id as string), ', product id: '||cast(product_id as string)) ) from `product-updates`;"
  properties = {
    "sql.current-catalog"  : confluent_environment.environment.display_name
    "sql.current-database" : confluent_kafka_cluster.cluster.display_name
  }
  rest_endpoint   =  data.confluent_flink_region.my_flink_region.rest_endpoint
  credentials {
    key    = confluent_api_key.my_flink_api_key.id
    secret = confluent_api_key.my_flink_api_key.secret
  }

  lifecycle {
    prevent_destroy = false
  }
}

# --------------------------------------------------------
# Flink SQL: CREATE TABLE product-vector
# --------------------------------------------------------
resource "confluent_flink_statement" "product-vector" {
  depends_on = [
    resource.confluent_flink_statement.create_model
  ]    

  organization {
    id = data.confluent_organization.main.id
  }

   environment {
    id = confluent_environment.environment.id
  }
  compute_pool {
    id = confluent_flink_compute_pool.my_compute_pool.id
  }
  principal {
    id = confluent_service_account.app-general.id
  }
  statement  = "CREATE TABLE `product-vector` ( `store_id` INT, `product_id`   INT, `count`        INT, `articleType`  STRING, `size`         STRING, `fashionType`  STRING, `brandName`    STRING, `baseColor`    STRING, `gender`       STRING, `ageGroup`     STRING, `price`        DOUBLE, `season`       STRING, `content`      STRING, `vector`      ARRAY<FLOAT> );"
  properties = {
    "sql.current-catalog"  : confluent_environment.environment.display_name
    "sql.current-database" : confluent_kafka_cluster.cluster.display_name
  }
  rest_endpoint   =  data.confluent_flink_region.my_flink_region.rest_endpoint
  credentials {
    key    = confluent_api_key.my_flink_api_key.id
    secret = confluent_api_key.my_flink_api_key.secret
  }

  lifecycle {
    prevent_destroy = false
  }
}

