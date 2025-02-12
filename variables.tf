variable "network_interface_id" {
	type = string
	default = "vpc-4f53e932s"
}

variable "ami" {
	type = string
	default = "ami-0182f373e66f89c85"
}

variable "instance_type" {
	type = string
	default = "t2.micro"
}