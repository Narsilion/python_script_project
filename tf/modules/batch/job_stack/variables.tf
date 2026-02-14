variable "name" {
  type        = string
  description = "Base name for Batch resources."
}

variable "region" {
  type        = string
  description = "AWS region for logging configuration."
}

variable "image" {
  type        = string
  description = "Container image URI (usually ECR)."
}

variable "command" {
  type        = list(string)
  description = "Default command for the Batch job definition."
  default     = ["python", "/app/main.py"]
}

variable "vcpu" {
  type        = number
  description = "vCPU for each job (Fargate-compatible values)."
  default     = 0.25
}

variable "memory" {
  type        = number
  description = "Memory (MiB) for each job (Fargate-compatible values)."
  default     = 512
}

variable "max_vcpus" {
  type        = number
  description = "Maximum vCPUs that the compute environment can scale to."
  default     = 8
}

variable "compute_resource_type" {
  type        = string
  description = "Batch compute resource type for Fargate workloads."
  default     = "FARGATE_SPOT"

  validation {
    condition     = contains(["FARGATE", "FARGATE_SPOT"], var.compute_resource_type)
    error_message = "compute_resource_type must be either FARGATE or FARGATE_SPOT."
  }
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for Batch Fargate tasks."
  default     = []
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security groups for Batch Fargate tasks."
  default     = []
}

variable "security_group_name" {
  type        = string
  description = "Fallback security group name used when IDs are not passed."
  default     = "test-sg"
}

variable "assign_public_ip" {
  type        = bool
  description = "Assign public IP to Fargate task ENI."
  default     = true
}

variable "log_group_name" {
  type        = string
  description = "CloudWatch log group name."
  default     = null
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log retention days."
  default     = 30
}
