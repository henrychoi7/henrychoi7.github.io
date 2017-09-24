---
layout: post
title: SUA 시스템 해킹 스터디 - PE 파일 구조
---

### 170804 2주차

어셈블리어, 디버거, 디스어셈블러에 대한 기초 실습을 마치고, 리버싱하면서 윈도우 PE 파일을 분석하는 방법과 취약점에 대해 알아보게 되었다.

<br>
## 윈도우 실행 파일 구조

윈도우 해킹을 하기 위해서는 당연히 윈도우 실행 파일 구조를 알아야 한다.

<br>
### 1. PE 파일

윈도우 실행 파일을 PE(*Portable Executable*) 파일이라 부른다. PE는 다양한 정보를 가진 커다란 구조체들로 이루어져 있으며, 내부에 수많은 테이블과 멤버들을 가지고 있다.

종류 | 설명
---- | ----
EXE | 실행 파일
SCR | 실행 파일(화면 보호기)
DLL | 라이브러리
OCX | 라이브러리(ActiveX)
SYS | 시스템 드라이버
OBJ | 오브젝트 파일

PE 파일을 공부하는 것은 PE 헤더 구조체 그 자체를 공부하는 것이라 할 수 있다. PE 파일은 파일에 존재할 때의 구조와 메모리에 로드된 후의 모습이 달라지는데, **파일** 에서는 첫 바이트부터의 거리를 뜻하는 *offset* 을 사용하고, **메모리** 에서는 VA(*Virtual Address, 가상 주소*)와 RVA(*Relative Virtual Address, 상대적 가상 주소*)를 사용한다.

> 고정 주소 대신 상대 주소를 사용하는 이유는 PE 파일이 메모리에 로드될 때 한 주소에 고정적으로 로딩되는 것이 아니기 때문이다.

> 메모리에 로드된 후 조금 사이즈가 커진다. 일반적으로 File Alignment 값보다 Section Alignment 값이 더 크기 때문이다. Alignment란, 여러 가지 내부 연산 등 처리 상의 효율성을 위해 특정 단위로 간격을 맞춰주는 것을 말하며 PE에서 남는 공간은 널바이트로 채워주게 된다.

<br>
- **Image_DOS_Header와 DOS Stub**

PE 포맷의 시작 부분에 위치한 40바이트인 구조체인 DOS Header와 Stub은 Windows가 아닌 DOS 운영체제를 위한 것이며 DOS에서 PE 파일이 실행되는 경우를 위해 만들어진 것이다. 하지만, 요즘 DOS를 사용하는 경우가 거의 없고 헤더 내용도 대부분 지금 사용하지 않는다.

<br>
```c
typedef struct IMAGE_DOS_HEADER {  // DOS Header
  WORD e_magic;                   // Magic Number
  WORD e_cblp;
  WORD e_cp;
  WORD e_crlc;                    // Relocations
  ...
  WORD e_res2[10];                // Reserved words
  LONG e_lfanew;                  // File address of new exe header
} IMAGE_DOS_HEADER, *PIMAGE_DOS_HEADER; // winNT.h 에 포함
```
<br>

**e_magic** : 해당 파일이 PE 파일임을 나타내 주는 첫 2개 바이트로, MZ(*5A4D*)로 고정되어 있음

**e_lfanew** : NT Header(*IMAGE_NT_HEADERS*)가 시작되는 위치의 offset

**DOS Stub** : 대부분의 PE 파일에 존재하지만 사실 없어도 실행에 지장이 없는 DOS용 실행 코드
> 해당 부분은 16비트 코드라 32비트 윈도우에서 실행 조차 되지 않는다.

<br>
- **Image_NT_Headers**

Image_NT_Headers는 NT 헤더임을 나타내는 시그니처인 "*P E 0 0*" 4바이트를 시작으로, FileHeader와 OptionalHeader를 멤버로 가지는 구조체다.

```c
typedef struct _IMAGE_NT_HEADERS {
  DWORD Signature;
  IMAGE_FILE_HEADER FileHeader;
  IMAGE_OPTIONAL_HEADER32 OptionalHeader;
} IMAGE_NT_HEADERS32, *PIMAGE_NT_HEADERS32;
```

<br>
  - **FileHeader**

```c
typedef struct _IMAGE_FILE_HEADER {
  WORD Machine;                     // 이 파일의 실행 대상 플랫폼(Intel386, Intel64, ARM 등)
  WORD NumberOfSections;            // 이 파일에 존재하는 섹션의 수
  DWORD TimeDateStamp;
  DWORD PointerToSymbolTable;
  DWORD NumberOfSymbols;
  WORD SizeOfOptionalHeader;        // OptionalHeader의 크기
  WORD Characteristics;             // 이 파일이 DLL인지, 실행 파일인지 PE 파일의 특성을 알려줌
} IMAGE_FILE_HEADER, *PIMAGE_FILE_HEADER; // 위 멤버의 상수 값은 WinNT.h 에 정의되어 있음
```

