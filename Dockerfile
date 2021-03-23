FROM alpine:latest

ENV NGINX_VERSION=1.19.8

# 修改源,加速
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories && apk update && apk upgrade

# 安装编译环境
RUN set -x && export BUILD_DEPS=" \
  gcc \
  g++ \
  # --with-file-aio
  linux-headers \
  # --without-http_rewrite_module
  pcre-dev \
  # openssl
  openssl-dev \
  # --without-http_gzip_module
  zlib-dev \
  # 
  make \
  # ldap 
  openldap-dev \
  # curl 
  curl \
  # git \
  git \
" \
&& apk add --no-cache ${BUILD_DEPS}

# 安装 nginx
# Install Nginx from source, see http://nginx.org/en/linux_packages.html#mainline
RUN mkdir -p /tmp/src/nginx
# 使用github加速地址，原地址 https://github.com/nginx/nginx/archive/release-${NGINX_VERSION}.tar.gz
RUN curl -fsSL https://hub.fastgit.org/nginx/nginx/archive/release-${NGINX_VERSION}.tar.gz | tar xz --strip=1 -C /tmp/src/nginx

# 安装 nginx ldap
# 使用github加速地址，原地址 https://github.com/kvspb/nginx-auth-ldap.git
RUN apk add git --no-cache && \
    cd /tmp/src/ && \
    git clone https://hub.fastgit.org/kvspb/nginx-auth-ldap.git && \
    cd nginx-auth-ldap && \
    git checkout -b b80942160417e95adbadb16adc41aaa19a6a00d9

# 编译 nginx
RUN mkdir -p /var/log/nginx
RUN mkdir -p /var/cache/nginx

RUN cd /tmp/src/nginx && \
    ./auto/configure \
        --prefix=/usr/share/nginx \
        --sbin-path=/usr/sbin/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/run/nginx.lock \
        --http-client-body-temp-path=/var/cache/nginx/client_temp \
        --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
        --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
        --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
        --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
        --user=nginx \
        --group=nginx \
        --with-http_ssl_module \
        --with-http_realip_module \
        --with-http_addition_module \
        --with-http_sub_module \
        --with-http_dav_module \
        --with-http_flv_module \
        --with-http_mp4_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_random_index_module \
        --with-http_secure_link_module \
        --with-http_stub_status_module \
        --with-http_auth_request_module \
        --with-mail \
        --with-mail_ssl_module \
        --with-file-aio \
        --with-http_v2_module \
        --with-threads \
        --with-stream \
        --with-stream_ssl_module \
        --with-http_slice_module \
        --add-module=/tmp/src/nginx-auth-ldap \
 && make \
 && make install \
 && ln -sf /dev/stdout /var/log/nginx/access.log \
 && ln -sf /dev/stderr /var/log/nginx/error.log

# Create users for the Nginx process 
RUN addgroup -g 1000 -S nginx && \
    adduser -u 1000 -S nginx

# 移除编译工具
RUN apk del --purge ${BUILD_DEPS}
# 移除临时文件
RUN rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

# 配置文件
COPY nginx/nginx.conf /etc/nginx/nginx.conf
ADD nginx/conf.d /etc/nginx/conf.d

# 启动时pid问题
RUN mkdir /run/nginx

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]