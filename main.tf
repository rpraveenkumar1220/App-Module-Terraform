#### Creating security groups for app components
resource "aws_security_group" "SG" {
  name        = "${var.component}-${var.env}-sg"
  description = "${var.component}-${var.env}-sg"
  vpc_id = var.vpc_id
  ingress {
    from_port        = var.app_port
    to_port          = var.app_port
    protocol         = "tcp"
    cidr_blocks      = var.sg_subnet_cidr
  }
  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = var.allow_ssh_cidr
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.component}-${var.env}-sg"
  }
}


### Creating launch template for Auto Scaling Group #####
resource "aws_launch_template" "lt" {
  name = "${var.component}-${var.env}-lt"
  iam_instance_profile {
    name = aws_iam_instance_profile.instance_profile.name
  }
  image_id      = data.aws_ami.ami.id
  instance_type = var.instance_type
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.component}-${var.env}"
    }
  }
  vpc_security_group_ids = [aws_security_group.SG.id]

  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    env       = var.env
    component = var.component
  }))
}




#### Creating DNS records
resource "aws_route53_record" "dns" {
  zone_id = "Z0860624TQ63X2IAQS8P"
  name    = "${var.component}-${var.env}"
  type    = "CNAME"
  ttl     = 30
  records = [var.lb_dns_name]
}



### Creating Auto Scaling Group using the above template  ###
resource "aws_autoscaling_group" "asg" {
  name = "${var.component}-${var.env}-asg"
  desired_capacity   = var.desired_capacity
  max_size           = var.max_size
  min_size           = var.min_size
  vpc_zone_identifier = var.subnets
  target_group_arns = [aws_lb_target_group.lbtg.arn]

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }
}


### Creating a Target group for the load balancer  #####
resource "aws_lb_target_group" "lbtg" {
  name     = "${var.component}-${var.env}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled = true
    interval = 5
    path = "/health"
    port = var.app_port
    protocol = "HTTP"
    timeout = 4
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}



resource "aws_lb_listener_rule" "ls_rule" {
  listener_arn = var.listener_arn
  priority     = var.lb_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lbtg.arn
  }


  condition {
    host_header {

      values = ["${var.component}-${var.env}.devopskumar.site"]
    }
  }
}



/*
resource "aws_security_group" "SG" {
  name        = "${var.component}-${var.env}-sg"
  description = "${var.component}-${var.env}-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = var.allow_ssh_cidr
  }


  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.component}-${var.env}-sg"
  }
}

resource "aws_instance" "Test" {
  instance_type = "t3.micro"
  ami = data.aws_ami.ami.id
  vpc_security_group_ids = [aws_security_group.SG.id]
  subnet_id = var.subnet_id
  tags = {
    Name = "Test"
  }
}



#### Creating EC2 instances with security groups
resource "aws_instance" "instance" {
  ami           = data.aws_ami.ami.id
  instance_type = var.instance_type
  vpc_security_group_ids = [ aws_security_group.SG.id]
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name
  subnet_id = var.subnet_id
  tags = {
    Name = "${var.component}-${var.env}"
  }
}

#### creating a null resource to run the provisioner block
resource "null_resource" "ansible" {
  depends_on = [aws_instance.instance, aws_route53_record.dns]
  provisioner "remote-exec" {

    connection {
      type     = "ssh"
      user     = "centos"
      password = "DevOps321"
      host     = aws_instance.instance.public_ip
    }

    inline = [
      "sudo labauto ansible",
      "ansible-pull -i localhost, -U https://github.com/rpraveenkumar1220/Roboshop-Ansible.git  roboshop.yml -e env=${var.env} -e role_name=${var.component}"
    ]
  }
}*/
