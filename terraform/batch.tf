########## Log Groups ##########
resource "aws_cloudwatch_log_group" "batch_log_group" {
  name              = "/aws/batch"
  retention_in_days = var.log_retention_period
}
########## Roles ##########
# Batch Execution Role
resource "aws_iam_role" "batch_execution_role" {
  name = "BatchExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "batch_execution_policy" {
  name = "BatchExecutionPolicy"
  role = aws_iam_role.batch_execution_role.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "batch_ecs_execution_policy" {
  role       = aws_iam_role.batch_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task Role
resource "aws_iam_role" "batch_job_role" {
  name = "BatchJobRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Compute Environment Role
resource "aws_iam_role" "aws_batch_service_role" {
  name = "AWSBatchServiceRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "batch.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "aws_batch_service_role" {
  role       = aws_iam_role.aws_batch_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

# ECR

data "aws_ecr_repository" "batch_job_repo" {
  name = var.batch_job_repo
}

########## Batch Resources ##########
# Batch Task Definition
resource "aws_batch_job_definition" "batch_job_definition" {
  name = var.batch_job_def_name
  type = "container"
  
  platform_capabilities = ["FARGATE",]

  container_properties = jsonencode({
    image       = "${data.aws_ecr_repository.batch_job_repo.repository_url}:latest"
    jobRoleArn  = aws_iam_role.batch_job_role.arn
    executionRoleArn = aws_iam_role.batch_execution_role.arn
    schedulingPriority = 1

    fargatePlatformConfiguration = {
      platformVersion = "LATEST"
    }

    "networkConfiguration": {
      "assignPublicIp": "ENABLED"
    },
        
    resourceRequirements = [
      {
        type  = "VCPU"
        value = "0.5"
      },
      {
        type  = "MEMORY"
        value = "1024"
      }
    ]

    environment = [
      {
        name  = "VARNAME"
        value = "VARVAL"
      }
    ]

    logConfiguration = {
      logDriver = "awslogs",
      options   = {
        "awslogs-group"         = aws_cloudwatch_log_group.batch_log_group.name,
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "/${var.batch_job_def_name}/logs"
      }
    }
  })
}

# Batch Job Queue
resource "aws_batch_job_queue" "fargate_job_queue" {
  name                 = var.batch_job_queue_name
  state                = "ENABLED"
  priority             = 1
  compute_environments = [aws_batch_compute_environment.fargate_compute_environment.arn]
}

# Batch Compute Environment
resource "aws_security_group" "compute_environment_security_group" {
  name   = "compute_environment_security_group"
  vpc_id = "vpc-021f46a7b92671d9c"

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_batch_compute_environment" "fargate_compute_environment" {
  compute_environment_name = "fargate_compute_environment"

  compute_resources {
    type                = "FARGATE"
    # type                = "FARGATE_SPOT"
    # allocation_strategy = "SPOT_CAPACITY_OPTIMIZED"
    subnets             = ["subnet-0bfeb088420ba498c", "subnet-034da439c79fb9c50"]
    security_group_ids  = [aws_security_group.compute_environment_security_group.id]
    min_vcpus           = 0
    max_vcpus           = 4
  }

  service_role = aws_iam_role.aws_batch_service_role.arn
  type         = "MANAGED"

  depends_on = [aws_iam_role_policy_attachment.aws_batch_service_role]
}
