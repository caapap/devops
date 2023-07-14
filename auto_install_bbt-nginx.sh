#!/bin/bash

###############################################
# Desc: 一键安装BBT-nginx
# Date: 2023-07-14
###############################################

###### repo list #####
# 1.openssl-libs-1.0.2k-19.el7.x86_64.rpm
# 2.openssl-1.0.2k-19.el7.x86_64.rpm
# 3.nginx-1.20.2-1.el7.ngx.x86_64.rpm
repo1=openssl-libs-1.0.2k-19.el7.x86_64.rpm
repo2=openssl-1.0.2k-19.el7.x86_64.rpm
repo=nginx-1.20.2-1.el7.ngx.x86_64.rpm

###### variable on bk #########
soft_dir=/iflytek/soft
#download_repo_ip=:5000/repo
server_ip=172.31.18.212

###### variable on script #####
conf_dir=/etc/nginx/conf.d/default.conf



mkdir -p /iflytek/data/dtp/ 
mkdir -p /iflytek/data/bbt/ 

check_and_download_file() {
    local repo_name="$1"
    
    if [ ! -f "$soft_dir/$repo_name" ]; then
        echo "=====不存在${repo_name}安装文件，下载该文件！====="
        if wget "http://${download_repo_ip}/${repo_name}" -P "$soft_dir" && sleep 1; then
            printf "${repo_name}安装文件下载成功\n"
        else
            printf "${repo_name}安装文件下载失败，请检查\n"
            exit 1
        fi
    else
        echo "=====${repo_name}安装文件已存在！====="
    fi
}

check_and_download_file  "$repo1"
check_and_download_file  "$repo2"
check_and_download_file  "$repo"

cd $soft_dir
yum install -y "$repo1" "$repo2" "$repo" 

# 配置nginx
#如果 DTP 和 BBT 应用部署在一台服务器上，那么使用同一个 nginx，如下图所示配置

# conf_dir=/etc/nginx/conf.d/default.conf

cat > $conf_dir << EOF
#######bbt#######
server { 
 listen 20060; 
 server_name localhost; 
 #access_log /var/log/nginx/host.access.log main; 
 add_header Access-Control-Allow-Origin *; 
 add_header Access-Control-Allow-Headers X-Requested-With; 
 add_header Access-Control-Allow-Methods GET,POST,OPTIONS; 
 
 location /bbt { 
 alias /iflytek/data/bbt/; 
 autoindex on; 
 } 
 location /nginx_status { 
 stub_status on; 
 } 
 #location / { 
 # root /usr/share/nginx/html; 
 # index index.html index.htm; 
 #} 
 #error_page 404 /404.html; 
 # redirect server error pages to the static page /50x.html 
 # 
 error_page 500 502 503 504 /50x.html; 
 location = /50x.html { 
 root /usr/share/nginx/html; 
 } 
 # proxy the PHP scripts to Apache listening on 127.0.0.1:80 
 # 
 #location ~ \.php$ { 
 # proxy_pass http://127.0.0.1; 
 #} 
 # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000 
 # 
 #location ~ \.php$ { 
 # root html; 
 # fastcgi_pass 127.0.0.1:9000; 
 # fastcgi_index index.php; 
 # fastcgi_param SCRIPT_FILENAME /scripts$fastcgi_script_name; 
 # include fastcgi_params; 
 #} 
 # deny access to .htaccess files, if Apache's document root 
 # concurs with nginx's one 
 # 
 #location ~ /\.ht { 
 # deny all; 
 #} 
} 

####### dtp #######
server { 
 listen 8080; 
 server_name localhost; 
 #access_log /var/log/nginx/host.access.log main; 
 add_header Access-Control-Allow-Origin *; 
 add_header Access-Control-Allow-Headers X-Requested-With; 
 add_header Access-Control-Allow-Methods GET,POST,OPTIONS; 
 
 location /dtp { 
 alias /iflytek/data/dtp/; 
 autoindex on; 
 } 
 location /nginx_status { 
 stub_status on; 
 } 
 #location / { 
 # root /usr/share/nginx/html; 
BBT_v3.1.0 部署手册 
 # index index.html index.htm; 
 #} 
 #error_page 404 /404.html; 
 # redirect server error pages to the static page /50x.html 
 # 
 error_page 500 502 503 504 /50x.html; 
 location = /50x.html { 
 root /usr/share/nginx/html; 
 } 
 
} 

EOF

#启动 nginx 服务，并设置开机自启动
systemctl start nginx;
systemctl enable nginx;
systemctl status nginx;

echo "check bbt nginx page..."
response=$(curl -s -o /dev/null -w "%{http_code}"  "http://127.0.0.1:20060/bbt/")
if [ $response -eq 200 ]; then
    echo "bbt nginx success!"
else
    echo "bbt nginx failed: $response"
    exit 1
fi

echo "check dtp nginx page..."
response=$(curl -s -o /dev/null -w "%{http_code}"  "http://127.0.0.1:8080/dtp/")
if [ $response -eq 200 ]; then
    echo "dtp nginx success!"
else
    echo "dtp nginx failed: $response"
    exit 1
fi



