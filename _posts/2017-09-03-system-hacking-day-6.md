---
layout: post
title: SUA 시스템 해킹 스터디
---

### 170903 5주차

지난 시간에 배운 내용을 토대로, 실제로 WinDBG를 활용하여 프로세스에 로드된 kernel32.dll의 ActivateActCtx 함수의 주소값을 구할 수 있다.

[WinDBG](https://developer.microsoft.com/ko-kr/windows/hardware/windows-driver-kit)와 [PEView](http://wjradburn.com/software/) 프로그램을 이용해 보자.

이전과 동일하게 WinDBG로 iexplore.exe 파일을 열자. 그리고 `!dlls` 명령어를 이용해 로드된 dll 목록에서 kernel32.dll의 Base 주소를 확인할 수 있다.

다음 IMAGE_EXPORT_DIRECTORY를 찾기 위해 IMAGE_OPTIONAL_HEADER를 찾아야 한다. IMAGE_OPTIONAL_HEADER는 DOS_HEADER, IMAGE_FILE_HEADER의 다음에 위치하므로 각 구조체의 크기 만큼을 더해 주면 된다. (ex: `dt nt! _IMAGE_OPTIONAL_HEADER 0x764f0000 + 0xf4 + 0x14`)

여기서 우리가 찾아야할 IMAGE_EXPORT_DIRECTORY의 주소는 0x60 Offset에 존재한다. `dd [IMAGE_OPTIONAL_HEADER 주소] + 0x60` 명령어를 쳐 보자. 그렇다면, 맨 처음에 나오는 주소가 바로 IMAGE_EXPORT_DIRECTORY의 Offset 주소다. PEView에서 IMAGE_OPTIONAL_HEADER 내 EXPORT Table 값을 보면 동일한 것을 알 수 있다.

이제 Base 주소에 IMAGE_EXPORT_DIRECTORY의 Offset 주소를 더해서 IMAGE_EXPORT_DIRECTORY의 주소를 알 수 있다. `dd [Base 주소] + [IMAGE_EXPORT_DIRECTORY Offset 주소]`를 치면 함수 주소 배열, 함수명 배열, 함수 서수 배열의 Offset을 확인할 수 있다. 이 또한 PEView에서 IMAGE_EXPORT_DIRECTORY의 정보를 보면 동일한 값이 보인다.
> 지난 시간에 배웠듯이 IMAGE_EXPORT_DIRECTORY 구조체의 멤버 변수 중 이 세 가지 주요 변수는 7번째 뒤부터 나오므로 즉, 8번째부터 시작한다.

- **함수명 배열에서 원하는 함수명의 인덱스 값을 찾는다.**
> EXPORT Name Table(*ENT*) = DLL Base + ENT Offset

이제 함수명의 인덱스 값을 찾아보자. 위에서 구한 함수명 배열의 Offset에 Base 주소값을 더하면 실제 함수명 배열의 주소값이 나온다. `dd [Base 주소값] + [함수명 배열의 Offset 주소]`를 치자. 시작지점부터 각 4바이트마다 함수명의 Offset이 저장되어 있으며, Base 주소에 각 Offset 주소를 더하면 된다. 여기서 `da [Base 주소값] + [함수명 Offset 주소]`를 치면 세 번째 함수(**인덱스 2**)가 바로 ActivateActCtx인 것을 확인할 수 있다. PEView로 보면 함수명 배열(*IMAGE_NT_HEADER > SECTION.text > EXPORT Name Pointer Table*) 정보 내 동일하게 나온다.

- **서수 배열의 인덱스 2일 때의 값을 확인한다.**
> EXPORT Ordinal Table(*EOT*) = DLL Base + EOT Offset

다음은 인덱스 2일 때 서수를 확인한다. 이는 특정 함수를 구할 때, 함수명 배열과 함수 주소 배열의 인덱스가 서로 같지 않은 경우도 존재하기 때문이다. `dd [Base 주소값] + [함수 서수 배열의 Offset 주소]`를 치면 인덱스 2일 때 값은 4인 것을 확인할 수 있다.

- **함수 주소 배열(EAT)에서 인덱스 4의 값을 확인한다.**
> EXPORT Address Table(*EAT*) = DLL Base + EAT Offset

함수 주소 테이블에서 위에서 구한 서수(*인덱스 4*)에 해당하는 값을 구하면 된다. 즉, EAT에서 인덱스 4의 값, 5번째 주소값을 확인하자. `dd [Base 주소값] + [함수 주소 배열의 Offset 주소]`를 쳐서 나온 5번째 주소값이 바로 ActivateActCtx 함수의 Offset 주소다. PEView로 확인하면 Data 항목과 동일한 것을 알 수 있다.

- **Base 주소에 함수의 Offset을 더해서 최종 주소값을 구한다.**
> ActivateActCtx 주소값 = DLL Base + ActivateActCtx Offset 주소

마지막으로, ActivateActCtx 함수의 실제 주소값을 구하기 위해 `u [Base 주소값] + [ActivateActCtx 함수의 Offset 주소]`를 치면 해당 주소가 디스어셈블되고, 정확하게 kernel32.dll 내 ActivateActCtx 함수의 주소값이 나온다(*DLL Base에 ActivateActCtx Offset 주소를 더한 값과 동일하다*).

이제 함수의 주소값을 동적으로 찾는 방법을 이해할 수 있다. 다음 시간에는 지금까지의 과정을 쉘코드로 구현해 보자.

<br>
## [질문 내용 정리]

[질문 내용]


- **이중 연결 리스트란?**

자료 구조에서 배열을 갖춘 리스트 형태 중 하나로, 노드와 노드가 서로 연결되어 있는 리스트이다. 단순 연결 리스트와 다르게 노드가 이전 노드와 다음 노드로 구성되어 있어서 노드를 탐색하는 방향이 양쪽(*양방향*)으로 가능하다.

- **EAT(Export Address Table)란?**

윈도우 운영체제에서는 프로그램에서 함수를 호출할 때 라이브러리를 사용한다. 여기서 Export는 라이브러리 자신이 가지고 있는 함수를 다른 PE 파일에게 제공하는 것을 의미한다. 만약에 다른 PE 파일에서 kernel32.dll이라는 라이브러리에 존재하는 함수를 사용하고 싶을 때, kernel32.dll의 EAT을 통해 사용하고자 하는 함수의 시작 주소를 구할 수 있다. 참고로, 라이브러리 파일은 대부분 .dll, .sys이다.

- **IMAGE_EXPORT_DIRECTORY란?**

IMAGE_EXPORT_DIRECTORY는 해당 라이브러리에서 Export할 함수들에 대한 정보를 담고 있는 구조체이며 한 PE 파일 내 하나만 존재한다. 멤버 변수 중 AddressOfFunctions, AddressOfNames, AddressOfNameOrdinals은 각각 Export 하는 함수의 주소 배열, 함수 이름의 주소 배열, Ordinal(*서수*) 주소 배열을 말한다.

- **WinDBG 명령어 중 dt [구조체명] [메모리 주소]는 정확히 무슨 뜻일까?**

자료 구조를 볼 때 사용하는 명령어가 dt다. dt는 Data Type(*데이터 형*)의 약자이며, 디버깅 심볼이 다운 가능할 때 해당 구조체의 정보를 보여준다. 예를 들어, `dt ntdll! _LIST_ENTRY 0x12345678` 명령어는 0x12345678 메모리 주소를 가진 데이터를 ntdll의 LIST_ENTRY 구조체로 맞추어 보여준다는 뜻이다.

- **MAGE_EXPORT_DIRECTORY 를 찾기 위해 Base 주소에 DOS_HEADER, IMAGE_FILE_HEADER 크기를 더하는 데, 여기서 DOS_HEADER 크기가 왜 0xf4 인가?**

인터넷에 찾아보면 64바이트(*0x40*)라고 나오지만.. 뭔가 덜 더한 것 싶어 DOS_stub 크기를 봤는데, 이 크기는 가변값이라고 함. 아직 해결 중. 노가다로 4바이트 씩 더하고 싶지 않음..

- **WinDbg에서 심볼릭 링크 서버에서 제대로 다운이 안 받아진 오류?**

VM에서는 다운이 잘 받아졌는데 가상화하지 않은 윈도우 환경에서는 받아졌다. 아직 해결 중
