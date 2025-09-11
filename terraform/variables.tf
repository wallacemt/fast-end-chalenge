variable "aws_region" { default = "us-east-1" }
variable "key_name" { description = "SSH key pair name" }
variable "public_key_path" { description = "Local public key to upload" }
variable "instance_count" { default = 3 }
variable "instance_type" { default = "t3.micro" }