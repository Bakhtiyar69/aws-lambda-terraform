terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.zone
}

# Create a VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_id
  enable_dns_hostnames = true
  enable_dns_support   = true
}
# Create Public Subnet
resource "aws_subnet" "private-subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public
  availability_zone = var.availability_zone
  tags = {
    Name = "private"
  }
}
resource "aws_route_table" "private-subnet" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = var.all_traffic
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "private-subnet" {
  subnet_id      = aws_subnet.private-subnet.id
  route_table_id = aws_route_table.private-subnet.id
}

# Create an Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "main"
  }
}

# Create a Security Group
resource "aws_security_group" "sg" {
  name        = var.security
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "security_group"
  }
}

resource "aws_s3_bucket" "b" {
  bucket = var.s3

  tags = {
    Name        = "s3-bucket"
    Environment = "Dev"
  }
  force_destroy = true
}

resource "aws_s3_bucket_acl" "acl" {
  bucket = aws_s3_bucket.b.id
  acl    = "private"
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "aws_s3_object" "lambda" {
  bucket = var.s3
  key    = var.s3_obj

  depends_on = [
    aws_s3_bucket_object.object,
  ]
}
resource "aws_s3_bucket_object" "object" {

  bucket = var.s3
  key    = var.s3_obj
  acl    = "private"  # or can be "public-read"
  source = "/home/bakhtiyar/Downloads/Compressed/python3.8.zip"

  depends_on = [
    aws_s3_bucket.b,
  ]
}

resource "aws_lambda_function" "s3_lambda" {

  function_name = var.lambda_filename
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "python3.8.zip"
  s3_bucket     = aws_s3_bucket.b.id
  s3_key        = aws_s3_bucket_object.object.key


  runtime = "python3.8"

  environment {
    variables = {
      foo = "bar"
    }
  }
  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.cloudwatch,
  ]
}

resource "aws_cloudwatch_log_group" "cloudwatch" {
  name = var.lambda_filename

  retention_in_days = 7
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}
