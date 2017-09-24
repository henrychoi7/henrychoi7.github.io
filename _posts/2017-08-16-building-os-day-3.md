---
layout: post
title: 64비트 멀티코어 OS 만들기 - 부팅과 부트 로더 제작
---

### 170816

<br>
## 부팅과 부트 로더

드디어 PC를 부팅하는 단계이다. 이번 시간에는 부팅과 부트 로더에 대해 알아보겠다.

부팅(*Booting*)은 PC가 켜진 후에 OS가 실행되기 전까지 수행되는 일련의 작업 과정이다. 부팅 과정은 프로세서 초기화(*멀티코어 관련 처리 포함*), 메모리와 외부 디바이스 검사 및 초기화, 부트 로더를 메모리에 복사하고 OS를 시작하는 과정 등이 포함된다.

PC 환경에서 부팅 과정 중 하드웨어와 관련된 작업을 BIOS(*Basic Input/Output System*)이 담당하며, BIOS에서 수행하는 각종 테스트나 초기화를 POST(*Power On Self Test*)라고 부른다.

BIOS는 메인보드에 포함된 펌웨어(*Firmware*)의 일종으로, 입출력을 담당하는 작은 프로그램이다. 보통 PC 메인보드에 롬(*ROM*)이나 플래시 메모리로 존재하고, 전원이 켜지면서 프로세서가 가장 먼저 실행하는 코드다. 현재 만들려고 하는 OS도 OS 이미지를 메모리에 복사하고 GUI 모드로 변환할 때 BIOS의 기능을 사용할 것이다.

부트 로더는 부트스트랩(*Bootstrap*) 코드라고도 불리며, BIOS에서 처음으로 제어를 넘겨받는 부분이다. PC는 다양한 장치(*디스크, 플래시 메모리 등*)로 부팅할 수 있다. 그래서 BIOS는 POST가 완료된 후 여러 장치를 검사하여 앞부분에 부트 로더가 있는지 확인한다. 부트 로더가 있다면 코드를 **0x7C00** 주소에 복사한 후 프로세서가 **0x7C00** 주소로부터 코드를 수행하도록 하고 없으면, '*Operating System Not Found*'와 같은 메시지를 출력한다.

부트 로더가 디스크에서 메모리로 복사되어 실행되었다면 BIOS에 의해 PC가 정상적으로 구동되었다는 것을 의미한다.

부트 로더는 디스크 저장 매체에서 가장 첫 번째 섹터 MBR(*Master Boot Record*)에 있는 작은 프로그램이다. 섹터(*Sector*)는 디스크를 구성하는 데이터의 단위로, 섹터 하나는 512바이트로 구성된다. 그래서 부트 로더의 크기도 512바이트로 정해져 있고, 다양한 기능을 넣는 건 좀 힘들다. 대부분의 부트 로더는 OS 이미지를 메모리로 복사하고 제어를 넘겨주는 정형화된 작업을 수행한다.

BIOS는 읽어들인 512바이트 중 가장 마지막 2바이트의 값이 0x55, 0xAA인지 검사해서 부트 로더인지 확인한다. 읽은 데이터가 0x55, 0xAA로 끝나지 않는다면 데이터로 인식하고 부팅 과정을 더 진행하지 않는다.
> 사실 디스크의 첫 번째 섹터인 MBR 영역에는 부트 로더 외에 디스크의 파티션 정보도 있다. 파티션(*Partition*)은 디스크 영역을 논리적으로 구분하는 단위며, MBR 영역에는 4개의 파티션 영역이 있다. 자세한 건 나중에 다루기로!

<br>
## 부트 로더 제작을 위한 준비

앞으로 제작할 OS는 MINT(*Multi-core Intelligent*)64 OS입니다. MINT64 OS는 리얼 모드, 보호 모드, IA-32e 모드용 코드를 나눠서 관리한다. 부트 로더 디렉토리와 대부분 유틸리티 디렉토리는 다른 디렉토리와 달리 소스 파일 디렉토리와 임시 파일 디렉토리를 구분하지 않지만, 보호 모드 커널, IA-32e 커널, 각 응용 프로그램은 여러 파일로 복잡하게 구성되므로 혼잡하지 않게 임시 파일 디렉토리를 별도로 생성한다. 그 다음에 OS 이미지 빌드에 필요한 make 파일을 생성하자.

