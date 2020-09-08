provider "aws" {
  version = "~> 3.5.0"
  region  = var.region
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "az1" {
  availability_zone = var.default_az
}

resource "aws_security_group" "allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow ssht http inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Http from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self = true
  }

  tags = {
    Name = "allow_ssh_http"
  }
}

resource "aws_security_group" "allow_3306" {
  name        = "allow_3306"
  description = "Allow 3306 inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "3306 from VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [data.aws_subnet.az1.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self = true
  }

  tags = {
    Name = "allow_3306"
  }
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
  vpc_security_group_ids = ["${aws_security_group.allow_3306.id}"]
}

resource "aws_key_pair" "example" {
  key_name   = "examplekey"
  public_key = file("~/.ssh/terraform.pub")
}

resource "aws_instance" "example" {
  key_name = aws_key_pair.example.key_name
  ami = "ami-0010d386b82bc06f0"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids = [
    "${aws_security_group.allow_ssh_http.id}"]
  subnet_id = data.aws_subnet.az1.id
}
resource "null_resource" "ansible" {
  triggers = {
    cluster_instance = aws_db_instance.default.id
  }

  connection {
    type        = "ssh"
    host        = aws_instance.example.public_ip
    user        = "ubuntu"
    private_key = file("~/.ssh/terraform")
  }
  provisioner "local-exec" {
    command = "echo DB_HOSTNAME: ${aws_db_instance.default.address} >> ~/TTT/variables.yml"
  }
  provisioner "local-exec" {
    command = "echo DB_PORT: ${aws_db_instance.default.port} >> ~/TTT/variables.yml"
  }
  provisioner "local-exec" {
    command = "echo DB_NAME: ${aws_db_instance.default.name} >> ~/TTT/variables.yml"
  }
  provisioner "local-exec" {
    command = "echo DB_USERNAME: ${aws_db_instance.default.username} >> ~/TTT/variables.yml"
  }
  provisioner "local-exec" {
    command = "echo DB_PASSWORD: ${aws_db_instance.default.password} >> ~/TTT/variables.yml"
  }
  provisioner "file"{
    source = "~/TTT"
    destination = "~/"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get upgrade -y",
      "sudo apt install -y software-properties-common python3 python3-pip mysql-client-core-5.7",
      "sudo apt-add-repository --yes --update ppa:ansible/ansible",
      "sudo apt install -y ansible",
      "export ANSIBLE_CONFIG=~/ansible/ansible.cfg",
      "cd ~/TTT",
      "ansible-playbook -c local site.yml -e@variables.yml"
    ]
  }
}

output "pubIP" {
  value = aws_instance.example.public_ip
}
