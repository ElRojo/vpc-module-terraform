variable "ami" {
  type        = string
  default     = "al2023-ami-2023.6.20250107.0-kernel-6.1-x86_64"
  description = "AMI used for the project."
}

variable "instance_type" {
  default     = "t2.micro"
  description = "Default instance type"
}

variable "public_key" {
  type        = string
  description = "Public ssh key path"
  default     = "id_rsa.pub"
}

variable "shell_command" {
  type        = string
  description = "Commands run on start"
  default     = "user-data.txt"
}


