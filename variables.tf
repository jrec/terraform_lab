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
