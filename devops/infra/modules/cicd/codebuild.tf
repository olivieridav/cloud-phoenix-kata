data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_codebuild_project" "code_build" {
  name            = "phoenix-code-build-plan-${var.envir}"
  build_timeout   = 30
  queued_timeout  = 15
  service_role    = aws_iam_role.codebuild_role.arn
  badge_enabled   = false

  vpc_config {
    vpc_id = var.vpc_id

    subnets = [
      var.codebuild_subnet_id
    ]

    security_group_ids = [
      aws_security_group.codebuild_sg.id
    ]
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "AWS_REGION"
      value = data.aws_region.current.name
    }

     environment_variable {
      name  = "ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }

    environment_variable {
      name  = "REPOSITORY_URI"
      value = var.registry
    }

    environment_variable {
      name  = "CONTAINER_NAME"
      value = "app"
    }

  }

  source {
    type            = "CODEPIPELINE"
    git_clone_depth = 0
  }

  logs_config {
    cloudwatch_logs {
      status = "ENABLED"
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [ environment ]
  }

  depends_on = [aws_iam_role_policy.codebuild_role_policy, aws_security_group.codebuild_sg]
}

resource "aws_codebuild_project" "code_build_tag" {
  name            = "phoenix-code-build-tag-${var.envir}"
  build_timeout   = 5
  queued_timeout  = 10
  service_role    = aws_iam_role.codebuild_role.arn
  badge_enabled   = false

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name = "SSM_PARAMETER_NAME"
      value = var.ssm_parameter_tag_name
    }
  }

  source {
    type = "CODEPIPELINE"
    buildspec = file("${path.module}/buildspec_tag.yml")
  }

   logs_config {
    cloudwatch_logs {
      status = "ENABLED"
    }
  }

  tags = var.tags

  depends_on = [aws_iam_role_policy.codebuild_role_policy, aws_security_group.codebuild_sg]
}



resource "aws_security_group" "codebuild_sg" {
  name        = "phoenix-code-build-plan-${var.envir}-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = var.vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "phoenix-code-build-plan-${var.envir}-sg"
  }
}

resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-phoenix-${var.envir}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      },
    ]
  })

  tags = var.tags
}


resource "aws_iam_role_policy" "codebuild_role_policy" {
  role = aws_iam_role.codebuild_role.name

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Resource": [
              "*"
            ],
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": [
                "${aws_s3_bucket.codepipeline_bucket.arn}/*"
            ],
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:GetBucketAcl",
                "s3:GetBucketLocation"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "codebuild:CreateReportGroup",
                "codebuild:CreateReport",
                "codebuild:UpdateReport",
                "codebuild:BatchPutTestCases",
                "codebuild:BatchPutCodeCoverages"
            ],
            "Resource": [
                "arn:aws:codebuild:*:*:report-group/*"
            ]
        },
         {
            "Effect": "Allow",
						"Resource": "*",
            "Action": [
                "ecr:GetAuthorizationToken"
            ]
        },
  			{
            "Effect": "Allow",
						"Resource": "*",
            "Action": [
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:CompleteLayerUpload",
                "ecr:GetDownloadUrlForLayer",
                "ecr:InitiateLayerUpload",
                "ecr:PutImage",
                "ecr:UploadLayerPart"
            ]
        },
     {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeDhcpOptions",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcs",
        "ec2:CreateNetworkInterfacePermission"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterfacePermission"
      ],
      "Resource": "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:network-interface/*",
      "Condition": {
        "StringEquals": {
          "ec2:AuthorizedService": "codebuild.amazonaws.com"
        },
        "ArnEquals": {
          "ec2:Subnet": [
            "arn:aws:ec2:::::subnet/${var.codebuild_subnet_id}"
          ]
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:PutParameter"
      ],
      "Resource": "arn:aws:ssm:*:*:parameter/${var.ssm_parameter_tag_name}"
    }
    ]
}
POLICY

  lifecycle {
	ignore_changes = [ policy ]
  }

  depends_on = [aws_iam_role.codebuild_role]
}


