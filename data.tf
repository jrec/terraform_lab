data "aws_availability_zones" "available" {}

data "aws_region" "current" {}


data "aws_subnet" "subnetid_private_a" {
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  vpc_id            = "${var.vpc_id}"

  tags = {
    "network" = "private"
  }
}

data "aws_subnet" "subnetid_private_b" {
  availability_zone = "${data.aws_availability_zones.available.names[1]}"
  vpc_id            = "${var.vpc_id}"

  tags = {
    "network" = "private"
  }
}

### retrieve aws eks-optimized ami 
data "aws_ami" "eks-worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${aws_eks_cluster.demo.version}-v*"]
  }

  most_recent = true
  owners      = ["self"]
  #owners      = ["602401143452"] # Amazon EKS AMI Account ID
}
