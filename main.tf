provider "aws" {
  region = "eu-west-2"
}

resource "aws_instance" "example" {
  ami = "ami-0f60b09eab2ef8366"
  instance_type = "t2.micro"
  subnet_id     = "subnet-01a52236a2c5bf299"
  tags {
    Name = "terraform-example"
  }

}

