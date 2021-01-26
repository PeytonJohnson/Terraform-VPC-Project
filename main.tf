# Terraform configuration

provider "aws" {
  region = "us-west-2"
}

########################################################################
#VPC resources and data variables
########################################################################


data "aws_vpc" "default" {
  id = module.vpc.vpc_id
  # default = true
  
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
}


data "aws_security_group" "default" {
  name   = "default"
  vpc_id = data.aws_vpc.default.id
}


resource "random_pet" "this" {
  length = 2
}

locals {
    user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd.x86_64
              systemctl start httpd.service
              systemctl enable httpd.service
              echo “AWS-POC created by Tommy Le” > /var/www/html/index.html
              EOF
  
}

########################################################################
#VPC Section
########################################################################


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.21.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = var.vpc_azs
  private_subnets = var.vpc_private_subnets
  public_subnets  = var.vpc_public_subnets

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = var.vpc_enable_nat_gateway

  tags = var.vpc_tags
}


#######################################################################
#EC2 Section
########################################################################

resource "aws_key_pair" "ssh-key" {
  key_name   = "ssh-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCYg17NjhX40pTGOeg4VyZbEhFpNA1KXk+eYZy0MMJkSASeHAkzx7uABYkW//nMoWwOFyVcP5jPcOQfrkFSF/hloUd073C3cHuTziMKnc3TZxZuS2rZ/b3um71gpCvB5Am6VfIW388EB3oiBJzzxuCyhhy52sXHkq2uFeHyYRyuq5TWoGEODmvNZzeBXtcovouDl8wtsshtqC2UKDO4/I+Up7xBpFXCyy1DlIDOyWgkOk3LHOspKIttgjVHIE0hoqY8stWFH1ZWtaj5dnZ5JYH7HKCtyw0QdAILONR36OWDBGzCnmSuegYu+1VgUh7dVQtdOALHz2MWqOdJzQcRt5eJ"
}

resource "aws_security_group" "ec2" {
  name = "ec2-sg"

  description = "EC2 security group (terraform-managed)"
  vpc_id      = data.aws_vpc.default.id


  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    description = "Telnet"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    description = "HTTP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    description = "HTTPS"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "ec2_private" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "2.16.0"

  instance_count = 1

  name          = "Private_instance_subnet3"
  ami           = "ami-01e78c5619c5e68b4"
  instance_type = "t2.micro"
  subnet_id     = tolist(module.vpc.private_subnets)[1]
  vpc_security_group_ids      = [aws_security_group.ec2.id]


  user_data_base64 = base64encode(local.user_data)

  root_block_device = [
    {
      volume_type           = var.volume_type
      volume_size           = var.volume_size
      delete_on_termination = "true"
    },
  ]

  tags = {
    "Env"      = "Private"
    "Location" = "Secret"
  }
}
module "ec2_public" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "2.16.0"

  instance_count = 1

  name          = "Public_instance_subnet1"
  ami           = "ami-01e78c5619c5e68b4"
  instance_type = "t2.micro"
  subnet_id     = tolist(module.vpc.public_subnets)[0]
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = true
  key_name = "ssh-key"
  

  root_block_device = [
    {
      volume_type           = var.volume_type
      volume_size           = var.volume_size
      delete_on_termination = "true"
    },
  ]

  tags = {
    "Env"      = "Public"
    "Location" = "Secret"
  }
}


########################################################################
#ALB Section
########################################################################

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 5.0"

  name = "my-alb"

  load_balancer_type = "application"

  vpc_id             = data.aws_vpc.default.id
  subnets            = ["subnet-0b31550cb94a00bc0", "subnet-06a5a374099fd0510"]
  security_groups    = [module.alb_security_group.this_security_group_id]
  enable_cross_zone_load_balancing = true

  target_groups = [
    {
      name_prefix      = "pref-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "ip"
    }
  ]


  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
      ation_type        = "forward"
    }
  ]




  tags = {
    Environment = "dev"
  }
} 


module "alb_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 3.0"

  name        = "alb-sg-${random_pet.this.id}"
  description = "Security group for example usage with ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "all-icmp"]
  egress_rules        = ["all-all"]
}
