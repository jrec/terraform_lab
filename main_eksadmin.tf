


resource "aws_iam_role" "eks_admin_role" {
  name                  = "eks-admin-role"
  description           = "Allows EKS Admin server to access AWS services"
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
  lifecycle {
    create_before_destroy = true
  }
}

# EKS Admin Policy
resource "aws_iam_policy" "eks_admin_policy" {
  name = "policy_eks_admin_server"
  description = "Allows EKS Admin server to access S3 and describe EKS"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
  {
    "Action": [
      "eks:DescribeCluster"      
    ],
    "Effect": "Allow",
    "Resource": "*"
  }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "policy-attachment" {
  role       = "${aws_iam_role.eks_admin_role.name}"
  policy_arn = "${aws_iam_policy.eks_admin_policy.arn}"
}

# EKS Admin Instance Profile
resource "aws_iam_instance_profile" "eks_admin_role_ip" {
  name = "ip-eks-admin-role"
  role = "${aws_iam_role.eks_admin_role.name}"
}

resource "aws_security_group" "eks_admin_sg" {
  name                   = "${var.cluster-name}-admin-sg"
  description            = "EKS Admin communication rules for ${var.cluster-name}"
  vpc_id                 = "${var.vpc_id}"
  revoke_rules_on_delete = "true"
  
  tags = {
    Name = "${var.cluster-name}-admin-sg"
  }
}

resource "aws_security_group_rule" "eks_admin_sg_ingress_controlplane_https" {
  source_security_group_id = "${aws_security_group.demo-cluster.id}"
  description              = "Allow admin to control plane communication for ${var.cluster-name}-admin-sg"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.eks_admin_sg.id}"
  type                     = "ingress"
}


resource "aws_security_group_rule" "eks_admin_sg_egress_controlplane_https" {
  source_security_group_id = "${aws_security_group.demo-cluster.id}"
  description              = "Allow admin to control plane communication for ${var.cluster-name}"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.eks_admin_sg.id}"
  type                     = "egress"
}

#  EC2 Instance creation
resource "aws_instance" "eks_admin" {

  ami                    = "${var.amiid}"
  instance_type          = "t2.micro"
  subnet_id              = "${data.aws_subnet.subnetid_private_a.id}"
  vpc_security_group_ids = ["${aws_security_group.eks_admin_sg.id}"]
  iam_instance_profile   = "${aws_iam_instance_profile.eks_admin_role_ip.id}"
  user_data              = "${data.template_file.user_data_data.rendered}"
  key_name  = "kopslab"

  root_block_device {
    volume_size = 30
  }
  volume_tags = {
    Name = "${var.cluster-name}-admin-volume"
  }

  credit_specification {
    cpu_credits = "standard"
  }
  disable_api_termination = "false"
  
  tags = {
      Name = "${var.cluster-name}-admin"
  }




}


/* User Data object creation */
data "template_file" "user_data_data" {
  template = "${file("${path.module}/userdata.sh")}"
  vars = {
    CLUSTER_NAME   = "${var.cluster-name}"
    
  }
}


