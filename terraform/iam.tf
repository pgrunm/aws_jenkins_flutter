
# This is the role under which ECS will execute our task. This role becomes more important
# as we add integrations with other AWS services later on.

# The assume_role_policy field works with the following aws_iam_policy_document to allow
# ECS tasks to assume this role we're creating.
resource "aws_iam_role" "JenkinsThesisAwsDev-task-execution-role" {
  name               = "${var.application_name}-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs-task-assume-role.json
}

data "aws_iam_policy_document" "ecs-task-assume-role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Normally we'd prefer not to hardcode an ARN in our Terraform, but since this is an AWS-managed
# policy, it's okay.
data "aws_iam_policy" "ecs-task-execution-role" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Attach the above policy to the execution role.
resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-default" {
  role       = aws_iam_role.JenkinsThesisAwsDev-task-execution-role.name
  policy_arn = data.aws_iam_policy.ecs-task-execution-role.arn
}


# Attach the required permissions to the Jenkins Task
resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-jenkins" {
  role       = aws_iam_role.JenkinsThesisAwsDev-task-execution-role.name
  policy_arn = aws_iam_policy.jenkins_agents.arn
}

# Data Policy for Jenkins Master to start new Jenkins Agents
# https://stackoverflow.com/questions/62831874/terrafrom-aws-iam-policy-document-condition-correct-syntax
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#condition
data "aws_iam_policy_document" "jenkins_master" {
  statement {
    actions = [
      "ecs:RegisterTaskDefinition",
      "ecs:ListClusters",
      "ecs:DescribeContainerInstances",
      "ecs:ListTaskDefinitions",
      "ecs:DescribeTaskDefinition",
      "ecs:DeregisterTaskDefinition",
    ]
    resources = ["*"]
    effect    = "Allow"
  }

  # Listing of Container Instances
  statement {
    actions   = ["ecs:ListContainerInstances"]
    effect    = "Allow"
    resources = [aws_ecs_cluster.JenkinsThesisAwsDev.arn]
  }
  # Run Tasks in ECS
  statement {
    actions   = ["ecs:RunTask"]
    effect    = "Allow"
    resources = ["arn:aws:ecs:${data.aws_region.current.name}:526531137161:task-definition/*"]
    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"
      values = [
        aws_ecs_cluster.JenkinsThesisAwsDev.arn
      ]
    }
  }

  statement {
    actions = ["ecs:StopTask"]
    effect  = "Allow"
    resources = [
      "arn:aws:ecs:*:*:task/*",
      "arn:aws:ecs:${data.aws_region.current.name}:526531137161:task/*"
    ]
    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"
      values = [
        aws_ecs_cluster.JenkinsThesisAwsDev.arn
      ]
    }
  }
  statement {
    actions = ["ecs:DescribeTasks"]
    effect  = "Allow"
    resources = [
      "arn:aws:ecs:*:*:task/*",
      "arn:aws:ecs:${data.aws_region.current.name}:526531137161:task/*"
    ]
    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"
      values = [
        aws_ecs_cluster.JenkinsThesisAwsDev.arn
      ]
    }
  }

  statement {
    actions   = ["iam:GetRole", "iam:PassRole"]
    effect    = "Allow"
    resources = [aws_iam_role.JenkinsThesisAwsDev-task-execution-role.arn]
  }
}

# Policy for Jenkins Master to start new Jenkins Agents
# https://stackoverflow.com/questions/62831874/terrafrom-aws-iam-policy-document-condition-correct-syntax
resource "aws_iam_policy" "jenkins_agents" {

  description = "Allows the Jenkins master to start new agents."
  name        = "${var.application_name}_ecs_policy"

  # Policy
  # Hint: Curly braces may not be indented otherwise Terraform fails
  policy = data.aws_iam_policy_document.jenkins_master.json
}

# Password for Jenkins Access
# resource "aws_secretsmanager_secret" "jenkins_secret" {
#   name        = "JenkinsPassword"
#   description = "Initial password for Jenkins."
# }
