# network.tf
resource "aws_vpc" "app-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.app-vpc.id
  count             = length(var.public_subnets)
  cidr_block        = var.public_subnets[count.index]
  availability_zone = var.azs[count.index]
}

# Internet GW
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.app-vpc.id

  tags = {
    Name        = var.application_name,
    Environment = var.environment
  }
}

resource "aws_route_table" "route" {
  vpc_id = aws_vpc.app-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "Gatewayroute for ${var.application_name}: ${var.environment} environment"
  }
}

# resource "aws_route_table_association" "public" {
#   subnet_id      = aws_subnet.public[count.index].id
#   route_table_id = aws_route_table.route.id
#   count          = length(var.public_subnets)
# }

# Private Subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.app-vpc.id
  count             = length(var.private_subnets)
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.azs[count.index]
}

# NAT Stuff

# Elastic IP for NAT
resource "aws_eip" "nat" {
  vpc   = true
  count = 2
}

resource "aws_nat_gateway" "ngw" {
  subnet_id     = aws_subnet.public[count.index].id
  allocation_id = aws_eip.nat[count.index].id
  count         = length(var.public_subnets)
  depends_on    = [aws_internet_gateway.gw]
}

# Routing

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.app-vpc.id
  count  = length(var.public_subnets)
  tags = {
    "Name" = "Route Table for Public Subnet ${count.index}"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.app-vpc.id
  count  = length(var.private_subnets)
  tags = {
    "Name" = "Route Table for Private Subnet ${count.index}"
  }
}

# Routing Table Association
resource "aws_route_table_association" "public_subnet" {
  subnet_id      = aws_subnet.public[count.index].id
  count          = length(var.public_subnets)
  route_table_id = aws_route_table.public[count.index].id
}

resource "aws_route_table_association" "private_subnet" {
  subnet_id      = aws_subnet.private[count.index].id
  count          = length(var.private_subnets)
  route_table_id = aws_route_table.private[count.index].id
}

# Creating the Network Routes
resource "aws_route" "public_igw" {
  count                  = length(var.public_subnets)
  gateway_id             = aws_internet_gateway.gw.id
  route_table_id         = aws_route_table.public[count.index].id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "private_ngw" {
  count                  = length(var.private_subnets)
  nat_gateway_id         = aws_nat_gateway.ngw[count.index].id
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_security_group" "https" {
  name        = "Incoming HTTP"
  description = "HTTP and HTTPS traffic for ${var.environment} environment of ${var.application_name}"
  vpc_id      = aws_vpc.app-vpc.id

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Outbound TCP Connections to Jenkins Master"
    from_port   = 8080
    protocol    = "TCP"
    to_port     = 8080
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "jenkins" {
  name        = "Jenkins Master"
  description = "Allows traffic to Jenkins Master."
  vpc_id      = aws_vpc.app-vpc.id
  # HTTP Alternative
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "TCP"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.https.id]
  }
  ingress {
    from_port   = 50000
    to_port     = 50000
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "jenkins_agent" {
  name        = "Jenkins Agents"
  description = "Allows traffic to Jenkins Agents."
  vpc_id      = aws_vpc.app-vpc.id

  # Allow Incoming Traffic on JLNP Port -> 50000
  ingress {
    description = "Allows JLNP Traffic"
    from_port   = 50000
    protocol    = "tcp"
    self        = true
    to_port     = 50000
  }

  tags = {
    "Environment" = var.environment
    "Application" = var.application_name
  }
}

resource "aws_security_group" "outbound" {
  name        = "Outbound Traffic"
  description = "Allow any outbound traffic for ${var.environment} environment of ${var.application_name}"
  vpc_id      = aws_vpc.app-vpc.id

  # Any Outbound connections allowing
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# DNS Resolution for local zone
resource "aws_service_discovery_private_dns_namespace" "jenkins_zone" {
  name        = "jenkins.local"
  description = "DNS Resolution for ${var.application_name}: ${var.environment} environment"
  vpc         = aws_vpc.app-vpc.id
}

# Load Balancer
resource "aws_lb_target_group" "jenkins" {
  name                 = "Jenkins"
  port                 = 8080
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = aws_vpc.app-vpc.id
  deregistration_delay = 10

  health_check {
    enabled = true
    path    = "/login"
    port    = "8080"
  }

  depends_on = [aws_alb.jenkins]
}

resource "aws_alb" "jenkins" {
  name               = "Jenkins"
  internal           = false
  load_balancer_type = "application"

  subnets = [
    aws_subnet.public[0].id,
    aws_subnet.public[1].id,
  ]

  security_groups = [
    aws_security_group.https.id,
  ]

  depends_on = [aws_internet_gateway.gw]
}

resource "aws_alb_listener" "jenkins_listener" {
  load_balancer_arn = aws_alb.jenkins.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jenkins.arn
  }
}
