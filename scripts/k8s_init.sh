#!/bin/bash
#############################################
# Perform an initialization of k8s cluster #
#############################################

IP=ip -4 -o route get 10/8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p'

cat << EOF >> ~/.bashrc
export BASH_SILENCE_DEPRECATION_WARNING=1
export PS1='\u@\h:\[\e[01;32m\]\w\[\e[0m\]\$ '
export EDITOR='vim'
export CLICOLOR=1
alias ls='ls --color'
EOF
source ~/.bashrc

## aliyun source repo
yum install epel-release -y
yum install wget git jq net-tools yum-utils vim socat conntrack ebtables ipset python3 -y 
yum install gcc openssl-devel bzip2-devel libffi-devel -y
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

systemctl enable docker
systemctl start docker

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

systemctl stop firewalld
systemctl disable firewalld
systemctl status firewalld

setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
swapoff -a
sed -i 's/.*swap.*/#&/' /etc/fstab

yum remove epel-release -y
echo "hostname is :$(hostname)"

