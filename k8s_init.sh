#!/bin/bash
#############################################
# Perform an initialization of k8s cluster #
#############################################

ip_info=`ifconfig|grep -v virbr0|grep -v lo|grep -v docker0|grep -A 1 "RUNNING" |grep inet|awk '{print $2}'`
IP=`ifconfig|grep -v virbr0|grep -v lo|grep -v docker0|grep -A 1 "RUNNING" |grep inet|awk '{print $2}'`

cat <<EOF > ~/.vimrc
syntax on
set tabstop=2
set shiftwidth=2
set expandtab
set ai
"set number
set hlsearch
set ruler
highlight Comment ctermfg=green
map s <nop>
map S :<CR>
map Q :q<CR>
map R :source $MYVIMRC<CR>
EOF

echo "localhost is:$IP"


_waitcheck() {
countdown=3
while [ $countdown -ge 0 ]; do
  echo "waiting to check...: $countdown s"
    sleep 1
      ((countdown--))
      done
      echo "continue..."
}

_waitcheck

master=172.31.18.212 
node1=172.31.18.213 
node2=172.31.18.214
#harbor=192.168.5.222

systemctl stop firewalld
systemctl disable firewalld
systemctl status firewalld

setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
swapoff -a

sed -ri "/config begin/,/config end/d" /etc/sysctl.conf
cat <<EOF >> /etc/sysctl.conf
# config begin
vm.swappiness=1
vm.max_map_count=262144
# config end
EOF

sysctl -p

cp -a /etc/rc.d/rc.local /etc/rc.d/rc.local.bak01

sed -ri "/config begin/,/config end/d" /etc/rc.d/rc.local
cat <<EOF >> /etc/rc.d/rc.local 
# config begin
if test -f /sys/kernel/mm/transparent_hugepage/defrag; then
    echo never > /sys/kernel/mm/transparent_hugepage/defrag
fi
if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
    echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi 
# config end
EOF


chmod +x /etc/rc.d/rc.local
bash /etc/rc.d/rc.local
printf "/etc/sysctl.conf中swappiness参数配置完成\n"

# add host infor to /etc/hosts

systemctl stop chronyd
systemctl disable chronyd
systemctl status chronyd


_waitcheck
yum -y install ntp
systemctl enable ntpd

#备份并用以下内容替换/etc/ntp.conf文件中的内容
mv /etc/ntp.conf /etc/ntp.conf.bak.$(date +%F_%T)

if [ $IP == $master ];then
    cat <<EOF > /etc/ntp.conf
driftfile /var/lib/ntp/drift
restrict 127.0.0.1
restrict -6 ::1
server 127.127.1.0
fudge  127.127.1.0 stratum 10
includefile /etc/ntp/crypto/pw
keys /etc/ntp/keys
EOF
else 
    cat <<EOF > /etc/ntp.conf
driftfile /var/lib/ntp/drift
restrict 127.0.0.1
restrict -6 ::1
server $master
includefile /etc/ntp/crypto/pw
keys /etc/ntp/keys
EOF
fi

date -R
echo "检查时间同步是否正常"
_waitcheck

# 检查目标文件是否存在
if [ -e /etc/localtime ]; then
    # 备份或删除原有文件
    # 例如：备份为 localtime.bak
    mv /etc/localtime /etc/localtime.bak.$(date +%F_%T)
fi
# 创建符号链接,调整时区
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

#date -s “当前时间”
hwclock --systohc

systemctl start ntpd
systemctl status ntpd
ntpdc -np

#显示本机名称

echo "hostname is :$(hostname)"


#####kubeshere install#####


#./kk create config --with-kubesphere v3.3.2 --with-kubernetes v1.22.12 -f config-sample.yaml
