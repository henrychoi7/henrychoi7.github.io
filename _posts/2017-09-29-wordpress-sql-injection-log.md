---
layout: post
title: 워드프레스(WordPress) Logging 설정 후 SQL Injection 공격 로그 확인하고 SELinux 적용까지
---

### 170929

워드프레스(*WordPress*)는 기본적으로 에러, 경고, 알림을 화면에 표시하지 않는다(*이는 PHP 스크립트의 기본 성질이기도 함*). 그래서 치명적인 에러가 발생하거나, 서버에 데이터 유출 문제가 발생하는 등 전혀 알 수 없다. 그래서 워드프레스 코어나 다른 플러그인, 테마와의 충돌을 미리 알기 위해 **디버그** 모드를 활성화할 수 있다.
> 디버그 기능을 켜면 아래에서 다룰 SQL Injection 공격을 탐지할 수 있다.

워드프레스 설치 디렉토리에 가서 `wp-config.php` 파일을 아래와 같이 원하는 기능 별로 수정하면 디버깅을 사용할 수 있다.

```bash
# 에러 발생 시 화면에 표시함
define('WP_DEBUG', true);

# 에러 발생 시 화면에 표시하고 wp-content 디렉토리 내 debug.log 파일 생성 및 기록
define('WP_DEBUG_LOG', true);

# 에러 발생 시 화면에 표시하지 않고 debug.log 파일만 생성 및 기록
define('WP_DEBUG_DISPLAY', false);
```
> 위 세 가지 기능을 모두 적용하면 워드프레스 사이트에서 에러가 공개적으로 노출되지 않고, 에러 관련 사항을 로그 파일로만 확인할 수 있게 된다.

<p style="text-align:center;">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/170929/debug.png" width="80%">
</p>
> 디버깅 설정 적용

<br>
- **SQL Injection 공격**

이제 SQL Injection 공격에 대해 살짝 알아보자. 이 공격 기법은 다음 세 가지로 정의할 수 있다.

- SQL Injection 공격은 공격 대상 서버의 DB를 파괴할 수 있는 코드 삽입 기술이다.

- SQL Injection 공격은 웹 해킹 기술 중 가장 많이 알려져 있으며 보편적이다.

- SQL Injection 공격은 웹 페이지 내 입력값(*Input*)에 SQL문으로 악의적인 코드를 서버로 넣는 것이다.

SQL Injection 공격은 주로 사용자에게 입력을 요구(*예) 로그인*)할 때, 정상적인 입력값 대신에 SQL문을 넣는 것으로 발생한다. 결과적으로, 서버 DB에서 공격자가 원하는 정보를 유출하거나 변조할 수 있다. 아래 예시를 보자.

```sql
txtUserId = getRequestString("UserId");
txtSQL = "SELECT * FROM Users WHERE UserId = " + txtUserId;
```
> getRequestString에서 사용자로부터 입력값을 받았을 때, txtUserId 변수를 이용해 SELECT 구문을 생성하고 있다.

