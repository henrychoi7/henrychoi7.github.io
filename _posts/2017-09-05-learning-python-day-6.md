---
layout: post
title: 파이썬(Python) 기초 - 함수 입출력, 파일 입출력
---

### 170905

우리가 사용하는 대부분의 프로그램은 입력에 따라 그에 맞는 출력을 내보내는 기능을 가지고 있다. 이 부분도 함수의 입력과 출력을 이용한다.

<br>
## 사용자 입력과 출력

사용자가 입력한 값을 어떤 변수에 대입하고 싶을 때 아래와 같이 사용한다.

```python
>>> a = input()
Life is too short, you need python
>>> a
'Life is too short, you need python'
>>>
```
> input()은 입력되는 모든 것을 문자열로 취급한다.

이 때, 프롬프트를 띄어서 사용자에게 안내 문구, 질문이 나오도록 하고 싶을 때도 있다. 그럴 때는 input()의 괄호 안에 내용을 입력하면 된다.

```python
>>> number = input("숫자를 입력하세요: ")
숫자를 입력하세요: 3
>>> print(number)
3
>>>
```

보통 print문은 입력한 자료형을 출력하는 것이지만, 그 외에도 다른 응용이 가능하다.

### 1. 큰 따옴표("")로 둘러싸인 문자열은 + 연산으로 취급한다.

```python
>>> print("life" "is" "too short") # ①
lifeistoo short
>>> print("life"+"is"+"too short") # ②
lifeistoo short
```

### 2. 문자열 띄어쓰기는 콤마로 한다.

```python
>>> print("life", "is", "too short")
life is too short
```

### 3. 한 줄에 결과값 출력하기

```python
>>> for i in range(10):
...     print(i, end=' ')
...
0 1 2 3 4 5 6 7 8 9
```
> 지난 for문에서 봤듯이 한 줄에 결과값을 계속 이어서 출력하려면 입력 인수 end를 이용해 끝 문자를 지정해야 한다.

이제 파일 읽고 쓰는 방법을 알아보자. 여태까지 "**입력**"을 받을 때는 직접 입력하고, "**출력**"할 때는 결과값을 출력하는 방식으로 프로그래밍했지만, 파일을 통해 입출력도 가능하다. 파일을 새로 만들고, 새 파일에 내용을 적고, 적은 내용을 읽어 보는 프로그램을 만들어보자.

<br>
## 파일 읽고 쓰기

파일을 생성하는 기본은 아래와 같다.

```python
f = open("새파일.txt", 'w')
f.close()

f = open("C:/Python/새파일.txt", 'w')
f.close()
```
> open() 함수는 "파일 이름, 파일 열기 모드"를 입력값으로 받고 결과값으로 파일 객체를 돌려준다.
> f.close()는 열려 있는 파일 객체를 닫아 주는 역할을 한다. 하지만, 파이썬 프로그램은 열려 있는 파일의 객체를 자동으로 닫아주기 때문에 생략해도 된다. 쓰기 모드로 열었던 파일을 닫지 않고 다시 사용하려고 하면 오류가 발생할 수 있기 때문에 참고할 것!

파일 열기 모드는 아래와 같은 것들이 있다.

| 파일 열기 모드 | 설명 |
| :------------- | :------------- |
| r       | 읽기 모드 - 파일을 읽기만 할 때 사용       |
| w       | 쓰기 모드 - 파일에 내용을 쓸 때 사용
| a       | 추가 모드 - 파일의 마지막에 새로운 내용을 추가시킬 때 사용

파일에 직접 쓰는 예제는 아래와 같다.

```python
f = open("C:/Python/새파일.txt", 'w')
for i in range(1, 11):
    data = "%d번째 줄입니다.\n" % i
    f.write(data)
f.close()

for i in range(1, 11):
    data = "%d번째 줄입니다.\n" % i
    print(data)
```
> 위 두 프로그램의 차이점은 data를 출력하는 방법이다. 첫 번째 프로그램은 data를 print 대신에 파일 객체 f의 write() 함수를 이용한 것이다.

