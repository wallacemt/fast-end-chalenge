variable "aws_region" { default = "us-east-1" }
variable "key_name" { default = "deployer" }
variable "public_key_path" { default = "../keys/deploy_key.pub" }
variable "instance_count" { default = 3 }
variable "instance_type" { default = "t3.medium" }