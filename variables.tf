variable "AWS_ACCESS_KEY_ID" {
    description = "AWS access key id"
}

variable "AWS_SECRET_ACCESS_KEY" {
    description = "AWS secret access key"
}

variable "AWS_REGION" {
  description = "AWS region e.g. us-east-1 (Please specify a region supported by the Fargate launch type)"
}

variable "AWS_RESOURCE_NAME_PREFIX" {
  description = "Prefix to be used in the naming of some of the created AWS resources e.g. demo-webapp"
} 

variable "ENVIRONMENT_PREFIX" {
  description = "Prefix to be used in the naming of environment (e.g. development, staging, production)"
}

variable "CIRCLECI_API_TOKEN" {
  description = "API token for using circleci"
}

variable "CIRCLECI_VCS_TYPE" {
  description = "Circleci vsc type"
  default = "github"
}

variable "CIRCLECI_ORGANIZATION" {
  description = "Circleci organization"
}
