output "compute_environment_arn" {
  description = "Batch compute environment ARN."
  value       = aws_batch_compute_environment.this.arn
}

output "job_queue_arn" {
  description = "Batch job queue ARN."
  value       = aws_batch_job_queue.this.arn
}

output "job_queue_name" {
  description = "Batch job queue name."
  value       = aws_batch_job_queue.this.name
}

output "job_definition_arn" {
  description = "Batch job definition ARN (latest revision)."
  value       = aws_batch_job_definition.this.arn
}

output "job_definition_name" {
  description = "Batch job definition name."
  value       = aws_batch_job_definition.this.name
}

output "task_execution_role_arn" {
  description = "Execution role ARN used by Batch jobs."
  value       = aws_iam_role.task_execution.arn
}
