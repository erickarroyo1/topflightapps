resource "aws_ecs_cluster" "this" {
  name = "${var.app}-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags     = local.common_tags
  provider = aws.landing-zone-account
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.app}/${terraform.workspace}"
  retention_in_days = 90
  tags              = local.common_tags
  provider          = aws.landing-zone-account
}

# Credentials are injected by ECS at task start via "secrets" (valueFrom).
# They never appear in the task definition, in `describe-task-definition`
# output, or in Terraform plan diffs.
resource "aws_ecs_task_definition" "this" {
  family                   = "${var.app}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = var.app
      image     = var.container_image
      essential = true

      portMappings = [{
        containerPort = 8080
        hostPort      = 8080
        protocol      = "tcp"
      }]

      environment = [
        { name = "DB_NAME", value = var.db_name },
        { name = "DB_HOST", value = data.terraform_remote_state.rds.outputs.endpoint_rds },
        { name = "DB_PORT", value = tostring(data.terraform_remote_state.rds.outputs.rds_port) }
      ]

      secrets = [
        { name = "DB_USERNAME", valueFrom = "${data.terraform_remote_state.rds.outputs.db_secret_arn}:username::" },
        { name = "DB_PASSWORD", valueFrom = "${data.terraform_remote_state.rds.outputs.db_secret_arn}:password::" }
      ]

      readonlyRootFilesystem = true
      linuxParameters = {
        initProcessEnabled = true
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.app.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags     = local.common_tags
  provider = aws.landing-zone-account
}

resource "aws_ecs_service" "this" {
  name            = "${var.app}-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = var.app
    container_port   = 8080
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }

  network_configuration {
    subnets          = data.terraform_remote_state.network.outputs.private_subnets
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  tags     = local.common_tags
  provider = aws.landing-zone-account
}

# ---------------------------------------------------------------------------
# IAM: two roles with different jobs.
#   execution role -> what ECS itself needs: pull image, write logs, read the secret to inject it
#   task role      -> what the application code needs at runtime (nothing, today)
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "ecs_tasks_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "ecs_execution" {
  name               = "${var.app}-${terraform.workspace}-ecs-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
  tags               = local.common_tags
  provider           = aws.landing-zone-account
}

resource "aws_iam_role_policy_attachment" "ecs_execution_managed" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  provider   = aws.landing-zone-account
}

data "aws_iam_policy_document" "read_db_secret" {
  statement {
    sid       = "ReadDbSecret"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [data.terraform_remote_state.rds.outputs.db_secret_arn]
  }
}

resource "aws_iam_role_policy" "ecs_execution_secret" {
  name     = "read-db-secret"
  role     = aws_iam_role.ecs_execution.id
  policy   = data.aws_iam_policy_document.read_db_secret.json
  provider = aws.landing-zone-account
}

resource "aws_iam_role" "ecs_task" {
  name               = "${var.app}-${terraform.workspace}-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
  tags               = local.common_tags
  provider           = aws.landing-zone-account
}
