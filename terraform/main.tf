provider "aws" {
  region  = "us-east-1"
  profile = "terraform-local"

}
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's AWS account ID

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
  cidr_block = "10.0.0.0/16"
  tags = {
    name = "main"
  }

}
resource "aws_subnet" "subnet1" {
  cidr_block        = "10.0.1.0/24"
  vpc_id            = aws_vpc.main.id
  availability_zone = "us-east-1a"
  tags = {
    name = "main_subnet"
  }

}
resource "aws_instance" "server" {

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.subnet1.id
  vpc_security_group_ids = [aws_security_group.allow_tls_ssh.id]
  availability_zone      = "us-east-1a"
  key_name               = "tut ec2"
  tags = {
    name = "server"
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
  cidr_ipv4         = "0.0.0.0/0"
  to_port           = 80
  from_port         = 80



}
resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.allow_tls_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  to_port           = 443
  from_port         = 443


}
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.allow_tls_ssh.id
  ip_protocol       = "tcp"
  to_port           = 22
  from_port         = 22
  cidr_ipv4         = "0.0.0.0/0"


}
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic" {
  security_group_id = aws_security_group.allow_tls_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
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