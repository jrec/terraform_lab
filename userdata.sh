#!/bin/bash
set -x
DATE=`date +%Y-%m-%d-%H:%M:%S`
LOGFILE="${CLUSTER_NAME}_userdata_$DATE.log"
exec > >(tee /var/log/userdata|logger -t user-data ) 2>&1
echo BEGIN  
echo "##### create a deployment status tag #####"
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
#update kube config
aws eks update-kubeconfig --name ${CLUSTER_NAME} --region eu-west-1
#install kubectl
curl -o kubectl https://amazon-eks.s3-us-west-2.amazonaws.com/1.14.6/2019-08-22/bin/linux/amd64/kubectl
chmod +x ./kubectl
mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$HOME/bin:$PATH
echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc
kubectl version --short --client
#Cloudwatch Agent
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/master/k8s-yaml-templates/cloudwatch-namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/master/k8s-yaml-templates/cwagent-kubernetes-monitoring/cwagent-serviceaccount.yaml
curl -O https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/master/k8s-yaml-templates/cwagent-kubernetes-monitoring/cwagent-configmap.yaml
sed -i "s/{{cluster_name}}/\1 ${CLUSTER_NAME}/" ./cwagent-configmap.yaml
kubectl apply -f cwagent-configmap.yaml
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/master/k8s-yaml-templates/cwagent-kubernetes-monitoring/cwagent-daemonset.yaml
kubectl get pods -n amazon-cloudwatch