variable "aws_region" {}
variable "aws_profile" {}
variable "server_port" {
	description = "The port the servers will use for HTTP requests"
}
variable "access_key" {}
variable "secret_key" {}
variable "key_pair" {
  default = "deployer-key"
}
