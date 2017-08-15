---
layout: post
title: 64비트 멀티코어 OS 만들기
---

### 170726 1주차

학교에서 17-1 CTF 러닝셀을 진행하면서 운영체제를 만들게 되었다.

<br>
## GCC 설치
<br>

GCC(GNU Compiler Collection)란, 무료로 사용할 수 있는 컴파일러 관련 프로그램의 집합이다. 나는 OS X 운영체제를 사용 중이므로, [Cygwin](https://www.cygwin.com/)(윈도우에서 리눅스 같은 환경을 만들어 주는 것)을 사용하지 않겠다.

만약에 리눅스나 OS X 운영체제를 사용 중이라면 GCC는 이미 설치는 끝난 것이므로, 다음 단계인 NASM 설치 단계로 넘어가면 된다.

GCC 설치 확인과 테스트는 다음 예제를 통해 할 수 있다.

**test.c**

```c
#include <stdio.h>

int main(int argc, char** argv)
{
  printf("Hello World");
  return 0;
}
```

예제 코드를 작성 후, 저장한 다음에 아래 GCC 명령어를 입력하면 테스트까지 완료된다.

`gcc -m32 -o test32 test.c`<br>
`gcc -m64 -o test64 test.c`<br>

위 명령어를 통해 test32, test64 파일이 같은 디렉토리에 있다면 테스트가 성공한 것이다. 만약에 자신의 운영체제(리눅스)가 64비트가 아니면 test64 파일이 만들어지지 않을 테지만, 어짜피 GCC가 설치되어 있으면 소스 파일에 64비트 옵션을 활성화하여 빌드할 수 있다. 결국, 32비트와 64비트를 모두 지원하는 GCC를 만들 수 있기 때문에 상관 없다는 말~


> 혹시 test32 파일이 만들어지지 않는다면, 리눅스 운영체제에서 `sudo apt-get install gcc-multilib` 명령어를 실행하여 설치하고 나면 된다. GCC는 멀티 라이브러리를 사용한다는 옵션이 -m32, -m64 등 있기 때문에 이 라이브러리를 설치해야 빌드가 가능하다.

> 크로스 컴파일러는 GCC 덕분에 이미 있으므로 건너뛰기!

<br>
## NASM 설치
<br>

NASM(The Netwide Assembler)는 윈도우와 리눅스 등 다양한 플랫폼을 지원하는 어셈블러다. 리눅스 운영체제에서 `sudo apt-get install nasm` 명령어를 입력하면 설치된다. 설치가 끝나면 `nasm -version` 명령어를 실행하여 설치가 제대로 됐는 지 확인해 보자.

<br>
## QEMU 설치
<br>

QEMU는 오픈 소스 프로세서 에뮬레이터로 다양한 종류의 프로세서를 소프트웨어적으로 구현한 프로그램이다. x86, x86_64, ARM, SPARC, PowerPC 등 다양한 프로세서를 지원하는 몇 안되는 가상머신 SW이다. 마찬가지로, 리눅스 운영체제에서 `sudo apt-get install qemu` 명령어를 입력하면 설치된다.

*다음에 계속~!*
