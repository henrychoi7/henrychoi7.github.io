---
layout: post
title: SUA 시스템 해킹 스터디 - Universal 쉘코드
---

### 170829 4주차

이제 쉘코드 실전으로 들어가자. Windows 7 이상 운영체제는 부팅할 때마다 kernel32.dll 상위 2바이트 주소값이 바뀌기 때문에, 주소값을 하드코딩해서 사용할 수 없고, 프로세스 상에서 함수의 주소값을 동적으로 구해오는 Universal 쉘코드를 작성할 필요가 있다.

<br>
## 1. Universal 쉘코드

프로세스에서 함수의 주소값을 구하려면 dll의 시작 주소값과 dll 시작 주소로부터 함수까지의 Offset을 알아야 한다. 프로그램 실행 중에 해당 주소값을 스스로 구해서 동적으로 입력해 주는 것이 Universal 쉘코드의 목적이다. 하나씩 알아보자.

- **TEB**(*Thread Environment Block*)
  - TEB는 현재 실행되고 있는 스레드에 대한 정보를 담고 있는 구조체다. TEB의 주소는 FS 레지스터에 저장되어 있으며, 프로세스 내부적으로 TEB에 접근할 때 FS 레지스터를 사용할 수 있다. 여기서 우리가 필요한 정보는 TEB+0x30에 위치한 PEB 주소다. 여기서 중요한 것은 FS 레지스터를 이용하여 TEB에 접근할 수 있고, 결과적으로 PEB의 주소값을 알 수 있다는 것이다.

- **PEB**(*Process Environment Block*)
  - PEB는 실행 중인 프로세스에 대한 정보를 담고 있는 구조체다. 우리는 여기서 프로세스에 관련된 여러 정보들 중 PE Image(*EXE, DLL 등*)들에 대한 정보가 필요하다. PEB+0x00C에 위치한 Ldr 값은 PEB_LDR_DATA를 가리키는 포인터이고, PEB_LDR_DATA 구조체가 PE Image들에 대한 정보를 담고 있다. 해당 구조체 안에 있는 0x14 InMemoryOrderModuleList는 프로세스의 PE Image들의 데이터가 저장된 LDR_DATA_TABLE_ENTRY 구조체의 더블 링크드 리스트(*이중 연결 리스트*) 시작 주소가 저장되어 있다.

  - LDR_DATA_TABLE_ENTRY 구조체는 로드된 모듈에 대한 다양한 정보들을 저장하고 있으며, 우리가 원하는 정보는 DllBase 즉, 모듈의 주소값이다. 첫 번째 LDR_DATA_TABLE_ENTRY 구조체는 실행 파일(*EXE*) 그 자체에 대한 정보가 들어있고, 해당 구조체 내 정보 중 InMemoryOrderLinks의 FLINK(*Forward Link*)를 따라가면 첫 번째 로드된 라이브러리인 ntdll.dll 파일의 정보가 담긴 두 번째 LDR_DATA_TABLE_ENTRY 구조체가 나온다. 한 번 더 FLINK를 따라가면 두 번째 로드된 라이브러리인 kernel32.dll 파일의 정보가 담긴 LDR_DATA_TABLE_ENTRY 구조체가 나온다. 여기서 우리가 원하는 모듈인 kernel32.dll의 주소값을 알아낼 수 있다.

윈도우 내부적으로 관리되는 이러한 구조체 정보들은 WinDBG로 쉽게 확인할 수 있다. 주요 명령어들은 아래와 같다.

| 명령어 | 설명 | 사용 예시
| :------------- | :------------- |
| db | byte 단위로 메모리 표시 | db 0x7ffd6000
| dd | double word 단위로 메모리 표시 | dd 0x7ffd6000
| dt | type 표시(*구조체 등*), <br>type에 해당하는 메모리값 확인 | dt _PEB, <br>dt _PEB 0x7ffd6000

WinDBG를 처음에 사용할 때는 마이크로소프트 심볼 서버 연동이 필요하다. `Ctrl+S`를 눌러서 `Srv*C:\WebSymbols*http://msdl.microsoft.com/download/symbols`를 입력하고 `C:\Program Files\Internet Explorer\iexplore.exe` 파일을 열어보면 여러 개의 DLL 파일들이 로드된 후 특정 지점에서 멈춘다. 아래 과정대로 하면 된다.

1. `!teb` 명령어를 입력하여 TEB 주소를 구한 뒤, `dt _TEB [TEB 주소값]`을 입력하여 PEB 구조체의 주소를 확인하자.
2. `dt _PEB [PEB 주소값]`을 입력하면 PEB+0x00C에서 Ldr 값을 확인할 수 있다. 이 Ldr 값으로 PEB_LDR_DATA 구조체를 보자.
3. `dt PEB_LDR_DATA [PEB_LDR_DATA 주소값(*Ldr 값*)]`을 입력하면 InMemoryOrderModuleList 항목이 있다. 그리고, LDR_DATA_TABLE_ENTRY 구조체의 위치가 더블 링크드 리스트 형태로 저장되어 있다. 여기서 주의할 점은 `dt LDR_DATA_TABLE_ENTRY [LDR_DATA_TABLE_ENTRY 구조체의 위치(*시작 주소*)]-8`을 입력하는 데, InMemoryOrderLinks 항목은 다른 LDR_DATA_TABLE_ENTRY 내 InMemoryOrderLinks를 가리키고 있기 때문이다. 실제로 8을 빼면 iexplore.exe 파일의 정보가 나온다.
4. 다음 FLINK가 가리키고 있는 주소(*LDR_DATA_TABLE_ENTRY-8*)를 따라가면 ntdll.dll 파일의 정보가 나오고, 한 번 더 FLINK를 따라가면 kernel32.dll 모듈의 정보가 나온다. 최종적으로 우리는 kernel32.dll의 DllBase 주소값을 알 수 있다.
5. 이제 고정적인 함수의 Offset을 더해주면 쉽게 함수의 주소를 계산할 수 있다.


