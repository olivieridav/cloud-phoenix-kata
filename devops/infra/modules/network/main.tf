output "vpc_id" {  
	value = aws_vpc.phoenix_vpc.id
}

output "public_subnet_1a" {  
	value = aws_subnet.phoenix_public_1a.id
}

output "public_subnet_1b" {  
	value = aws_subnet.phoenix_public_1b.id
}

output "private_subnet_1a" {  
	value = aws_subnet.phoenix_priv_1a.id
}

output "private_subnet_1b" {  
	value = aws_subnet.phoenix_priv_1b.id
}

output "vpc_cidr" {  
	value = aws_vpc.phoenix_vpc.cidr_block
}

resource "aws_vpc" "phoenix_vpc" {
  cidr_block = var.vpc_cidr_block
}

resource "aws_subnet" "phoenix_priv_1b" {
  vpc_id            = aws_vpc.phoenix_vpc.id
  cidr_block        = var.subnet_cidr_priv_1b
  availability_zone = "${var.aws_region}a"
}

resource "aws_subnet" "phoenix_priv_1a" {
  vpc_id            = aws_vpc.phoenix_vpc.id
  cidr_block        = var.subnet_cidr_priv_1a
  availability_zone = "${var.aws_region}b"

}

resource "aws_subnet" "phoenix_public_1a" {
  vpc_id            = aws_vpc.phoenix_vpc.id
  cidr_block        = var.subnet_cidr_pub_1a
  availability_zone = "${var.aws_region}a"
}

resource "aws_subnet" "phoenix_public_1b" {
  vpc_id            = aws_vpc.phoenix_vpc.id
  cidr_block        = var.subnet_cidr_pub_1b
  availability_zone = "${var.aws_region}b"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.phoenix_vpc.id
}

resource "aws_eip" "ngweip" {
  vpc      = true
}

resource "aws_nat_gateway" "ngw" {
  subnet_id     = aws_subnet.phoenix_public_1b.id
  allocation_id = aws_eip.ngweip.id
  tags = {
    Name = "phoenix-nat-gw-${var.envir}"
  }

  depends_on = [aws_internet_gateway.gw, aws_route_table_association.phoenix_public_1b,
               aws_eip.ngweip]
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.phoenix_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "phoenix-public-rt-${var.envir}"
  }
}

resource "aws_route_table_association" "phoenix_public_1b" {
  subnet_id      = aws_subnet.phoenix_public_1b.id
  route_table_id = aws_route_table.public_rt.id

  depends_on = [aws_subnet.phoenix_public_1b, aws_route_table.public_rt]
}

resource "aws_route_table_association" "phoenix_public_1a" {
  subnet_id      = aws_subnet.phoenix_public_1a.id
  route_table_id = aws_route_table.public_rt.id

  depends_on = [aws_subnet.phoenix_public_1a, aws_route_table.public_rt]
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.phoenix_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
  }

  tags = {
    Name = "phoenix-private-rt-${var.envir}"
  }

  depends_on = [aws_nat_gateway.ngw]
}

resource "aws_route_table_association" "phoenix_private_1b" {
  subnet_id      = aws_subnet.phoenix_priv_1b.id
  route_table_id = aws_route_table.private_rt.id

  depends_on = [aws_route_table.private_rt]
}

resource "aws_route_table_association" "phoenix_private_1a" {
  subnet_id      = aws_subnet.phoenix_priv_1a.id
  route_table_id = aws_route_table.private_rt.id

  depends_on = [aws_route_table.private_rt]
}


