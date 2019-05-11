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

variable "instanceType" {
  default = "t2.micro"
}

variable "availabilityZoneA" {
  default = "us-east-1a" 
}

variable "ubuntuAmiNamePatten" {
  default = "ami-ubuntu-18.04*"
}

variable "availabilityZoneB" {
  default = "us-east-1b" 
}