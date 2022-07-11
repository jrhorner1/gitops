## GitOps

### Provision
```bash
pip3 install pipenv
pipenv install
pipenv shell
gilt overlay
ansible-playbook provision/ansible/playbooks/cluster-prepare.yml
ansible-playbook provision/ansible/playbooks/openebs-prereqs.yaml
ansible-playbook provision/ansible/cluster-installation.yml
```

### Bootstrap
```bash
KEY_FP=532458423DABB727A756D856F1F771FB906E1D53

kubectl create namespace flux-system

gpg --export-secret-keys --armor "${KEY_FP}" |
kubectl create secret generic sops-gpg \
    --namespace=flux-system \
    --from-file=sops.asc=/dev/stdin

export GITHUB_TOKEN=

flux bootstrap github \
    --owner=jrhorner1 \
    --repository=gitops \
    --branch main \
    --path=./clusters/production \
    --personal
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
