data "aws_eks_cluster" "example" {
  name       = "${var.cluster-name}"
  #depends_on = ["aws_eks_cluster.demo"]
}
/*
# it works well for the 1st apply but after the token has expired eks endpoint refuse the connection...
data "aws_eks_cluster_auth" "example" {
  name = "${var.cluster-name}"
  depends_on = [  "aws_eks_cluster.demo"  ]
}

# external command, sh for linux and powershell for windows, how to manage interoperability, maybe wiht condition
data "external" "token" {
  program = ["sh", "-c", "aws eks get-token --cluster-name ${var.cluster-name}"|jq ...]
}*/

provider "kubernetes" {
  host                   = "${data.aws_eks_cluster.example.endpoint}"
  cluster_ca_certificate = "${base64decode(data.aws_eks_cluster.example.certificate_authority.0.data)}"
  #token                 = "${data.aws_eks_cluster_auth.example.token}"
  #token                 = "${data.external.token.result.token}"
/*
#old method aws-iam-authenticator should be replaced by aws eks get-token
exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    args        = ["token", "-i" ,"${data.aws_eks_cluster.example.name}"]
    command     = "aws-iam-authenticator"
  }*/
  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    args        = ["eks","get-token", "--cluster-name" ,"${data.aws_eks_cluster.example.name}"]
    command     = "aws"
  }


  load_config_file = false
  #version = "~> 1.5"
}

resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
  data = {
    mapRoles = <<EOF
- rolearn: ${aws_iam_role.demo-cluster.arn}
  username: system:node:{{EC2PrivateDNSName}}
  groups:
    - system:bootstrappers
    - system:nodes
- rolearn: arn:aws:iam::465242977050:role/EC2InstanceRole-codepipeline
  username: adminserver
  groups:
    -system:masters
EOF
  }
  depends_on = [
  "aws_eks_cluster.demo"]
}

/*
output "test" {
  value = "${data.external.token.result.token}"

}*/
