

```markdown
# Flask AWS S3 Bucket Content Viewer with Terraform Infrastructure

This project is a Flask web application that interacts with an AWS S3 bucket to list the contents of files and directories. The app is integrated with Terraform to manage the AWS infrastructure, including VPC, subnets, S3 bucket, Internet Gateway (IGW), Security Groups, and IAM User/Policy. The application demonstrates error handling, AWS CLI configuration, and Terraform commands.


## Project Overview
### Objective:
### Develop a Python Flask HTTP service that:

Lists the contents of an S3 bucket.
Allows interaction via HTTP GET requests.
### Infrastructure:
The service is deployed on an EC2 instance in AWS.
Terraform is used to automate the deployment of the EC2 instance, security groups, and other AWS resources like VPC, IGW, subnets, route table, IAM, and key pairs.

### Project Structure:
## HTTP Service (app.py):

A Flask application that exposes an endpoint /list-bucket-content to list the contents of a specified S3 bucket.
It interacts with AWS S3 using the Boto3 library.
## Terraform Infrastructure (main.tf):

Terraform provisions an EC2 instance, a VPC, Internet Gateway (IGW), subnets, route table, IAM, security groups, and key pairs.
Security groups are set up to allow HTTP traffic on port 80 and Flask application traffic on port 5000.
Terraform Outputs:

## Outputs the public IP address of the EC2 instance for accessing the service.
### Design Decisions
## Choice of HTTP Framework (Flask):

Flask was chosen because it is a lightweight Python web framework ideal for building small services like this one.
It is easy to set up, supports RESTful APIs, and integrates seamlessly with Boto3, making it easy to interact with AWS services like S3.
## Choice of Infrastructure (EC2 + Security Groups):

EC2 instance was selected over other services like AWS ECS for simplicity and cost-effectiveness, using a t2.micro instance that falls under the free-tier.
Security Groups were configured to allow inbound HTTP traffic on port 80 and Flask’s port 5000, ensuring public access to the application but limiting external traffic to essential ports.
## AWS S3 Interaction:

Boto3, the official AWS SDK for Python, was used to interact with S3. The list_objects_v2 method is utilized to retrieve the contents of the S3 bucket.
The application allows users to specify a path (prefix) to list objects under a given folder in the S3 bucket.
## Terraform Configuration:

Terraform is used to automate infrastructure provisioning, ensuring reproducibility and ease of deployment.
The EC2 instance is provisioned with a user-data script that installs Python, Flask, and Boto3, and automatically runs the Flask application upon launch.
Additionally, VPC, Internet Gateway (IGW), subnets, route table, IAM roles, and security groups are configured using Terraform.
## Security:

Security is managed by ensuring the EC2 instance only allows necessary traffic via security groups. Adding IAM roles for accessing S3 would improve security, rather than relying on manual credentials management.
## Error Handling:

The application handles various potential errors, such as missing credentials, S3 access issues, and general exceptions.
Error responses are returned as JSON objects with appropriate status codes to assist in debugging.



### Assumptions
## AWS Credentials:

AWS credentials are assumed to be configured in the local environment for both Terraform and Boto3 to interact with AWS services.
You should configure AWS CLI or set environment variables for AWS access.
## AMI Selection:

The AMI ID (ami-0c55b159cbfafe1f0) used in the Terraform script is for an Amazon Linux 2 instance in the us-east-1 region. This ID may need to be changed depending on the AWS region you deploy in.
## Security Groups:

The security group configuration opens ports 80 (HTTP) and 5000 (Flask app) to the public (0.0.0.0/0), suitable for development and testing purposes. For production environments, it is recommended to restrict access to specific IPs.

### Challenges Faced
## S3 Permissions:

One challenge was ensuring that the EC2 instance had the proper IAM role and permissions to interact with S3. setting up IAM roles is critical for better security.
### Security Groups and Network Configuration:

Managing the right security group settings for inbound and outbound traffic was key. By default, AWS blocks all inbound traffic, so configuring rules to allow HTTP and Flask ports was necessary.
For more secure deployments, a VPC (Virtual Private Cloud) with private subnets could be set up, especially if you’re handling sensitive data.


### Getting Started


## `Prerequisites`

Before setting up the project, ensure you have the following:

- **Python 3.7+**
- **Terraform** installed
- **AWS Account** with access to manage resources
- **Flask** and **boto3** libraries installed
- **AWS CLI** configured with your credentials
- **pip** for managing Python dependencies




## Step 1: Flask Application Development

## 1.1 Install Python Dependencies

1. create your project directory:

```bash
mkdir <project directory>

```


2. Install the required Python libraries:

```bash
pip install -r requirements.txt
```

### 1.2 `requirements.txt`

Create a `requirements.txt` file with the following content:

```bash
Flask==2.2.3
boto3==1.26.9
botocore==1.29.9
```

### 1.3 Create the Flask App (`app.py`)

Create a `app.py` file with the following content:

```python
from flask import Flask, jsonify
import boto3
from botocore.exceptions import NoCredentialsError, PartialCredentialsError, ClientError

app = Flask(__name__)

# Set up AWS S3 client
s3 = boto3.client('s3')

# Specify your S3 bucket name
BUCKET_NAME = 'python-app-terraform'  # Replace with your actual bucket name

@app.route('/')
def home():
    return "Welcome to the S3 Bucket Content Viewer!"

