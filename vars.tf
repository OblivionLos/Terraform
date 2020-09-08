variable "region" {
  default = "us-east-2"
}
variable "vpc_cidr" {
  default = "190.160.0.0/16"
}
variable "enable_dns_support" {
  default = "true"
}
variable "enable_dns_hostnames" {
  default = "true"
}
variable "aws_id" {
  default = " YOUR ID "
}
variable "aws_key" {
  default = "YOUR SECRET KEY"
}
variable "password" {
  default = "PASSWORD FOR DATABASE (8 characters)"
}
variable "default_az" {
  default = "us-east-2a"
}
