
variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default = "8080"
}

#Display public-ip without pocking around in AWS console
/*
output "public_ip" {
  value = "${aws_instance.example.public_ip}"
}
*/


//Display DNS name of the ELB
output "elb_dns_name" {
  value = "${aws_elb.example.dns_name}"
}

data "aws_availability_zones" "all" {}

provider "aws" {
  region = "eu-west-2"
}




resource "aws_security_group" "instance"{
  name = "terraform-example-instance2"

  ingress {
    from_port = "${var.server_port}"
    protocol = "tcp"
    to_port = "${var.server_port}"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

/*
resource "aws_instance" "example" {
  ami = "ami-0f60b09eab2ef8366"
  instance_type = "t2.micro"
  subnet_id     = "subnet-01a52236a2c5bf299"
  vpc_security_group_ids = ["${aws_security_group.instance.id}"]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF

  tags {
    Name = "terraform-example"
  }

}
*/

resource "aws_launch_configuration" "example" {
  image_id = "ami-0f60b09eab2ef8366"
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.instance.id}"]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = "${aws_launch_configuration.example.id}"
  availability_zones = ["${data.aws_availability_zones.all.names}"]


  load_balancers = ["${aws_elb.example.name}"]
  health_check_type = "ELB"

  max_size = 10
  min_size = 2
  tag {
    key = "Name"
    propagate_at_launch = true
    value = "terraform-asg-example"
  }
}


//Security group to permit access to port 80
//Allow helathcheck on egress
resource "aws_security_group" "elb" {
  name = "terraform-example-elb"

  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

}

//Create elb to receive HTTP requests on port 80
resource "aws_elb" "example" {
  name = "terraform-asg-example"
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  security_groups = ["${aws_security_group.elb.id}"]

  "listener" {
    instance_port = "${var.server_port}"
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  //Health check block sends HTTP request every 30 seconds to the "/" URL of each of the EC2 instancesin the ASG
  health_check {
    healthy_threshold = 2
    interval = 30
    target = "HTTP:${var.server_port}/"
    timeout = 3
    unhealthy_threshold = 2
  }
}



