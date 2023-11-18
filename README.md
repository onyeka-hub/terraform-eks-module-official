# terraform-eks-module-official
Terraform module to create an Elastic Kubernetes (EKS) cluster and associated resources

version = "~> 18.0"

kubectl cheatsheet - https://kubernetes.io/docs/reference/kubectl/cheatsheet/

Kubernetes API Spec - https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/




Extra Notes

Port forward to access the cluster IP service
-- kubectl port-forward pod/nginx-pod 8000:80 -n dev
-- kubectl port-forward svc/nginx-service 8080:80 -n masterclass

Use this to update your kubeconfig file

```
aws eks update-kubeconfig --name onyeka-terraform-eks --region us-east-2
```

