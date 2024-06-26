variable "prefix" {
 type        = string
 description = "prefix to apply to resources - optional, but keeps your stuff identify"
 default     = "tf"
}

variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API Key"
  type = string
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API Secret"
  type = string
}

variable "cloud" {
  description = "The Cloud provider to deploy the Cluster"
  type        = string
  default = "AWS"
  //Note : Schema registry essential package is not supported in all regions, so this variable is not used for it. See sr_region
}

variable "region" {
  description = "The AWS Region to deploy the Cluster"
  type        = string
  default = "eu-central-1"
  //Note : Schema registry essential package is not supported in all regions, so this variable is not used for it. See sr_region
}

variable "sr_region" {
  description = "The Schema Registry AWS Region"
  type        = string
  default = "eu-central-1"
}

variable mongodbatlas_public_key {
  description = "MongoDB public key"
  type        = string
}

variable mongodbatlas_private_key {
  description = "MongoDB private key"
   type        = string
}

# Atlas Organization ID 
variable "mongodbatlas_org_id" {
  type        = string
  description = "Atlas Organization ID"
}
# Atlas Project Name
variable "mongodbatlas_project_name" {
  type        = string
  description = "Atlas Project Name"
}

# Atlas Project Environment
variable "mongodbatlas_environment" {
  type        = string
  description = "The environment to be built"
}

# Cluster Instance Size Name 
variable "mongodbatlas_cluster_instance_size_name" {
  type        = string
  description = "Cluster instance size name"
}

# Cloud Provider to Host Atlas Cluster
variable "mongodbatlas_cloud_provider" {
  type        = string
  description = "AWS or GCP or Azure"
}

# Atlas Region
variable "mongodbatlas_region" {
  type        = string
  description = "Atlas region where resources will be created"
}

# MongoDB Version 
variable "mongodbatlas_version" {
  type        = string
  description = "MongoDB Version"
}

# OpenAi Key
variable "openai_key" {
  type        = string
  description = "MongoDB Version"
}

# limits insert Flink statement
variable "embedding_calls_limit" {
  type        = string
  description = "MongoDB Version"
}

# mongodb_db_user

variable "mongodbatlas_user" {
  type        = string
  description = "MongoDB Version"
}

# mongodb_db_password

variable "mongodbatlas_password" {
  type        = string
  description = "MongoDB Version"
}

variable "mongodbatlas_collection" {
  type        = string
  description = "product-vector"
}









/*
variable "sfdc_password" {
  description = "SFDC Password"
  type = string
}

variable "sfdc_consumer_key" {
  description = "SFDC consumer key"
  type = string
}

variable "sfdc_consumer_secret" {
  description = "SFDC consumer secret"
  type = string
}

variable "sfdc_consumer_token" {
  description = "SFDC consumer token"
  type = string
}
*/