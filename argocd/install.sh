#!/bin/bash

kubectl create namespace argocd
# Default install
#kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -n argocd -f install.yaml
# Core install
#kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/core-install.yaml

# Load Balancer
#kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
# Ingress
#
# Port Forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# KSOPS
kubectl patch -n argocd deployment/argocd-repo-server -f patch.yaml

# Log in using the cli
ARGO_PW=`kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`
echo "ArgoCD Initial Password: ${ARGO_PW}"
echo ""
echo "https://argo-cd.readthedocs.io/en/stable/getting_started/#4-login-using-the-cli"
