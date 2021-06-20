provider "aws" {
  region = "eu-central-1"
}

# We need a cluster in which to put our service.
resource "aws_ecs_cluster" "JenkinsThesisAwsDev" {
  name = var.application_name
}

# Log groups hold logs from our app.
resource "aws_cloudwatch_log_group" "JenkinsThesisAwsDev" {
  name = "/ecs/${var.application_name}"
  # Delete Logs after 7 days
  retention_in_days = 7

  # Write the environment into tags
  tags = {
    "Environment" = var.environment
  }
}

# The main service.
resource "aws_ecs_service" "JenkinsThesisAwsDev" {
  name            = "ecs_service_${var.application_name}"
  task_definition = aws_ecs_task_definition.jenkins_master.arn
  cluster         = aws_ecs_cluster.JenkinsThesisAwsDev.id
  launch_type     = "FARGATE"

  # Require service version 1.4.0!
  platform_version = "1.4.0"

  desired_count = 1

  # Register the master and the port in dns
  service_registries {
    registry_arn = aws_service_discovery_service.jenkins_master.arn
    port         = 50000
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.jenkins.arn
    container_name   = "jenkins_master"
    container_port   = 8080
  }

  network_configuration {
    assign_public_ip = false

    security_groups = [
      aws_security_group.outbound.id,
      aws_security_group.efs_jenkins_security_group.id,
      aws_security_group.jenkins.id
    ]

    subnets = [
      aws_subnet.private[0].id,
      aws_subnet.private[1].id,
    ]
  }
}
