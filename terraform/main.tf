data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "dorm-app-vpc"
  }
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "dorm-app-igw"
  }
}

resource "aws_subnet" "main_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "dorm-app-public-subnet"
  }
}

resource "aws_route_table" "main_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "dorm-app-rt"
  }
}

resource "aws_route_table_association" "main_rta" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_rt.id
}

resource "aws_security_group" "web_sg" {
  name        = "allow_web"
  description = "Allow HTTP and SSH inbound traffic"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Next.js App from anywhere (Fallback)"
    from_port   = 3001
    to_port     = 3001
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
    Name = "dorm-app-web-sg"
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.main_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
#!/bin/bash
set -ex
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

export DEBIAN_FRONTEND=noninteractive

# --- Create Swap Space to prevent Next.js build Out-Of-Memory errors ---
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile none swap sw 0 0" >> /etc/fstab
# -----------------------------------------------------------------------

apt-get update -y
apt-get install -y git curl iptables iptables-persistent

# Install Node.js 20.x
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Install PM2
npm install -g pm2

# Clone the repository
cd /home/ubuntu
git clone ${var.github_repo} app
cd app

# Create .env.local file
cat <<EOT > .env.local
NEXT_PUBLIC_SUPABASE_URL=https://mkiptuvunpismpkawgwj.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_DEFAULT_KEY=sb_publishable_8O4EbF9HlnM2t5F3-z1Q-Q_DOdCqEEH
NEXT_PUBLIC_SUPABASE_ANON_KEY=sb_publishable_8O4EbF9HlnM2t5F3-z1Q-Q_DOdCqEEH
CRON_SECRET=DormitorySecretCronTokenWinai
EOT

# Set correct ownership for ubuntu user
chown -R ubuntu:ubuntu /home/ubuntu/app

# Install dependencies and build as ubuntu user
sudo -u ubuntu bash -c 'cd /home/ubuntu/app && npm install'
sudo -u ubuntu bash -c 'cd /home/ubuntu/app && npm run build'

# Start the application using PM2 on port 3001
sudo -u ubuntu bash -c 'cd /home/ubuntu/app && pm2 start npm --name "dorm-app" -- run start'
sudo -u ubuntu bash -c 'pm2 save'

# Redirect port 80 to 3001 so it's accessible directly by IP
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 3001
netfilter-persistent save

EOF

  tags = {
    Name = "dorm-app-web-server"
  }
}
