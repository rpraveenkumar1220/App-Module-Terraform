#### Creating security groups
resource "aws_security_group" "SG" {
  name        = "${var.component}-${var.env}-sg"
  description = "${var.component}-${var.env}-sg"
  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
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

#### Creating EC2 instances with security groups
resource "aws_instance" "instance" {
  ami           = data.aws_ami.ami.id
  instance_type = "t3.small"
  vpc_security_group_ids = [ aws_security_group.SG.id]
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name

  tags = {
    Name = "${var.component}-${var.env}"
  }
}

#### Creating DNS records
resource "aws_route53_record" "dns" {
  zone_id = "Z0860624TQ63X2IAQS8P"
  name    = "${var.component}-${var.env}"
  type    = "A"
  ttl     = 30
  records = [aws_instance.instance.private_ip]
}

#### Creating IAM policy for parameter store in systems manager
resource "aws_iam_policy" "policy" {
  name        = "${var.component}-${var.env}-ssm-pm-policy"
  path        = "/"
  description = "${var.component}-${var.env}-ssm-pm-policy"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "VisualEditor0",
        "Effect": "Allow",
        "Action": [
          "ssm:GetParameterHistory",
          "ssm:GetParametersByPath",
          "ssm:GetParameters",
          "ssm:GetParameter"
        ],
        "Resource": "arn:aws:ssm:us-east-1:751367052640:parameter/roboshop.${var.env}.${var.component}.*"
      }
    ]
  })
}


######  Creating IAM role
resource "aws_iam_role" "role" {
  name = "${var.component}-${var.env}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

##### Creating instance profile for ec2
resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.component}-${var.env}-ec2-profile"
  role = aws_iam_role.role.name
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








