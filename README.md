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

## Kubernetes setup

Setup a local kubernetes cluster with kind, minikube or kubernetes in docker desktop

Alternatively setup a cluster in AWS with terraform by running

```sh
$ terraform init
...
$ terraform apply
...
```

Once you have gained access to the cluster. Apply the prerequisite systems

```sh
$ kubectl apply -R -f deploy/systems
namespace/csi created
...
statefulset.apps/vault created
```

## Kubernetes simple setup with secret

```sh
$ kubectl apply -f deploy/apps/simple.yaml
namespace/simple-secret-poc created
deployment.apps/xsecret created
secret/xsecret created
```

## Kubernetes setup with ingress controller

```sh
$ kubectl apply -f deploy/apps/ingress-based.yaml
namespace/ingress-poc created
deployment.apps/xsecret created
secret/xsecret created
secret/basic-auth created
service/ingress-poc created
ingress.networking.k8s.io/xsecret created
```

## Kubernetes setup with CSI

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
$ kubectl apply -f deploy/apps/csi-based.yaml
namespace/csi-poc created
deployment.apps/xsecret created
serviceaccount/application created
secretproviderclass.secrets-store.csi.x-k8s.io/vault-htpasswd created
```
