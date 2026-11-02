provider "aws" {
  region  = var.region
  profile = var.profile

}
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = [var.ami_owner] # Canonical's AWS account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "main"
  }

}
resource "aws_subnet" "subnet1" {
  cidr_block        = var.subnet_cidr
  vpc_id            = aws_vpc.main.id
  availability_zone = var.availability_zone
  tags = {
    Name = "main_subnet"
  }

}
resource "aws_instance" "server" {

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.subnet1.id
  vpc_security_group_ids = [aws_security_group.allow_tls_ssh.id]
  availability_zone      = var.availability_zone
  key_name               = var.key_name
  tags = {
    Name = "server"
  }
}
resource "aws_security_group" "allow_tls_ssh" {
  vpc_id      = aws_vpc.main.id
  description = "allow inbound traffic from ports 22 443 80"
  name        = "allow_tls_ssh"

}
resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.allow_tls_ssh.id
  ip_protocol       = "tcp"
  cidr_ipv4         = var.security_group_cidr_ingress_web
  to_port           = 80
  from_port         = 80



}
resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.allow_tls_ssh.id
  cidr_ipv4         = var.security_group_cidr_ingress_ssh
  ip_protocol       = "tcp"
  to_port           = 443
  from_port         = 443


}
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.allow_tls_ssh.id
  ip_protocol       = "tcp"
  to_port           = 22
  from_port         = 22
  cidr_ipv4         = var.security_group_cidr_ingress_ssh


}
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic" {
  security_group_id = aws_security_group.allow_tls_ssh.id
  cidr_ipv4         = var.security_group_cidr_egress
  ip_protocol       = "-1"



}
resource "aws_internet_gateway" "main_gateway" {
  vpc_id = aws_vpc.main.id

}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    gateway_id = aws_internet_gateway.main_gateway.id
    cidr_block = "0.0.0.0/0"
  }

}


resource "aws_eip" "server_eip" {
  domain = "vpc"

}
resource "aws_eip_association" "server_ip_association" {
  instance_id   = aws_instance.server.id
  allocation_id = aws_eip.server_eip.id

}
resource "aws_route_table_association" "public_subnet1" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.subnet1.id

}
output "server_public_ip" {
  description = "public ip of EC2"
  value       = aws_eip.server_eip.public_ip
}