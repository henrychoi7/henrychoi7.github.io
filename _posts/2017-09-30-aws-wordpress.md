---
layout: post
title: 아마존 웹 서비스(AWS)에 인스턴스(Instance) 생성하기
---

워드프레스(*WordPress*) 같은 설치형 블로그는 보통 리눅스 계열 운영체제(*CentOS, Ubuntu 등*)에 설치된다. 하지만 개인이 이러한 서버를 24시간 내내 켜 놓기 어렵기 때문에 이를 USB나 VM에 설치하지 않고 간편하게 클라우드 서비스를 이용할 수 있다. 대표적인 예로, 아마존 웹 서비스(*Amazon Web Services*)의 Amazon EC2(*Amazon Elastic Compute Cloud*)가 있다. AWS에서는 이를 인스턴스(*Instance*)라고 부른다.

우선, 아마존 웹 서비스 공식 [홈페이지](https://aws.amazon.com/ko/)에 들어가서 로그인하자.

<p align="center">
  <img
  src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/170930/aws_main.png"
  width="80%">
</p>

오른쪽 위에 `가입` or `무료 계정 생성` 버튼을 눌러서 로그인하면 된다. 로그인하면 아래와 같은 창이 뜬다.

<p align="center">
  <img
  src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/170930/aws_login.png"
  width="80%">
</p>

여기서 EC2 또는 왼쪽 위에 서비스 메뉴의 EC2를 눌러서 들어가면 인스턴스 시작 버튼이 있다. 이 버튼을 누르면 AMI(*Amazon Machine Image*)를 선택할 수 있다. 여기에 있는 이미지들은 인스턴스를 시작하는 데 필요한 기본적인 소프트웨어 구성이 포함된 템블릿이다. 여기서는 CentOS 7을 선택하겠다. 인스턴스를 시작하는 과정을 아래와 같다.

<p align="center">
  <img
  src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/170930/aws_ami.png"
  width="80%">
</p>

<p align="center">
  <img
  src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/170930/aws_ami2.png"
  width="80%">
</p>

<p align="center">
  <img
  src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/170930/aws_ami3.png"
  width="80%">
</p>
> 인스턴스 정보 세부 구성을 눌러서 보안 그룹과 스토리지, 인스턴스 유형 등 개별 설정이 가능하지만 여기서는 기본 값으로 넘어가겠다. 나중에 SSH 로그인이 필요할 때는 해당 인스턴스의 보안 그룹에 인바운드, 아웃바운드 규칙을 세우면 된다.

<p align="center">
  <img
  src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/170930/aws_ami4.png"
  width="80%">
</p>

마지막으로, 시작을 누르면 키 페어를 생성할 수 있다. SSH를 통해 인스턴스에 접속하기 위해서 필요한 `.pem` 개인 키 파일이다. 키 페어 없이 인스턴스를 시작할 수 있지만, 보안을 생각한다면 아래와 같이 생성하자.

<p align="center">
  <img
  src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/170930/aws_key.png"
  width="80%">
</p>

<p align="center">
  <img
  src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/170930/aws_success.png"
  width="80%">
</p>
> 인스턴스 생성 완료!

이제 인스턴스 ID 옆에 있는 값을 눌러서 인스턴스의 상태를 확인하자. 인스턴스가 정상적으로 구동이 되고 있고, 아래에서 IPv4 퍼블릭 주소를 확인할 수 있다. 저 주소를 사용해서 SSH 접속을 할 수 있다. 위에서 다운로드 받았던 개인 키를 이용해서 SSH 접속을 시도하자.

<p align="center">
  <img
  src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/170930/instance.png"
  width="80%">
</p>

<p align="center">
  <img
  src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/170930/ssh.png"
  width="80%">
</p>
> SSH 접속 성공!

이제 인스턴스에서 워드프레스 또는 웹 애플리케이션 서버를 설치하는 등 자유롭게 원하는 대로 사용할 수 있다. 필요에 따라 보안 그룹 내 해당 인스턴스의 인바운드, 아웃바운드 규칙을 수정하면 된다.

클라우드와 모바일 서비스들이 점점 좋아지는 걸 보면, 결국 나중에는 하드한 유저들을 제외한 나머지 사람들은 컴퓨터(*PC*)를 사지 않아도 되지 않을까라는 생각이 든다. 보안을 공부하는 사람으로서 간단하게 `SQL Injection` 공격 환경을 구성하거나 사이버 침해사고 데이터 분석을 하기 위한 서버를 구축해도 되지 않을까 싶다.
