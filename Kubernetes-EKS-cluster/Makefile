###Create resourses###
#1
vpc-eks-init-plan:
	cd vpc-eks && terraform init && terraform plan
#2
vpc-eks-apply:
	cd vpc-eks && terraform apply -auto-approve
#3
worker-nodes-init-plan:
	cd self-managed-node-group/module && terraform init && terraform plan
#4
worker-nodes-apply:
	cd self-managed-node-group/module && terraform apply -auto-approve
	aws eks update-kubeconfig --name centos_eks
	sleep 60
	kubectl get nodes
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.5.1/deploy/static/provider/aws/deploy.yaml
	kubectl -n ingress-nginx patch service ingress-nginx-controller -p '{"spec":{"externalTrafficPolicy":"Cluster"}}'
	kubectl -n ingress-nginx describe svc ingress-nginx-controller

###Destroy resourses###
#5
worker-nodes-destroy:
	kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.5.1/deploy/static/provider/aws/deploy.yaml
	cd self-managed-node-group/module && terraform destroy -auto-approve
#6	
vpc-eks-destroy:
	cd vpc-eks && terraform destroy -auto-approve