# variables.tf

variable "vpcCIDRblock" {
  default = "10.0.0.0/16"
}

variable "instanceTenancy" {
  default = "default"
}

variable "dnsSupport" {
  default = true
}

variable "dnsHostNames" {
  default = true
}

variable "defaultCIDRblock" {
  default = "0.0.0.0/0"
}


variable "availabilityZoneA" {
  default = "us-east-1a" 
}

variable "availabilityZoneB" {
  default = "us-east-1b" 
}