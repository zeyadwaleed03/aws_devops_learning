variable "region" {
  default     = "us-east-1"
  description = "The AWS region to create resources in"

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
  type        = string
  description = "The CIDR block for the security group SSH rule"

  validation {
    condition     = can(cidrnetmask(var.security_group_cidr_ingress_ssh)) && endswith(var.security_group_cidr_ingress_ssh, "/32")
    error_message = "SSH ingress must be a single IPv4 address with a /32 mask."
  }
}

variable "security_group_cidr_ingress_ssh_runner" {
  type        = string
  description = "Temporary GitHub Actions runner CIDR for SSH access"
  default     = null
  nullable    = true

  validation {
    condition = var.security_group_cidr_ingress_ssh_runner == null ? true : (
      can(cidrnetmask(var.security_group_cidr_ingress_ssh_runner)) &&
      endswith(var.security_group_cidr_ingress_ssh_runner, "/32")
    )
    error_message = "Runner SSH ingress must be a single IPv4 address with a /32 mask."
  }
}
