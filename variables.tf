# variables.tf

variable "vpcCIDRblock" {
   default = "10.0.0.0/16"
}

variable "subnetCIDRblock" {
   default = "10.0.0.0/24"
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

variable "destinationCIDRblock" {
   default = "0.0.0.0/0"
}
