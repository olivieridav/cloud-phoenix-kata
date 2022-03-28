variable "ec2_public_key" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "db_subnet_id" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "alb_subnets" {
  type = list(string)
}

variable "envir" {
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

variable "listen_port" {
  type = number
}

variable "db_backup_retention_days" {
  type = number
}

variable "db_backup_schedule" {
  type = string
}