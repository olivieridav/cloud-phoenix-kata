resource "aws_sns_topic" "cpu_peaks" {
  name = "phoenix-cpu-peaks-${var.envir}"
}

resource "aws_sns_topic_subscription" "cpu_peaks" {
  topic_arn = aws_sns_topic.cpu_peaks.arn
  protocol  = "email"
  endpoint  = var.alert_email_address

  depends_on = [aws_sns_topic.cpu_peaks]
}

resource "aws_sns_topic_policy" "cpu_peaks" {
  arn = aws_sns_topic.cpu_peaks.arn

  policy = <<EOF
{
  "Version": "2008-10-17",
  "Id": "__default_policy_ID",
  "Statement": [
    {
      "Sid": "__default_statement_ID",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": [
        "SNS:Publish"
      ],
      "Resource": "${aws_sns_topic.cpu_peaks.arn}",
      "Condition": {
          "ArnLike": {
            "aws:SourceArn": "${aws_cloudwatch_metric_alarm.cpu_peak.arn}"
        }
      }
    }
  ]
}
EOF

  depends_on = [aws_sns_topic.cpu_peaks, aws_cloudwatch_metric_alarm.cpu_peak]
}

resource "aws_cloudwatch_metric_alarm" "cpu_peak" {
  alarm_name                = "phoenix-cpu-peaks-${var.envir}"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "CpuUtilized"
  namespace                 = "ECS/ContainerInsights"
  period                    = "60"
  statistic                 = "Maximum"
  threshold                 = "40"
  alarm_description         = "This metric monitors ecs cpu utilization"
  insufficient_data_actions = []
  alarm_actions             = [aws_sns_topic.cpu_peaks.arn]


   dimensions = {
        TaskDefinitionFamily = aws_ecs_service.ecs_service.name
        ClusterName = aws_ecs_cluster.ecs_cluster.name
      }

  depends_on = [aws_sns_topic.cpu_peaks]
}

