## GitOps

### Bootstrap
```bash
KEY_FP=532458423DABB727A756D856F1F771FB906E1D53
NAMESPACE=

gpg --export-secret-keys --armor "${KEY_FP}" | 
kubectl create secret generic sops-gpg \
    --namespace=${NAMESPACE} \
    --from-file=sops.asc=/dev/stdin
```

### Secrets
#### Encrypt
```bash
sops --config .sops.yaml -e --in-place path/to/secret.yaml
```
#### Decrypt
See [upstream issue](https://github.com/mozilla/sops/issues/884) for additional details.
```bash
sops --config <(echo '') -d path/to/secret.yaml
```