# Type of environment e. g. dev or prod
variable "environment" {
  description = "The name to use for the environment, used in Names etc."
  type        = string
  default     = "dev"
}

# Name of the Application
variable "application_name" {
  description = "The name of the application"
  type        = string
  default     = "jenkins_flutter_thesis"
}

# Output of the current region
data "aws_region" "current" {}

# Name of the Admin Account
variable "jenkins_accountname" {
  description = "The Jenkins Master Account"
  type        = string
  default     = "developer"
}

# Create a random password for the first login of the administrator account.
resource "random_string" "jenkins_pass" {
  length           = 20
  special          = true
  override_special = "/@\" "
}

variable "master_memory_amount" {
  default     = 1024
  description = "Soft RAM Limit for Jenkins Agent"
}

variable "master_cpu_amount" {
  default     = 512
  description = "Soft CPU Limit for Jenkins Agent"
}

variable "agent_memory_amount" {
  default     = 4096
  description = "Soft RAM Limit for Jenkins Agent"
}

variable "agent_cpu_amount" {
  default     = 2048
  description = "Soft CPU Limit for Jenkins Agent"
}

variable "s3_artifact_bucket_name" {
  default     = "jenkins-flutter-artifact-bucket"
  description = "Default Name for S3 Bucket where Jenkins stores artifacts"
}

variable "s3_folder_prefix_name" {
  default     = "jenkins_artifacts"
  description = "Default folder prefix for folder in the S3 Bucket where Jenkins stores artifacts"
}
