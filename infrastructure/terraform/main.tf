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
  availability_zone       = "us-east-2a"

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
  include_deprecated = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 1. Database Security Group
resource "aws_security_group" "db_access" {
  name        = "db-access-sg"
  description = "Allow MySQL traffic from Web Server"
  vpc_id      = aws_vpc.commerce_cloud.id

  # MySQL access only from the Web Security Group
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_access.id] 
  }

  # Allow SSH for management (optional, based on your lab needs)
  ingress {
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
}

# 1. Register the Public Key with AWS
resource "aws_key_pair" "lab_key" {
  key_name   = "vuln-lab-key"
  public_key = file("${path.module}/id_rsa.pub")
}

# 2. Update Web Server to use the key
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.ubuntu_16_04.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.lab_key.key_name # Associated Key
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_access.id]
  
  tags = { Name = "Legacy-Woo-Web" }
}

# 3. Update DB Server to use the same key
resource "aws_instance" "db_server" {
  ami                    = data.aws_ami.ubuntu_16_04.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.lab_key.key_name # Associated Key
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.db_access.id]

  tags = { Name = "Legacy-Woo-DB" }
}

# Capture the IP and write to a file
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    web_ip = aws_instance.web_server.public_ip,
    db_ip  = aws_instance.db_server.public_ip
  })
  filename = "${path.module}/../ansible/inventory.ini"
}
