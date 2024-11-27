// aws console
provider "aws" {
  region = "eu-west-2"
}

// create keypair
// RSA key of size 4096 bits
resource "tls_private_key" "keypair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

// Creating private keypair file 
resource "local_file" "private_key" {
  content         = tls_private_key.keypair.private_key_pem
  filename        = "docker-key.pem"
  file_permission = "600"
}

// Creating Ec2 keypair
resource "aws_key_pair" "keypair" {
  key_name   = "docker-key"
  public_key = tls_private_key.keypair.public_key_openssh
}

// Security group for Docker
resource "aws_security_group" "docker_sg" {
  name        = "docker-sg"
  description = "Allow inbound traffic for Docker instance"

  ingress {
    description = "Allow application traffic"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH access"
    from_port   = 22
    to_port     = 22
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
    Name = "docker-sg"
  }
}

// Creating EC2 instance for Docker
resource "aws_instance" "docker_host" {
  ami                    = "ami-07d1e0a32156d0d21" // Red Hat AMI
  instance_type          = "t2.medium"
  vpc_security_group_ids = [aws_security_group.docker_sg.id]
  key_name               = aws_key_pair.keypair.key_name
  associate_public_ip_address = true
  user_data              = file("./docker-userdata.sh")

  tags = {
    Name = "docker-host"
  }
}

// Security group for Maven
resource "aws_security_group" "maven_sg" {
  name        = "maven-sg"
  description = "Security group for Maven instance"

  ingress {
    description = "Allow SSH access"
    from_port   = 22
    to_port     = 22
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
    Name = "maven-sg"
  }
}

// Creating EC2 instance for Maven
resource "aws_instance" "maven_host" {
  ami                    = "ami-07d1e0a32156d0d21" // Red Hat AMI
  instance_type          = "t2.medium"
  vpc_security_group_ids = [aws_security_group.maven_sg.id]
  key_name               = aws_key_pair.keypair.key_name
  associate_public_ip_address = true
  user_data              = file("./maven-userdata.sh")

  tags = {
    Name = "maven-host"
  }
}

// Outputs
output "docker-ip" {
  value = aws_instance.docker_host.public_ip
}

output "maven-ip" {
  value = aws_instance.maven_host.public_ip
}
