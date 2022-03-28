resource "aws_cloudwatch_metric_alarm" "requests" {
  alarm_name                = "phoenix-${var.envir}-requests-alarm"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "RequestCount"
  namespace                 = "AWS/ApplicationELB"
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = "600"
  dimensions = {
    TargetGroup  = var.target_group_arn_suffix
    LoadBalancer = var.load_balancer_arn_suffix
  }

  alarm_actions = [aws_appautoscaling_policy.ecs_scale_up_policy.arn]
  ok_actions = [aws_appautoscaling_policy.ecs_scale_down_policy.arn]

  depends_on = [aws_appautoscaling_policy.ecs_scale_up_policy,
                aws_appautoscaling_policy.ecs_scale_down_policy]
}

resource "aws_appautoscaling_target" "ecs_scale_target" {
  max_capacity       = 2
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  #role_arn           =  aws_iam_role.ecs_autoscale_role.arn

  depends_on = [aws_iam_role_policy.ecs_autoscale_role_policy]
}

resource "aws_appautoscaling_policy" "ecs_scale_up_policy" {
  name               = "phoenix-service-scale-up-${var.envir}"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs_scale_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_scale_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_scale_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound  = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = [aws_appautoscaling_target.ecs_scale_target]
}

resource "aws_appautoscaling_policy" "ecs_scale_down_policy" {
  name               = "phoenix-service-scale-down-${var.envir}"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs_scale_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_scale_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_scale_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = [aws_appautoscaling_target.ecs_scale_target]
}

resource "aws_iam_role" "ecs_autoscale_role" {
  name = "phoenix-autoscale-role-${var.envir}"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ecs.application-autoscaling.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "ecs_autoscale_role_policy" {
  name = "phoenix-autoscale-role-policy-${var.envir}"
  role = aws_iam_role.ecs_autoscale_role.id

  policy = jsonencode(
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecs:DescribeServices",
                "ecs:UpdateService",
                "cloudwatch:PutMetricAlarm",
                "cloudwatch:DescribeAlarms",
                "cloudwatch:DeleteAlarms"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
})
    depends_on = [aws_iam_role.ecs_autoscale_role]
}