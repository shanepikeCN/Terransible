variable "aws_profile" {
  default = "superhero"
}
variable "server_port" {
	description = "The port the servers will use for HTTP requests"
	default = "8080"
}
variable "aws_region" {
  default = "us-east-1"
}
variable "key_pair" {
  default = "deployer-key"
}

