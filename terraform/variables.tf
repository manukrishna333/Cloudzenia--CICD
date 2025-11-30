variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "microservice"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "30.0.0.0/16"
}

variable "container_port" {
  description = "Port on which the container listens"
  type        = number
  default     = 5000
}

variable "ecs_task_cpu" {
  description = "CPU units for ECS task (256 = 0.25 vCPU)"
  type        = number
  default     = 512
}

variable "ecs_task_memory" {
  description = "Memory for ECS task in MB"
  type        = number
  default     = 1024
}

variable "ecs_service_desired_count" {
  description = "Desired number of tasks in ECS service"
  type        = number
  default     = 1
}

