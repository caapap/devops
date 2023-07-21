#!/bin/bash
###############################################
# Desc: deploy zookeeper,kafka,kafka manager,zkui
# Date: 2023-07-19
# Version: 1.0
# Author: caapap
###############################################

###### repo list #####
# 1.zookeeper-3.4.6.tar.gz
# 2.zkui2.0.tar.gz
# 3.kafka_2.12-2.2.1.zip
# 4.kafa-manager-2.0.0.2.zip

###### variable on bk #########
#download_repo_ip=172.31.98.204:6000/repo
#soft_dir=/iflytek/soft
#install_dir=/iflytek/server
#server_ip=172.31.98.206
#km_port=9024
#zkui_port=9090
###### variable on bk #########

###### variable on script #####
repo=zookeeper-3.4.6.tar.gz
repo1=zkui2.0.tar.gz
repo2=kafka_2.12-2.2.1.zip
repo3=kafka-manager-2.0.0.2.zip
#zookeeper部署变量
zk_data=/iflytek/data/zookeeper
zk_conf=${install_dir}/zookeeper-3.4.6/conf
zkServer_start=${install_dir}/zookeeper-3.4.6/bin/zkServer.sh
#zkui部署变量
zkui_conf=${install_dir}/zkui2.0/config.cfg
zkui_start=${install_dir}/zkui2.0/start.sh
#kafka部署变量
kafka_conf="${install_dir}/kafka_2.12-2.2.1/config/server.properties"
kafka_bin="${install_dir}/kafka_2.12-2.2.1/bin"
#kafka-manager部署变量
kafka_manager_conf="${install_dir}/kafka-manager-2.0.0.2/conf/application.conf"
kafka_manager_run="${install_dir}/kafka-manager-2.0.0.2/bin/kafka-manager"
###### variable on script #####

##################### prefix #########################
VERSION="BBT_v3.10-kafka_kafkamanager_zkui"
EXITCODE=0
#set -e
# 设置字体的 ANSI 转义序列
red () {
    echo -e "\033[0;31m  $*  \033[0m" # \033[0m 表示重置终端颜色的 ANSI 转义序列
}
green () {
    echo -e "\033[0;32m  $*  \033[0m"
}
yellow () {
    echo -e "\033[0;33m  $*  \033[0m"
}
##################### prefix #########################

################ function ##################
usage_and_exit () {
    #usage
    exit "$1"
}

log () {
    echo "[INFO]: $*"
}

warning () {
    yellow "[WARN]: $*" 1>&2
    EXITCODE=$((EXITCODE + 1))
}

version () {
    echo "deploy_kafka version $VERSION"
}

highlight () {
    echo -e "\033[7m  $*  \033[0m"
}

error () {
    red "[ERROR]: $*" 1>&2
    usage_and_exit 1
}

ok_kafka_manager () {
    cat <<EOF
$(
    log "LOCAL_IP: $server_ip"
    highlight "Welcome to KAFKA MANAGER on http://$server_ip:${km_port}"
)
EOF
}
ok_zkui () {
    cat <<EOF
$(
    log "LOCAL_IP: $server_ip"
    highlight "Welcome to ZKUI on http://$server_ip:${zkui_port}"
)
EOF
}
_waitcheck() {    #等待检查
local countdown=$1
while [ $countdown -ge 0 ]; do
  echo "waiting to check...: $countdown s"
    sleep 1
      ((countdown--))
      done
      echo "continue..."
}
_portcheck() {    
    log "检查端口是否被占用"
    local port=$1
    if netstat -tuln | grep ":$port" >/dev/null; then
        error "Port $port is in use !"
    else 
        log "Port $port is available"
    fi
}
################ function ##################

mkdir -p $soft_dir
mkdir -p $install_dir
# 等待检查函数


log "检查安装文件是否存在，不存在下载，存在继续"
check_and_download_file() {
    local repo_name="$1"
    
    if [ ! -f "$soft_dir/$repo_name" ]; then
        log "不存在${repo_name}安装文件，下载该文件!"
        if wget "http://${download_repo_ip}/${repo_name}" -P "$soft_dir" && sleep 1; then
            green "${repo_name}安装文件下载成功\n"
        else
            error "${repo_name}安装文件下载失败，请检查\n"
        fi
    else
        warning "${repo_name}安装文件已存在！"
    fi
}
check_and_download_file  "$repo"
check_and_download_file  "$repo1"
check_and_download_file  "$repo2"
check_and_download_file  "$repo3"