<br>
- **make 프로그램**

make 프로그램은 소스 파일을 이용해서 자동으로 실행 파일 또는 라이브러리 파일을 만들어주는 빌드 관련 유틸리티다. make 프로그램은 소스 파일과 목적 파일을 비교한 뒤 마지막 빌드 후에 수정된 파일만 선택하여 빌드를 수행하므로, 빌드 시간을 크게 줄여준다. make 프로그램이 빌드를 자동으로 수행하려면 각 소스 파일의 의존 관계나 빌드 순서, 빌드 옵션 등에 대한 정보가 필요하며 이러한 내용이 저장된 파일은 바로 makefile이다.

MINT64 OS에서는 디렉토리 별로 계층 관계가 있는 makefile을 구성하고 이를 통해 최종 OS 이미지를 생성하게 할 것이다. 최종 빌드 결과물을 최상위 디렉토리로 복사하고, 최상위 디렉토리의 makefile은 이 결과물을 이용해서 최종적으로 OS 이미지를 생성하는 방식으로 진행할 예정이다.

<br>
- **make 문법**

make의 문법은 복잡하고 다양하다. 기본 형식은 다음과 같이 Target, Dependency, Command 세 부분으로 구성되어 있다. Target은 생성할 파일을 나타내고, 특정 레이블(*Label*)을 지정하여 해당 레이블과 관련된 부분만 빌드하는 것도 가능하다. Dependency는 Target 생성에 필요한 소스 파일이나 오브젝트 파일 등을 나타내고, Command는 Dependency에 관련된 파일이 수정되면 실행할 명령을 의미한다.

```make
Target: Dependency
<tab> Command
<tab> Command
<tab> ...
```

<br>
**makefile 예제**

```makefile
# a.c, b.c를 통해서 output.exe 파일을 생성하는 예제 <- 주석(Comment)
all: output.exe <- 별다른 옵션이 없을 때 기본적으로 생성하는 Target을 기술

a.o: a.c
  gcc -c a.c

b.o: b.c
  gcc -c b.c

output.exe: a.o b.o
  gcc -o output.exe a.o b.o

```

make는 최종으로 생성할 Target의 의존성을 추적하면서 빌드를 처리하기 때문에 makefile은 역순으로 따라가면 된다. all은 make를 실행하면서 옵션으로 Target을 직접 명시하지 않았을 때 기본적으로 사용하는 Target이다. 여러 Target을 빌드할 때 'all' Target의 오른쪽에 순서대로 나열하면 한 번에 처리할 수 있다.

<br>
**계층적 빌드**

```makefile
# output.exe를 빌드한다.
all: output.exe

# Library 디렉토리로 이동한 후 make를 수행
libtest.a:
  make -C Library

output.o: output.c
  gcc -c output.c

output.exe: libtest.a output.o
  gcc -o output.exe output.c -ltest -L ./
```

<br>
- **MINT64용 makefile 생성**

최상위 makefile의 목적은 OS 이미지 생성을 위해 각 하위 디렉토리의 makefile을 실행하는 것이다. 지금은 부트 로더만 있으므로 해당 디렉토리로 이동해서 빌드하고, 빌드한 결과물을 복사하여 OS 이미지를 생성하는 게 전부다. 최상위 디렉토리에 makefile을 생성했으면 다음에는 부트 로더 디렉토리에 makefile을 생성한다. 부트 로더 makefile의 목적은 BootLoader.asm 파일을 nasm 어셈블리어 컴파일러로 빌드하여 BootLoader.bin 파일을 생성하는 것이다.

<br>
**MINT64 디렉토리의 makefile**

