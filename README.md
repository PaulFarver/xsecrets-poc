# External secrets poc

This is a repo for trying out various forms of secret injection

## Simple setup in docker compose

```sh
$ htpasswd -c .htpasswd neo
New Password:
Re-type new password:
Adding password for user neo
```

```sh
$ docker compose up
[+] Building 1.5s (9/9) FINISHED
...
 ⠿ Container xsecrets-poc-nginx-1  Created                                                                                                                                  0.0s
...
xsecrets-poc-nginx-1  | /docker-entrypoint.sh: Configuration complete; ready for start up
```

Page is available at localhost:8090

## Kubernetes simple setup with secret

```sh
$ kubectl apply -f deploy/simple.yml
namespace/simple-secret-poc created
deployment.apps/xsecret created
secret/xsecret created
```

## Kubernetes setup with CSI

```sh
$ kubectl apply -f deploy/csi-driver.yaml -f deploy/vault.yaml
namespace/csi created
customresourcedefinition.apiextensions.k8s.io/secretproviderclasses.secrets-store.csi.x-k8s.io created
customresourcedefinition.apiextensions.k8s.io/secretproviderclasspodstatuses.secrets-store.csi.x-k8s.io created
serviceaccount/secrets-store-csi-driver created
clusterrole.rbac.authorization.k8s.io/secretproviderrotation-role created
clusterrole.rbac.authorization.k8s.io/secretproviderclasses-admin-role created
clusterrole.rbac.authorization.k8s.io/secretproviderclasses-viewer-role created
clusterrole.rbac.authorization.k8s.io/secretprovidersyncing-role created
clusterrole.rbac.authorization.k8s.io/secretproviderclasses-role created
clusterrolebinding.rbac.authorization.k8s.io/secretproviderrotation-rolebinding created
clusterrolebinding.rbac.authorization.k8s.io/secretprovidersyncing-rolebinding created
clusterrolebinding.rbac.authorization.k8s.io/secretproviderclasses-rolebinding created
daemonset.apps/csi-secrets-store-csi-driver created
csidriver.storage.k8s.io/secrets-store.csi.k8s.io created
serviceaccount/csi-secrets-store-csi-driver-upgrade-crds created
serviceaccount/csi-secrets-store-csi-driver-keep-crds created
clusterrole.rbac.authorization.k8s.io/csi-secrets-store-csi-driver-upgrade-crds created
clusterrole.rbac.authorization.k8s.io/csi-secrets-store-csi-driver-keep-crds created
clusterrolebinding.rbac.authorization.k8s.io/csi-secrets-store-csi-driver-upgrade-crds created
clusterrolebinding.rbac.authorization.k8s.io/csi-secrets-store-csi-driver-keep-crds created
job.batch/secrets-store-csi-driver-upgrade-crds created
job.batch/secrets-store-csi-driver-keep-crds created
namespace/vault created
serviceaccount/vault-csi-provider created
serviceaccount/vault created
clusterrole.rbac.authorization.k8s.io/vault-csi-provider-clusterrole created
clusterrolebinding.rbac.authorization.k8s.io/vault-csi-provider-clusterrolebinding created
clusterrolebinding.rbac.authorization.k8s.io/vault-server-binding created
daemonset.apps/vault-csi-provider created
statefulset.apps/vault created
pod/vault-server-test created
```

Set up resources in vault

```sh
$ kubectl exec sts/vault -n vault -it -- sh
$ vault kv put secret/ngx_htpasswd htpasswd='
admin:$apr1$S1LM/dVo$Q53WbevvUKjrig8VH.9LK.
neo:$apr1$O6MEhCH.$LNJSRhOquKLIkW3sCYpD21
'
$ vault auth enable kubernetes
$ vault write auth/kubernetes/config kubernetes_host="https://kubernetes.default:443"
$ vault policy write internal-app - <<EOF
path "secret/data/ngx_htpasswd" { 
    capabilities = ["read"] 
}
EOF

$ vault write auth/kubernetes/role/nginx_application bound_service_account_names=application bound_service_account_namespaces=csi-poc policies=internal-app ttl=20m
Success! Data written to: auth/kubernetes/role/nginx_application
```

Apply resources in kubernetes

```sh
$ kubectl apply -f deploy/csi.yml
namespace/csi-poc created
deployment.apps/xsecret created
serviceaccount/application created
secretproviderclass.secrets-store.csi.x-k8s.io/vault-htpasswd created
```
