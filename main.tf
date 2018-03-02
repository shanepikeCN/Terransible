# Selecting region to deploy
provider "aws" {
  region = "${var.aws_region}"
# Using locally stored SSH keys
  shared_credentials_file = "/root/.aws/credentials"
}

# Setting up the SSH key
resource "aws_key_pair" "deployer" {
  key_name = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDSfaPktvPwiMmWPLtjMu9hjiYzHgE1lP0a995M6E86yGkyxnFe7ZAksaD+nNm2awUeYK1I1txGSzW878yCamypto3Z1458o1tfIc9Lsp5MUfsBKKqpYn8jYqCXIxZAmHPhnZWIGY5i7sX99/oFR9zZpISNWJLQ6e///PbfmNMkAwW/iqy0AdZdXHPn7jzj3skn0KY2UI1Hb9viFfStTWvkkZ/Y3xACjKTUTtfMar/4lmRhjWv1BXi/ZJ8jR5sRcN/c4YUgE7J93d756joivoOeny2MB/pl+h6VLR1HBaAL8L/11/ZWC7FanUL7W4eTF/ePHih+uuk0bs85uTXxzxCN aws_terraform_ssh_key"
}

# Get list of availability zones
data "aws_availability_zones" "all" {}


# Runs bootstrap shell script when EC2 instance is created
data "template_file" "user_data" {
  template = "${file("bootstrap.sh")}"
}

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
	from_port = "${var.server_port}"
	to_port = "${var.server_port}"
	protocol = "tcp"
	cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
	from_port = "22"
	to_port = "22"
	protocol = "tcp"
	cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Creating launch configuration to be used for auto scaling groups
resource "aws_launch_configuration" "example" {
  image_id = "ami-2d39803a"
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.instance.id}"]
  user_data = "${data.template_file.user_data.rendered}"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = "${aws_launch_configuration.example.id}"
  min_size = 2
  max_size = 2
  tag {
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
}

resource "aws_instance" "example" {
  ami = "ami-2d39803a"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.instance.id}"]
  user_data = "${data.template_file.user_data.rendered}"
  key_name = "deployer-key"

  tags {
    Name = "terraform-example"
  }
}



output "public_ip" {
  value = "${aws_instance.example.public_ip}"
}
