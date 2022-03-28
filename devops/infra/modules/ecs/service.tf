output "ecs_service_name" {  
	value = aws_ecs_service.ecs_service.name
}

resource "aws_ecs_service" "ecs_service" {
  name            = "phoenix-${var.envir}"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task.arn
  desired_count   = var.desired_count
  launch_type       = "FARGATE"
  platform_version  = "1.4.0"

  network_configuration {
      subnets = var.ecs_subnets
      security_groups = [aws_security_group.ecs_service.id]
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "app"
    container_port   = var.listen_port
  }

lifecycle {
    ignore_changes = [
      task_definition
    ]
  }

  depends_on = [aws_ecs_task_definition.ecs_task]
}

resource "aws_security_group" "ecs_service" {
  name        = "phoenix-sg-${var.envir}"
  vpc_id = var.vpc_id

  ingress {
    from_port   = var.listen_port
    to_port     = var.listen_port
    protocol    = "tcp"
    security_groups = [var.lb_security_group]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "all traffic"
  }
}