이번에는 외부 파일을 읽어 들여 프로그램에서 사용해보자. 첫 번째 방법은 readline() 함수를 이용하는 것이다.

```python
f = open("C:/Python/새파일.txt", 'r')
line = f.readline()
print(line)
f.close()
```
> 새파일.txt를 읽기 모드로 연 후 readline() 함수를 이용해서 파일의 첫 번째 줄을 읽어 출력하는 경우다. 만약에 모든 라인을 읽어서 화면에 출력하고 싶으면 아래와 같이 작성하면 된다.

```python
f = open("C:/Python/새파일.txt", 'r')
while True:
    line = f.readline()
    if not line: break
    print(line)
f.close()

# 위 파일 입력과 아래 키보드 입력 방식이 동일하다
while 1:
    data = input()
    if not data: break
    print(data)
```
> while True:라는 무한 루프 안에서 f.readline()을 이용해 파일을 계속해서 한 줄씩 읽어들이는 경우다. 만약 더 이상 읽을 라인이 없으면 break를 수행한다. 참고로, readline()은 더 이상 읽을 라인이 없으면 None을 출력한다.

이번에는 readlines() 함수를 이용해보자. readlines() 함수는 파일의 모든 라인을 읽어서 각각의 줄을 요소로 갖는 리스트로 리턴한다. 아래를 보자.

```python
f = open("C:/Python/새파일.txt", 'r')
lines = f.readlines()
for line in lines:
    print(line)
f.close()
# 출력하면 ["1 번째 줄입니다.\n", "2 번째 줄입니다.\n", ..., "10 번째 줄입니다.\n"]라는 리스트가 된다.
```

세 번째 방법은 read() 함수를 이용한다.

```python
f = open("C:/Python/새파일.txt", 'r')
data = f.read()
print(data)
f.close()
```
> f.read()는 파일의 내용 전체를 문자열로 리턴한다. 즉, 위 예의 data는 파일의 전체 내용이다.

파일을 쓰기 모드(*'w'*)로 열면 해당 파일의 내용이 모두 사라진다. 하지만, 기존의 값을 유지하고 새로운 값만 추가할 경우, 파일을 추가 모드(*'a'*)로 열면 된다.

```python
f = open("C:/Python/새파일.txt",'a')
for i in range(11, 20):
    data = "%d번째 줄입니다.\n" % i
    f.write(data)
f.close()
```
> 위 예시는 파일을 하나 열고, write를 이용해서 파일이 원래 가지고 있던 내용 바로 다음부터 결과값을 적기 시작한다.

파일을 항상 열고 닫을 때, 만약에 자동으로 처리할 수 있다면? 이럴 때 파이썬의 with문을 쓰면 된다.

```python
# 파일을 열고 닫는 일반적인 예시
f = open("foo.txt", 'w')
f.write("Life is too short, you need python")
f.close()

# with문을 이용해 위 예제를 다시 쓴 모습
with open("foo.txt", "w") as f:
    f.write("Life is too short, you need python")
```
> with문을 사용하면 with 블록을 벗어나는 순간 열린 파일 객체 f가 자동으로 close된다.

DOS를 사용할 때 type 명령어가 바로 뒤에 적힌 파일 이름을 인수로 받아 그 내용을 출력해 주는 명령어다. 파이썬에서는 sys라는 모듈을 이용하여 입력 인수를 직접 줄 수 있다.

```python
import sys

args = sys.argv[1:]
for i in args:
    print(i)
```
> 위처럼 쓰면 입력받는 인수들을 for문을 이용해 차례대로 하나씩 출력하는 예다. sys 모듈의 argv는 명령창에서 입력한 인수들을 의미한다.

위의 예를 이용해 아래처럼 입력된 소문자를 대문자로 바꾸는 간단한 스크립트를 하나 만들 수 있다.

```python
import sys

args = sys.argv[1:]
for i in args:
    print(i.upper(), end = ' ')
```
