output "LOAD_BALANCER_FQDN" { 
  value = module.infra_ec2.load_balancer_fqdn
}

output "MONGO_DB_IP" { 
  value = module.infra_ec2.db_private_ip
}

output "PIPELINE_NAME" { 
  value = module.ci_cd.pipeline_name
}

output "BACKUP_DUMPS_BUCKET" {
  value = module.infra_ec2.backup_dumps_bucket
}

output "APPLICATION_LOG_CWGROUP" {
  value = module.ecs.application_log_group
}

output "GIT_BRANCH_RELEASED" {
  value = var.branch
}

output "ENVIRONMENT" { 
  value = var.envir
}

output "BACKUP_SSM_COMMAND" {
  value = module.infra_ec2.backup_ssm_command
}

