
data "aws_ami" "ami" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-*"]
  }
}

resource "aws_security_group" "sg" {
  name   = "${var.name}-sg"
  vpc_id = var.vpc_id
  tags = {
    Name = "${var.name}-sg"
  }
}

resource "aws_security_group_rule" "ingress" {
  type              = "ingress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg.id
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg.id
}

resource "aws_network_interface" "nic" {
  subnet_id       = var.subnet_id
  security_groups = [aws_security_group.sg.id]
  private_ips     = var.private_ip == null ? null : [var.private_ip]
  tags = {
    Name = "${var.name}-nic"
  }
}

resource "aws_eip" "eip" {
  vpc = true
  tags = {
    Name = "${var.name}-eip"
  }
}

resource "aws_eip_association" "eip-association" {
  network_interface_id = aws_network_interface.nic.id
  allocation_id        = aws_eip.eip.id
  depends_on = [
    aws_instance.instance
  ]
}

resource "aws_instance" "instance" {
  ami           = data.aws_ami.ami.image_id
  instance_type = var.instance_type
  key_name      = var.key_name
  network_interface {
    network_interface_id = aws_network_interface.nic.id
    device_index         = 0
  }
  user_data = var.user_data
  tags = {
    Name = "${var.name}"
  }
}