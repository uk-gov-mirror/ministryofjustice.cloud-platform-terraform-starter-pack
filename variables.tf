variable "enable_starter_pack" {
  type        = bool
  default     = true
  description = "Enable/Disable the whole module - all resources"
}

variable "cluster_domain_name" {
  description = "The cluster domain used for externalDNS annotations and certmanager"
}

variable "enable_postgres_container" {
  default     = true
  description = "Enable postgres inside a container"
  type        = bool
}

variable "namespace" {
  type    = string
  default = "starter-pack"
}

variable "helloworld" {
  default = true
  type    = bool
}

variable "multi_container_app" {
  default = true
  type    = bool
}


variable "rds_secret" {
  default     = ""
  type        = string
  description = "kubernetes secret if using RDS for postgres"
}


variable "helloworld_version" {
  type    = string
  default = "0.2.4"
}

variable "multi_container_app_version" {
  type    = string
  default = "0.3.6"
}

variable "starter_pack_count" {
  type        = number
  default     = 1
  description = "The number of starter pack needs to be created"
}
