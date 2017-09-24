---
layout: post
title: SUA 시스템 해킹 스터디 - 쉘코드 작성 기초
---

### 170822 3주차

이제 본격적으로 윈도우 시스템 해킹을 다룰 것이다. 저번 Exploit 예제에서 봤듯이 쉘코드는 공격이 성공한 후 실행을 시킬 실질적인 코드를 말한다.

<br>
## 1. 쉘코드 작성 원리

공격이 성공하고 원하는 코드를 실행시키려면 미리 만들어둔 기계어 코드가 필요하다. 공격이 성공하면, 프로그램 실행 흐름을 바꿔서 공격자가 원하는 특정 주소로 이동할 수 있다. CPU는 흐름이 바뀐 메모리에서 직접 코드를 읽으려 하므로 CPU가 해석할 수 있는 기계어 코드가 필요하다.

쉘코드를 작성하기 위한 기본 지식은 C언어, 어셈블리어, 디버깅 스킬이면 충분하다. 간단하게 하나 작성해 보자.

**shellcode_cmd.cpp**

```c
#include "stdafx.h"
#include "windows.h"

int _tmain(int argc, TCHAR* argv[])
{
  char cmd[4] = {'c', 'm', 'd', '₩x0'};
  WinExec(cmd, SW_SHOW);
  ExitProcess(1);
}
```
> cmd 명령을 실행하는 프로그램을 작성했다. 여기서 명령을 실행하는 함수는 WinExec()다.

디스어셈블리로 쉘코드 프로그램의 어셈블리어를 추출한 후, 이를 어셈블리어로 다시 작성하자.

**shellcode_cmd2.cpp**

```c
asm {
	// cmd
	mov  byte ptr[ebp - 4], 63h  // 'c'
	mov  byte ptr[ebp - 3], 6Dh  // 'm'
	mov  byte ptr[ebp - 2], 64h  // 'd'
	mov  byte ptr[ebp - 1], 0    // '₩x0'
	// call WindExec('cmd', SW_SHOW)
	push 5                   // SW_SHOW
	lea  eax, [ebp - 4       // eax에 'cmd' 문자열 저장
	push eax                 // 스택에 'cmd' 문자열 주소 push
	mov  eax, 0x76b32b00     // eax에 WinExec 함수 주소 저장
	call eax                 // WinExec 함수 실행
	// call ExitProcess(1)
	push 1
	mov  eax, 0x76af3cb0
	call eax
};
```
> WinExec() 함수 부분을 보면, 인자값 2개를 역순으로 스택에 PUSH한 뒤, 함수 주소를 CALL 명령으로 호출한다. 저기서 0x76b32b00라는 함수 주소는 간단한 스크립트로 가져올 수 있다.

> 함수의 주소값은 DLL이 로드되는 주소에 따라 달라지며, 윈도우에서 부팅할 때마다 kernel32.dll이 로드되는 주소가 바뀐다. 그래서, 현재 시스템에서 직접 주소값을 꼭 확인하자.

위 예제 `shellcode_cmd.cpp`와 `shellcode_cmd2.cpp` 둘 다 컴파일 후 실행하면 같은 cmd 명령이 실행된다. 하지만, 쉘코드 중간에 널바이트인 0x00이 들어가 있어서 C언어 문자열 복사 계열 함수에서 발생하는 취약점에 사용할 수 없다. 공격할 때, 쉘코드가 모두 복사되지 않고 중간에 끊어지면 공격에 실패하므로 공격의 안정성을 위해 널바이트를 제거하자.

<br>
## 2. 널바이트 제거

널바이트를 제거하는 여러 방법이 있다. 위 예제의 쉘코드에서는 cmd 문자열 뒤에 '0'을 넣는 과정에서 널바이트가 발생했다. 이를 가장 쉽게 해결하려면, '0'을 직접 쓰는 대신 레지스터나 메모리를 0으로 만든 후 해당 레지스터를 이용하며 된다. 풀이는 다음과 같다.

**shellcode_cmd3.cpp**

```c
asm {
		// cmd
		xor   ebx, ebx
		mov   [ebp-4], ebx
		mov   byte ptr[ebp - 4], 63h
		mov   byte ptr[ebp - 3], 6Dh
		mov   byte ptr[ebp - 2], 64h
		//mov byte ptr[ebp - 1], 0
		// call WindExec('cmd', SW_SHOW)
		push  5
		lea   eax, [ebp - 4]
		push  eax
		mov   eax, 0x76b32b00
		call  eax
		// call ExitProcess(1)
		push  1
		mov   eax, 0x76af3cb0
		call  eax
	};
```
> XOR을 통해 ebx 레지스터를 0으로 초기화하고, ebx 레지스터를 ebp-4의 주소에 넣어줘서 기존의 `mov byte ptr[ebp-1], 0` 코드를 대체할 수 있다.

널바이트를 제거한 후, 변경한 코드를 컴파일하여 쉘코드를 확인하면 아래와 같다.

