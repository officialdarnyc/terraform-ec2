terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

resource "aws_key_pair" "jenkins-ec2-key" {
  key_name   = "jenkins-ec2-key"
  public_key = file("key.pub")

}

resource "aws_security_group" "jenkins-ec2-sg" {
  name        = "jenkins-ec2-sg"
  description = "Allow HTTP, HTTPS, and SSH traffic"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "JenkinsServer"
  }
}

resource "aws_instance" "jenkins-ec2" {
  ami           = "ami-0892d3c7ee96c0bf7"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.jenkins-ec2-key.key_name

  tags = {
    Name = "JenkinsServer"
  }

  vpc_security_group_ids = [
    aws_security_group.jenkins-ec2-sg.id
  ]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("key.pem")
    host        = self.public_ip
  }

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_type = "gp2"
    volume_size = 30
  }

}

resource "aws_eip" "eip-jenkins-ec2" {
  vpc      = true
  instance = aws_instance.jenkins-ec2.id
}
