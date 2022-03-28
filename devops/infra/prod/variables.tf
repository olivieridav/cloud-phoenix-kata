variable "aws_region" {
  type = string
}

variable "ec2_public_key" {
  type = string
}

variable "tags" {
  type = map(string)
  default = {}
}

variable "envir" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}
variable "github_repo_name" {
  type = string
}

variable "subnet_cidr_priv_1a" {
  type = string
}

variable "subnet_cidr_priv_1b" {
  type = string
}

variable "subnet_cidr_pub_1b" {
  type = string
}
variable "subnet_cidr_pub_1a" {
  type = string
}

variable "github_connection_arn" {
  type = string
}

variable "db_instance_type" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_password" {
  type = string
}

variable "branch" {
  type = string
}

variable "listen_port" {
  type = number
  default = 8000
}

variable "db_backup_retention_days" {
  type = number
}

variable "logs_retention_days" {
  type = number
}

variable "db_backup_schedule" {
  type = string
}

variable "alert_email_address" {
  type = string
}

