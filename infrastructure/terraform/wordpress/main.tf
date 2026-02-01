provider "aws" {
  region = "us-east-2"
}

resource "aws_vpc" "commerce_cloud" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "commerce-cloud-vpc"
  }
}

# 2. Create the Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.commerce_cloud.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true # Ensures your instance gets a Public IP
  availability_zone       = "us-east-2"

  tags = { Name = "commerce-cloud-subnet" }
}

# Internet Gateway (The "Door" to the internet)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.commerce_cloud.id
}

# 4. Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.commerce_cloud.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# 5. Associate Route Table with Subnet
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "web_access" {
  name        = "web-access-sg"
  description = "Allow SSH, HTTP, HTTPS, and Ping"
  vpc_id      = aws_vpc.commerce_cloud.id

  # SSH (22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Recommendation: Limit this to your IP
  }

  # HTTP (80)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS (443)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ping (ICMP Echo Request)
  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Essential: Allow all outbound traffic (Egress)
  # Without this, your instance cannot download updates or talk to the internet.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Look up the latest Ubuntu 16.04 AMI
data "aws_ami" "ubuntu_16_04" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Launch the EC2 Instance
resource "aws_instance" "legacy_server" {
  ami           = data.aws_ami.ubuntu_16_04.id
  instance_type = "t3.micro" # Note: Avoid newer Nitro-only families like m7g

  tags = {
    Name = "Legacy-Ubuntu-16.04"
  }
}

# Capture the IP and write to a file
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tftpl", {
    ip_address = aws_instance.legacy_server.public_ip
  })
  filename = "${path.module}/inventory.ini"
}
