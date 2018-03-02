# Selecting region to deploy
provider "aws" {
  region = "${var.aws_region}"
  shared_credentials_file = "/root/.aws/credentials"
}

# Setting up the SSH key
resource "aws_key_pair" "deployer" {
  key_name = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDSfaPktvPwiMmWPLtjMu9hjiYzHgE1lP0a995M6E86yGkyxnFe7ZAksaD+nNm2awUeYK1I1txGSzW878yCamypto3Z1458o1tfIc9Lsp5MUfsBKKqpYn8jYqCXIxZAmHPhnZWIGY5i7sX99/oFR9zZpISNWJLQ6e///PbfmNMkAwW/iqy0AdZdXHPn7jzj3skn0KY2UI1Hb9viFfStTWvkkZ/Y3xACjKTUTtfMar/4lmRhjWv1BXi/ZJ8jR5sRcN/c4YUgE7J93d756joivoOeny2MB/pl+h6VLR1HBaAL8L/11/ZWC7FanUL7W4eTF/ePHih+uuk0bs85uTXxzxCN aws_terraform_ssh_key"
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
