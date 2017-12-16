---
layout: post
title: CentOS 7에 ELK, Filebeat, AWStats 설치 후 웹 로그 및 쉘 명령어 분석하기
---

휴 드디어 중간고사가 끝났다. 다시 포스팅을 진행하자.

오늘은 CentOS 7에 ELK(*Elasticsearch + Logstash + Kibana*) Stack을 설치하겠다. 워드프레스(*WordPress*)는 전 세계에서 가장 많이 사용하는 CMS 기반 웹사이트 플랫폼이다. 그래서 워드프레스에서 사용하는 각종 테마와 플러그인 때문에 에러가 쉽게 발생하고, 해킹 공격의 대상이 되기도 한다.

웹 관리자는 보안 위협을 탐지하기 위한 로그 모니터링 시스템을 구축해야 하며, 큰 기업에서는 주로 ELK Stack을 사용하여 실시간 로그 모니터링을 구현한다. 그리고 시스템 관리자 권한 획득 등 내부 침투가 발생하는 경우를 대비하여 .bash_history 내용을 ELK로 전달해서 중요 Command List를 확인할 수 있도록 하는 것이 좋다.

이 플랫폼이 구축된다면 최종적으로 SQL Injection(*id, passwd 로그 및 HTTP Request 중 GET, POST, HEAD 등 로그 확인*) 탐지, 홈페이지 로그 및 쉘 명령어(*.bash_history 로그*) 분석, Kibana를 이용한 Command History 분석 후 해킹 관련 Command 발생 알람까지 확인할 수 있다.

## ELK, Filebeat, AWStats란?

