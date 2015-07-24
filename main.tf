variable "vpc_id" {}
variable "ami" {}
variable "ssh_key" {}
variable "subnet_id" {}
variable "name" {}
variable "environment" {}
variable "roles" {}
variable "project" {}

variable "instance_type" {
  default = "m3.medium"
}

variable "instance_count" {
  default = "1"
}

variable "additional_security_group_ids" {
  default = " "
}


resource "aws_security_group" "ssh_traffic" {
  name = "${var.name}-${var.environment}-ssh_traffic"
  vpc_id = "${var.vpc_id}"
  description = "Allow all inbound traffic to port 22"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "node_security_group" {
  name = "${var.name}-${var.environment}-node"
  vpc_id = "${var.vpc_id}"
  description = "Indentifier security group for access"
}

resource "aws_instance" "web" {
  ami = "${var.ami}"
  instance_type = "${var.instance_type}"
  key_name = "${var.ssh_key}"
  subnet_id = "${var.subnet_id}"
  count = "${var.instance_count}"
  associate_public_ip_address = true

  vpc_security_group_ids = ["${split(",", replace("${aws_security_group.ssh_traffic.id},${aws_security_group.node_security_group.id},${var.additional_security_group_ids}", ", ", ""))}"]

  tags {
    Name = "${var.name} Web ${count.index+1} ${var.environment}"
    Project = "${var.project}"
    Roles = "${var.roles}"
    Stage = "${var.environment}"
  }
}

output "instance_ids" {
  value = "${join(",", aws_instance.web.*.id)}"
}

output "instance_security_group_id" {
  value = "${aws_security_group.node_security_group.id}"
}
