# External secrets poc

This is a repo for trying out various forms of secret injection

## TL;DR

```sh
$ htpasswd -c .htpasswd neo
New Password:
Re-type new password:
Adding password for user neo
```

```sh
$ docker compose up
[+] Building 1.5s (9/9) FINISHED
 => [internal] load build definition from Dockerfile                                                                                                                        0.0s
 => => transferring dockerfile: 31B                                                                                                                                         0.0s
 => [internal] load .dockerignore                                                                                                                                           0.0s
 => => transferring context: 2B                                                                                                                                             0.0s
 => [internal] load metadata for docker.io/library/nginx:1.23-alpine                                                                                                        1.3s
 => [auth] library/nginx:pull token for registry-1.docker.io                                                                                                                0.0s
 => [internal] load build context                                                                                                                                           0.0s
 => => transferring context: 770B                                                                                                                                           0.0s
 => [1/3] FROM docker.io/library/nginx:1.23-alpine@sha256:082f8c10bd47b6acc8ef15ae61ae45dd8fde0e9f389a8b5cb23c37408642bf5d                                                  0.0s
 => CACHED [2/3] COPY static /usr/share/nginx/html                                                                                                                          0.0s
 => CACHED [3/3] COPY nginx.conf /etc/nginx/nginx.conf                                                                                                                      0.0s
 => exporting to image                                                                                                                                                      0.0s
 => => exporting layers                                                                                                                                                     0.0s
 => => writing image sha256:2376764a3d64f60f3e5accb56c1c929f6a8a12bec7a952bd4788703be6acfcdb                                                                                0.0s
 => => naming to docker.io/library/xsecrets-poc_nginx                                                                                                                       0.0s
[+] Running 1/0
 ⠿ Container xsecrets-poc-nginx-1  Created                                                                                                                                  0.0s
Attaching to xsecrets-poc-nginx-1
xsecrets-poc-nginx-1  | /docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
xsecrets-poc-nginx-1  | /docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
xsecrets-poc-nginx-1  | /docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
xsecrets-poc-nginx-1  | 10-listen-on-ipv6-by-default.sh: info: IPv6 listen already enabled
xsecrets-poc-nginx-1  | /docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
xsecrets-poc-nginx-1  | /docker-entrypoint.sh: Launching /docker-entrypoint.d/30-tune-worker-processes.sh
xsecrets-poc-nginx-1  | /docker-entrypoint.sh: Configuration complete; ready for start up
```

Page is available at localhost:8090
