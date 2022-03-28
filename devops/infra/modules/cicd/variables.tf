variable "tags" { type = map(string) }

variable "envir" {
  type = string
}

variable "github_repo_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "codebuild_subnet_id" {
  type = string
}

variable "github_connection_arn" {
  type = string
}

variable "branch" {
  type = string
}

variable "ecs_service_name" { type = string }

variable "ecs_cluster_name" { type = string }

variable "registry" { type = string }

variable "ssm_parameter_tag_name" {
  type = string
}