- **IMAGE_EXPORT_DIRECTORY**
  - DLL은 자신이 어떤 함수들을 Export하고 있는지에 대한 정보를 PE Header에 저장하고 있다. 이 정보들은 PE Header IMAGE_OPTIONAL_HEADER32의 Data Directory 배열의 첫 번째 구조체인 Export Table에 저장되어 있다.

Export Table은 IMAGE_EXPORT_DIRECTORY 구조체로 되어 있으며 구성은 아래와 같다.

```c
typedef struct _IMAGE_EXPORT_DIRECTORY {
  DWORD   Characteristics
  DWORD   TimeDateStamp
  WORD    MajorVersion
  WORD    MinorVersion
  DWORD   Name
  DWORD   Base
  DWORD   NumberOfFunctions
  DWORD   NumberOfNames
  DWORD   AddressOfFunctions    // 함수 주소 배열(EAT)
  DWORD   AddressOfNames        // 함수명 배열
  DWORD   AddressOfNameOrdinals // 함수 서수 배열
} IMAGE_EXPORT_DIRECTORY, *PIMAGE_EXPORT_DIRECTORY
```
> AddressOfFunctions는 실제 함수의 시작 주소까지의 Offset 배열을 가리키며, AddressOfNames는 함수 이름의 배열을 가리킨다. AddressOfNameOrdinals는 함수의 서수 배열을 가리킨다.

위 정보들을 이용해 실제 함수의 주소값은 아래와 같은 과정을 거쳐 구할 수 있다.

**1) 함수명 배열로 이동해서 원하는 함수의 이름과 해당 인덱스를 찾는다.**<br>
**2) Ordinals 배열에서 인덱스에 해당하는 서수 인덱스 값을 찾는다.**<br>
**3) EAT 배열에서 서수 인덱스에서 해당하는 함수 Offset을 확인한다.**<br>
**4) DLL Base 주소와 Offset을 더해서 함수의 실제 주소를 구한다.**

주의할 것은 EAT, 함수명 배열 모두 직접 값이 들어있는 것이 아니라 RVA(*상대 주소*) 값의 배열이다. 이 모든 과정이 어려워 보일 수 있겠지만, 쉽게 말해서 EAT에서 함수의 Offset을 구하고, Base 주소에 더해주는 과정이다.

(*다음에 계속!*)

<br>
## [질문 내용 정리]

- **프로세스란?**

우리가 OS에서 작업을 할 때 워드, 음악 플레이어 정도는 동시에 켜 둔 상태에서 작업한다. 동시에 이러한 작업을 수행할 수 있는 것은 CPU가 시간을 분할하여 CPU를 사용할 수 있는 제어권을 각각의 프로그램에게 한 번씩 나누어주고 있기 때문이다. 보통 이 하나의 작업 즉, 운영체제에서 실행 중인 하나의 프로그램을 프로세스라고 하며 작업이 여러 개 이루어진다는 것은 프로세스가 여러 개가 동시에 동작하고 있다는 의미이다.

- **TEB, PEB 구조체?**

PEB(*Process Environment Block*)는 프로세스의 정보를 담고 있는 구조체다. WinDBG에서 `!peb`를 쳐서 PEB의 주소와 정보를 볼 수 있으며 더 자세한 정보는 `dt_peb`를 치면 된다. TEB(*Thread Environment Block*)는 스레드의 정보를 담고 있는 구조체다. WinDBG에서 마찬가지로 `dt_teb`를 쳐서 자세한 정보를 확인할 수 있다. TEB의 주소를 구하면 PEB의 주소를 구하는 데 많은 도움이 되기 때문에 꼭 알아야 한다.

- **스레드란?**

스레드는 프로세스 내에서 실행되는 세부 작업의 단위이다. 여러 개의 스레드가 모여 하나의 프로세스를 구성하며, 이 하나의 프로세스를 구성하는 여러 개의 스레드를 멀티스레드라고 부른다. 스레드는 한 번에 하나씩 밖에 동작할 수 없으며 어떤 스레드가 먼저 실행될 지 아무도 알 수 없다. 운영체제에서 프로그램을 실행하게 되면 하나의 프로세스가 동작하며 이 프로세스는 자신을 구성하고 있는 스레드를 하나씩 CPU에게 아주 빠르게 실행시키도록 한다.

- **Ldr(LDR)?**

로드된 모듈에 대한 정보를 제공하는 PEB_LDR_DATA 구조체를 가리키는 포인터

- **프로세스와 모듈의 차이?**

프로세스란 모듈들이 모여서 이루어지는 하나의 프로그램이고, 모듈은 스레드를 구성하면서 프로세스를 지지하는 요소들이다.

- **파이썬에서 a, a[:] 차이**

파이썬에서 a는 변수고, a[:]는 슬라이싱 기법이다. `a = "hello world"` 일 때 a와 a[:]는 같지만, `a = 123` 일 때는 a가 int(*숫자*)형이기 때문에 슬라이싱이 되지 않는다. 슬라이싱은 문자열, 튜플, 리스트형에서 사용하는 기법이다.

- **WinDBG에서 심볼릭 링크 서버에서 제대로 다운이 안 받아진 오류?**

VM에서는 다운이 잘 받아졌는데 가상화하지 않은 윈도우 환경에서는 받아졌다. 아직 해결 중
