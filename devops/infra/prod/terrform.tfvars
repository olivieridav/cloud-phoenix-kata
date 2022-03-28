aws_region = "eu-central-1"
ec2_public_key = 

branch = "master"
github_connection_arn = 
github_repo_name = "olivieridav/cloud-phoenix-kata"

envir = "prod"

vpc_cidr_block = "172.16.0.0/16"
subnet_cidr_priv_1a = "172.16.1.0/24"
subnet_cidr_priv_1b = "172.16.0.0/24"
subnet_cidr_pub_1a = "172.16.2.0/24"
subnet_cidr_pub_1b = "172.16.3.0/24"

db_instance_type = "t3.micro"
db_name = "phoenix"
db_user = "phoenixusr"
#db_password = 
db_backup_retention_days = 7
db_backup_schedule = "rate(12 hours)"

logs_retention_days = 7

alert_email_address = 
