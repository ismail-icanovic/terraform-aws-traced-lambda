output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.this.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.this.function_name
}

output "lambda_role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.this.arn
}

output "lambda_role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.this.name
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.this.name
}

output "layer_arn" {
  description = "ARN of the shared layer (if enabled)"
  value       = var.use_shared_layer ? aws_lambda_layer_version.shared[0].arn : null
}

output "alias_arn" {
  description = "ARN of the Lambda alias (if created)"
  value       = var.create_alias ? aws_lambda_alias.this[0].arn : null
}