그렇다면, 디버그 기능을 활성화한 워드프레스에 직접 SQL Injection 공격을 시도하자. 공격 대상 워드프레스는 CentOS에 Apache httpd, PHP, MySQL을 설치하여 구축했으며, 워드프레스 관리자 로그인 창에 `105 OR 1=1`을 입력하여 공격을 시도하고 로그를 확인한다.
> 2017년 9월, 아직까지 SQL Injection 공격은 웹 해킹 분야에서 가장 많이 사용되고 있으며 이에 기본적인 방어 대책을 구비한 기업들이 많이 있지 않다. 하지만 국내 [정보통신망법](http://www.law.go.kr/법령/정보통신망%20이용촉진%20및%20정보보호%20등에%20관한%20법률) 제 48조 1항, `누구든지 정당한 접근권한 없이 또는 허용된 접근권한을 넘어 정보통신망에 침입해서는 안된다.`라는 말을 명심하자. 사회에서 함부로 해킹하면 형사처벌을 받는다는 말이다.

<p style="text-align:center;">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/170929/sqlinjection1.png" width="80%">
</p>
> `105 OR 1=1`을 입력 후 로그인을 시도하면?

<p style="text-align:center;">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/170929/sqlinjection2.png" width="80%">
</p>
> wp-content 디렉토리 내 debug.log 파일에 보면, PHP 경고가 뜨면서 DB 설정과 맞지 않는다는 에러가 뜬다. 하지만, 이 로그를 보고 관리자 입장에서 SQL Injection 공격인 것을 확인하기 힘들다.

> `105 OR 1=1`은 `SELECT * FROM Users WHERE UserId = 105 OR 1=1;`와 비슷한 의미다. `OR 1=1`은 항상 참인데, 만약에 Users 안에 이름이나 비밀번호가 있다면? `SELECT UserId, Name, Password FROM Users WHERE UserId = 105 or 1=1;`는 굉장히 위험할 것이다.

이번에는 해당 공격 로그를 MySQL General Log 기능을 켜서 DB에서 직접 보고, 워드프레스 플러그인 및 Apache의 access_log 파일을 활용하자.

<br>
- **MySQL 로그 디버깅**

MySQL 로그(*MySQL 구동과 모니터링, 쿼리 에러 로그 포함*)는 기본적으로 `/var/log/mysqld.log`에 기록되지만, SQL Injection 공격을 정확하게 탐지하려면 General Log 기능을 켜서 봐야 한다. General Log는 MySQL에 실행되는 전체 쿼리에 대하여 저장 가능하며, MySQL이 쿼리 요청을 받을 경우 바로 기록한다.

mysqld 서비스를 재시작할 필요 없이 MySQL General Log를 활성화할 수 있다. General Log 파일 경로는 아래와 같이 명령어를 입력할 때 보인다.

```bash
# MySQL DB 로그인
mysql -u root -p

# General Log 상태 확인
mysql> show variables like 'general%';

# General Log 활성화
mysql> set global general_log = ON;

mysql> quit
```

<p style="text-align:center;">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/170929/general.png" width="80%">
</p>
> General Log 파일 경로는 `/var/lib/mysql/gachon.log`으로 되어 있지만, `/etc/my.cnf` 파일에서 따로 지정할 수 있다. 그럴 때는 파일 및 디렉토리 권한을 따로 설정해야 한다.

이제 워드프레스가 SQL Injection 공격을 받았을 때 General Log가 어떤 형식으로 나오는 지 아래처럼 볼 수 있다. 아래 프롬프트 창에 보면, `105 or 1=1`이라고 출력되는 것을 확인할 수 있다.

<p style="text-align:center;">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/170929/sqlinjection3.png" width="80%">
</p>
> 여기서 사용한 명령어는 `tail -f /var/lib/mysql/gachon.log`, `tail -f /var/log/mysqld.log`, `tail -f /var/www/html/wp-content/debug.log`다. tail 명령어는 주로 실시간 모니터링할 때 많이 사용한다.

<br>
- **Plug-in 활용 디버깅**

워드프레스에는 다양한 테마와 편의성을 고려한 플러그인들이 있다. 사용자가 워드프레스의 보안성을 높이기 위해 몇 가지 플러그인을 설치할 수 있으며 그 중에 유명한 것들이 [Activity Log](https://ko.wordpress.org/plugins/aryo-activity-log/), [Error Log Monitor](https://ko.wordpress.org/plugins/error-log-monitor/), [WP Security Audit Log](https://ko.wordpress.org/plugins/wp-security-audit-log/) 등이 있다. 여기서는 Activity Log 플러그인을 사용하겠다. 워드프레스에 로그인한 후, 아래처럼 플러그인을 검색해서 설치하자. 설치하고 나면, Activate를 눌러서 활성화시킨다.

<p style="text-align:center;">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/170929/plugin1.png" width="80%">
</p>

그리고, 워드프레스에 SQL Injection 공격을 몇 번 시도하면 아래와 같이 Activity Log가 출력되는 것을 확인할 수 있다.

<p style="text-align:center;">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/170929/plugin2.png" width="80%">
</p>
> Description 항목에 보면 SQL문까지 확인할 수 있어서 무척 편리하다.

마지막으로, Apache의 access_log 파일을 확인하여 공격을 확인할 수 있는지 봤지만 큰 성과는 얻을 수 없었다. Apache 디렉토리인 `/etc/httpd/logs/`에서 access_log와 error_log 파일을 확인했지만, 서버 자체 HTTP 통신 에러를 기록하고 있었으며 SQL Injection 공격과 관련된 에러는 찾을 수 없었다.

<p style="text-align:center;">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/170929/apache.png" width="80%">
</p>

<br>
- **SELinux 사용하기**

이제 [SELinux](https://ko.wikipedia.org/wiki/보안_강화_리눅스)(*Security-enhanced Linux*)에 대해 알아보겠다. SELinux는 NSA(*National Security Agency*)가 개발한 Linux의 보안을 강화해 주는 보안 강화 커널이며, SQL Injection 공격보다 더 치명적인 제로-데이 공격 및 버퍼 오버플로우 등 애플리케이션 취약점으로 인한 해킹을 방지해 주는 핵심 구성요소이다.

기존 Linux의 보안 문제점 중 하나는 Root가 슈퍼 유저(*Super User*)라는 것이다. Root 권한을 획득하면 해당 시스템의 모든 정보에 접근이 가능하므로 Root 권한으로 구동되는 데몬(*Daemon*)을 최소화해야 한다. 또한, Apache 서버가 구동 시에 자식 프로세스의 소유자를 httpd.conf 파일에 지정된 User, Group으로 바꾸는 것도 이런 취약점을 방지하기 위한 것이다.
> NSA가 Linux 커널 2.6부터 정식 커널 트리에 기증한 SELinux는 바이너리가 아닌 소스이므로 안심하고 사용하자.

SELinux는 아래와 같은 특징을 가진다.

- SELinux는 방화벽, 백신, 침입탐지시스템(*IDS*)가 아닌 [Type Enforcement Framework](https://kldp.org/files/selinux_140.pdf)이다.

- SELinux 기본 규칙은 Deny ALL(*모두 거부*)이며 허용하는 규칙에 대해 Allow를 설정해야 한다. Linux 배포판에 미리 정의된 정책이 탑재되어 있다.

- 제로-데이 공격으로 시스템이 뚫렸을 때 피해 최소화가 가능하다. 예를 들어, 원격으로 Apache httpd를 해킹해서 httpd 권한을 얻어도, SELinux는 httpd가 80, 443, 8009 포트만 접속할 수 있게 TE(*Type Enforcement*)를 적용하여 공격자가 동일 네트워크 내 다른 서버로 침입이 불가능하게 만든다.

- 애플리케이션에 대해 샌드박스(*Sandbox*)를 제공하므로 버퍼 오버플로우 공격 피해를 최소화할 수 있다.

만약에 서버나 홈페이지를 공개(Public) 서비스로 전환하면 SELinux는 옵션이 아닌 필수다. SELinux를 설정하는 방법은 아래와 같다.

```shell
# SELinux 모드 확인
sestatus

vi /etc/sysconfig/selinux

# SELinux 파일 내 설정을 확인한다.
SELINUX=enforcing

# 시스템 재시작
reboot
```
> 참고로, SELinux를 설정하면 사설 인증서(Root CA)를 브라우저에 등록해서 사용할 수 없다.
