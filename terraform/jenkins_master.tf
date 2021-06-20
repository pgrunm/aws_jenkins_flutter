# The task definition for our app.
resource "aws_ecs_task_definition" "jenkins_master" {
  family = "JenkinsThesisAwsDev"

  container_definitions = <<EOF
[
    {
        "name": "jenkins_master",
        "image": "falconone/jenkins_thesis:latest",
        "portMappings": [
            {
                "containerPort": 8080,
                "hostPort": 8080
            },
            {
                "containerPort": 50000,
                "hostPort": 50000
            }
        ],
        "environment": [
            {
                "name": "AGENT_EXECUTION_ROLE_ARN",
                "value": "${aws_iam_role.JenkinsThesisAwsDev-task-execution-role.arn}"
            },
            {
                "name": "AGENT_SECURITY_GROUP_ID",
                "value": "${aws_security_group.jenkins_agent.id},${aws_security_group.outbound.id},${aws_security_group.efs_jenkins_security_group.id}"
            },
            {
                "name": "AWS_REGION",
                "value": "${data.aws_region.current.name}"
            },
            {
                "name": "ECS_AGENT_CLUSTER",
                "value": "${aws_ecs_cluster.JenkinsThesisAwsDev.name}"
            },
            {
                "name": "JENKINS_URL",
                "value": "http://${aws_service_discovery_service.jenkins_master.name}.${aws_service_discovery_private_dns_namespace.jenkins_zone.name}:8080"
            },
            {
                "name": "LOG_GROUP_NAME",
                "value": "/ecs/${var.application_name}"
            },
            {
                "name": "PRIVATE_JENKINS_HOST_AND_PORT",
                "value": "http://${aws_service_discovery_service.jenkins_master.name}.${aws_service_discovery_private_dns_namespace.jenkins_zone.name}:50000"
            },
            {
                "name": "SUBNET_IDS",
                "value": "${aws_subnet.private[0].id}, ${aws_subnet.private[1].id}"
            },
            {
                "name": "JENKINS_USERNAME",
                "value": "${var.jenkins_accountname}"
            },
            {
                "name": "JENKINS_PASSWORD",
                "value": "${var.jenkins_pass}"
            }
        ],
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
                "awslogs-region": "eu-central-1",
                "awslogs-group": "/ecs/${var.application_name}",
                "awslogs-stream-prefix": "ecs"
            }
        }
    }
]
EOF
  # See here: https://stackoverflow.com/a/49947471
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
  execution_role_arn = aws_iam_role.JenkinsThesisAwsDev-task-execution-role.arn
  task_role_arn      = aws_iam_role.JenkinsThesisAwsDev-task-execution-role.arn

  # These are the minimum values for Fargate containers.
  cpu                      = 512
  memory                   = 1024
  requires_compatibilities = ["FARGATE"]

  # This is required for Fargate containers (more on this later).
  network_mode = "awsvpc"

  # Storage options for jenkins_home
  volume {
    name = "service-storage"

    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.jenkins_master_home.id
      root_directory          = "/var/jenkins_home"
      transit_encryption      = "ENABLED"
      transit_encryption_port = 2999
      authorization_config {
        access_point_id = aws_efs_access_point.jenkins_master_home.id
        iam             = "ENABLED"
      }
    }
  }
}

# DNS Resolution for Jenkins Master
resource "aws_service_discovery_service" "jenkins_master" {
  name = "master"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.jenkins_zone.id

    dns_records {
      ttl  = 60
      type = "A"
    }
    dns_records {
      ttl  = 60
      type = "SRV"
    }
    routing_policy = "MULTIVALUE"
  }
}

# Output the DNS Name of the Jenkins Master
output "Jenkins_master_dns_name" {
  value = "${aws_service_discovery_service.jenkins_master.name}.${aws_service_discovery_private_dns_namespace.jenkins_zone.name}"
}
