# system-init

## sys env
```
version：CentOS Linux release 7.6.1810 (Core)
kernel：3.10.0-957.el7.x86_64
network：online
Spec：larger than 1C1G
Nic：at least 1
system volume：  at least 100GB of space
data volume：  at least 100GB of space（optional）
```

## mount disk(optional)
command to mount a data disk
```
mkfs.xfs -f /dev/sdb
mkdir -p /data
mount /dev/sdb /data/
 echo "/dev/sdb                                  /data                   xfs     defaults        0 0" >>/etc/fstab ; cat /etc/fstab |grep data
```

## config yum repo
```
rm -f /etc/yum.repos.d/*.repo
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.cloud.tencent.com/repo/centos7_base.repo
curl -o /etc/yum.repos.d/epel.repo http://mirrors.cloud.tencent.com/repo/epel-7.repo
yum repolist
```

## yum install
```
yum -y install ansible vim git
```

## pull repository
```
cd /root/
git clone https://gitee.com/chriscentos/system-init.git
```

## copy template and modify it
```
cd /root/system-init/
\cp group_vars/all-template group_vars/all
\cp hosts-example hosts
```

## add host lists 
vim hosts
```
[nodes01]
192.168.1.10 

[all:vars]
ansible_ssh_port=22            ## sshd port 
ansible_ssh_user=root          ## remote user
ansible_ssh_pass="bkce123"     ## remote pass
```

## ssh-keygen
check keys 
```
# ls -l /root/.ssh/id_rsa*
-rw------- 1 root root 1679 Dec  3 22:51 /root/.ssh/id_rsa
-rw-r--r-- 1 root root  403 Dec  3 22:51 /root/.ssh/id_rsa.pub
```
skip step if keys exist
```
# ssh-keygen    ## input: ENTER 
```

## init variable
vim group_vars/all
```
# system init size percentage
ntp_server_host: 'ntp1.aliyun.com' #config NTP addr
dns_server_host: '114.114.114.114' #config DNS addr

# Safety reinforcement related configuration
auth_keys_file: '/root/.ssh/authorized_keys' #set key file addr
password_auth: 'yes' #Whether to enable password login. yes:enabled. no:disabled
root_public_key: ''  #config public key
root_passwd: 'bkce123'
```
how to acquire pub key ：cat /root/.ssh/id_rsa.pub 

## check server status
check sshd
```
ansible -m ping nodes01
192.168.1.10 | SUCCESS => {
```

## optimize server
```
ansible-playbook playbooks/system_init.yml -e "nodes=nodes01"
```

## check server service
verify 
```
1.check if no pass
# ssh 192.168.1.1
[root@linux-bkce-node1 ~]#

2.check dns config
# cat /etc/redhat-release 
CentOS Linux release 7.6.1810 (Core) 

3.check ntp status 
# ntpstat 
synchronised to NTP server (120.25.115.20) at stratum 3
   time correct to within 25 ms
   polling server every 64 s
case：
# ntpstat 
Unable to talk to NTP daemon. Is it running?
advised to restart chronyd ： systemctl restart chronyd

4.check if mounted(optional)
# df -h|grep data
/dev/sdb        500G   61G  440G  13% /data
```
