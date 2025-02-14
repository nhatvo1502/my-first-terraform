terraform {
	required_providers {
		aws = {
			source = "hashicorp/aws"
		}
	}
}

#############
# RESOURCES #
#############

# VPCs
resource "aws_vpc" "terraform_vpc" {
	cidr_block = "10.0.0.0/16"
	
	tags = {
		Name = "Terraform VPC"
	}
}

################# PUBLIC SUBNET ########################
# Note: we need a VPC with a public subnet, an internet gateway, a public route table and route all traffic to the internet gateway, then associate public route table to public subnet. A security group that allow SSH from ingress and all trafic egress. An EC2 instance deployed on this subnet for testing
# Public Subnet
resource "aws_subnet" "terraform_public_subnet" {
	vpc_id = aws_vpc.terraform_vpc.id
	cidr_block = "10.0.1.0/24"

	map_public_ip_on_launch = true

	tags = {
		Name = "Terraform VPC Public Subnet"
	}
}

# Internet Gateway
resource "aws_internet_gateway" "terraform_igw" {
	vpc_id = aws_vpc.terraform_vpc.id

	tags = {
		Name = "Terraform Internet Gateway"
	}
}

# Public Route Table
resource "aws_route_table" "terraform_rt_public" {
	vpc_id = aws_vpc.terraform_vpc.id

	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = aws_internet_gateway.terraform_igw.id
	}

	tags = {
		Name = "Terraform Public Route Table"
	}
}

# Associate Public Route Table to Public Subnet
resource "aws_route_table_association" "public" {
	subnet_id = aws_subnet.terraform_public_subnet.id
	route_table_id = aws_route_table.terraform_rt_public.id
}

# Security Group for EC2 Instance to allow SSH
resource "aws_security_group" "allow_ssh" {
	name = "allow_ssh"
	description = "Allow ssh inbound and all outbound traffic"
	vpc_id = aws_vpc.terraform_vpc.id

	tags = {
		Name = "allow_ssh"
	}
}

# Ingress rule for ssh ipv4
resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
	security_group_id = aws_security_group.allow_ssh.id
	cidr_ipv4 = "0.0.0.0/0"
	from_port = 22
	ip_protocol = "tcp"
	to_port = 22
}

# Egress rule for all traffic ipv4
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
	security_group_id = aws_security_group.allow_ssh.id
	cidr_ipv4 = "0.0.0.0/0"
	ip_protocol = "-1"
}

# ################# PRIVATE SUBNET 1 ########################
# Note: We need a private subnet, private subnet route table, NAT Gateway bound with elastic ip deployed on public subnet, then use the private route table to direct traffic from private subnet to this NAT Gateway
# Private Subnet 1 with Internet Access
resource "aws_subnet" "terraform_private_subnet_1" {
	vpc_id = aws_vpc.terraform_vpc.id
	cidr_block = "10.0.2.0/24"

	tags = {
		Name = "Terraform VPC Private Subnet 1"
	}
}

# Private Route Table 1
resource "aws_route_table" "terraform_rt_private_1" {
	vpc_id = aws_vpc.terraform_vpc.id

	route {
		cidr_block = "0.0.0.0/0"
		nat_gateway_id = aws_nat_gateway.terraform_natgateway.id
	}

	tags = {
		Name = "Terraform Private Route Table 1"
	}
}

# Elastic IP
resource "aws_eip" "terraform_eip" {
	domain = "vpc"
}

# NAT Gateway
resource "aws_nat_gateway" "terraform_natgateway" {
	allocation_id = aws_eip.terraform_eip.id
	subnet_id = aws_subnet.terraform_public_subnet.id

	tags = {
		Name = "terraform-natgateway"
	}
}

# Associate Private Route Table with Private Subnet
resource "aws_route_table_association" "private" {
	subnet_id = aws_subnet.terraform_private_subnet_1.id
	route_table_id = aws_route_table.terraform_rt_private_1.id
}

###########
# keypair #
###########
resource "aws_key_pair" "terraform_kp" {
	key_name = "terraform_kp"
	public_key = file("C:/Users/NhatVo/PROJECTS/OpenVPN/OpenVPN-Terraform/my-key.pub")
}

#############
# Instances #
#############

# Public EC2 Instance
resource "aws_instance" "public_instance" {
	ami = var.ami
	instance_type = var.instance_type
	subnet_id = aws_subnet.terraform_public_subnet.id
	vpc_security_group_ids = [aws_security_group.allow_ssh.id]

	key_name = aws_key_pair.terraform_kp.key_name

	tags = {
		Name = "public_instance"
	}
}

# Private EC2 Instance (with secured internet)
resource "aws_instance" "private_instance" {
	ami = var.ami
	instance_type = var.instance_type
	subnet_id = aws_subnet.terraform_private_subnet_1.id
	vpc_security_group_ids = [aws_security_group.allow_ssh.id]

	key_name = aws_key_pair.terraform_kp.key_name

	tags = {
		Name = "private_instance"
	}
}

##########
# OUTPUT #
##########
output "terraform_vpc_id" {
	value = aws_vpc.terraform_vpc.id
}

output "public_subnet_id" {
	value = aws_subnet.terraform_public_subnet.id
}

output "public_instance_id" {
	value = aws_instance.public_instance.id
}

output "ssh_public_instance" {
	value = "ssh -i my-key ec2-user@${aws_instance.public_instance.public_ip}"
}

output "private_instance_id" {
	value = aws_instance.private_instance.id
}

output "private_instance_private_ip" {
	value = aws_instance.private_instance.private_ip
}