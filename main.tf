
provider "aws" {
  region = "ap-south-1"  # You can change to your desired AWS region
}

resource "aws_s3_bucket" "bucket" {
  bucket = "python-app-terraform"  # Replace with your actual bucket name
}

resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow HTTP inbound traffic"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "app_server" {
  ami           = "ami-0fd05997b4dff7aac"  # Replace with the latest Amazon Linux 2 AMI ID
  instance_type = "t2.micro"
  security_groups = [aws_security_group.allow_http.name]

  # Install dependencies and start the Flask app
  user_data = <<-EOF
 #!/bin/bash
# Update the instance

 sleep 60

 sudo su 
 sudo yum update -y

# Install Python 3 and pip
sudo yum install python3 -y

# Install Flask and Boto3 for Python
sudo pip3 install flask boto3

# (Optional) Install Git if you're pulling the app from GitHub
sudo yum install git -y

cd /home/ec2-user/
mkdir app
cd app/

# Clone your application repository if it is on GitHub (example)
 git clone https://github.com/tarun-code/python_app.git 

# Start the application using Flask (assuming app.py is in the specified location)
nohup python3 /home/ec2-user/app.py &

# Ensure the app starts in the background
echo "App started"


              EOF
}

output "ec2_public_ip" {
  value = aws_instance.app_server.public_ip
}
