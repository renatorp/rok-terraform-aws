# vars.tf

variable "instance_type" {
  default = "t2.micro"
}

variable "ubuntuAmiNamePatten" {
  default = "ami-ubuntu-18.04*"
}

variable "vpc_security_group_id" {
}

variable "instances" {
  type = "list"
  description = "Required values: subnet_id, availability_zone, instance_name, policy"
}

variable "num_instances" {
  default = 1
}