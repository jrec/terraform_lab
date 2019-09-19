### EKS master cluster

provider "aws" {
  version = "~> 2.13"

  region = "eu-west-1"
}

#IAM role and policy 

resource "aws_iam_role" "demo-cluster" {
  name = "terraform-eks-demo-cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "demo-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role = "${aws_iam_role.demo-cluster.name}"
}

resource "aws_iam_role_policy_attachment" "demo-cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role = "${aws_iam_role.demo-cluster.name}"
}


### Security group

resource "aws_security_group" "demo-cluster" {
  name = "terraform-eks-demo-cluster"
  description = "Cluster communication with worker nodes"
  vpc_id = "${var.vpc_id}"

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-eks-demo"
  }
}

resource "aws_security_group_rule" "demo-cluster-ingress-workstation-https" {
  cidr_blocks = ["193.57.249.2/32", "10.1.1.197/32"]
  description = "Allow workstation to communicate with the cluster API Server"
  from_port = 443
  protocol = "tcp"
  security_group_id = "${aws_security_group.demo-cluster.id}"
  to_port = 443
  type = "ingress"
}

## EKS cluster

resource "aws_eks_cluster" "demo" {
  name = "${var.cluster-name}"
  role_arn = "${aws_iam_role.demo-cluster.arn}"
  enabled_cluster_log_types = ["api", "audit"]

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access = false
    security_group_ids = ["${aws_security_group.demo-cluster.id}"]
    subnet_ids = ["${data.aws_subnet.subnetid_private_a.id}", "${data.aws_subnet.subnetid_private_b.id}"]
  }

  depends_on = [
    "aws_iam_role_policy_attachment.demo-cluster-AmazonEKSClusterPolicy",
    "aws_iam_role_policy_attachment.demo-cluster-AmazonEKSServicePolicy",
    "aws_cloudwatch_log_group.eks_log_group"
  ]
}

resource "aws_cloudwatch_log_group" "eks_log_group" {
  name = "/aws/eks/${var.cluster-name}/cluster"
  retention_in_days = 7
}
