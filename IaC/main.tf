provider "aws" {
  region = "eu-west-3"
}

variable "app_image" {}
variable "app_port" {}
variable "vpc_cidr_block" {}
variable "subnet_cidr_block" {}
variable "avail_zone" {}

resource "aws_ecs_cluster" "app_cluster" {
  name = "testAppCluster"
}

resource "aws_vpc" "myapp_vpc" {
    cidr_block = var.vpc_cidr_block
    tags = {
        Name = "app-vpc"
    }
}

resource "aws_subnet" "public_subnet" {
    vpc_id = aws_vpc.myapp_vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
    tags = {
        Name = "app-subnet"
    }
}

resource "aws_internet_gateway" "app_igw" {
    vpc_id = aws_vpc.myapp_vpc.id
    tags = {
        Name = "app-igw"
    }
}

resource "aws_default_route_table" "app-rtb" {
    default_route_table_id = aws_vpc.myapp_vpc.default_route_table_id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.app_igw.id
    }
    tags = {
        Name = "app-rtb"
    }
}

resource "aws_default_security_group" "app_sg" {
    vpc_id = aws_vpc.myapp_vpc.id

    # application
    ingress {
        from_port = 5000
        to_port = 5000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = []
    }
}

resource "aws_ecs_task_definition" "app_task_def" {
  family = "app_task"
  # execution_role_arn = "arn:aws:iam::091537710292:user/capstoneProject"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  cpu = 1024
  memory = 8192
  container_definitions = <<TASK_DEFINITION
    [
      {
        "essential": true,
        "image": "${var.app_image}",
        "name": "app_container",
        "portMappings": [
          {
            "containerPort": ${var.app_port},
            "hostPort": ${var.app_port}
          }
        ]
      }
    ]
  TASK_DEFINITION
}

resource "aws_ecs_service" "app_task" {
  name = "my_app"
  cluster = aws_ecs_cluster.app_cluster.id
  desired_count = 1
  task_definition = aws_ecs_task_definition.app_task_def.id
  force_new_deployment = true
  network_configuration {
    subnets = [aws_subnet.public_subnet.id]
    # assign_public_ip = true
    security_groups = [aws_default_security_group.app_sg.id]
  }
}

resource "aws_ecs_task_set" "app_tasks" {
  cluster = aws_ecs_cluster.app_cluster.id
  service = aws_ecs_service.app_task.id
  task_definition = aws_ecs_task_definition.app_task_def.id
  count = 1
  launch_type = "FARGATE"
  network_configuration {
    subnets = [aws_subnet.public_subnet.id]
    security_groups = [aws_default_security_group.app_sg.id]
    assign_public_ip = true
  }
}

# output "ecs_ip" {
#   value = aws_ecs_task_set.app_tasks[0]
# #   value = aws_ecs_service.app_task.network_configuration[0].public_ip
# }
