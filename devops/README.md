# Phoenix application deploy runbook 

This Readme describes how to deploy the Phoenix application on the AWS cloud using Terraform on Linux or MacOS.

The following infrastructure components will be created:

- Network setup
- Mongodb EC2 instance with an empty database
- Application load balancer with a public DNS
- ECS cluster with a Fargate service 
- CI/CD pipeline
- Basic backup and monitoring

## Requirements

- Terraform cli 1.0 or above (check [this page](https://learn.hashicorp.com/tutorials/terraform/install-cli) for installation instructions)
- AWS credentials with administrator permissions in the target account
- A GitHub account with permissions to clone the repository
- Familiarity with AWS
- This solution uses "ECS Container Insights", which is not available in all AWS regions. Kindly refer to [this](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContainerInsights.html) documentation article for a list of enabled regions.

## Usage

1. Create an S3 bucket using the AWS [console or CLI](https://docs.aws.amazon.com/AmazonS3/latest/userguide/create-bucket-overview.html). Terraform will save the state of the infrastructure in this bucket which must exist beforehand. Note down the bucket name and the region where it was created.

2. Create a connection to GitHub following this AWS tutorial: https://docs.aws.amazon.com/dtconsole/latest/userguide/connections-create-github.html . A GitHub connection is required by Codepipeline in order to download the source code. Note down the ARN of the newly created connection, you will need it at step 5.

3. Clone the phoenix repository.

4. Open the `devops/infra/prod/configuration.tf` file and set the `bucket` and `region` properties in the backend configuration block to match the name and region of the bucket created at step 1.
   

        backend "s3" {
            bucket         = "my-tf-state-bucket"
            key            = "prod/terraform.tfstate"
            region         = "eu-central-1"
        }


5. Edit the `devops/infra/prod/terraform.tfvars` file. This file contains parameters that will be used to configure the environment (such as AWS region, branch released, etc). Set `ec2_public_key`, `github_connection_arn` and `alert_email_address` and change any default value if required. Kindly refer to the "Inputs" table below for a description of each parameter.

        ec2_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDWcYfcmyKkwLm9EbHJHHP74KGRxT2T8xXbGOtuWAaiH6y80KILQERO/ygAGKXA0V3YjJbpIRMVsF6iZ+PWWKnInCX/8DiJhku99G8Nx3nQ5grKoFAMyKkqucICQGZU057NAjctODM7KJW9/yE/bO8Ph/dtzd7ZJ4GbP2grtYm5CsoALOAl+cjfbLZg5yiSiDrH4HaDKPRds2wqXUNtlxatBf9+aEATegv5/oc11JhJqMH9MsvnKE+ski71rZBF/2DcBMccn8vogtugIJPUDZXkYys321ka1Yh84CUy56k/dCddWqtDv4qiBHV9KKAR1Rv7zRjkBYOWdv9FnsSC2ABx"
        github_connection_arn = "arn:aws:codestar-connections:eu-central-1:743030344285:connection/d3c3b232-a9eb-4576-a7e4-4be37a2f6b93"
        alert_email_address = "phoenixalerts@mydomain.net"

6. Set the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environmental variables to match your IAM user access key:

        export AWS_ACCESS_KEY_ID="AKIA22AAPJJR3SFWKFNB"
        export AWS_SECRET_ACCESS_KEY="aOpV3BmAv9kIVypaevyIGNOQVn+/2poc3dT+bEkN"

    If you have the AWS cli configured with a profile you can set the `AWS_PROFILE` variable instead.

        export AWS_PROFILE=phoenix-prod

7. Go to the `devop/infra/prod` folder inside the repository.

7. Initialize the terraform project:

        terraform init

8. Run the plan command. Terraform will prompt for the password of the database user.

        terraform plan -var-file terraform.tfvars -out=plan.out

10. Run the apply command to initiate resources creation (it should take between 5 and 10 minutes):

        terraform apply "plan.out"

When the apply completes, terraform will print out a few output values (refer to the "Outputs" table below for a description).

Since the CI/CD pipeline is the last component deployed the application will be reachable at the fqdn of the load balancer a few minutes after terraform completes the apply. While waiting you can check the email address specified at point 5, you should see an email with subject *"AWS Notification - Subscription Confirmation"*. Open it and click on the "Confirm subscription" link to subscribe to email alerts notifications.

## Teardown

To delete the environment navigate to the `devop/infra/prod` folder and run the destroy command:

        terraform destroy -var-file terraform.tfvars -var db_password=""

## Inputs (terrform.tfvars)

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws_region | AWS region where resources will be deployed | `string` | `"eu-central-1"` | yes |
| ec2_public_key | Public key of an ssh keypair (required by the db EC2 instance creation) | `string` | n/a | yes |
| branch | The branch released by the ci/cd pipeline | `string` | `"master"` | yes |
| github_connection_arn | ARN of an already existing GitHub connection | `string` | n/a | yes |
| github_repo_name | Name of the github repository hosting the code | `string` | `"olivieridav/cloud-phoenix-kata"` | yes |
| envir |  Friendly name for the environment | `string` | `"prod"` | yes |
| vpc_cidr_block | VPC range of IP addresses  | `string` | `"172.16.0.0/16"` | yes |
| subnet_cidr_priv_1a | Subnet range of IP addresses | `string` | `"172.16.1.0/24"` | yes |
| subnet_cidr_priv_1b | Subnet range of IP addresses | `string` | `"172.16.9.0/24"` | yes |
| subnet_cidr_pub_1a | Subnet range of IP addresses | `string` | `"172.16.2.2/24"` | yes |
| subnet_cidr_pub_1b | Subnet range of IP addresses | `string` | `"172.16.2.3/24"` | yes |
| db_instance_type | EC2 instance type for the mongodb instance | `string` | `"t3.micro"` | yes |
| db_name | Name of the mongodb database that will be created | `string` | `"phoenix"` | yes |
| db_user | Mongodb user that will be created | `string` | `"phoenixusr"` | yes |
| db_password | db_user's password will be intially set to this value | `string` | n/a | yes |
| db_backup_retention_days | Days of retention of mongodb snapshots | `number` | 7 | yes |
| db_backup_schedule | Schedule Expressions to trigger execution of db snapthot | `string` | `"rate(12 hours)"` | yes |
| logs_retention_days | Application logs retention days | `number` | 7 | yes |
| alert_email_address | Email address where alerts will be sent | `string` | n/a | yes |


## Outputs


| Name | Description |
|------|-------------|
| APPLICATION_LOG_CWGROUP | CloudWatch log group where application logs are saved |
| BACKUP_DUMPS_BUCKET | Name of the S3 bucket that stores the database dumps |
| BACKUP_SSM_COMMAND | Name of the SSM RunCommand document that perform backup snapshots |
| ENVIRONMENT | Friendly name of the deployed environment |
| GIT_BRANCH_RELEASED | The branch released by the ci/cd pipeline |
| LOAD_BALANCER_FQDN | Load balancer public fqdn |
| MONGO_DB_INSTANCE_ID | The ec2 instance id of the mongodb database | 
| MONGO_DB_IP | IP of the mongodb database instance |
| PIPELINE_NAME | Name of the codebuild ci/cd pipeline |

## Notes

- The CI/CD pipeline deployed will automatically build and release any new commits pushed to the branch specified in the `terraform.tfvars` file.

- If you provide a new value for the database user password only the connection string will be updated. The password will not be changed on the database. 

- The number of requests will be checked each minute and an autoscaling action will be triggered it if exceeds 600.

- The application logs are saved in CloudWatch logs and expire according to `logs_retention_days`.

- ECS will spawn a new container in case of an application crash.

- The mongodb instance does not have a public ip, however it is possible to open an interactive bash session with [SSM](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-sessions-start.html#start-ec2-console). 

- To start the CI/CD pipeline manually or check build/deploy errors you can use the Codepipeline console. Check *terraform apply* Outpus to get the name of the pipeline.  
