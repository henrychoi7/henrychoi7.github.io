---
layout: post
title: sqlmap으로 워드프레스(WordPress) 공격 및 로그 확인하기
---

### 171002

지난 [포스트](https://handongchoi.com/2017/09/29/wordpress-sql-injection-log/)에 이어서 이번에는 [sqlmap](http://sqlmap.org/)을 사용해서 워드프레스에 공격을 시도하고, 로그를 확인하겠다.
> 테스트 환경은 지난 포스트와 동일하게 CentOS에 Apache httpd, PHP, MySQL을 설치하여 구성했다.

<p align="center">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/171002/warning.png" width="80%">
</p>

sqlmap은 모의 침투 테스트에 사용하는 오픈소스 도구다. 대상의 SQL Injection 취약점을 자동으로 분석 후 공격하고 심지어 DB 서버까지 장악할 수 있다. 해당 도구를 사용할 때는 대상의 소유자 혹은 사업자의 사전 동의를 구해야 한다. 사전 동의가 없는 스캐닝(*취약점 스캔, 포트 스캔 등*), 모의 침투 테스트 행위는 명백한 범죄이므로 주의하자.
> 특히, 악의적인 해킹은 [반의사불벌죄](https://namu.wiki/w/반의사불벌죄)에 해당되지 않으므로, 해킹 피해 고소가 들어오면 무조건 수사, 형벌을 받게 된다. 목적이 어떠하든 절대 타인의 정보통신망에 무단으로 접근하지 말자.

sqlmap을 사용하려면 우선 파이썬(*Python*) 2.x 버전을 설치해야 한다. 각각 공식 홈페이지에서 다운로드 받아 설치한다. 이 과정이 완료되면 아래 사진과 같이 확인할 수 있다.

- 파이썬(*Python*) 2.7 다운로드 : [링크](https://www.python.org/downloads/)
- sqlamp 다운로드 : [링크](http://sqlmap.org/)

<p align="center">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/171002/sqlmap1.png" width="80%">
</p>

이제 sqlmap을 본격적으로 다뤄보자. sqlmap에서 가장 기본이 되는 명령어인 -u 옵션을 써서 뒤에 파라미터가 존재하는 URL을 입력하면, 취약점 점검을 시작한다. 아래 명령어처럼 입력하면 바로 결과가 나온다.
> 여기서는 `https://www.gachon.com/?s=hello` 라는 URL을 입력했다.

`./sqlmap.py -u https://www.gachon.com/?s=hello -v 3`

`./sqlmap.py -u https://www.gachon.com/wp-login.php?action=lostpassword -v 3`
> 마지막에 `-v 3` 옵션을 주면 분석 과정 중 어떤 패턴들이 넘어가는지 확인할 수 있다.

sqlmap은 크게 5가지 정도 SQL Injection 취약점을 분석 및 공격할 수 있다.

- Boolean-based blind: 참인 임의의 값과 거짓인 임의의 값을 입력했을 때 페이지 반응을 테스트했을 때, 만약에 내용에 차이가 있으면 취약점으로 판단한다.

- Time-based blind: 입력한 시간만큼 지연한 후, 쿼리를 실행하는 함수를 이용하여 원하는 정보를 얻는 취약점이다.

- Error-based: 에러 메시지를 이용해서 원하는 정보를 얻는 취약점이다.

- UNION query-based: SQL문에서 UNION은 복수 테이블에 SQL 질의를 할 수 있게 도와주는 함수다. 이를 악용하면 다른 테이블의 값을 획득할 수 있고, 쿼리를 통해 다양한 데이터를 볼 수 있는 취약점이다.

- Stacked queries(*piggy backing*): 하나의 쿼리에 추가적인 쿼리를 삽입하는 공격이다. 세미콜론으로 쿼리를 종료하는데, 그 뒤에 추가로 입력하여 쿼리를 실행할 수 있는 취약점이다. MySQL과 PHP에서는 Stacked queries를 지원하지 않는다.

위에 썼던 명령어를 실행하면 아래와 같이 나온다.

<p align="center">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/171002/sqlmap2.png" width="80%">
</p>

sqlmap 명령을 한 번 실행하면 더 이상 SQL 질의 및 삽입 공격을 할 수 없을 때까지 공격을 수행한다. 처음에는 페이로드(*Payload*)를 보내기 전에 WAF, IDS, IPS 같은 방화벽에 존재하는지 확인한다. 그리고, 임의의 값을 넣어서 페이지에 변화가 있는지 확인하며 에러 메시지를 나타나게 한다. 하지만 `[WARNING] heuristic (basic) test shows that GET parameter '파라미터 변수' might not be injectable` 같은 메시지가 나올 경우, SQL 삽입 공격이 불가능할 것이라고 나오는 정보다.

이번에는 --dbs 옵션을 사용해서 DB 정보를 획득 시도를 진행하겠다.

`./sqlmap.py -u https://www.gachon.com/?s=hello --dbs -v 3`

`./sqlmap.py -u https://www.gachon.com/wp-login.php?action=lostpassword --dbs -v 3`

아래 화면을 보자.

<p align="center">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/171002/sqlmap3.png" width="80%">
</p>

sqlmap으로 워드프레스 웹사이트 분석 결과, `GET parameter '파라미터 변수' does not apper to be dynamic`이라는 메시지가 뜬다. 그래서 어떤 파라미터를 지정해야 동적 변수를 찾을 수 있는지 아직 연구 중이다. 하지만, sqlmap은 이 외에도 상당히 많은 공격을 수행할 수 있다.

`./sqlmap.py -u https://www.gachon.com/wp-login.php?id=1 -p id --dbms=mysql --current-user`
> 위 명령어는 -p 옵션으로 취약한 지점이 되는 파라미터를 지정 후, --dbms 옵션으로 DBMS 형태를 MySQL로 지정하고, --current-user 옵션으로 현재 DB의 User 정보를 추출하도록 한다.

<p align="center">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/171002/sqlmap4.png" width="80%">
</p>

만약에 DB와 테이블 이름까지 파악했다면, `./sqlmap.py -u https://www.gachon.com/wp-login.php?id=1 --dbms=mysql --current-user -D wordpress -T sample` 이런 식으로 테이블 내 정보까지 추출할 수 있다.

<p align="center">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/171002/sqlmap5.png" width="80%">
</p>

혹시, 현재 워드프레스보다 더 취약한 환경에서 SQL Injection 취약점 분석을 진행하고 싶다면 Acunetix 사의 웹 해킹 테스트 플랫폼 [웹사이트](http://testphp.vulnweb.com/)에 가서 하자.
> 여긴 정말 취약점이 잘 나온다.. 아래는 해당 사이트에서 sqlmap 모의 침투 테스트 결과!

<p align="center">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/171002/sqlmap6.png" width="80%">
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/171002/sqlmap7.png" width="80%">
</p>
> 위 사진을 보면 DB 계정 정보(심지어 비밀번호)가 모두 나오는 것을 확인할 수 있다.
