resource "aws_security_group" "efs_jenkins_security_group" {
  name        = "efs_access"
  description = "Allows efs access from jenkins master to efs storage on port 2049 for ${var.environment} environment."
  vpc_id      = aws_vpc.jenkins-vpc.id

  #   EFS default port
  ingress {
    description = "EFS access"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    # security_groups = [aws_security_group.efs_jenkins_security_group.id]
    # Self is required to allow access for this group on EFS storage
    self = "true"
  }
}

# Create the EFS Storage
resource "aws_efs_file_system" "jenkins_master_home" {
  creation_token = "jenkins_master"

  tags = {
    Name        = "jenkins_master"
    environment = var.environment
  }
}

# Create the EFS Mount Target
resource "aws_efs_mount_target" "jenkins_master_home" {
  file_system_id  = aws_efs_file_system.jenkins_master_home.id
  subnet_id       = aws_subnet.public.id
  security_groups = [aws_security_group.efs_jenkins_security_group.id]
}

resource "aws_efs_access_point" "jenkins_master_home" {
  file_system_id = aws_efs_file_system.jenkins_master_home.id
  posix_user {
    uid = 1000
    gid = 1000
  }

  root_directory {
    path = "/jenkins-home"

    # Create the path with this rights, if it does not exist.
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = 755
    }
  }
}

# S3 Bucket for Artifact Storage
resource "aws_s3_bucket" "jenkins_artifact_storage" {
  bucket = var.s3_artifact_bucket_name
  acl    = "private"

  tags = {
    Name        = var.s3_artifact_bucket_name
    Environment = var.environment
  }
}
