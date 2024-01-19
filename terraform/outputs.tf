output "app" {
  value = aws_emrserverless_application.basic.id
}

output "executor" {
  value = aws_iam_role.emr_serverless.arn
}