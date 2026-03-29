variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "instance_type" {
  description = "Type of EC2 instance to provision"
  type        = string
  default     = "t2.micro"
}

variable "github_repo" {
  description = "GitHub repository to clone"
  type        = string
  default     = "https://github.com/Gurkkiat/dorm_devops.git"
}
