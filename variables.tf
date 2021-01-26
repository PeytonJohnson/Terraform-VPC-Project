# Input variable definitions


 variable "private_sub3" {
  description = "Private subnets for VPC"
  type        = list(string)
  default     = ["subnet-0fcc6c4b7553f3acf", "subnet-04c33609d71aff902"]
} 


variable "vpc_name" {
  description = "AWS POC"
  type        = string
  default     = "AWS-POC"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_azs" {
  description = "Availability zones for VPC"
  type        = list
  default     = ["us-west-2a", "us-west-2b"]
}

variable "vpc_private_subnets" {
  description = "Private subnets for VPC"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.2.0/24"]
}

variable "vpc_public_subnets" {
  description = "Public subnets for VPC"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "vpc_enable_nat_gateway" {
  description = "Enable NAT gateway for VPC"
  type    = bool
  default = true
}

variable "vpc_tags" {
  description = "test for CF POC"
  type        = map(string)
  default     = {
    Terraform   = "true"
    Environment = "dev"
  }
}

variable "volume_type" {
  description = "The type of volume. Can be standard gp2 or io1 or sc1st1"
  default = "standard"
}

variable "volume_size" {
  description = "size of the ebs volume needed"
  default = "20"
}

variable "gateway_id" {
  description = "id for gateway"
  default = "igw-0c14c3c68c4d7e10b"
}
