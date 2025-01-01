# Provider Configuration
provider "aws" {
  region = "ap-south-1" # Specify your AWS region
}

# Create VPC
resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "MyVPC"
  }
}

# Create Subnet
resource "aws_subnet" "my_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a" # Change to a supported zone
  map_public_ip_on_launch = true # Enable public IP assignment for instances
  tags = {
    Name = "MySubnet"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "MyInternetGateway"
  }
}

# Create Route Table
resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
  tags = {
    Name = "MyRouteTable"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "my_route_table_association" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my_route_table.id
}

# Create Security Group
resource "aws_security_group" "my_security_group" {
  vpc_id = aws_vpc.my_vpc.id
  name   = "AllowHTTPandSSH"

  # Allow HTTP (port 80)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH (port 22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow Flask App (port 5000)
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "MySecurityGroup"
  }
}

# Create Key Pair
resource "aws_key_pair" "my_key_pair" {
  key_name   = "my-key-pair"
  public_key = file("~/.ssh/id_rsa.pub") # Replace with the correct path to your public key
}

# Create IAM Role for EC2
resource "aws_iam_role" "ec2_role" {
  name = "EC2_S3_Access_Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach S3 and EC2 Policies to IAM Role
resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.ec2_role.name
}

resource "aws_iam_role_policy_attachment" "attach_ec2_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  role       = aws_iam_role.ec2_role.name
}

# Create IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "EC2InstanceProfile"
  role = aws_iam_role.ec2_role.name
}




# Create S3 Bucket
resource "aws_s3_bucket" "my_bucket" {
  bucket = "python-app-terraform"  # Replace with a globally unique name for your bucket

  # Optional settings for the bucket (can be omitted if you don't need them)
  #acl    = "private"  # Sets the ACL for the bucket, options: private, public-read, etc.

  versioning {
    enabled = true  # Enables versioning for the bucket (optional)
  }

  tags = {
    Name        = "MyS3Bucket"
    Environment = "Dev"
  }
}




# Create EC2 Instance
resource "aws_instance" "app_server" {
  ami           = "ami-0fd05997b4dff7aac" # Replace with the latest Amazon Linux 2 AMI ID
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.my_subnet.id
  key_name      = aws_key_pair.my_key_pair.key_name

  vpc_security_group_ids = [aws_security_group.my_security_group.id]

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  # availability_zone = "ap-south-1a"
  associate_public_ip_address = true

  user_data = <<-EOF

    #!/bin/bash
    sudo su
    # Sleep for 120 seconds to wait for instance initialization
    sleep 120

    

    # System Update
     yum update -y

    # Install Python 3 and pip3
     yum install -y python3
     yum install python3-pip -y

    # Install Flask and Boto3
    pip3 install flask boto3

    # Install Git
    yum install -y git

    # Clone the app repository from GitHub
    mkdir -p /home/ec2-user/app
    cd /home/ec2-user/app
    git clone https://github.com/tarun-code/python_app.git

    # Change ownership
    chown -R ec2-user:ec2-user /home/ec2-user/app

    # Change to app directory and start Flask application
    cd /home/ec2-user/app/python_app
    sleep 120
    # Create a systemd service for Flask

  
    if ! pgrep -f "python3 app.py" > /dev/null
    then
        nohup python3 app.py &
        echo "Flask app started on port 8000."
    else
        echo "Flask app already running."
    fi
  EOF


  tags = {
    Name = "Flask-App-Server"
  }
}


# Output the S3 bucket name
output "s3_bucket_name" {
  value = aws_s3_bucket.my_bucket.bucket
}



# Output EC2 Public IP
output "ec2_public_ip" {
  value = aws_instance.app_server.public_ip
}
