output "ecr_url" {  
	value = aws_ecr_repository.ecr.repository_url
}

resource "aws_ecr_repository" "ecr" {
  name                 = "cloud-phoenix-phoenix-${var.envir}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}



