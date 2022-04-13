variable "bank" {
  type    = string
  default = "pol"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "location" {
  type    = string
  default = "northeurope"
}

variable "parent_domain" {
  type = object({
    domain              = string
    resource_group_name = string
  })
  default = {
    domain              = "pollinate.dev"
    resource_group_name = "pol-nnprod-dns-rg"
  }
}

variable "app_time_zone" {
  type    = string
  default = "UTC"
}

variable "subnets" {
  type = object({
    subnet = object({
      aks              = list(string)
      hdinsights_kafka = list(string)
      piper_aks        = list(string)
      apim             = list(string)
    })
  })
  default = {
    subnet = {
      aks              = ["10.241.0.0/20"]
      hdinsights_kafka = ["10.241.24.0/23"]
      piper_aks        = ["10.241.16.0/21"]
      apim             = ["10.241.28.0/22"]
    }
  }
}

variable "terraform_timeouts" {
  type = object({
    create = string
    delete = string
    update = string
    read   = string
  })
  default = {
    create = "60m"
    delete = "60m"
    update = "60m"
    read   = "15m"
  }
}

variable "tags" {
  type = map(string)
  default = {
    layer = "app"
  }
}

variable "dmz_prefix" {
  type    = string
  default = "pol-nnprod"
}

variable "dmz_subscription_id" {
  type    = string
  default = "ce38cf7c-3580-4375-b891-13a38abb98be"
}

variable "terratest" {
  type    = bool
  default = false
}

# -- should match foundation variable
variable "network" {
  type = object({
    vnet = list(string)
  })
  default = {
    vnet = ["10.241.0.0/18"] # -- 183861242 addresses (minus 5 for Azure accounted for)
  }
}

variable "kubernetes_version" {
  type    = string
  default = "1.21.7"
}