variable "project" {
  description = "Project name, applied as a tag to every resource."
  type        = string
  default     = "PROJECT_NAME"
}

variable "owner" {
  description = "Owner tag applied to every resource."
  type        = string
}

variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "eu-west-2"
}

variable "ttl" {
  description = "Time-to-live tag driving auto-teardown, for example 8h."
  type        = string
  default     = "8h"
}
