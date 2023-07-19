#!/bin/bash
set -e
#######需在bk平台上赋值的变量#######
$zk_data=/iflytek/data/zookeeper
$soft_dir=/iflytek/server
$download_repo_ip=172.31.98.204
#$localhost=$target_mechine_ip
#######需在bk平台上赋值的变量#######
#zk安装
# 检查安装文件是否存在，不存在下载，存在继续
if [ ! -f $soft_dir/$zookeeper_files ];then
    echo "=====不存在zookeeper-3.4.6安装文件，下载该文件！====="
wget http://${download_repo_ip}:6000/repo/zookeeper-3.4.6.tar.gz -P /iflytek/soft/|sleep 1s
       if [ $? -eq 0 ];then
            printf "zookeeper-3.4.6安装文件下载成功\n"
            continue
        else
            printf "zookeeper-3.4.6安装文件下载失败，请检查\n"
        exit 1
         fi
else
        echo "=====zookeeper-3.4.6安装文件已存在！====="
fi
if [ ! -f $soft_dir/zkui2.0 ];then
    echo "=====不存在zkui2.0安装文件，下载该文件！====="
wget http://${download_repo_ip}:6000/repo/zkui2.0.tar.gz -P /iflytek/soft/|sleep 1s
       if [ $? -eq 0 ];then
            printf "zkui2.0安装文件下载成功\n"
            continue
        else
            printf "zkui2.0安装文件下载失败，请检查\n"
        exit 1
         fi
else
        echo "=====zkui2.0安装文件已存在！====="
fi

if [ ! -f $soft_dir/kafka_2.12-2.2.1.zip ];then

    echo "=====不存在zkui2.0安装文件，下载该文件！====="

wget http://${download_repo_ip}:6000/repo/kafka_2.12-2.2.1.tgz -P /iflytek/soft/|sleep 1s
       if [ $? -eq 0 ];then
            printf "kafka安装文件下载成功\n"
            continue
        else
            printf "kafka安装文件下载失败，请检查\n"
        exit 1
         fi
else
        echo "=====kafka安装文件已存在！====="
fi

rm -rf $soft_dir/zookeeper* && rm -rf $zk_data
tar -zxvf zookeeper-3.4.6.tar.gz -C iflytek/server/|sleep 1s
mkdir -p $zk_data
zk_conf=$zk_data/conf
find $zk_conf -type f -name "zoo.cfg" -exec sed -i "s/dataDir=.*/dataDir=/iflytek/data/zookeeper/g;s/server.1=.*/server.1=$localhost:2888:3888" {} \;
echo "1" > $zk_data/myid
cd $soft_dir/zookeeper-3.4.6/bin/
./zkServer.sh start

#zkui部署
##############手动放置安装包#############
cd /iflytek/soft

tar -zxvf zkui2.0.tar.gz -C $soft_dir|sleep 1s

cd $soft_dir/zkui2.0 
zkui_conf="$soft_dir/zkui2.0/conf"
sudo find $zkui_conf -type f -name "config.cfg" -exec sed -i "s/zkServer=.*/zkServer=$localhost:2181/g" {} \;
sh $soft_dir/zkui2.0/start.sh

echo "访问http://$localhost:9090/ 进行页面查看..."

response=$(curl -s -o /dev/null -w "%{http_code}" -u "admin:manager" "http://$localhost:9090/")
if [ $response -eq 200 ]; then
    echo "zkui安装成功"
else
    echo "zkui安装失败! HTTP状态码: $response"
    exit 1
fi

#kafka安装
cd /iflytek/soft
tar -zxvf kafka_2.12-2.2.1.tgz -C $soft_dir | sleep 2s
kafka_conf="$soft_dir/kafka_2.12-2.2.1/config/server.properties"
cp $kafka_conf $kafka_conf.bak
sed -i "s/listeners=.*/listeners=PLAINTEXT://$locahost:9092/g" $kafka_conf;
sed -i "s/zookeeper.connect=.*/zookeeper.connect=$locahost:2181/g" $kafka_conf;
kafka_run="soft_dir/kafka_2.12-2.2.1/bin"
kafka_run_sh="$kafka_run/kafka-run-class.sh"
JMX="JMX_POPT"
sed -i '/JMX_PORT=9988/s/^/#/' $kafka_run_sh;
chmod -R 775 $soft_dir/kafka_2.12-2.2.1/bin
nohup ./kafka-server-start.sh ../config/server.properties &|sleep 1s

cd /iflytek/soft
unzip kafka-manager-2.0.0.2.zip -d $soft_dir | sleep 1s
kafka_manager_conf="$soft_dir/kafka-manager-2.0.0.2/conf/application.conf"
sed -i "s/kafka-mananger.zkhosts=.*/kafka-manager.zkhosts=$localhost:2181/g" $kafka_manager_conf;
chmod -R 775 $soft_dir/kafka-manager-2.0.0.2/
nohup $soft_dir/kafka-manager-2.0.0.2/bin/kafka-manager -Dconfig.file=$soft_dir/kafka-manager-2.0.0.2/conf/application.conf -Dhttp.port=9000 &






