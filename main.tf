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

#S3_access

resource "aws_iam_instance_profile" "s3_access_profile" {
  name = "s3_access"
  role = "${aws_iam_role.s3_access_role.name}"
}

resource "aws_iam_role_policy" "s3_access_policy" {
  name = "s3_access_policy"
  role = "${aws_iam_role.s3_access_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "s3_access_role" {
  name = "s3_access_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
  {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
  },
      "Effect": "Allow",
      "Sid": ""
      }
    ]
}
EOF
}





/*
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

# Security group for load balancer
resource "aws_security_group" "elb" {
  name = "terraform-example-elb"

  # Allow outgoing traffic
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow incoming traffic to port 80
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  min_size = 2
  max_size = 2

  # Register instances with ASG
  load_balancers = ["${aws_elb.example.name}"]
  health_check_type = "ELB"


  tag {
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
}

# Adding load balancer for EC2 instances
resource "aws_elb" "example" {
  name = "terraform-asg-example"
  security_groups = ["${aws_security_group.elb.id}"]
  availability_zones = ["${data.aws_availability_zones.all.names}"]
 
  # Health check will check port 8080 on EC2 instances every 30 seconds 
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:${var.server_port}/"
  }

  
  # LB will listen on port 80 and direct traffic to EC2 instances
  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "${var.server_port}"
    instance_protocol = "http"
  }
}

#resource "aws_instance" "example" {
#  ami = "ami-2d39803a"
#  instance_type = "t2.micro"
#  vpc_security_group_ids = ["${aws_security_group.instance.id}"]
#  user_data = "${data.template_file.user_data.rendered}"
#  key_name = "deployer-key"

#  tags {
#    Name = "terraform-example"
#  }
#}



#output "public_ip" {
#  value = "${aws_instance.example.public_ip}"
#}

output "elb_dns_name" {
  value = "${aws_elb.example.dns_name}"
}
*/
