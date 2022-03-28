variable "aws_region" {
    type = string
}

variable "ecs_subnets" {
    type = list(string)
}

variable "vpc_id" {
    type = string
}

variable "lb_security_group" {
    type = string
}

variable "target_group_arn" {
    type = string
}

variable "target_group_arn_suffix" {
    type = string
}

variable "load_balancer_arn_suffix" {
    type = string
}

variable "tags" {
    type = map(string)
}

variable "envir" {
    type = string
}

variable "listen_port" {
    type = number
}

variable "cpu" {
    type = number
}

variable "memory" {
    type = number
}

variable "desired_count" {
    type = number
}

variable "logs_retention" {
    type = number
}

variable "db_host" {
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

variable "alert_email_address" {
    type = string
}
