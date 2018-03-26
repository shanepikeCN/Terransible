# Selecting region to deploy
provider "aws" {
  region = "${var.aws_region}"
# Using locally stored SSH keys
  shared_credentials_file = "~/.aws/credentials"
}

resource "aws_key_pair" "deployer" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

# Get list of availability zones
data "aws_availability_zones" "all" {}

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "wp_app" {
  instance_type = "${var.dev_instance_type}"
  ami           = "${var.dev_ami}"

  tags {
    Name = "wp_dev"
  }

  associate_public_ip_address = true
  key_name               = "${aws_key_pair.deployer.id}"
  vpc_security_group_ids = ["${aws_security_group.instance.id}"]
  #iam_instance_profile   = "${aws_iam_instance_profile.s3_access_profile.id}"
  #subnet_id                = "${aws_subnet.wp_public1_subnet.id}"

provisioner "local-exec" {
  command = <<EOF
  printf "[app]\n${aws_instance.wp_app.public_ip} private_ip=${aws_instance.wp_app.private_ip}\n" > aws_hosts
EOF
}

provisioner "local-exec" {
 command = "sleep 120; ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook --user=ubuntu --private-key keys/aws_terraform -i aws_hosts node.yml"
}

}

resource "aws_instance" "wp_lb" {
  instance_type = "${var.dev_instance_type}"
  ami           = "${var.dev_ami}"

  tags {
    Name = "wp_lb"
  }

  associate_public_ip_address = true
  key_name               = "${aws_key_pair.deployer.id}"
  vpc_security_group_ids = ["${aws_security_group.instance.id}"]
  #iam_instance_profile   = "${aws_iam_instance_profile.s3_access_profile.id}"
  #subnet_id                = "${aws_subnet.wp_public1_subnet.id}"

provisioner "local-exec" {
  command = <<EOF
  printf "[nginx]\n${aws_instance.wp_lb.public_ip}\n" >> aws_hosts
EOF
}

provisioner "local-exec" {
 command = "sleep 120; ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook --user=ubuntu --private-key keys/aws_terraform -i aws_hosts main.yml"
}

  depends_on = ["aws_instance.wp_app"]
}

resource "aws_launch_configuration" "centos7_alc" {
  image_id = "${var.dev_ami}" # Centos 7 AMI
  instance_type = "${var.dev_instance_type}"
  security_groups = ["${aws_security_group.instance.id}"]
  lifecycle {
    create_before_destroy = true
  }
}
/**

**/
# Creating launch configuration to be used for auto scaling groups
/**
resource "aws_launch_configuration" "centos7_alc" {
  image_id = "${var.dev_ami}" # Centos 7 AMI
  instance_type = "${var.dev_instance_type}"
  security_groups = ["${aws_security_group.instance.id}"]
  user_data = "${data.template_file.user_data.rendered}"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = "${aws_launch_configuration.centos7_alc.id}"
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
**/




/**
output "elb_dns_name" {
  value = "${aws_elb.example.dns_name}"
}
**/
output "lb_ip" {
  value = "${aws_instance.wp_lb.public_ip}"
}

output "app_ip" {
  value = "${aws_instance.wp_app.public_ip}"
}
