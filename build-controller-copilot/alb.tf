resource "aws_security_group" "alb" {
  count       = var.create_alb ? 1 : 0
  name        = "Aviatrix ALB Security Group"
  description = "Aviatrix ALB Security Group"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.incoming_ssl_cidr
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "Aviatrix ALB Security Group"
  }
}

resource "aws_lb" "alb" {
  count              = var.create_alb ? 1 : 0
  name               = "Aviatrix-ALB"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb[0].id]
  subnets            = [aws_subnet.subnet.id, aws_subnet.subnet_ha.id]
  idle_timeout       = 3600
}

resource "aws_lb_target_group" "controller" {
  count       = var.create_alb ? 1 : 0
  name        = "Aviatrix-Target-Group"
  port        = 443
  protocol    = "HTTPS"
  target_type = "ip"
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_lb_target_group_attachment" "attachment" {
  count            = var.create_alb ? 1 : 0
  target_group_arn = aws_lb_target_group.controller[0].arn
  target_id        = module.aviatrix-controller-build.private_ip
}

resource "aws_lb_listener" "listener" {
  count             = var.create_alb ? 1 : 0
  load_balancer_arn = aws_lb.alb[0].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.controller[0].arn
  }
}

output "alb_dns_name" {
  value = var.create_alb ? aws_lb.alb[0].dns_name : null
}