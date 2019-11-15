variable "cluster-name" {
  type    = "string"
  default = "terraform-eks-cluster"
}

variable "env" {
  type    = "string"
  default = "dev"
}

variable "vpc_id" {
  type    = "string"
  default = "vpc-0c2d8f12853a8257c"
}

variable "amiid-eks" {
  type    = "string"
  default = "ami-059c6874350e63ca9"
}

variable "amiid" {
  type    = "string"
  default = "ami-0ce71448843cb18a1"
}
