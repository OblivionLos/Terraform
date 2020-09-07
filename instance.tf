provider "aws" {
  version = "~> 3.5.0"
  region  = var.region
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_db_instance" "default" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "pepega"
  username             = "pepega"
  password             = var.password
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = "true"
}

resource "aws_key_pair" "example" {
  key_name   = "examplekey"
  public_key = file("~/.ssh/terraform.pub")
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 3.0"

  name        = "example"
  description = "Security group for example usage with EC2 instance"
  vpc_id      = data.aws_vpc.default.id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["all-all"]
  egress_rules        = ["all-all"]
}

resource "aws_instance" "example" {
  key_name = aws_key_pair.example.key_name
  ami = "ami-0010d386b82bc06f0"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids = [
    module.security_group.this_security_group_id]

  connection {
    type        = "ssh"
    host        = aws_instance.example.public_ip
    user        = "ec2-user"
    private_key = file("~/.ssh/terraform")
    #depends_on = aws_instance.example
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get upgrade -y",
      "sudo apt install -y software-properties-common python3 python3-pip",
      "sudo apt-add-repository --yes --update ppa:ansible/ansible",
      "sudo apt install ansible",
      "mkdir ~/files && cd ~/files",
      "pip install awscli",
      "aws configure",
      "var.aws_id",
      "var.aws_key",
      "var.region",
      "json",
      "aws s3 cp s3://wordpressfiles/wordpress.yaml ~/files/wordpress.yaml",
      "ansible-playbook wordpress.yaml"
    ]
  }
}