아래는 WinNT.h 에 정의된 Characteristics 값이며 최종 값은 해당되는 속성들의 OR 값으로 표시한다.

```c
#define IMAGE_FILE_RELOCS_STRIPPED      0x0001
#define IMAGE_FILE_EXECUTABLE_IMAGE     0x0002
// File is executable
#define IMAGE_FILE_LINE_NUMS_STRIPPED   0x0004
#define IMAGE_FILE_LOCAL_SYMS_STRIPPED  0x0008
#define IMAGE_FILE_32BIT_MACHINE        0x0100
// 32 bit word machine.
...
#define IMAGE_FILE_NET_RUN_FROM_SWAP    0x0800
#define IMAGE_FILE_SYSTEM               0x1000
#define IMAGE_FILE_DLL                  0x2000
// File is a DLL.
```

<br>
  - **Image_Optional_Header**

```c
typedef struct _IMAGE_OPTIONAL_HEADER {
  WORD Magic;                           // Image_Optional_Header32인지 64인지를 구분
  ...
  DWORD AddressOfEntryPoint;            // 파일이 메모리에 매핑된 후의 코드 시작 주소를 나타냄
  ...
  DWORD ImageBase;                      // PE 로더는 ImageBase 값에 위 AddressOfEntryPoint 값을 더해서 코드 시작 지점을 설정함
  DWORD SectionAlignment;               // 메모리에서의 정렬값
  DWORD FileAlignment;                  // 파일 상태에서의 정렬값
  // 섹션에서 크기가 남더라도 0으로 채워서 Alignment 값을 맞춰준다. 각 섹션은 반드시 Alignment의 배수여야만 함.
  ...
  WORD Subsystem;                       // 동작 환경을 정의
  // 시스템 드라이버 파일인 sys는 0x1, 대부분 윈도우 기반 GUI 프로그램의 경우 0x2, CLI 프로그램의 경우 0x3의 값을 가짐

  DWORD NumberOfRvaAndSizes;            // DataDirectory의 디렉토리 수를 정해줄 수 있음(일반적으로 16개의 디렉토리를 가짐)
  IMAGE_DATA_DIRECTORY DataDirectory[IMAGE_NUMBEROF_DIRECTORY_ENTRIES];
} IMAGE_OPTIONAL_HEADER32, *PIMAGE_OPTIONAL_HEADER32;
```

DataDirectory는 16개의 구조체 배열로 이루어져 있으며 디렉토리 별로 각각의 정보를 담고 있다.

**Export Directory** : DLL 등의 파일에서 외부에 함수를 공개하기 위한 정보들을 가짐<br>
**Import Directory** : 프로그램 실행을 위해 Import하는 DLL 이름과 사용할 함수 정보가 담긴 INT, IAT 주소 등의 정보들을 가짐

여기서 중요한 건 Import Directory는 외부 DLL과 함수를 사용할 때 필요한 정보를 담고 있다는 것이다. 외부 DLL 파일의 함수 주소를 가져올 때 *Export Table* 를 참고하고,
여기서 찾은 주소를 *Import Table* 을 활용해서 IAT(*Import Address Table*)에 저장해두고 사용한다.

<br>
- **Section Header**

섹션은 실제 파일의 내용들이 존재하는 부분으로, 각 섹션 별로 섹션의 정보를 담고 있는 헤더를 가지고 있다.

```c
typedef struct _IMAGE_SECTION_HEADER {
  BYTE Name[IMAGE_SIZEOF_SHORT_NAME];
  union {
    DWORD PhysicalAddress;
    DWORD VirtualSize;                  // 메모리 상에서의 크기
  } Misc;
  DWORD VirtualAddress;                 // 메모리 상에서의 주소
  DWORD SizeOfRawData;                  // 파일 상에서의 크기
  DWORD PointerToRawData;               // 파일 상에서의 offset
  ...
  DWORD Characteristics;
} IMAGE_SECTION_HEADER, *PIMAGE_SECTION_HEADER;
```

마지막으로 Characteristics는 각 섹션의 특징을 알려준다.

```c
#define IMAGE_SCN_CNT_CODE                0x00000020
// Section contains code.
#define IMAGE_SCN_CNT_INITIALIZED_DATA    0x00000040
// Section contains initialized data.
#define IMAGE_SCN_CNT_UNINITIALIZED_DATA  0x00000080
// Section contains uninitialized data.
...
#define IMAGE_SCN_MEM_SHARED              0x10000000
// Section is shareable.
#define IMAGE_SCN_MEM_EXECUTE             0x20000000
// Section is executable.
#define IMAGE_SCN_MEM_READ                0x40000000
// Section is readable.
#define IMAGE_SCN_MEM_WRITE               0x80000000
// Section is writeable.
```

*다음 포스트에서 계속!*
