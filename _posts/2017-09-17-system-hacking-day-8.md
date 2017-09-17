---
layout: post
title: SUA 시스템 해킹 스터디
---

### 170917 7주차

여태까지 다룬 Universal 쉘코드는 단순히 cmd 명령을 시키는 코드였다. 이는 주로 취약점에 대한 공격이 가능하다는 증명 코드(*Proof of Concept, PoC*)로 사용되는 쉘코드고, 실제 공격에 사용하는 쉘코드는 더 다양하다.

<br>
## 2. 포트 바인딩 쉘코드

일반적으로, 시스템 권한 획득은 대상 시스템 쉘 접속을 의미한다. 쉘을 접속할 수 있게 포트를 열도록 해 주는 쉘코드를 **포트 바인딩 쉘코드** 라고 하며, 실행되면 특정 포트를 열고 공격자가 인증 절차 없이 공격 대상 시스템에 접속할 수 있도록 해 준다.

사실 모든 쉘코드는 Universal 쉘코드라고 봐도 무방하다. 특히 포트 바인딩 쉘코드처럼 기능이 많아지고 강력해질수록 작성 과정이 쉽지 않지만, 우리에게는 Metasploit이라는 프레임워크(*Framework*)가 있다.
> Metasploit은 포트 스캐닝, Exploit, 쉘코드 생성 등 침투 테스트 시 필요한 다양한 기능들을 모듈화한 Framework다.

Metasploit Framework는 [공식 홈페이지](https://www.metasploit.com/)에서 다운 받거나 [Kali Linux](https://www.kali.org/) OS를 설치하면 사용할 수 있다. 여기서는 Kali Linux를 구동해서 쉘코드 생성 기능을 가진 msfvenom 모듈을 사용했다.

Kali Linux에 로그인한 후, 터미널을 열고 `msfvenom -h` 명령을 실행해 보자. 자세한 사용법은 [공식 문서](https://www.offensive-security.com/metasploit-unleashed/msfvenom/)나 [GitHub](https://github.com/rapid7/metasploit-framework/wiki/How-to-use-msfvenom)를 참고하면 된다. 기본적으로 출력 형식, 포맷, 아키텍처, 플랫폼을 적으면 된다. 사용 가능한 Payload 목록은 `msfvenom -l | grep windows` 명령어를 실행해서 확인하자. 예를 들어 계산기를 띄우는 명령 수행 쉘코드를 만들어 보자.

<p style="text-align:center;">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/msfvenom1.png" width="80%">
</p>
> `msfvenom -h`

<p style="text-align:center;">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/msfvenom2.png" width="80%">
</p>
> `msfvenom -l | grep windows`

<p style="text-align:center;">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/msfvenom3.png" width="80%">
</p>
> 계산기를 띄우는 쉘코드. 비록 널바이트가 포함되어 있더라도 이는 쉘코드 인코딩을 통해 해결이 가능하다. 쉘코드 정상 동작을 위해 테스트를 하면 똑같이 cmd 명령이 실행되는 것을 확인할 수 있다.

이번에는 팝업 창을 띄워 주는 Messagebox를 실행하는 쉘코드를 Python 형식으로 출력해 본다.

<p style="text-align:center;">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/msfvenom4.png" width="80%">
</p>

Python Exploit 용 쉘코드도 쉽게 얻을 수 있으며, 아래와 같이 작성한 후 공격 목표에 따라 쉘코드만 변경하면 다양한 공격을 실행할 수 있다.

```python
import os, sys
...
# 쉘코드 입력
SHELLCODE = "\xd9\xeb\x9b\xd9\x74\x24\xf4\x31\xd2\xb2\x77\x31\xc9"
...
PAYLOAD = BUFFER + DUMMY + SHELLCODE
...
```
> 위 예시를 참고하고 다양한 쉘코드를 공부해 보자.

포트 바인딩 쉘코드는 아래와 같이 명령어를 실행하면 출력된다.

<p style="text-align:center;">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/msfvenom5.png" width="80%">
</p>

그러면 로컬에 7777번 포트가 접속 준비(*Listening*)하고 있는 것을 볼 수 있다. 외부에서 telnet, nc 등의 클라이언트 접속 프로그램으로 해당 포트에 접근하면 인증없이 바로 쉘에 접속할 수 있게 된다.
> nc(*netcat*)는 간단한 명령으로 포트 리스닝, 명령 실행 바인딩 등 다양한 네트워크 기능을 수행할 수 있게 해 준다. 꼭 알아두자.

<br>
## [질문 내용 정리]

- **Kali Linux 안에 들어있는 Metasploit 프레임워크 명령어 중 msfvenom과 msfpayload의 차이점은?**

msfvenom은 msfpayload와 msfencode 도구를 하나의 프레임워크 객체로 합친 것이다. msfpayload는 다양한 종류의 쉘코드를 출력하거나 생성하는 도구이며, msfencode는 생성된 쉘코드가 잘 동작할 수 있도록 또는 64비트 대상에 맞게 인코딩을 바꿔주는 도구다. 2015년에 이 두 가지 도구를 대체한 도구가 msfvenom이다.

- **페이로드(Payload)는 무엇인가?**

정보통신기술용어 해설에 따르면 각종 운용 및 제어(*오버헤드, 헤더*) 정보를 뺀 실제 정보가 들어있는 부분을 말한다. 또한, 악의적인 활동을 수행하는 바이러스의 구성 요소와 관련이 있으며, 페이로드가 강력할수록 바이러스의 파괴력이 더 커진다. 바이러스로 인한 데이터 파괴, 사용자 계정을 통한 스팸 메일 전송 등이 페이로드의 예이다. 최근 악성코드는 시스템 파일 파괴를 위해 페이로드를 사용하는 것보다 민감한 정보 유출과 사용자 컴퓨터로의 원격 접속을 위해 사용한다.

- **msfvenom과 msfpayload 옵션의 차이점?**

우선 하나의 예를 들어보자. calc.exe에 대해 버퍼 오버플로우 취약점을 찾기위한 쉘코드를 추출하기 위해 아래 msfpayload 명령어를 입력했다.

`msfpayload windows/exec cmd=calc.exe R | msfencode -e x86/alpha_mixed -t c -v`

이것을 msfvenom 명령어로 변환하면 다음과 같다.

`msfvenom -p windows/exec cmd=calc.exe -a x86 -f c --platform windows`

그냥 cmd 프롬프트 창을 띄우는 쉘코드를 작성하고 싶으면 아래와 같다.

`msfvenom -p windows/exec cmd=cmd -a x86 -f c --platform windows`

혹시 메시지 박스를 띄우고 싶다면 아래와 같이 하면 된다.

`msfvenom -p windows/messagebox title=“test” text=“hello” -a x86 -f python --platform windows`

- **Metasploit 프레임워크와 비슷한 것들은?**

Kali Linux에 보면 Armitage(Metasploit의 무료 버전, GUI 사용)도 있고, 취약점 관련 프레임워크 중 OpenVAS, SET(Social-Engineer Toolkit)과 Exploit Pack이 있다.
