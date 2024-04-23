resource "aws_iam_policy" "ecs_task_execution_policy" {
  count       = var.airflow_ecs_role == null ? 1 : 0
  name        = "pol-ecs-task-execution"
  description = "Policy for ECS Task Execution"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:GetAuthorizationToken",
        "ecr:GetDownloadUrlForLayer"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:Describe*",
        "logs:Get*",
        "logs:List*",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": [
          "ecs:ExecuteCommand",
          "ecs:DescribeTasks"
        ],
        "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": [
            "ssm:StartSession",
            "ssm:TerminateSession",
            "ssm:DescribeSessions",
            "ssm:GetConnectionStatus",
            "ssmmessages:CreateControlChannel",
            "ssmmessages:CreateDataChannel",
            "ssmmessages:OpenControlChannel",
            "ssmmessages:OpenDataChannel"
        ],
        "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": [
            "s3:*"
        ],
        "Resource": [
            "arn:aws:s3:::${var.s3_bucket_name}",
            "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
    }
  ]
}
EOF
}

resource "aws_iam_role" "role_ecs_task_execution" {
  count                = var.airflow_ecs_role == null ? 1 : 0
  name                 = "role-ecs-task-execution"
  assume_role_policy   = var.airflow_ecs_role == null ? data.aws_iam_policy_document.role_ecs_task_execution_assume_policy[0].json : ""
  max_session_duration = 3600
}

data "aws_iam_policy_document" "role_ecs_task_execution_assume_policy" {
  count = var.airflow_ecs_role == null ? 1 : 0
  statement {
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "role_ecs_task_execution_attach" {
  count      = var.airflow_ecs_role == null ? 1 : 0
  role       = aws_iam_role.role_ecs_task_execution[0].name
  policy_arn = aws_iam_policy.ecs_task_execution_policy[0].arn
}
