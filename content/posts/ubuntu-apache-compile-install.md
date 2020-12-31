+++
title = "Ubuntu 18.04에서 Apache HTTP 컴파일 후 설치하기"
date = 2020-02-01
[taxonomies]
categories = ["Infra"]
tags = ["ubuntu", "apache"]
+++

Apache HTTP를 수동 설치해 본 적 있으세요? 생각보다 어렵지 않습니다.

<!-- more -->

가장 쉽게 접할 수 있는 웹 애플리케이션 중에 Apache HTTP를 직접 설치해 볼게요. 저는 AWS EC2 환경에서 작업했지만, 지속적인 배포 환경 또는 로컬에서도 가능합니다. Ubuntu 18.04.3 LTS에서 설치했습니다.

```bash
$ sudo apt-get update
$ sudo apt-get install build-essential
$ sudo apt-get install libexpat1-dev libnghttp2-dev libxml2-dev
```

먼저 컴파일에 필요한 패키지부터 설치합니다.

```bash
$ mkdir apache_server
$ cd apache_server
$ wget http://mirror.navercorp.com/apache//apr/apr-1.7.0.tar.gz
$ wget http://mirror.navercorp.com/apache//apr/apr-util-1.6.1.tar.gz
$ wget https://ftp.pcre.org/pub/pcre/pcre-8.43.tar.gz
$ wget http://mirror.apache-kr.org//httpd/httpd-2.4.41.tar.gz
$ tar -xzf apr-1.7.0.tar.gz
$ tar -xzf apr-util-1.6.1.tar.gz
$ tar -xzf pcre-8.43.tar.gz
$ tar -xzf httpd-2.4.41.tar.gz
```

설치 진행을 위한 디렉터리를 만들고, 설치 파일을 다운 받아 압축을 풉니다.

```bash
$ mv apr-1.7.0 ./httpd-2.4.41/srclib/apr
$ mv apr-util-1.6.1 ./httpd-2.4.41/srclib/apr-util
$ cd pcre-8.43/
$ ./configure
$ make
$ sudo make install
```

APR과 APR 라이브러리를 컴파일 디렉터리 내부로 옮기고, PCRE를 시스템에 설치합니다.

```bash
$ cd ~/apache_server/httpd-2.4.41/
$ ./configure --prefix=/usr/local/src/apache --with-included-apr --with-included-apr-util --with-included-pcre
$ make -j4
$ sudo make install
$ cp /usr/local/src/apache/bin/apachectl /etc/init.d/httpd
```

컴파일 과정입니다. configure의 prefix 옵션 (시스템 내 설치 위치)은 수정 가능합니다. make 작업을 빠르게 하기 위해 -j 옵션을 줬습니다. 마지막으로, 시스템 부팅 시 HTTP 데몬을 시작하도록 만들었습니다.

여기까지 설치는 마무리가 됐습니다. 서버에 대한 기본 설정은 아래 파일을 수정하면 됩니다. Apache 웹 서버는 포트, 서버 이름, 모듈 추가/삭제, 로그, 서버 디렉터리 등 다양하게 수정이 가능하니 자세한 내용은 Ubuntu 공식 문서를 참고하세요.

```bash
$ sudo vi /usr/local/src/apache/conf/httpd.conf
```

아무것도 설정하지 않고 서버를 시작하면 ServerName이 등록되어 있지 않아 경고 메시지가 나옵니다. 당장 문제는 없지만 127.0.0.1를 사용하지 않거나, 타 프로그램과의 충돌을 방지하기 위해 따로 설정하는 게 좋습니다. 설정을 다 했으면 아래처럼 시작/재시작/정지 명령어를 사용할 수 있습니다.

```bash
$ sudo /etc/init.d/httpd start
$ sudo /etc/init.d/httpd restart
$ sudo /etc/init.d/httpd stop
```

정상적으로 실행되었으면 아래 화면 처럼 나올 겁니다.

<p style="text-align:center;">
    <img src="success.png" width="80%">
</p>

저는 실행하기 전에 8080 포트로 수정했습니다.
이제 Tomcat 연동, 시스템 서비스 등록, 로드 밸런싱 설정, DB 추가, API 작성, Cordova 프레임워크 등 필요에 따라, 마음대로 확장이 가능합니다! :)

뭐든지 수동 설치는 까다롭습니다. 보통 처음에 설치 과정이 제일 어렵다고 하는데, 제대로 알지 못하고 넘어가면 나중에 개발할 때 정말 고생하게 됩니다. 게다가 요즘에는 패키지 관리자를 자주 사용해서 이걸 직접 손으로 치기 쉽지 않습니다. 모든 걸 알 필요는 없습니다. 하지만, 최소한 원리는 알고 넘어갑시다.