- [Elasticsearch](https://www.elastic.co/kr/products/elasticsearch): Apache Lucene을 기반으로 개발한 실시간 분산형 RESTful 검색 및 분석 엔진

- [Logstash](https://www.elastic.co/kr/products/logstash): 각종 로그를 가져와 JSON 형태로 만들어 Elasticsearch로 데이터를 전송함

- [Kibana](https://www.elastic.co/kr/products/kibana): Elasticsearch에 저장된 데이터를 사용자에게 Dashboard 형태로 보여주는 시각화 솔루션

- [Filebeat](https://www.elastic.co/kr/products/beats/filebeat): 로그 파일을 경령화시켜서 Elasticsearch 또는 Logstash로 넘겨주는 역할을 수행함. 특히, Logstash가 과부하되면 넘기는 속도를 줄여주고, 시스템 가동이 중단되거나 다시 시작해도, 로그의 중단점을 기억하고 그 지점부터 다시 보낼 수 있음

- [AWStats](https://awstats.sourceforge.io/): 웹 로그를 분석하는 유틸리티 중 하나로, 웹사이트에 접속한 사용자들에 대한 행위 분석을 가능하게 함

## 설치 과정

우선 JDK를 설치한다(*JDK를 설치하지 않았을 경우 진행*).

`$sudo yum -y install java-1.8.0-openjdk java-1.8.0-openjdk-devel`

<p align="center">
  <img
  src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/171028/jdk1.png"
  width="80%">
</p>

그리고, 아래 환경변수를 `/etc/profile`에 추가하고 적용한다.

```shell
$sudo vim /etc/profile

# 아래 내용 추가
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.102-1.b14.el7_2.x86_64
export PATH=$PATH:$JAVA_HOME/bin
export CLASSPATH=.:$JAVA_HOME/jre/lib:$JAVA_HOME/lib:$JAVA_HOME/lib/tools.jar

# 환경변수 등록
$source /etc/profile
```

<p align="center">
  <img
  src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/171028/jdk2.png"
  width="80%">
</p>

그리고, 서버에서 bash_history(*syslog에 기록*), Apache httpd 로그를 설정한다(*로그를 기록하도록 설정했으면 할 필요 없음*). bash_history 같은 경우는 logger를 통해 syslog에 기록할 수 있도록 지정했다.

```bash
$sudo vim /etc/profile.d/cmd.sh

# 아래 내용 추가
function history_to_syslog
{
  declare cmd
  who=$(whoami)
  cmd=$(history 1)
  TTY=`tty`
  HISNAME="`basename $TTY`"
  ip=`who |grep pts/${HISNAME} |cut -f 2 -d \(|cut -f 1 -d \)`

  logger -p local7.notice -- IP=$ip USER=$who, PID=$$, PWD=$PWD, CMD=$cmd
}
trap history_to_syslog DEBUG || EXIT

HISTSIZE=10000
HISTFILESIZE=1000000
HISTTIMEFORMAT="%F %T "

export PATH USER LOGNAME MAIL HOSTNAME HISTSIZE HISTFILESIZE HISTTIMEFORMAT INPUTRC

declare -r HISTFILE

# 환경변수 등록
$sudo source /etc/profile.d/cmd.sh

# syslog 설정
$sudo vim /etc/rsyslog.conf
# 아래 내용 추가
local7.notice    /var/log/bash_history
```

<p align="center">
  <img
  src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/171028/syslog.png"
  width="80%">
</p>

이제 사용자의 명령어가 .bash_history 파일에 기록된다. 그리고 Apache httpd 로그를 설정하자. 웹에서 데이터를 보낼 때, GET에는 URL로 데이터의 정보가 대략적으로 표시되고, POST는 패킷 Body에 담아져서 데이터가 보이지 않는다. 그래서 Apache(*v2.4.29 기준*)는 기본적으로 POST 방식으로 데이터를 전송할 때 Body 내용을 로그로 남길 수 있도록 Apache의 모듈 [mod_dumpio](https://httpd.apache.org/docs/2.4/mod/mod_dumpio.html) 또는 [mod_dumpost](https://github.com/danghvu/mod_dumpost)를 사용한다. 이 모듈은 따로 설치할 필요없이 간단하게 파일만 수정하면 사용할 수 있다(*여기서는 서버에 SSL을 적용했기 때문에 ssl.conf를 수정했다. 만약에 SSL을 사용하지 않는다면 httpd.conf를 수정하면 된다*).

<p align="center">
  <img
  src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/171028/mod_dumpost.png"
  width="80%">
</p>
> mod_dumpost 모듈 설치 화면

```bash
$sudo vim /etc/httpd/conf.d/ssl.conf

<VirtualHost _default_:443>
...
# 아래 내용 추가(여기서는 mod_dumpio 사용)
LoadModule dumpio_module modules/mod_dumpio.so

ErrorLog logs/ssl_error_log
TransferLog logs/ssl_access_log

# LogLevel warn 이상으로 설정해야 함
DumpIOInput On
LogLevel dumpio:trace7
```

이제 POST Body의 로그가 ssl_error_log 파일에 남을 것이다. 다음은 ELK 순서대로 하나씩 설치를 진행한다.

### 1. Elasticsearch

`/etc/yum.repos.d/`에 elasticsearch.repo 내용을 추가한다.

```bash
[elasticsearch-5.x]
name=Elasticsearch repository for 5.x packages
baseurl=https://artifacts.elastic.co/packages/5.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
```

이제 `yum`으로 설치한다.

`$sudo yum -y install elasticsearch`

<p align="center">
  <img
  src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/171028/elastic.png"
  width="80%">
</p>

### 2. Logstash

위의 Elasticsearch 설치 과정과 동일하다.

```bash
$sudo vim /etc/yum.repos.d/logstash.repo

# 아래 내용 추가
[logstash-5.x]
name=Elastic repository for 5.x packages
baseurl=https://artifacts.elastic.co/packages/5.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md

# 설치
$sudo yum -y install logstash
```

<p align="center">
  <img
  src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/171028/logstash.png"
  width="80%">
</p>

### 3. Kibana

위의 Elasticsearch 설치 과정과 동일하다.

```bash
$sudo vim /etc/yum.repos.d/kibana.repo

# 아래 내용 추가
[kibana-5.x]
name=Kibana repository for 5.x packages
baseurl=https://artifacts.elastic.co/packages/5.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md

# 설치
$sudo yum -y install kibana
```

<p align="center">
  <img
  src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/171028/kibana1.png"
  width="80%">
</p>

Kibana를 설치했으면 Host(*호스트*), Name(*이름*), SSL(*해도 되고 안 해도 됨*)을 설정한다. SSL 설정을 했을 경우 SSL 인증서의 권한도 같이 수정해야 한다. 만약에 시스템에서 방화벽을 사용하면 포트 설정도 추가한다.

```bash
$sudo vim /etc/kibana/kibana.yml

# 서버 호스트 및 이름 입력(여기서는 gachon.com 사용)
server.host: "127.0.0.1"

server.name: "gachon.com"

# 로그가 담긴 Elasticsearch 주소 입력
elasticsearch.url: "http://127.0.0.1:9200"

# SSL 설정
# 서버를 내부에서만 사용하면 할 필요는 없다. 하지만, 외부에서 연결하여 사용할 경우에는 보안성을 위해 SSL 설정을 반드시 해야 한다.
server.ssl.enabled: true

# .crt 파일 경로 입력
server.ssl.certificate:

# .key 파일 경로 입력
server.ssl.key:

# SSL 인증서 권한 수정
$sudo chown kibana. 경로(.crt와 .key 파일 둘 다 설정해야 함)

# 필요시 방화벽 설정
$sudo firewall-cmd --add-port=5601/tcp --permanent
$sudo firewall-cmd --reload
```

### 4. Filebeat

마찬가지로 Elasticsearch 설치 과정과 동일하다.

```bash
$sudo /etc/yum.repos.d/elastic.repo

# 아래 내용 추가
[elastic-5.x]
name=Elastic repository for 5.x packages
baseurl=https://artifacts.elastic.co/packages/5.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md

# 설치
$sudo yum install -y filebeat
```

설치가 완료되면 Filebeat에서 보낼 로그의 경로를 설정한다. 여기서는 Logstash를 사용하므로, output 쪽에 logstash로 지정한다.

```bash
$sudo vim /etc/filebeat/filebeat.yml

# 아래 내용 추가
filebeat.prospector:
- input_type: log
  paths:
    # 쉘 명령어들을 기록한 로그
    - /var/log/bash_history
    # MySQL 로그
    - /var/log/mysql/*
    # Apache httpd 로그
    - /var/log/httpd/*

output.logstash:
  hosts: ["127.0.0.1:5044"]
```

그리고, Filebeat로 보내진 로그를 Elasticsearch로 보내는 설정을 한다. 참고로 Filebeat 외 다른 beat(*Metricbeat, Packetbeat, Heartbeat, Winlogbeat 등*)에서 보낸 로그를 포함하여 이를 모두 Logstash에서 직접 로그를 보낼 수 있다.

```bash
$sudo vim /etc/logstash/conf.d/filebeat.conf

# 아래 내용 추가
input {
  beats {
    port => 5044
    host => "0.0.0.0"
  }
}
output {
  elasticsearch {
    hosts => ["http://127.0.0.1:9200"]
    index => "%{[@metadata][beat]}-%{+YYYY.MM.dd}"
    document_type => "%{[@metadata][type]}"
  }
}
```

이제 Kibana에서 위에서 설정한 로그를 확인할 수 있다.

```bash
# 서비스 모두 재시작
systemctl restart elasticsearch
systemctl restart logstash
systemctl restart kibana
systemctl restart filebeat
```

혹시 서비스 시작 도중 시스템이 느려지면 RAM 4GB 이상 설정한다. 이제 `http://127.0.0.1:5601`에 접속하면 Kibana가 정상적으로 실행된다. 처음에 Index Pattern이 없다고 나온다. 그러면 `curl localhost:9200/_cat/indices?v` 명령어를 실행해서 Elasticsearch에 저장된 Index Pattern을 확인하고 Kibana에 추가하면 된다(*여기서는 filebeat-*로 추가했다. Index Pattern은 추후 원하는 대로 수정 가능하므로 참고할 것*). 이제 Dashboard 혹은 Discover 메뉴에서 보고 싶은 로그를 필터링하여 볼 수 있다.

<p align="center">
  <img
  src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/171028/curl.png"
  width="80%">
</p>
> `curl localhost:9200/_cat/indices?v` 실행 결과

<p align="center">
  <img
  src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/171028/kibana2.png"
  width="80%">
</p>
> Index Pattern 설정

<p align="center">
  <img
  src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/171028/sql_injection.png"
  width="80%">
</p>
> SQL Injection 공격 시도 MySQL 로그

<p align="center">
  <img
  src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/171028/command.png"
  width="80%">
</p>
> 사용자가 su 명령어를 입력한 로그를 추출한 결과(원하는 Command List를 입력해서 로그를 확인 가능)

마지막으로, SQL Injection 공격 시도가 있을 때 `ssl_error_log`에서 아래처럼 POST Body 메시지를 볼 수 있다. Logstash 덕분에 JSON 형식으로 잘 넘어온다.

<p align="center">
  <img
  src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/171028/post1.png"
  width="80%">
</p>

<p align="center">
  <img
  src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/171028/post2.png"
  width="80%">
</p>

### 5. AWStats

`yum -y install awstats`로 설치한 후 설정 파일을 수정한다.

`$sudo /usr/share/awstats/tools/awstats_configure.pl`

위 파일을 열어서 도메인 이름과 config 파일의 경로를 지정한다(*여기서는 도메인 이름으로 gachon.com을 사용했다*). 그리고, 마지막으로 config 파일을 수정한다.

```bash
# config 파일 수정(여기서는 gachon.com으로 사용함)
$sudo vim /etc/awstats/awstats.gachon.com.conf

# 아래 내용 추가
LogFile="/var/log/httpd/access_log"
Lang="ko"
```

AWStats를 실행하려면 아래 명령어처럼 입력하면 된다.

`/usr/local/awstats/wwwroot/cgi-bin/awstats.pl -update -config=www.gachon.com`

웹 브라우저를 실행해서 다음 URL: `http://www.gachon.com/awstats/awstats.pl?config=www.gachon.com`처럼 주소창에 입력해서 들어가면 아래와 같이 AWStats 웹 로그를 다양한 형태로 확인할 수 있다.

<p align="center">
  <img
  src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/171028/awstats.png"
  width="80%">
</p>
