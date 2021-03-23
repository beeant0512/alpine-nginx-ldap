# alpine-nginx-ldap
nginx with ldap auth using alpine image

# using

* edit the ldap config in `nginx/conf.d/default.conf`
* docker build . -t nginx-ldap/alpine:latest

# 使用

* 修改 `nginx/conf.d/default.conf` 中的LDAP配置
* 构建镜像 `docker build . -t nginx-ldap/alpine:latest`