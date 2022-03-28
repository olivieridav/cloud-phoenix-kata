output "load_balancer_fqdn" {  value = aws_lb.alb_phoenix.dns_name}
output "load_balancer_arn" {  value = aws_lb.alb_phoenix.arn}
output "load_balancer_arn_suffix" {  value = aws_lb.alb_phoenix.arn_suffix}
output "load_balancer_http" {  value = aws_lb_listener.alb_phoenix_http.arn}
output "target_group_arn" {  value = aws_lb_target_group.tg.arn}
output "target_group_arn_suffix" {  value = aws_lb_target_group.tg.arn_suffix}
output "load_balancer_sg" {  value = aws_security_group.alb_phoenix.id}

resource "aws_lb" "alb_phoenix" {
  name               = "alb-phoenix-${var.envir}"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.alb_subnets
  security_groups    = [aws_security_group.alb_phoenix.id]
}


resource "aws_lb_listener" "alb_phoenix_http" {
  load_balancer_arn = aws_lb.alb_phoenix.arn
  port              = "80"
  protocol          = "HTTP"

 default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
  
}

resource "aws_security_group" "alb_phoenix" {
  name        = "alb-phoenix-sg-${var.envir}"
  description = "${var.envir} load balancer security group"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "all traffic"
  }
}

resource "aws_lb_target_group" "tg" {
  name     = "phoenix-tg-${var.envir}"
  port     = var.listen_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"
  deregistration_delay = 60

  health_check {
    healthy_threshold = 2
    interval = 10
  }
}