rm -rf ${install_dir}/zookeeper* && rm -rf ${zk_data}
log "清除zookeeper文件目录并解压到安装目录"
mkdir -p ${zk_data}
tar -zxf ${soft_dir}/$repo -C ${install_dir} && sleep 1s

cp $zk_conf/zoo_sample.cfg $zk_conf/zoo.cfg && sleep 1s
sed -i 's/dataDir=.*/dataDir=${zk_data}\nserver.1=${server_ip}:2888:3888/g' $zk_conf/zoo.cfg
log "修改dataDir=/iflytek/data/zookeeper"
log "修改server.1=$server_ip:2888:3888"
cd $zk_data
touch myid && echo "1" > myid 
log "生成myid文件，内容为1" 

log "启动zookeeper"
${zkServer_start} start &
sleep 3s

kill -9 $(ps -ef|grep zkui-2.0-SNAPSHOT-jar-with-dependencies.jar |grep -v grep|awk '{print $2}')
log "清除zkui残留服务"
rm -rf ${install_dir}/zkui2.0
log "清除zkui安装目录"
tar -zxf ${soft_dir}/$repo1 -C ${install_dir} && sleep 1s

sudo find $zkui_conf -type f -name "config.cfg" -exec sed -i "s/zkServer=.*/zkServer=$server_ip:2181/g" {} \;
log "修改config.cfg中zkServer值"

${zkui_start} &
sleep 3s

log "check zkui web ..."
response=$(curl -s -o /dev/null -w "%{http_code}"  "http://127.0.0.1:${zkui_port}/")
if [ $response -eq 200 ]; then
    green "zkui install complated!"
    ok_zkui
else
    error "zkui install failed!"
fi

log "清除kafka安装目录并解压"
rm -rf ${install_dir}/kafka*   # delete old version of kafka and kafka manager
unzip -q ${soft_dir}/$repo2 -d $install_dir && sleep 1s

############ kafka配置 ############# 

log "取消注释，并设值=PLAINTEXT://$server_ip:9092"
log "注释JMX_PORT"
cp ${kafka_conf} ${kafka_conf}.bak
sed -i "s/^#listeners=.*/listeners=PLAINTEXT:\/\/$server_ip:9092/g" $kafka_conf  
sed -i "s/zookeeper.connect=.*/zookeeper.connect=$server_ip:2181/g" $kafka_conf
sed -i '/JMX_PORT=9988/s/^/#/' "$kafka_bin/kafka-run-class.sh"
############ kafka配置 ############# 

############ 启动kafka #############
chmod -R 775 ${kafka_bin}
nohup $kafka_bin/kafka-server-start.sh $kafka_conf & 
sleep 5s

if jps |grep -w "Kafka" >/dev/null; then
    green "Kafka已启动成功"
else
    error "Kafka未启动"
fi
############ 启动kafka #############

############ kafka-manager配置 ############# 
unzip -q $soft_dir/$repo3 -d $install_dir && sleep 1s

sed -i '/kafka-manager.zkhosts=${?ZK_HOSTS}/d' $kafka_conf
sed -i "s/kafka-manager.zkhosts=.*/kafka-manager.zkhosts=$server_ip:2181/g" $kafka_conf
chmod -R 775 $install_dir/kafka-manager*
############ kafka-manager配置 ############# 

############ 启动kafka-manager #############
_portcheck $km_port
nohup $kafka_manager_run -Dconfig.file=$kafka_manager_conf -Dhttp.port=$km_port &
sleep 5s

log "check kafka-manager web ..."
response=$(curl -s -o /dev/null -w "%{http_code}"  "http://127.0.0.1:${km_port}/")
if [ $response -eq 200 ]; then
    green "kafka-manager install complated!"
    ok_kafka_manager
else
    error "kafka-manager install failed!"
fi

highlight "Finish"




