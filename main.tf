provider "aws" {
  access_key = "${var.AWS_ACCESS_KEY_ID}"
  secret_key = "${var.AWS_SECRET_ACCESS_KEY}"
  region     = "${var.AWS_REGION}"
}

provider "circleci" {
  api_token    = "${var.CIRCLECI_API_TOKEN}"
  vcs_type     = "${var.CIRCLECI_VCS_TYPE}"
  organization = "${var.CIRCLECI_ORGANIZATION}"
}

####### LOCALS #######

locals {
  aws_ecs_cluster_name = "${var.AWS_RESOURCE_NAME_PREFIX}-cluster"
  aws_alb_security_group_name = "${var.AWS_RESOURCE_NAME_PREFIX}-alb-security-group"
  aws_alb_name = "${var.AWS_RESOURCE_NAME_PREFIX}-alb"
  aws_vpc_name = "${var.AWS_RESOURCE_NAME_PREFIX}-vpc"
  aws_public_subnet_name = "${var.AWS_RESOURCE_NAME_PREFIX}-public-subnet"
  aws_private_subnet_name = "${var.AWS_RESOURCE_NAME_PREFIX}-private-subnet"
  aws_gateway_name = "${var.AWS_RESOURCE_NAME_PREFIX}-gateway"
  aws_nat_gateway_name = "${var.AWS_RESOURCE_NAME_PREFIX}-nat_gateway"
}



####### NETWORK #######

resource "aws_vpc" "default" {
  cidr_block = "10.32.0.0/16"

  tags = {
    Name = "${local.aws_vpc_name}"
  }
}

data "aws_availability_zones" "available_zones" {
  state = "available"
}

resource "aws_subnet" "public" {
  count                   = 2
  cidr_block              = cidrsubnet(aws_vpc.default.cidr_block, 8, 2 + count.index)
  availability_zone       = data.aws_availability_zones.available_zones.names[count.index]
  vpc_id                  = aws_vpc.default.id
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.aws_public_subnet_name}-${count.index}"
  }
}

resource "aws_subnet" "private" {
  count             = 2
  cidr_block        = cidrsubnet(aws_vpc.default.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available_zones.names[count.index]
  vpc_id            = aws_vpc.default.id

  tags = {
    Name = "${local.aws_private_subnet_name}-${count.index}"
  }
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.default.id

  tags = {
    Name = "${local.aws_gateway_name}"
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.default.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gateway.id
}

resource "aws_eip" "gateway" {
  count      = 2
  vpc        = true
  depends_on = [aws_internet_gateway.gateway]
}

resource "aws_nat_gateway" "gateway" {
  count         = 2
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  allocation_id = element(aws_eip.gateway.*.id, count.index)

  tags = {
    Name = "${local.aws_nat_gateway_name}-${count.index}"
  }
}

resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.gateway.*.id, count.index)
  }
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}



####### APPLICATION LOAD BALANCER #######

resource "aws_security_group" "alb_security_group" {
  name        = "${local.aws_alb_security_group_name}"
  vpc_id      = aws_vpc.default.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "default" {
  name            = "${local.aws_alb_name}"
  subnets         = aws_subnet.public.*.id
  security_groups = [aws_security_group.alb_security_group.id]
}



####### ECS CLUSTER #######

resource "aws_ecs_cluster" "main" {
  name = "${local.aws_ecs_cluster_name}"
}



####### CIRCLE CI #######


resource "circleci_context" "aws" {
  name  = "aws"
}

resource "circleci_context_environment_variable" "aws" {
  for_each = {
    AWS_ACCESS_KEY_ID = "${var.AWS_ACCESS_KEY_ID}"
    AWS_SECRET_ACCESS_KEY = "${var.AWS_SECRET_ACCESS_KEY}"
    AWS_DEFAULT_REGION = "${var.AWS_REGION}"
  }

  variable   = each.key
  value      = each.value
  context_id = circleci_context.aws.id
}


