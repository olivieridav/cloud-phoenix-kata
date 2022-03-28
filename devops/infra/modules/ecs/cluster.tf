output "ecs_cluster_name" {  
	value = aws_ecs_cluster.ecs_cluster.name
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "phoenix-ecs-cluster-${var.envir}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.tags
}
