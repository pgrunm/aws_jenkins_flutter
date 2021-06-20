output "AGENT_EXECUTION_ROLE_ARN" {

  value = aws_iam_role.JenkinsThesisAwsDev-task-execution-role.arn

}

output "AGENT_SECURITY_GROUP_ID" {
  value = aws_security_group.jenkins_agent.name
}

output "ECS_AGENT_CLUSTER" {
  value = aws_ecs_cluster.JenkinsThesisAwsDev.name
}


# "LOG_GROUP_NAME" : "/ecs/${var.application_name}",
output "PRIVATE_JENKINS_HOST_AND_PORT" {
  value = "${aws_service_discovery_service.jenkins_master.name}.${aws_service_discovery_private_dns_namespace.jenkins_zone.name}:50000"
}

output "JENKINS_USERNAME" {
  value = var.jenkins_accountname
}

output "Application_name" {
  description = "Output of the application name"
  value       = var.application_name
}

output "type_of_environment" {
  description = "Output of the environment name"
  value       = var.environment
}

output "AWS_Region" {
  description = "Output of region used"
  value       = data.aws_region.current.name
}

output "vpc_id" {
  value = aws_vpc.app-vpc.id
}

output "Jenkins_ALB_URL" {
  description = "URL of the AWS Load Balancer"
  value = "http://${aws_alb.jenkins.dns_name}"
}