@app.route('/list-bucket-content/', defaults={'path': ''})
@app.route('/list-bucket-content/<path:path>', methods=['GET'])
def list_bucket_content(path):
    path = path.strip('/')  # Normalize path to remove leading/trailing slashes

    try:
        # List objects in the S3 bucket with the provided path prefix
        response = s3.list_objects_v2(Bucket=BUCKET_NAME, Prefix=path)

        # Check if the S3 bucket exists
        if 'Error' in response:
            return jsonify({"error": "Bucket does not exist or there was an issue accessing it"}), 404

        content = []
        if 'Contents' in response:
            for obj in response['Contents']:
                content.append(obj['Key'][len(path):].split('/')[0])  # Extract first-level dirs/files

        # Handle case where no content is found for the given path
        if not content:
            return jsonify({"error": f"No content found for path '{path}'"}), 404

        return jsonify({"content": content}), 200

    except NoCredentialsError:
        return jsonify({"error": "AWS credentials are missing"}), 403
    except PartialCredentialsError:
        return jsonify({"error": "Incomplete AWS credentials"}), 403
    except ClientError as e:
        # This will catch errors like permission issues, bucket not found, etc.
        error_code = e.response['Error']['Code']
        if error_code == 'NoSuchBucket':
            return jsonify({"error": f"Bucket '{BUCKET_NAME}' does not exist"}), 404
        elif error_code == 'AccessDenied':
            return jsonify({"error": "Access denied to the S3 bucket"}), 403
        else:
            return jsonify({"error": f"Client error: {str(e)}"}), 400
    except Exception as e:
        return jsonify({"error": f"An unexpected error occurred: {str(e)}"}), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
```

### 1.4 Flask App Explanation (`app.py`)

- **Flask setup**: The app is built using the Flask framework, a lightweight web framework for Python.
- **AWS S3 interaction**: The app uses the `boto3` library to interact with AWS S3. The `boto3.client('s3')` creates an S3 client that is used to fetch content from a specified S3 bucket.
- **Error handling**: The app includes several error handling mechanisms:
  - **NoCredentialsError**: If AWS credentials are missing or invalid.
  - **PartialCredentialsError**: If incomplete AWS credentials are provided.
  - **ClientError**: Handles specific S3 errors, such as access denial or bucket not found.
- **Route functionality**: The route `/list-bucket-content/<path:path>` lists the content of the specified S3 bucket path. If no content is found or there's an error, it returns a relevant error message in JSON format.

### 1.5 Run the Flask App

To run the Flask app:

```bash
python app.py
```

The Flask app will be accessible at `http://localhost:5000`.

### 1.6 Validate the Endpoints

Test the S3 content listing by visiting the following endpoints:

- `http://localhost:5000/list-bucket-content/`
- `http://localhost:5000/list-bucket-content/<path_to_folder>`

If the bucket or path exists, it will return the content of the folder.

### 1.7 Error Handling

The app implements error handling for common issues such as missing AWS credentials, access denial, non-existing buckets, and unexpected errors.

---

## Step 2: Terraform Configuration for AWS Infrastructure

Now, let's use Terraform to provision the necessary AWS infrastructure, including VPC, subnets, S3 bucket, Internet Gateway (IGW), Security Groups, and IAM User/Policy.

### 2.1 Install Terraform

To set up Terraform on your machine, follow these steps:

#### 2.1.1 Install Terraform on linux

```bash
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform
```


Verify the installation:

```bash
terraform version
```

### 2.2 Configure AWS CLI

1. Install the AWS CLI if you haven't already:

```bash
pip install awscli
```

2. Configure your AWS credentials by running:

```bash
aws configure
```

Provide the following details:
- **AWS Access Key ID**
- **AWS Secret Access Key**
- **Default region name** (e.g., `us-west-2`)
- **Default output format** (e.g., `json`)

Alternatively, you can configure your AWS credentials via environment variables or IAM roles if running on an EC2 instance.

### 2.3 Terraform Configuration Explanation (`main.tf`)

Create a `main.tf` file inside the `terraform` directory with the following content:

```hcl
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
    from_port   = 5000
    to_port     = 5000
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
        echo "Flask app started on port 5000."
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
```
2.4 Explanation of main.tf
Provider: The AWS provider block defines which region Terraform should manage resources in (e.g., us-west-2).

VPC: A Virtual Private Cloud (VPC) is created to define the network environment.

Subnets: A public subnet within the VPC is created where AWS resources can be launched.

S3 Bucket: A new S3 bucket (python-app-terraform) is created.

Internet Gateway: This allows communication between the VPC and the internet.

Security Group: The security group allows all inbound and outbound traffic for testing purposes.

IAM User/Policy: An IAM user (s3User) is created with full access to the S3 bucket, which is necessary for accessing the bucket from the Flask app.

Key Pair: A key pair is used for secure SSH access to the EC2 instance.

Route Table: A Route Table is configured to route traffic between subnets and the internet.


EC2 Instance: The EC2 instance is provisioned with a user-data script to install the necessary dependencies (Python, Flask, Boto3) and run the Flask app.

2.5 Run Terraform to Apply Configuration
Initialize Terraform:

```bash
terraform init

```
Apply the Terraform configuration:


```bash
terraform apply

```
This will create the necessary AWS resources. Confirm the prompt to proceed.

Confirm the prompt to proceed with creating the infrastructure.

---

## Step 3: Running the Flask Application

After applying the Terraform configuration,  run the Flask app and access the S3 bucket contents via the `/list-bucket-content/` endpoint.


Test the app at `http://<ip>:5000`.

---

## References

```

 -Terraform Documentation: https://www.terraform.io/docs
- Flask Documentation: https://flask.palletsprojects.com/
- AWS S3 Documentation: https://docs.aws.amazon.com/s3/index.html
```

This `README.md` file includes a step-by-step guide on setting up the application, configuring Terraform, and running the app with error handling and AWS integration. The references are provided .
