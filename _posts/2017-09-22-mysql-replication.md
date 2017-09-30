---
layout: post
title: MySQL Group Replication 설정하기
---

### 170922

CentOS에 MySQL 서버를 구축했으면 마스터(Slave)와 슬레이브(Slave)를 이용한 MySQL 데이터베이스 복제(Database Replication)을 적용해보자. 데이터베이스 복제는 한 서버에서 생긴 DB 변화를 다른 서버로 똑같이 적용하는 것이다. 마스터와 슬레이브를 설정하면 일방향(One-side) 데이터베이스 복제 기능이 활성화되고, 마스터와 마스터를 설정하면 양방향(Two-side) 데이터베이스 복제가 활성화된다. 이 글에서는 일방향을 다루겠다.

데이터베이스 복제 기능을 설정하기 전에, 마스터와 슬레이브에 MySQL DB가 설치 및 설정되어 있는지 확인한다. 그리고, 방화벽에 MySQL 포트 3306 허용 및 MySQL 서비스 시작도 철저히 확인할 것!
> 참고로, 여기서는 MySQL DB 이름을 wordpress, 계정 이름을 wordpress로 하겠다.

우선 마스터의 MySQL DB부터 설정하자.

```shell
# 우선 마스터에서 MySQL Root 계정으로 접속!
mysql -u root -p

# 데이터베이스 복제 기능을 적용하고 싶은 DB를 생성
mysql> create database wordpress;

# 데이터베이스 복제 기능을 적용하고 싶은 계정을 만든 후, 권한 설정
mysql> create user 'wordpress'@'마스터 IP' identified by 'DB 계정 비밀번호';

mysql> grant all on wordpress.* to 'wordpress'@'마스터 IP';

mysql> flush privileges;

mysql> exit
```

이제 마스터에서 데이터베이스 복제 기능을 설정한다.

```shell
vim /etc/my.cnf

# vim /etc/my.cnf 파일 내 아래 내용을 추가한다. server-id는 고유번호고, binlog-do-db는 데이터베이스 복제를 실행할 마스터의 DB 이름
server-id=1
binlog-do-db=wordpress
log-bin=mysql-bin

# MySQL 서비스 재시작
systemctl restart mysqld

# MySQL 로그인 후 슬레이브 설정
mysql -u root -p

mysql> grant replication slave on *.* to 'wordpress'@'슬레이브 IP' identified by 'DB 계정 비밀번호';

mysql> flush privileges;

# 해당 데이터베이스에서 잠깐 읽기 사용을 금지하고, 마스터 상태 확인
mysql> show databases;

mysql> use wordpress;

mysql> flush tables with read lock;

mysql> show master status;

mysql> exit
```

마스터 상태를 확인하면 아래와 같이 나온다.

<p style="text-align:center;">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/170922/master1.png" width="80%">
</p>

이제 마스터에서 MySQL DB를 백업하고 슬레이브로 옮겨보자.

```shell
mysqldump -u root -p wordpress > wordpress.sql

# SCP를 활용해도 되나, rsync도 가능
scp wordpress.sql root@192.168.0.13:/root/

# 만약에 위 명령어가 권한이 없거나 에러가 나면 서버 내 방화벽, 서비스를 확인하거나 아래처럼 디렉토리를 변경해도 됨
scp wordpress.sql henrychoi@192.168.0.13:/tmp/

# 전송이 끝났으면 MySQL DB에 접속해서 읽기 금지 풀기
mysql -u root -p

mysql> unlock tables;
```

자, 마스터 설정이 모두 끝났다. 이제 슬레이브를 만져보자. 슬레이브도 처음엔 마스터와 마찬가지로, my.cnf 파일을 수정하고 나서 MySQL DB에 접속한다.

```shell
vim /etc/my.cnf

# vim /etc/my.cnf 파일 내 아래 내용을 추가한다. server-id는 고유번호고, binlog-do-db는 데이터베이스 복제를 실행할 마스터의 DB 이름이며 여기서 마스터와 슬레이브의 server-id는 동일하면 안됨
server-id=2
binlog-do-db=wordpress
log-bin=mysql-bin

# MySQL 서비스 재시작
systemctl restart mysqld

# MySQL DB에 마스터의 MySQL DB 백업 파일을 불러온다. 이 때 에러가 발생할 수 있는데, 간단히 wordpress 데이터베이스를 만들면 됨
mysql -u root -p wordpress < wordpress.sql

# MySQL DB 계정 생성과 마스터 서버의 정보를 입력
mysql -u root -p

mysql> create user 'wordpress'@'슬레이브 IP' identified by 'DB 계정 비밀번호';

mysql> grant all on wordpress.* to 'wordpress'@'슬레이브 IP';

mysql> grant replication slave on *.* to 'wordpress'@'슬레이브 IP' identified by 'DB 계정 비밀번호';

mysql> flush privileges;

mysql> change master to master_host='192.168.0.11', master_user='wordpress', master_password='마스터 DB 계정 비밀번호', master_log_file='mysql-bin.000001', master_log_pos='594';

# 슬레이브 시작
mysql> start slave;
```

이제 마스터에서 MySQL DB를 수정하면 그 내용이 슬레이브의 MySQL DB로 복제된다. 위 모든 과정의 설정 결과를 아래처럼 확인할 수 있다.

<p style="text-align:center;">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/170922/master2.png" width="80%">
</p>
> 마스터 MySQL DB

<p style="text-align:center;">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/170922/slave.png" width="80%">
</p>
> 슬레이브 MySQL DB
