# Prometheus完整搭建+主机、进程监控（邮件）告警(学习笔记)
## 1. 下载与安装
### 1.1 prometheus下载地址：https://prometheus.io/download/ 
（系统初始化自主完成，注意关闭selinux）
选择对应系统版本，也有alertmanager以及大多数exporter，例如node_exporter、process_exporter可根据需要提前下载。
![](https://raw.githubusercontent.com/caapap/picrepo/main/6ddaa9a87a8b47aa8910ccddae6531a1.PNG)
### 1.2 prometheus解压安装
```shell
#用哈希值验证压缩包完整性（与下载页哈希值比较）
sha256sum prometheus-2.31.0.linux-amd64.tar.gz
tar -xzvf prometheus-2.31.0.linux-amd64.tar.gz
#根据实际情况选择文件夹以及更名，或建立连接
mv prometheus-2.31.0.linux-amd64 prometheus
可直接在终端启动prometheus
cd prometheus/
./prometheus 
```

> 为了不影响终端使用，可以将prometheus程序使用nohup放入后台运行，在一般情况下（需要长期使用，不单单是测试）添加prometheus为开机自启服务.

```shell
vim /usr/lib/systemd/system/prometheus.service #这是rhel7版本，rhel6添加服务与rhel7不一样，需要注意，centos同理。
在文件中写入如下内容：
[Unit]
Description=Prometheus server daemon
[Service]
Type=simple
#注意自己的路径
ExecStart=/data/prometheus/prometheus --config.file=/data/prometheus/prometheus.yml \#启动、配置文件路径
--storage.tsdb.path=/data/prometheus/data \ #数据存储路径
--storage.tsdb.retention=15d \
--web.console.templates=/data/prometheus/consoles \ #数据最大保留天数
--web.console.libraries=/data/prometheus/console_libraries \ #控制台库目录路径
--web.max-connections=256 \                #最大同时连接数
--web.external-url "http://本机IP:9090" \  #WEB UI
--web.listen-address "0.0.0.0:9090"   #默认端口
Restart=on-failure
[Install]
WantedBy=multi-user.target
```

> prometheus默认端口9090，注意关闭防火墙或开放端口，服务文件具体配置内容可通过 ./prometheus --help查看。

### 1.3 启动服务+验证

```shell
systemctl daemon-reload  #重新加载配置
systemctl enable prometheus.service  #加入开机自启
systemctl start prometheus.service   #启动
systemctl ststus prometheus.service  #查看状态
```



 至此，prometheus已经搭好了，可查看Status下拉菜单targets中prometheus工作是否为UP，UP代表服务。正常的UI界面需要自己熟悉探索，后面也会简单介绍。下面开始监控主机性能了。(注意浏览器主机与prometheus服务器时间要一致，同时若浏览器版本过低可能界面无法显示数据)

## 2. exporter

### 2.1 node_exporter
  在prometheus官网（或GitHub）下载node_exporter。https://prometheus.io/download/

  将tar包放入需要监控的主机中，选择合适的目录解压并配置服务自启。

  注意：node_exporter默认端口为9100，注意开放相应端口或修改指定端口。

```shell
tar -xzvf  node_exporter-1.2.2.linux-amd64.tar
mv  node_exporter-1.2.2.linux-amd64 /usr/local/node_exporter #根据自己实际需要选择目录，修改名称或建立符号连接
#写配置文件
touch /usr/lib/systemd/system/node_exporter.service
文件添加如下内容
[Unit]
Description=Node_exporter server daemon
After=network.target
 
[Service]
Type=simple
#User=node_exporter  #根据实际需要可选择是否新建用户组为服务专属
#Group=node_exporter
ExecStart=/usr/local/node_exporter/node_exporter #解压文件位置
Restart=on-failure
 
[Install]
WantedBy=multi-user.target
 
#### 也可以通过nohup ./node_exporter & 放入后台运行，每次机器重启后需要手动启动服务
```

可通过node_exporter所在主机的IP，通过url http://机器IP:9100/metrics查看页面。

 接下来开始编辑prometheus上的配置文件prometheus.yml

```shell

vim /data/prometheus/prometheus.yml
在文件中添加如下job内容
- job_name: "node_exporter"
 
    static_configs:
      - targets: ["ip1:9100","ip2:9100"] #填入自己的ip，此处若服务器过多有其他方法添加
#注意格式，可以参照配置文件中原prometheus job的格式
 
检查配置文件
./promtool check config prometheus.yml
若出现如下内容代表文件配置正确
Checking prometheus.yml
  SUCCESS: 0 rule files found
重启prometheus服务或采用热加载
systemctl restart prometheus.service
```

通过prometheus页面status下拉targets可查看节点状态
当显示为UP时说明连接成功，若不成功，请检查防火墙、端口、网络状态。

### 2.2 安装process_exporter

下载地址：https://github.com/ncabatoff/process-exporter/releases/tag/v0.7.10

安装配置与node_exporter同理。
〉process_exporter是用来监控进程的，例如监控nginx、mysql、redis等进程，可通过进程名或进程pid进行监控。与node_exporter类似，下载、解压、配置服务自启，注意端口号。

```shell
#后台运行
nohup ./process_exporter -config.path config.yml &
config.path前面一定不要忽视-，否则读取不到信息
#config.yml为当前目录下的配置文件（需要自己写），文件中设置自己需要监视的进程
添加如下内容可监视全部进程。
process_names:
  - name: "{{.Comm}}"
    cmdline:
    - '.+'
#具体如何使用可参考网络
```

在prometheus主机上修改配置文件prometheus.yml，添加如下job:

```shell
- job_name: "process_exporter"
 
    static_configs:
      - targets: ["ip1:9256","ip2:9256"]
#process_exporter 默认端口为9256，可通过在解压的process_exporter 中执行./process_exporter --help查看相关配置说明
 
文件修改完检查一下
./promtool check config prometheus.yml
重启prometheus
systemctl restart prometheus.service
```

targets界面查看process_exporter节点是否UP

## 3. prometheus + grafana
 prometheus界面简单，同时需要PromQL语言基础才能运用自如，而grafana能够很好的接入prometheus数据，并通过精美的dashboard展示。

### 3.1 grafana安装
下载地址：https://grafana.com/grafana/download

根据界面选择合适版本，若使用环境为专网建议下载rpm文件手动安装（毕竟wget用不了），若在公网还可以使用yum源安装，清华大学开源软件镜像站就有https://mirror.tuna.tsinghua.edu.cn/。

安装grafana
    
```shell
rpm -ivh grafana-enterprise-8.2.3-1.x86_64
systemctl daemon-reload
systemctl enable grafana-server.service
systemctl start grafana-server.service
```

注：建议grafana不要使用最新版本，7.2.0之前版本较稳定，之后版本可能出现界面打开报错问题，需要根据自己的实际环境进行选择。


 默认用户名密码为admin/admin，登录后可选择修改密码或跳过。


### 3.2 grafana+prometheus
登录后开始选择prometheus为数据源：


按步骤配置好URL地址，就可以接入prometheus数据源了


 下面导入面板（熟练后可以自己编辑），在grafana网站中找到dashboard,选择一款自己喜欢的，通过下载json文件或copy id将其导入到自己grafana面板中。（专网环境使用json文件上传方式）


  我们在grafana界面左侧菜单栏选择 “+” 中import导入dashboard，选择upload json file.


  修改自己需要的名称，选择好数据源就可以导入了。


  当我们需要监控不同信息时，比如进程监控、Redis监控，这些较为常见的监控项目前在prometheus上已有相应的exporter，我们如安装node_exporter一样进行安装，同时在grafana中选择相应的dashboard（有些个性化的监控点需要自己去探索开发，没有开源的exporter以及dashboard）。

进程监控面板推荐named-processes-by-interval-processes-host_rev1.json


## 4. Alertmanager安装配置
prometheus生态中，告警由独立两部分组成，prometheus server与Alertmanag是独立的两部分，其中由prometheus server获取监控指标，基于这些指标定义规则（rules），若这些指标满足告警规则便将信息推送到Alertmanager。

```shell
tar -xzvf alertmanager-0.23.0.linux-amd64.tar.gz #解压前注意检查哈希值
解压后文件夹内alertmanager.yml是配置文件，告警机制、通知在这里设置
vim /usr/lib/systemd/system/alertmanager.service #建立服务文件，对于rhel7或centos7也可以将服务文件放到/etc/systemd/system/下
文件中写入
[Unit]
Description=Prometheus Alertmanager server daemon
After=network.target
 
[Service]
Type=simple
#User=root
#Group=root
ExecStart=/data/alertmanager/alertmanager --config.file=/data/alertmanager/alertmanager.yml \
--storage.path "/data/alertmanager/data" \                    #数据存储路径
--data.retention=10d \                                        #历史数据最大保留时间
--web.external-url "http://localhost:9093" \             #alertmanager默认端口9093
--web.listen-address ":9093"
Restart=on-failure
 
[Install]
WantedBy=multi-user.target
 
 
添加服务子启动
systemctl daemon-reload
systemctl enable alertmanager.service
systemctl start alertmanager.service

```

通过http://alertmanagerIP:9093可查看服务是否正常

 alertmanager这里就不详细介绍了，主要是对告警信息的操作，下面在修改prometheus.yml配置文件，在prometheus.yml下配置主机地址。也可添加alertmanager job可以在prometheus targets界面上查看alertmanager的状态


重启或热加载prometheus服务查看alertmanager是否UP。

### 4.1 配置邮件告警

配置alertmanger.yml文件。

```shell
global:
  resolve_timeout: 1m
  smtp_from: 'xxxx@xxxx' #发送邮件的名称，不清楚可跟发送的邮箱名一样
  smtp_smarthost: 'aaaaa' #邮箱SMTP服务器代理地址，一般在邮件的服务器设置里面可查询到
  smtp_auth_username: 'xxxx@xxxx'  #你自己的邮箱或其他邮箱用户名称
  smtp_auth_password: ''   #邮箱的授权码，一般在邮箱的安全设置里面
  smtp_require_tls: false #不使用TLS协议
 
route:
  group_by: ['alertname'] #指定分组标签
  group_wait: 20s #同一组的告警等待时间，在该时间内同一组的告警会合并为一个邮件发送
  group_interval: 5s #相同的group之间发送告警通知的时间间隔
  repeat_interval: 12h #告警未解决时，再次发送告警的时间间隔
  receiver: 'admin' #接收者
  routes: #路由，本监控配备了子路由
  - match: #告警匹配项
      severity: 123-Warning #该处值为prometheus中告警配置里severity后面的内容，根据该处匹配不同的告警，并将该告警发给不同的接收者
    receiver: 'one'
  - match:
      severity: 456-Warning
    receiver: 'two'
receivers:
- name: 'admin' #管理员
  email_configs:
  - to: '------@------'            #收件人，此处代表管理员所有告警都要接收
    send_resolved: true
 
- name: 'one'   #根据route匹配得接收者
  email_configs:
  - to: '11111@11111'            #接收者邮箱，单引号里面用逗号隔开可以填写多个收件邮箱。
    send_resolved: true
 
- name: 'two'
  email_configs:
  - to: '1111@11111'            #接收者邮箱
    send_resolved: true
#这样可以自己根据监控规则将不同的告警发给相应负责的人
#配置完重启alertmanager服务或热加载是配置生效。
```


 alertmanager和prometheus无需部署在同一台服务器上，网络能通，端口不被占用就行。特别地，alertmanager部署的机器需要能访问互联网才能发送邮件。

 ## 5. 监控规则

 ### 5.1 配置规格

 在prometheus目录下修改配置文件prometheus.yml，定义规格文件。

 如图例中，prometheus加载规格时，会读取/data/prometheus/rules/目录下所有以rules.yml(图中手误写成了role)结尾的文件，建议每个文件中的规则属于一个不同的规则组。

做一个主机性能配置实例（自己可将for时间、定义范围修改来试验告警）

```shell
groups:                       #规则组名
- name: "Host monitoring"   
  rules:                     
  - alert: "Disk monitoring"  #当前规则组下一个规则实例
    expr: round((1 - (node_filesystem_avail_bytes{fstype=~"ext3|ext4|xfs|nfs",job="node_exporter"} / node_filesystem_size_bytes{fstype=~"ext3|ext4|xfs|nfs",job="node_exporter"})) * 100)  > 90
 
#表示分区使用率大于90%时产生告警
    for: 3m                  #满足告警条件持续多久后产生告警
    labels:                      
      severity: "warning"    #自定义标签
      alert_host: "{{ reReplaceAll \":(.*)\" \"\" $labels.instance }}" #获取完整告警服务器IP地址
    annotations:
      summary: "{{ reReplaceAll \":(.*)\" \"\" $labels.instance }} : {{ $labels.mountpoint }} 分区使用率过高"
      description: "{{ reReplaceAll \":(.*)\" \"\" $labels.instance }}的{{ $labels.mountpoint }} 分区使用大于90% (当前值: {{ $value }}%)"
 
  - alert: "CPU monitoring"
    expr: ceil(100 - sum(increase(node_cpu_seconds_total{job="node_exporter",mode="idle"}[5m]))  by(instance) / sum(increase(node_cpu_seconds_total{job="node_exporter"}[5m])) by(instance)*100) > 90
    for: 3m
    labels:
      severity: "warning"
      alert_host: "{{ reReplaceAll \":(.*)\" \"\" $labels.instance }}"
    annotations:
      summary: "{{ reReplaceAll \":(.*)\" \"\" $labels.instance }} : {{ $labels.mountpoint }} CPU使用率过高"
      description: "{{ reReplaceAll \":(.*)\" \"\" $labels.instance }}的{{ $labels.mountpoint }} CPU使用大于90% "

```

用./promtool check rules rules/*.yml检查规格文件是否配置成功。


修改监控指标测试告警（expr ....>10 for： 15s ）。


prometheus会对告警规则周期性加载，周期计算时间可在prometheus配置文件中修改evaluation_interval后的值。实例中的expr使用的事promQL,需要了解相应语法。我们可以从prometheus界面上查询相关实例来熟悉这些语法以及如何监控某一项指标。


不同的监控项内会有不同的指标，但instance、job均有，代表着哪个url上的数据（即哪一台主机）以及所属的job，而不同的监控项会有不同的值的表示，普遍有以0/1表示状态的值。同样我们就可以自己编辑grafana上一些监控数据了。


具体一些监控配置可参考网络如日志、redis、Tomcat、集群监控。总之，根据自己实际环境需要，选择相应的exporter（能力强也可以自己写），从exporter的数据作为监控指标来自己定义自己需要的告警规则，同时将告警推送给自己来实现监控。


### 5.2 进程监控实例

```shell
groups:
- name: "Process monitoring"
  rules:
  - alert: "Node monitoring"  #因为当process_exporter停掉后，无任何信息可以读取，所以单独增加一个规则，而node_exporter可以通过进行监控，所以不必单独设置一个规则。
    expr: up{job="process_exporter"} == 0
    for: 1m
    labels:
      severity: "warning"
      alert_host: "{{ reReplaceAll \":(.*)\" \"\" $labels.instance }}"
    annotations:
      summary: "{{reReplaceAll \":(.*)\" \"\" $labels.instance }} down"
      description: "{{reReplaceAll \":(.*)\" \"\" $labels.instance }} job {{ $labels.job }} last connection"
  - alert: "process monitoring"
    expr: namedprocess_namegroup_states{groupname=~"alertmanager|grafana-server|mysqld|node_exporter|prometheus",state="Sleeping",job="process_exporter"} == 0
#添加需要监控的进程，自己根据实际选择Sleeping的值来判断进程是否在运行。Running值为0时程序不一定停止运行，而Sleeping为0时程序已经完全停止。
    for: 1m
    labels:
      severity: "warning"
      alert_host: "{{ reReplaceAll \":(.*)\" \"\" $labels.instance }}"
    annotations:
      description: "{{reReplaceAll \":(.*)\" \"\" $labels.instance }} 的进程 {{ $labels.groupname}} 停止工作"

```

如果不清楚本机有哪些进程名，最简单的process_exporter监控所以进程后，grafana界面查看。

进程名在promQL中支持模糊匹配。 