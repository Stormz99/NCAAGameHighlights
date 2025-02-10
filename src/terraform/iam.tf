# iam.tf

# Retrieve AWS account information
data "aws_caller_identity" "current" {}

# Define the trust relationship for ECS tasks
data "aws_iam_policy_document" "ecs_task_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Create the ECS task execution role
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.project_name}-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_trust.json
}

# Attach the AWS-managed ECS Task Execution policy
resource "aws_iam_role_policy_attachment" "ecs_task_execution_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Define a custom IAM policy for ECS
data "aws_iam_policy_document" "ecs_custom_doc" {
  statement {
    actions   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
    effect    = "Allow"
    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}",
      "arn:aws:s3:::${var.s3_bucket_name}/*"
    ]
  }

  statement {
    actions   = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParameterHistory"]
    effect    = "Allow"
    resources = [
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/*"
    ]
  }

  statement {
    actions   = ["mediaconvert:CreateJob", "mediaconvert:GetJob", "mediaconvert:ListJobs"]
    effect    = "Allow"
    resources = ["*"]
  }
}

# Create and attach the custom ECS IAM policy
resource "aws_iam_policy" "ecs_custom_policy" {
  name   = "${var.project_name}-ecs-custom-policy"
  policy = data.aws_iam_policy_document.ecs_custom_doc.json
}

resource "aws_iam_role_policy_attachment" "ecs_custom_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_custom_policy.arn
}

# Define MediaConvert IAM Role
data "aws_iam_policy_document" "mediaconvert_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["mediaconvert.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "mediaconvert_role" {
  name               = "${var.project_name}-mediaconvert-role"
  assume_role_policy = data.aws_iam_policy_document.mediaconvert_trust.json
}

# Define MediaConvert IAM Policy
data "aws_iam_policy_document" "mediaconvert_policy_doc" {
  statement {
    actions   = ["s3:GetObject", "s3:PutObject"]
    effect    = "Allow"
    resources = ["arn:aws:s3:::${var.s3_bucket_name}/*"]
  }

  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    effect    = "Allow"
    resources = ["arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.project_name}/*"]
  }
}

# Create and attach the MediaConvert IAM Policy
resource "aws_iam_policy" "mediaconvert_policy" {
  name   = "${var.project_name}-mediaconvert-policy"
  policy = data.aws_iam_policy_document.mediaconvert_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "mediaconvert_attach" {
  role       = aws_iam_role.mediaconvert_role.name
  policy_arn = aws_iam_policy.mediaconvert_policy.arn
}