```makefile
all: BootLoader Disk.img

BootLoader:
	@echo
	@echo ========== Build Boot Loader ==========
	@echo

	make -C 00.BootLoader

	@echo
	@echo ========== Build Complete ==========
	@echo

Disk.img: 00.BootLoader/BootLoader.bin
	@echo
	@echo ========== Disk Image Build Start ==========
	@echo

	cp 00.BootLoader/BootLoader.bin Disk.img

	@echo
	@echo ========== All Build Complete ==========
	@echo

clean:
	make -C 00.BootLoader clean
	rm -f Disk.img
```

<br>
**00.BootLoader 디렉토리의 makefile**

```makefile
all: BootLoader.bin

BootLoader.bin: BootLoader.asm
	nasm -o BootLoader.bin BootLoader.asm

clean:
	rm -f BootLoader.bin
```

<br>
## 부트 로더 제작과 테스트

부트 로더를 만들려면 어셈블리어 명령어를 알아둬야 한다. 어셈블리어 전체는 [이 곳](http://index-of.co.uk/Assembly/vangelis.pdf)에서 확인할 수 있다.
> - JMP A: 무조건 해당 주소로 이동하여 A 위치의 코드 실행
> - JE, JA, JB, JZ, JNE, JNA, JNB, JNZ A: 조건 분기 명령으로 FLAGS 레지스터의 값에 따라 JMP 수행한다. 일반적으로 값을 비교하는 CMP 명령어와 함께 사용되며 각각 Equal(E), Above(A), Bellow(B), Zero(Z), Not(N) 등의 다양한 조건을 포함한다.
> 어셈블리어 문법은 크게 AT&T 문법과 인텔 문법 두 가지로 나뉜다. 가장 큰 차이점은 인텔 문법에서 '명령어(*Command*) 대상(*Destination*), 원본(*Source*)' 순서지만, AT&T는 '명령어 원본, 대상' 순서로 표기한다. 참고로, NASM은 인텔 문법을 따른다.

00.BootLoader 디렉토리에 BootLoader.asm 파일을 생성하고 빌드가 정상적으로 끝나면 MINT64 OS의 최상위 디렉토리에 Disk.img 파일이 생성된다.

<br>
**00.BootLoader 디렉토리의 BootLoader.asm**

```asm
[ORG 0x00]						; 코드의 시작 주소를 0x00으로 설정
[BITS 16]						  ; 이하의 코드는 16비트 코드로 설정

SECTION .text					; text 섹션(세그먼트)을 정의

jmp $							    ; 현재 위치에서 무한 루프 수행

times 510 - ( $ - $$ ) db 0x00	; $: 현재 라인의 주소
								                ; $$: 현재 섹션(.text)의 시작 주소
                                ; $ - $$: 현재 섹션을 기준으로 하는 오프셋
                                ; 510 - ( $ - $$ ): 현재부터 주소 510까지
                                ; db 0x00: 1바이트를 선언하고 값은 0x00
                                ; time: 반복 수행
                                ; 현재 위치에서 주소 510까지 0x00으로 채움
db 0x55							            ; 1바이트를 선언하고 값은 0x55
db 0xAA							            ; 1바이트를 선언하고 값은 0xAA
                                ; 주소 511, 512에 0x55, 0xAA를 써서 부트 섹터로 표기함
```

이제 QEMU를 사용해서 테스트할 수 있다. QEMU는 가상머신 실행 파일, 옵션과 함께 실행하는 배치 파일로 구성되어 있다. 리눅스에서 아래 명령어를 사용해서 부트 로더가 정상적으로 실행되는 지 확인해 보자.

`qemu-system-x86_64 -L . -m 64 -fda {MINT64 디렉토리 내 Disk.img 위치} -localtime -M pc`

MINT64 OS 부트 로더에도 한 번 화면 버퍼와 화면 제어 기능을 넣어보자. 화면에 문자를 출력하려면 현재 동작 중인 화면 모드와 관련된 비디오 메모리의 주소를 알아야 한다. 비디오 메모리는 화면 출력과 관계된 메모리로, 모드 별 정해진 형식에 따라 데이터를 채우면 화면에 원하는 문자나 그림을 출력하는 구조로 되어 있다.

(*다음에 계속!*)
