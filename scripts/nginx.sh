#!/bin/bash

# 安装 Nginx
sudo apt-get update
sudo apt-get install nginx -y

# 创建文件服务器目录
sudo mkdir -p /iflytek/repo

# 设置文件服务器目录权限
# sudo chown -R www-data:www-data /var/www/***/repo
# sudo chmod -R 755 /var/www/***/repo

# 创建 Nginx 配置文件
sudo tee /etc/nginx/sites-available/fileserver <<EOF
server {
    listen 6000;
    server_name localhost;

    location /repo {
        root /iflytek/;
        autoindex on;
        autoindex_exact_size off;
        autoindex_localtime on;
    }
}
EOF

# 启用文件服务器配置
sudo ln -s /etc/nginx/sites-available/fileserver /etc/nginx/sites-enabled/
sudo systemctl restart nginx

echo "文件服务器已经成功建立！"


