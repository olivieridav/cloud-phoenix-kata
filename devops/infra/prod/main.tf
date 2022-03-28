module "network" {
  source = "../modules/network"
  envir = var.envir
  aws_region = var.aws_region
  vpc_cidr_block = var.vpc_cidr_block
  subnet_cidr_priv_1a = var.subnet_cidr_priv_1a
  subnet_cidr_priv_1b = var.subnet_cidr_priv_1b
  subnet_cidr_pub_1b = var.subnet_cidr_pub_1b
  subnet_cidr_pub_1a = var.subnet_cidr_pub_1a
}

module "infra_ec2" {
  source = "../modules/ec2"

  ec2_public_key = var.ec2_public_key
  vpc_id = module.network.vpc_id
  vpc_cidr = module.network.vpc_cidr
  db_subnet_id = module.network.private_subnet_1b
  alb_subnets = [module.network.public_subnet_1a, module.network.public_subnet_1b] 
  envir = var.envir
  db_instance_type = var.db_instance_type
  db_name = var.db_name
  db_password = var.db_password
  db_user = var.db_user
  listen_port = var.listen_port
  db_backup_retention_days = var.db_backup_retention_days
  db_backup_schedule = var.db_backup_schedule
  
  depends_on = [module.network]
}

module "ecs" {
  source = "../modules/ecs"
  
  aws_region = var.aws_region
  target_group_arn = module.infra_ec2.target_group_arn
  target_group_arn_suffix = module.infra_ec2.target_group_arn_suffix
  load_balancer_arn_suffix = module.infra_ec2.load_balancer_arn_suffix
  envir = var.envir
  tags = var.tags
  vpc_id = module.network.vpc_id
  lb_security_group = module.infra_ec2.load_balancer_sg
  ecs_subnets = [module.network.private_subnet_1a, module.network.private_subnet_1b]
  listen_port = var.listen_port
  desired_count = 1
  logs_retention = var.logs_retention_days
  db_name = var.db_name
  db_password = var.db_password
  db_user = var.db_user
  db_host = module.infra_ec2.db_private_ip
  cpu = 256
  memory = 512
  alert_email_address = var.alert_email_address

  depends_on = [module.infra_ec2]
}

module "ci_cd" {
  source = "../modules/cicd"

  branch = var.branch
  envir = var.envir
  tags = var.tags
  github_repo_name = var.github_repo_name
  codebuild_subnet_id = module.network.private_subnet_1b
  vpc_id = module.network.vpc_id
  github_connection_arn = var.github_connection_arn
  registry = module.ecs.ecr_url
  ecs_cluster_name = module.ecs.ecs_cluster_name
  ecs_service_name = module.ecs.ecs_service_name
  ssm_parameter_tag_name = module.ecs.ssm_parameter_tag_name

  depends_on = [module.ecs]
}
