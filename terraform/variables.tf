variable "region" {
  default     = "us-east-1"
  description = "The AWS region to create resources in"

}
variable "profile" {
  default     = "terraform-local"
  description = "The AWS profile to use for authentication"

}
variable "ami_owner" {
  default     = "099720109477"
  description = "The owner ID for the Ubuntu AMI"

}
variable "vpc_cidr" {
  default     = "10.0.0.0/16"
  description = "The CIDR block for the VPC"

}
variable "subnet_cidr" {
  default     = "10.0.1.0/24"
  description = "The CIDR block for the subnet"

}
variable "instance_type" {
  default     = "t3.micro"
  description = "The instance type for the EC2 instance"

}
variable "key_name" {
  default     = "tut ec2"
  description = "The name of the key pair to use for the EC2 instance"

}

variable "security_group_cidr_ingress_web" {
  default     = "0.0.0.0/0"
  description = "The CIDR block for the security group"

}
variable "security_group_cidr_egress" {
  default     = "0.0.0.0/0"
  description = "The CIDR block for the security group egress rule"

}
variable "security_group_cidr_ingress_ssh" {

  description = "The CIDR block for the security group SSH rule"
}
