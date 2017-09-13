---
layout: post
title: 워드프레스(WordPress) 설치하기
---

### 170910

CMS(*Content Management System*) 시스템 중 워드프레스(*WordPress*)는 활발한 커뮤니티 지원, 다양한 플러그인과 테마, 호스팅 지원 및 문서 등 아주 강력한 웹사이드 구축 플랫폼이다. 특히, 사람들이 많이 이용하는 이유 중 하나가 웹사이트의 외형을 쉽게 변경할 수 있는 기능(*테마*) 때문이다. 당장 구글에 "wordpress theme"로 검색해도 수많은 사이트들과 테마가 나온다.

세상의 모든 CMS 중 가장 많은 플러그인을 제공하고, 모바일 기기에 반응형 웹으로 자동으로 디자인이 변경되기까지! 그 밖에도 수백 가지의 기능들이 존재한다. 자, 이제 설치해보자!

여기서는 VirtualBox, CentOS, PHP, nginx(*Apache httpd*), MySQL 설치한 다음에 워드프레스를 설치하겠다. 우선 VirtualBox부터 설치하자. [VirtualBox](https://www.virtualbox.org/wiki/Downloads) 웹사이트에서 OS에 맞게 다운로드 받을 수 있다. Ubuntu에서 VirtualBox 설치 화면은 아래와 같다. CentOS iso 파일은 [CentOS](https://www.centos.org/download/) 웹사이트에서 다운로드 받을 수 있다.

<p style="text-align:center;">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/virtualbox1.jpg" width="80%">
</p>

VirtualBox를 설치하고, 미리 다운 받은 CentOS iso 파일을 지정하여 가상머신을 실행시키면 아래 화면처럼 CentOS 초기 부팅 화면이 나온다.

<p style="text-align:center;">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/virtualbox2.jpeg" width="80%">
</p>

결과적으로, 아래 화면처럼 Ubuntu Linux 내 VirtualBox에서 CentOS를 성공적으로 실행시킬 수 있다.

<p style="text-align:center;">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/centos1.jpeg" width="80%">
</p>

이제 워드프레스 설치에 앞서 PHP, nginx(*Apache httpd*), MySQL을 순서대로 설치해보자. 워드프레스는 웹 서비스를 위한 nginx(*Apache httpd*), PHP 7과 데이터를 저장하기 위한 MySQL이 필요하다.
> SSH 접속 설정, SSH Root 로그인 제한 설정, SMTP 설정, Yum 저장소 추가 설정은 가본 또는 선택이다.

PHP는 서버에서 동적으로 HTML을 구성하기 위한 서버측(*Server-side*) 스크립트 언어이다. 아래 명령어를 입력해서 설치하자.

```bash
# PHP 7 설치
yum install php70w

# PHP 7 설치 확인
yum search php70w

# PHP 7 추가 모듈 설치
yum install php70w-mysql php70w-xml php70w-soap php70w-xmlrpc php70w-mbstring php70w-json php70w-gd php70w-mcrypt
```
> 필요하면 PHP에서 시간, 보안 설정을 변경해도 좋다.

<p style="text-align:center;">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/php1.png" width="80%">
</p>
> PHP 설치 확인!

이어서 Apache httpd를 설치하자. nginx는 비동기 처리 방식의 웹 서버로 Apache httpd와 더불어 가장 많이 쓰인다. 하지만, 세팅 중 CentOS에서만 PHP 파일 인식이 되지 않아 Apache로 바꿨다.. Apache httpd 설치 명령어는 아래를 입력하면 된다.

```bash
# Apache httpd 설치
yum install httpd

# Apache httpd 설치 후 서비스 시작 명령어
systemctl start httpd
systemctl enable httpd

# nginx 설치
yum install nginx

# nginx 설치 후 서비스 시작 명령어
systemctl enable nginx.service
systemctl start nginx.service

# nginx 설정 확인 및 적용
nginx -t
nginx -s reload

# 정상적인 웹 서비스를 하도록 방화벽 설정
systemctl enable firewalld
systemctl start firewalld

firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --permanent --zone=public --add-service=https
firewall-cmd --reload
```

이제 MySQL을 설치해보자. MySQL은 전 세계에서 가장 많이 쓰이는 오픈소스 DB 중 하나로 현재 MariaDB라는 것도 있지만, 여기서는 오라클에서 주도하는 MySQL 5 버전을 사용한다. 다음 명령어로 설치한다.

```bash
yum install mysql-server
```
> 필요하면 `vi /etc/my.cnf` 파일을 수정해서 기본 설정을 수정해도 된다.

```bash
chkconfig mysqld on
service mysqld start

# MySQL 보안 강화 및 서비스 재시작
mysql_secure_installation
service mysqld restart

# MySQL 서비스 등록 및 시작
systemctl enable mysqld.service
systemctl start mysqld.service
mysql_secure_installation
systemctl restart mysqld.service
```

nginx의 경우, PHP 기능을 사용하기 위한 모듈로 PHP-FPM(*FastCGI Process Manager*)를 설치하면 된다. PHP-FPM은 프로세스 관리, 통계 관리, 서비스 시작/종료 등 여러 가지 기능을 위해 사용한다.

```bash
# PHP-FPM 설치
yum install php70w-fpm

# /etc/php-fpm.d/www.conf 파일 수정
; RPM: apache Choosed to be able to access some dir as httpd
user = nginx
; RPM: Keep a group allowed to write in log dir.
group = nginx
...
; listen = 127.0.0.1:9000
listen = /var/run/php-fpm/php-fpm.sock
...
; Default Values: user and group are set as the running user
; mode is set to 0660
;listen.owner = nobody
;listen.group = nobody
;listen.mode = 0660
listen.owner = nginx
listen.group = nginx
listen.mode = 0660
...

# PHP-FPM 서비스 등록 및 시작
systemctl enable php-fpm.service
systemctl start php-fpm.service
```

워드프레스에 필요한 기본 소프트웨어를 모두 설치하면 아래와 같이 확인 가능하다. 사실, PHP에서 제공하지 않는 몇 가지 추가 기능, 방화벽 설정, 파일 업로드 제한 설정 등 건드려야 하지만 여기서는 생략하겠다. 보안을 생각한다면 디렉토리 권한 점검을 꼭 하자!
> 신규로 만든 www 디렉토리에 권한이 불충분하면 403 Forbidden 에러가 발생할 수 있다.

<p style="text-align:center;">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/version1.png" width="80%">
</p>

이후 워드프레스에서 사용할 MySQL DB에 대한 사용자 계정 생성 및 권한 설정, DB Scheme 생성 등이 필요하다. root 계정을 사용하는 건 아주 위험한 보안 문제를 가지는 것이지만, 우선 기본적인 것만 하고 넘어가자.

```
# 초기 MySQL root 계정에 대한 비밀번호 설정이 필요하다.
mysql
mysql> use mysql;
mysql> update user set password=password('비밀번호') where user='root';

# 적용
mysql> flush privileges;

# 적용 확인
mysql> select host, user, password from user;

# \q 명령어로 나가서 root 계정으로 로그인하자.     
mysql -u root -p
# 만약에 mysql 연결 실패 에러가 뜨면 `service mysqld start`를 입력해보자.

# wordpress 사용자 계정 생성
mysql> create user wordpress@localhost identified by "chl932356";

# wordpress DB 생성
mysql> create database wordpress;

# wordpress@localhost 계정에 전체 권한 부여 및 백업 플러그인 등 DB 관리 기능 사용
mysql> grant all privileges on wordpress.* TO wordpress@localhost;

# 적용
mysql> flush privileges;
mysql> exit
```
> 아래 사진이 위 과정을 실행한 결과다.

<p style="text-align:center;">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/mysql1.png" width="80%">
</p>

이제 워드프레스 최신 버전을 설치한다. 아래 스크립트의 주석으로 설명하겠다.

```bash
# 워드프레스 다운로드
wget https://wordpress.org/latest.tar.gz
tar zxvf latest.tar.gz wordpress
mv wordpress/ /var/www/html

# 워드프레스의 미디어, 테마 또는 플러그인이 저장되는 디렉토리 생성
mkdir /var/www/wordpress/wp-content/uploads
mkdir /var/www/wordpress/wp-content/upgrade

# (Apache httpd 경우) 신규 디렉토리가 추가 되었으므로 -R(하위 디렉토리까지 포함) 옵션을 주고, 다시 권한 수정
mkdir -p /var/www/html/wordpress/wp-content/uploads
chown -R apache:apache /var/www/html/wordpress
chcon -Rv --type=httpd_sys_content_t /var/www/html/wordpress

# 웹 서비스 방지를 위해 상위 디렉토리로 옮김
cd /var/www/html/wordpress/
mv wp-config-sample.php wp-config.php
```

nginx의 경우, 홈페이지 root 디렉토리(*/var/www*)를 `/var/www/wordpress`로 변경한다.

```bash
# vi /etc/nginx/conf.d/www.conf 파일 수정
server {
       ...
       root /var/www/wordpress;
       ...
}

# 서비스 적용을 위해 nginx(Apache httpd)재시작
systemctl restart nginx.service
systemctl restart httpd
```

마지막으로, wp-config.php를 편집해서 워드프레스의 DB 설정을 할 수 있다. 보안 설정도 여기서 수정하면 된다.

```
# vi /var/www/wordpress/wp-config.php
/** The name of the database for WordPress */
define('DB_NAME', 'wordpress');

/** MySQL database username */
define('DB_USER', 'wordpress');

/** MySQL database password */
define('DB_PASSWORD', 'wp123');

/** MySQL hostname */
define('DB_HOST', 'localhost');
```

설정은 완료됐다. 이제 설정한 도메인으로 접속하면 워드프레스 설정 화면이 나온다. 기본 URL은 `http://localhost/wordpress/wp-admin/install.php`이다. 여기서는 Apache httpd를 사용했지만, nginx도 추천한다.

<p style="text-align:center;">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/wordpress1.png" width="80%">
</p>
> 위 화면처럼 안 나왔으면 천천히 다시 세팅해보자.
