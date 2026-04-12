variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "handler" {
  description = "Handler for the Lambda function"
  type        = string
  default     = "app.handler"
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.13"
  validation {
    condition     = contains(["python3.12", "python3.13", "python3.14"], var.runtime)
    error_message = "Runtime must be one of: python3.12, python3.13, python3.14."
  }
}

variable "architecture" {
  description = "Lambda architecture"
  type        = string
  default     = "arm64"
  validation {
    condition     = contains(["arm64", "x86_64"], var.architecture)
    error_message = "Architecture must be either arm64 or x86_64."
  }
}

variable "memory_size" {
  description = "Memory allocation in MB"
  type        = number
  default     = 512
}

variable "timeout" {
  description = "Timeout in seconds"
  type        = number
  default     = 30
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "default"
}

variable "environment_variables" {
  description = "Environment variables for the Lambda"
  type        = map(string)
  default     = {}
}

variable "log_level" {
  description = "Log level (DEBUG, INFO, WARN, ERROR)"
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

variable "log_group_kms_key_id" {
  description = "KMS key ID for log group encryption"
  type        = string
  default     = null
}

variable "tracing_mode" {
  description = "X-Ray tracing mode (Active, PassThrough)"
  type        = string
  default     = null
}

variable "ephemeral_storage_size" {
  description = "Ephemeral storage size in MB (max 10240)"
  type        = number
  default     = 512
}

variable "vpc_security_group_ids" {
  description = "VPC security group IDs"
  type        = list(string)
  default     = []
}

variable "vpc_subnet_ids" {
  description = "VPC subnet IDs"
  type        = list(string)
  default     = []
}

variable "use_shared_layer" {
  description = "Deprecated and ignored. Layers are no longer managed by this module."
  type        = bool
  default     = false
}

variable "extra_layers" {
  description = "Additional Lambda layers"
  type        = list(string)
  default     = []
}

variable "lambda_s3_key" {
  description = "S3 key for Lambda function code"
  type        = string
  default     = ""
}

variable "lambda_s3_object_version" {
  description = "S3 object version for Lambda function code"
  type        = string
  default     = ""
}

variable "function_path" {
  description = "Deprecated and ignored. The package always includes all files under ../python_lambda_functions."
  type        = string
  default     = "."
}

variable "create_alias" {
  description = "Whether to create a Lambda alias"
  type        = bool
  default     = false
}

variable "alias_name" {
  description = "Name of the Lambda alias"
  type        = string
  default     = "live"
}

variable "attach_policy_arns" {
  description = "List of policy ARNs to attach to the IAM role"
  type        = list(string)
  default     = []
}

variable "inline_policies" {
  description = "Inline policies to attach to the IAM role"
  type        = list(string)
  default     = []
}

variable "permissions_boundary_arn" {
  description = "Permissions boundary ARN for the IAM role"
  type        = string
  default     = null
}

variable "enable_anomaly_detector" {
  description = "Enable CloudWatch Log Anomaly Detector"
  type        = bool
  default     = false
}

variable "allowed_triggers" {
  description = "List of allowed trigger sources"
  type = list(object({
    source     = string
    source_arn = string
  }))
  default = []
}
