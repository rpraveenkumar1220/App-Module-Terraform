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
  monitoring {
    enabled = true
  }
  vpc_security_group_ids = [aws_security_group.SG.id]

  user_data = base64decode(templatefile("${path.module}/userdata.sh", {
    env = var.env
    component = var.component
  }))
}


### Creating Auto Scaling Group using the above template  ###





#### Creating DNS records
resource "aws_route53_record" "dns" {
  zone_id = "Z0860624TQ63X2IAQS8P"
  name    = "${var.component}-${var.env}"
  type    = "A"
  ttl     = 30
  records = [aws_instance.instance.private_ip]
}













/*
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
}
*/
