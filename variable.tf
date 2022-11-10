variable "zone" {

  type    = string
  default = "eu-west-2"
}

variable "vpc_id" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public" {
  type    = string
  default = "10.0.1.0/24"
}
variable "availability_zone" {
  type    = string
  default = "eu-west-2a"
}
variable "security" {
  type    = string
  default = "security_groups"
}
variable "all_traffic" {
  type    = string
  default = "0.0.0.0/0"
}
variable "s3" {
  type    = string
  default = "gugugugagaga"
}

variable "lambda_filename" {
  type    = string
  default = "s3-lambda"
}
variable "s3_obj" {
  type    = string
  default = "test.zip"
}
