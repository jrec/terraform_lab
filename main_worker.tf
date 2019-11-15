### EKS WORKER

resource "aws_iam_role" "demo-node" {
  name                  = "terraform-eks-demo-node"
  force_detach_policies = true

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "demo-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role = "${aws_iam_role.demo-node.name}"
}

resource "aws_iam_role_policy_attachment" "demo-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role = "${aws_iam_role.demo-node.name}"
}

resource "aws_iam_role_policy_attachment" "demo-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role = "${aws_iam_role.demo-node.name}"
}

resource "aws_iam_role_policy_attachment" "demo-node-CloudWatchAgentServerPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role = "${aws_iam_role.demo-node.name}"
}

resource "aws_iam_instance_profile" "demo-node" {
  name = "terraform-instance-profile-eks-demo"
  role = "${aws_iam_role.demo-node.name}"
}


### Security Group

resource "aws_security_group" "demo-node" {
  name = "terraform-sg-eks-demo-node"
  description = "Security group for all nodes in the cluster"
  vpc_id = "${var.vpc_id}"

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
      "Name", "terraform-eks-demo-node",
      "kubernetes.io/cluster/${var.cluster-name}", "owned",
    )
  }"
}

resource "aws_security_group_rule" "demo-node-ingress-self" {
  description = "Allow node to communicate with each other"
  from_port = 0
  protocol = "-1"
  security_group_id = "${aws_security_group.demo-node.id}"
  source_security_group_id = "${aws_security_group.demo-node.id}"
  to_port = 65535
  type = "ingress"
}

resource "aws_security_group_rule" "demo-node-ingress-cluster" {
  description = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port = 1025
  protocol = "tcp"
  security_group_id = "${aws_security_group.demo-node.id}"
  source_security_group_id = "${aws_security_group.demo-cluster.id}"
  to_port = 65535
  type = "ingress"
}


resource "aws_security_group_rule" "demo-cluster-ingress-node-https" {
  description = "Allow pods to communicate with the cluster API Server"
  from_port = 443
  protocol = "tcp"
  security_group_id = "${aws_security_group.demo-cluster.id}"
  source_security_group_id = "${aws_security_group.demo-node.id}"
  to_port = 443
  type = "ingress"
}

### worker nodes auto scaling

locals {
  demo-node-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.demo.endpoint}' --b64-cluster-ca '${aws_eks_cluster.demo.certificate_authority.0.data}' '${var.cluster-name}'
USERDATA
}

resource "aws_launch_configuration" "demo" {
  associate_public_ip_address = false
  iam_instance_profile        = "${aws_iam_instance_profile.demo-node.name}"
  image_id                    = "${var.amiid}"
  instance_type               = "t3.medium"
  name_prefix                 = "terraform-eks-demo-test"
  security_groups             = ["${aws_security_group.demo-node.id}"]
  user_data_base64            = "${base64encode(local.demo-node-userdata)}"
  key_name                    = "kopslab"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "demo" {
  desired_capacity     = 2
  launch_configuration = "${aws_launch_configuration.demo.id}"
  max_size             = 2
  min_size             = 1
  name                 = "terraform-eks-demo"
  vpc_zone_identifier  = ["${data.aws_subnet.subnetid_private_a.id}", "${data.aws_subnet.subnetid_private_b.id}"]

  tag {
    key                 = "Name"
    value               = "terraform-eks-demo"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster-name}"
    value               = "owned"
    propagate_at_launch = true
  }

   depends_on = [
    "aws_eks_cluster.demo"
  ]
}
/*
locals {
  config_map_aws_auth = <<CONFIGMAPAWSAUTH


apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${aws_iam_role.demo-node.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
CONFIGMAPAWSAUTH
}

output "config_map_aws_auth" {
  value = "${local.config_map_aws_auth}"
}
*/
