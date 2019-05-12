#vars.tf

variable "name" {
  type = "string"
  description = "queue name"
}

variable "delay_seconds" {
  default = 90
}

variable "max_message_size" {
  default = 2048
}

variable "message_retention_seconds" {
  default = 86400
}

variable "receive_wait_time_seconds" {
  default = 10
}