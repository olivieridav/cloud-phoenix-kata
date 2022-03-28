output "db_private_ip" {
  value = aws_instance.phoenix_db.private_ip
}


resource "aws_key_pair" "phoenix_key" {
  key_name   = "phoenix-key-${var.envir}"
  public_key = var.ec2_public_key
}

data "aws_ami" "latest_amzn2" {
most_recent = true
owners = ["amazon"]

  filter {
      name   = "name"
      values = ["amzn2-ami-hvm-*-gp2"]
  }

  filter {
      name   = "virtualization-type"
      values = ["hvm"]
  }

  	filter {
     name   = "architecture"
      values = ["x86_64"]
  }

}

data "template_file" "init" {
  template = "${file("${path.module}/installmongo.userdata.tpl")}"
  vars = {
    db_name = var.db_name
    db_user = var.db_user
    db_password = var.db_password
  }
}

resource "aws_instance" "phoenix_db" {
  ami           = data.aws_ami.latest_amzn2.id
  instance_type = var.db_instance_type
  subnet_id = var.db_subnet_id
  key_name = aws_key_pair.phoenix_key.id
  user_data = data.template_file.init.rendered
  iam_instance_profile = aws_iam_instance_profile.phoenix_db_instance_profile.id

  vpc_security_group_ids = [aws_security_group.phoenix_db.id]

  root_block_device {
    volume_size = 10
    volume_type = "gp2"
    encrypted   = true
  }

  depends_on = [aws_key_pair.phoenix_key, aws_security_group.phoenix_db]

  tags = {
    Name = "phoenix-db-${var.envir}"
  }

  lifecycle {
    ignore_changes = [
      user_data
    ]
  }
}

resource "aws_security_group" "phoenix_db" {
  name        = "phoenix-mongo-db-${var.envir}"
  vpc_id      = var.vpc_id

  ingress {
    description      = "Mongo from VPC"
    from_port        = 27017
    to_port          = 27017
    protocol         = "tcp"
    cidr_blocks      = [var.vpc_cidr]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}