```c
#include "stdafx.h"
#include "windows.h"

char shellcode[] = "\xc6\x45\xfc\x63"
                   "\xc6\x45\xfd\x6d"
                   "\xc6\x45\xfe\x64"
                   "\xc6\x45\xff\x00"
                   "\x6a\x05"
                   "\x8d\x45\xfc"
                   "\x50"
                   "\xb8\x00\x2b\xb3\x76"
                   "\xff\xd0"
                   "\x6a\x01"
                   "\xb8\xb0\x3c\xaf\x76"
                   "\xff\xd0";

int _tmain(int argc, TCHAR* argv[])
{
  int * shell = (int*)shellcode;
  asm {
    jmp shell;
  }
}
```
> 쉘코드에 널바이트가 없어진 걸 확인할 수 있다. 컴파일 후 실행하면 동일한 cmd 명령이 실행된다.

널바이트를 제거하는 다른 방법들은 다음과 같다.

- **널바이트가 들어가지 않은 명령어로 대체**
  - 예를 들어, `mov eax, 12h`을 `push 12h, pop eax`로 대체할 수 있다.

- **32비트 레지스터가 아닌 16비트, 8비트 레지스터 사용**
  - 32비트 레지스터는 상황에 따라 16비트, 8비트로도 사용할 수 있다. 예를 들어, 0x12를 표현할 때, 32비트 레지스터는 0x00000012로 써야하지만, 8비트로 표현하면 0x12가 된다. (*mov eax, 12h -> mov al, 12h*)
- **ADD, SUB 등의 연산 명령 사용**
  - 위 방법과 마찬가지로 ADD와 SUB 등 연산 명령을 사용할 수 있다. 예를 들어, `mov eax, 12h`을 `add eax, 12h`로 바꿀 수 있다.

이 외에도 다양한 방법들이 있으니 직접 연구해 보자.

<br>
## [질문 내용 정리]

- **Padding Oracle Attack 의미?**

암호학에서 블록 암호화할 때, 평문 데이터를 고정된 크기의 블록으로 채우고, 블록의 나머지 부분을 패딩(*Padding*)으로 채운다. 만약에 평문 데이터가 블록 크기의 배수일 경우, 패딩으로 채운 빈 블록이 생성된다. 평문 데이터의 마지막 블록이 1(*0x01*) 같이 숫자 또는 문자열이면 패딩(*0x13, 0x03, 0x18 등*)과 구분하기 어렵기 때문이다. 평문 데이터가 특정 블록 크기 만큼 채워져 있지 않으면 그 블록까지만 패딩으로 채워진다. 패딩 오라클 공격(*Padding Oracle Attack*)은 이 패딩이 올바르게 채워져 있는 지 여부에 따라 오라클(*여기서는 서버를 의미함. 응답에 대한 판독 절차 수행하는 쪽*)의 응답이 달라져서 발생하는 공격이다. 이 공격은 블록 암호화를 사용하는 CBC(*Cipher Block Chaining*) 모드 방식 암호화에서 주로 발생하며, 암호문을 오라클로 보냈을 때 오라클이 복호화하면서 올바른 패딩인지 아닌지'만' 확인해 준다는 것에서 착안한 공격이다. 8바이트 블록 기준, 패딩이 1~8개일 때까지의 경우를 모두 생각해서 IV(*Initialization Vector*)를 대입하고, 응답을 확인하면서 공격 벡터를 늘려가면 Intermediary Value를 알 수 있다. 결과적으로, Intermediary Value 값을 알면 '평문 - 어떤 암호 알고리즘 - (1차 암호문, Intermediary Value) - IV와 XOR - 최종 암호문' 과정에서 평문에 사용한 어떤 암호 알고리즘을 추측할 수 있으며, 평문 값도 알 수 있게 된다.

- **Opcode, Bytecode?**

프로세서가 메모리부터 읽고 명령을 수행할 때 필요한 일련의 값들을 기계어 코드라고 부르며 디스어셈블러, 디버깅 프로그램에서 표시된다. 이 기계어 코드 중 프로세서에 의해 바로 실행하는 게 아닌 인터프리터 기반(*자바 or CLR*) 소프트웨어에서 사용될 때 Bytecode(*바이트 코드*)라고 불린다. Opcode(*Operation Code, 명령 코드*)는 가상 또는 실제 시스템에서 어떤 동작을 수행하는 명령어를 알려주는 숫자들이다. 이 명령들은 메모리 상에 16진수 숫자로 표시되며, 예를 들어 0x1F38520A에서 0x1F가 "ADD"를 뜻할 때, 0x1F는 "ADD" 명령어의 Opcode라고 부른다.

- **Opcode(코드 바이트로 표기)를 추출해서 C언어로 Shellcode 작성할 때 깔끔(?)하게 추출하는 방법?**

이럴 때 기본적으로 사용할 수 있는 건 IDE, 디스어셈블러, objdump 외 다른 변환 툴이다. ex) objdump -D -j .data test.o, ex) gdb에서 디스어셈블 후, x/bx + 엔터를 치면 어셈블리어 명령어가 하나씩 16진수로 표기됨?

- **널바이트 제거 시 함수 주소값에 널바이트가 있으면?**

주소에 있는 널바이트는 바이트 단위로 주소를 저장하면 해결
