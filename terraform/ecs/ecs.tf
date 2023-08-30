resource "aws_ecs_cluster" "topflightapp_ecs_cluster" {
  name     = "topflightapp_ecs_cluster"
  tags     = local.common_tags
  provider = aws.landing-zone-account
}

resource "aws_ecs_task_definition" "topflightapp-task-definition" {
  family                   = "topflightapp-task-definition"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  cpu                      = "256"
  memory                   = "512"
  container_definitions = jsonencode([
    {
      "name" : "topflightapp",
      "image" : "public.ecr.aws/s0p7h2p1/topflightappdemo:v3",
      "cpu" : 0,
      "memory" : 512,
      "portMappings" : [
        {
          "name" : "topflightapp-8080-tcp",
          "containerPort" : 8080,
          "hostPort" : 8080,
          "protocol" : "tcp",
          "appProtocol" : "http"
        }
      ],
      "essential" : true,
      "environment" : [
        {
          "name" : "DB_NAME",
          "value" : "db"
        },
        {
          "name" : "DB_USERNAME",
          "value" : data.terraform_remote_state.rds.outputs.rds_username
        },
        {
          "name" : "DB_HOST",
          "value" : data.terraform_remote_state.rds.outputs.endpoint_rds
        },
        {
          "name" : "DB_PORT",
          "value" : tostring(data.terraform_remote_state.rds.outputs.rds_port)
        },
        {
          "name" : "DB_PASSWORD",
          "value" : aws_secretsmanager_secret_version.topflightapp_db_password_secret_version.secret_string
        }
      ],
      "environmentFiles" : [],
      "mountPoints" : [],
      "volumesFrom" : [],
      "ulimits" : [],
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-create-group" : "true",
          "awslogs-group" : "/ecs/TopflightappV3",
          "awslogs-region" : "us-east-1",
          "awslogs-stream-prefix" : "ecs"
        },
        "secretOptions" : []
      }
    }
  ])

  tags     = local.common_tags
  provider = aws.landing-zone-account
}

resource "aws_ecs_service" "topflightsvc" {
  name            = "topflightsvc"
  cluster         = aws_ecs_cluster.topflightapp_ecs_cluster.id
  task_definition = aws_ecs_task_definition.topflightapp-task-definition.arn
  desired_count   = 2

  load_balancer {
    target_group_arn = aws_alb_target_group.topflight-tg_alb.arn
    container_name   = "topflightapp"
    container_port   = 8080
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }

  network_configuration {
    subnets         = [data.terraform_remote_state.network.outputs.private_subnets[0], data.terraform_remote_state.network.outputs.private_subnets[1]]
    security_groups = [aws_security_group.ecs_sg.id]
  }

  tags     = local.common_tags
  provider = aws.landing-zone-account
}



#Policies and roles

resource "aws_iam_role" "ecs_execution" {
  name = "ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  # Attach the AmazonECSTaskExecutionRolePolicy managed policy
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]
  tags     = local.common_tags
  provider = aws.landing-zone-account
}

resource "aws_iam_policy" "secret_manager_access_policy" {
  depends_on  = [aws_secretsmanager_secret_version.topflightapp_db_password_secret_version]
  name        = "SecretManagerAccessPolicy"
  description = "Allows access to a specific Secret Manager resource"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = "secretsmanager:GetSecretValue",
        Effect   = "Allow",
        Resource = aws_secretsmanager_secret_version.topflightapp_db_password_secret_version.arn
      }
    ]
  })
  tags     = local.common_tags
  provider = aws.landing-zone-account
}

resource "aws_iam_role_policy_attachment" "secret_manager_access_attachment" {
  policy_arn = aws_iam_policy.secret_manager_access_policy.arn
  role       = aws_iam_role.ecs_execution.name
  provider   = aws.landing-zone-account
}

