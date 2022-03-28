output "application_log_group" {
  value = aws_cloudwatch_log_group.log_group.name
}

resource "aws_ssm_parameter" "db_connection_string" {
  name  = "phoenix-db-connection-string-${var.envir}"
  type  = "SecureString"
  value = "mongodb://${var.db_user}:${var.db_password}@${var.db_host}/${var.db_name}"
}

resource "aws_ssm_parameter" "deployed_tag" {
  name  = "phoenix-deployed-tag-${var.envir}"
  type  = "String"
  value = "init"

  lifecycle {
    ignore_changes = [ name,
                      version,
                      value ]
  }
}

resource "aws_cloudwatch_log_group" "log_group" {
  name = "/ecs/phoenix-ecs-${var.envir}"
  retention_in_days = var.logs_retention
}

data "aws_ssm_parameter" "deployed_tag" {
  name = aws_ssm_parameter.deployed_tag.name
}

resource "aws_ecs_task_definition" "ecs_task" {
  family = "phoenix-${var.envir}"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn = aws_iam_role.execution_task_role.arn
  cpu = var.cpu
  memory = var.memory

  container_definitions = <<TASK_DEFINITION
[
    {
      "dnsSearchDomains": null,
      "environmentFiles": null,
      "logConfiguration": {
        "logDriver": "awslogs",
        "secretOptions": null,
        "options": {
          "awslogs-group": "/ecs/phoenix-ecs-${var.envir}",
          "awslogs-region": "${var.aws_region}",
          "awslogs-stream-prefix": "applogs"
        }
      },
      "entryPoint": null,
      "portMappings": [
        {
          "hostPort": ${var.listen_port},
          "protocol": "tcp",
          "containerPort": ${var.listen_port}
        }
      ],
      "command": null,
      "linuxParameters": null,
      "cpu": ${var.cpu},
      "secrets": [
        {
          "name": "DB_CONNECTION_STRING",
          "valueFrom": "${aws_ssm_parameter.db_connection_string.arn}"
        }
      ],
      "environment": [
        {
          "name": "PORT",
          "value": "${var.listen_port}"
        }
      ],
      "resourceRequirements": null,
      "ulimits": null,
      "dnsServers": null,
      "mountPoints": [],
      "workingDirectory": null,
      "dockerSecurityOptions": null,
      "memory": ${var.memory},
      "memoryReservation": null,
      "volumesFrom": [],
      "stopTimeout": null,
      "image": "${aws_ecr_repository.ecr.repository_url}:${data.aws_ssm_parameter.deployed_tag.value}",
      "startTimeout": null,
      "firelensConfiguration": null,
      "dependsOn": null,
      "disableNetworking": null,
      "interactive": null,
      "healthCheck": null,
      "essential": true,
      "links": null,
      "hostname": null,
      "extraHosts": null,
      "pseudoTerminal": null,
      "user": null,
      "readonlyRootFilesystem": null,
      "dockerLabels": null,
      "systemControls": null,
      "privileged": null,
      "name": "app"
    }
  ]
TASK_DEFINITION

  lifecycle {
    ignore_changes = [
      container_definitions
    ]
  }

    tags = {}
    tags_all = {}

    depends_on = [aws_iam_role_policy.execution_task_role_policy]
}

resource "aws_iam_role" "execution_task_role" {
  name = "phoenix-task-execution-role-${var.envir}"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ecs-tasks.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "execution_task_role_policy" {
  role = aws_iam_role.execution_task_role.name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter*"
      ],
      "Resource": "${aws_ssm_parameter.db_connection_string.arn}"
   }
  ]
}
POLICY


  depends_on = [aws_iam_role.execution_task_role]
}

