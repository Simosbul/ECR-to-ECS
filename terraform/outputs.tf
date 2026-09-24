output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution.arn
}