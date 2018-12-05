
variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default = "8080"
}

#Display public-ip without pocking around in AWS console
output "public_ip" {
  value = "${aws_instance.example.public_ip}"
}


provider "aws" {
  region = "eu-west-2"
}




resource "aws_security_group" "instance"{
  name = "terraform-example-instance"

  ingress {
    from_port = "${var.server_port}"
    protocol = "tcp"
    to_port = "${var.server_port}"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



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

