variable "batch_proxy_fname" {
    description = "Name of the lambda function to be used as AWS Batch Proxy"
    type        = string
}

variable "authorizer_fname" {
    description = "Name of the lambda function to be used as Custom Auhorizer"
    type        = string
}

variable "region" {
    description = "AWS Region where resources will be created"
    type        = string
}

variable "log_retention_period" {
    description = "Lifetime duration of the log in CloudWatch in terms of days"
    type        = number
}

variable "stage_name" {
    description = "Name of the API stage"
    type        = string
}

variable "batch_job_def_name" {
    description = "Name of the batch job"
    type        = string
}

variable "batch_job_log_group_name" {
    description = "Name of the log group"
    type        = string
}

variable "batch_job_repo" {
    description = "Name of the ECR that contains Batch Job Image"
    type        = string
}

variable "batch_job_queue_name" {
    description = "Name of the Batch Job Queue"
    type        = string
}

variable "api_secret" {
    description = "API secret value"
    type        = string   
}