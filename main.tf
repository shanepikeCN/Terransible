# Selecting region to deploy
provider "aws" {
  region = "us-east-1"
  access_key = "${var.access_key}" 
  secret_key = "${var.secret_key}"
}

# Setting up the SSH key
resource "aws_key_pair" "deployer" {
  key_name = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDvFLqaQN4zvLhC8QGbNI22LsHnq+o07XVr6fm9MTjuPzNqJ05Unc7mL7xrCg7NxzrrJuKsrb47AoV1t6qx4IdFrHpsB1Eq9QXRuEQiK3mCqCv8W7w/MC1CXEpmtsBVpcBAwQats25Vjs4MF2dzaVMJ+71RfC1LDn6C72DpgNACP9pU0oBaw8m56SHqaHefIWYXQNuKDlMbo423VsIy7SA6kIoT1OQp0Mm+XTgbDpQlQzfmHVZ4yJSW9tYjRR9WsQ14yZHoSyRq52zVRddeM9DEQRL8Jshao4HlWeE3M2U89Ikc4td8lLIQqVILzi/SOICVqmY+S4HZ4S0be6UBwG3F aws_terraform_ssh_key"
}

resource "aws_instance" "example" {
  ami = "ami-2d39803a"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.instance.id}"]
  key_name = "${var.key_pair}"
  user_data = <<-EOF
  	      #!/bin/bash
	      echo "Hello, World" > index.html
	      nohup busybox httpd -f -p "${var.server_port}" &
	      EOF


  tags {
    Name = "terraform-example"
  }
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
}

output "public_ip" {
  value = "${aws_instance.example.public_ip}"
}
