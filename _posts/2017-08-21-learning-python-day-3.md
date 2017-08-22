---
layout: post
title: 파이썬(Python) 기초
---

### 170821

리스트, 튜플, 딕셔너리 등 파이썬 프로그래밍의 기본적인 문법을 공부했으니 이제 if, while, for 등의 제어문에 대해 알아보겠다.

<br>
## if문

if문은 if와 else를 이용한 조건문이다. 조건문을 테스트해서 참이면 if문 바로 다음의 문장(*if 블록*)들을 수행하고, 조건문이 거짓이면 else문 다음 문장(*else 블록*)들을 수행한다. 그래서 else문은 if문 없이 독립적으로 사용할 수 없다. 기본 구조는 아래와 같다.

```
if 조건문:
    수행할 문장1
    수행할 문장2
    ...
else:
    수행할 문장A
    수행할 문장B
    ...
```
> if문을 만들 때는 if 조건문: 바로 아래 문장부터 if문에 속하는 모든 문장에 들여쓰기(*Indentation*)를 해야 한다. 다른 프로그래밍 언어와 차이가 있으니 주의하자.

> 조심할 것은 들여쓰기는 공백(`Spacebar`), 탭(`Tab`) 둘 중에 하나로 사용하자. 탭과 공백은 눈에 보이지 않는 것이기에 혼용해서 쓰면 에러가 발생할 수 있다. 최근 파이썬 프로그래머들은 공백 4개로 사용하기를 추천한다.

> 조건문 다음의 콜론(*:*)은 while이나 for, def, class문에도 문장 끝에 들어가므로 주의하자.

if 조건문에서 조건문이란, 참과 거짓을 판단하는 문장이다. 참과 거짓의 유형은 다음과 같다.

| 자료형 | 참 | 거짓
| :------------- | :------------- |
| 숫자 | 0이 아닌 숫자 | 0
| 문자열 | "abc" | ""
| 리스트 | [1, 2, 3] | []
| 튜플 | (1, 2, 3) | ()
| 딕셔너리 | {"a", "b"} | {}

조건이 참인지 거짓인지 판단할 때 자료형보다 비교연산자(`<`, `>`, `==`, `!=`, `>=`, `<=`)를 쓰는 경우가 많다. 다음 예제를 보자.

```python
>>> x = 3
>>> y = 2
>>> x > y
True
>>>
```

```python
money = 3000
if money >= 3000:
    print("택시를 타라")
else
    print("걸어가라")
...
# 택시를 타라
```

조건을 판단할 때 사용하는 다른 연산자로는 and, or, not이 있다.

| 연산자 | 설명 |
| :------------- | :------------- |
| x or y | x와 y 둘 중에 하나만 참이면 참 |
| x and y | x와 y 모두 참이어야 참
| not x | x가 거짓이면 참

```python
money = 2000
card = 1
if money >= 3000 or card:
    print("택시를 타라")
else
    print("걸어가라")
```

그리고, x in s, x not in s 같은 조건문도 있다.

| in | not in |
| :------------- | :------------- |
| x in 리스트 | x not in 리스트 |
| x in 튜플 | x not in 튜플
| x in 문자열 | x not in 문자열

예시는 아래와 같다.

```python
>>> 1 in [1, 2, 3]
True
>>> 1 not in [1, 2, 3]
False

>>> 'a' in ('a', 'b', 'c')
True
>>> 'j' not in 'python'
True

>>> pocket = ['paper', 'cellphone', 'money']
>>> if 'money' in pocket:
...     print("택시를 타고 가라")
...     # 여기에 pass를 쓰게 되면 아무런 일도 하지 않게 설정할 수 있다.
... else:
...     print("걸어가라")
...
택시를 타고 가라
>>>
```

사실 if와 else로만 다양한 조건을 판단하기 쉽지 않다. 그래서 나온 것이 elif이다.

```python
>>> pocket = ['paper', 'handphone']
>>> card = 1
>>> if 'money' in pocket:
...     print("택시를 타고가라")
... else:
...     if card:
...         print("택시를 타고가라")
...     else:
...         print("걸어가라")
...
택시를 타고가라
>>>
# 위 문장을 elif를 써서 바꿔보면 아래와 같다. elif는 파이썬에서 다중 조건 판단을 가능하게 한다.

>>> pocket = ['paper', 'cellphone']
>>> card = 1
>>> if 'money' in pocket:
...      print("택시를 타고가라")
... elif card:
...      print("택시를 타고가라")
... else:
...      print("걸어가라")
...
택시를 타고가라
# 즉, elif는 이전 조건문이 거짓일 때 수행된다. 그래서 if, elif, else 모두 사용한 구조에서는 if -> (elif) -> else 순서로 작성한다. elif는 개수에 제한이 없다. if문은 조건문 다음의 수행할 문장을 콜론 뒤에 바로 적어줄 수 있다.
```

<br>
## while문

일반적으로, 문장을 반복해서 수행할 때 while문을 사용한다. while문은 조건문이 참인 동안에 while문 아래에 속하는 문장들이 반복해서 수행된다. 예제는 다음과 같다.

```python
>>> treeHit = 0
>>> while treeHit < 10:
...     treeHit = treeHit +1
...     print("나무를 %d번 찍었습니다." % treeHit)
...     if treeHit == 10:
...         print("나무 넘어갑니다.")
...
나무를 1번 찍었습니다.
나무를 2번 찍었습니다.
나무를 3번 찍었습니다.
나무를 4번 찍었습니다.
나무를 5번 찍었습니다.
나무를 6번 찍었습니다.
나무를 7번 찍었습니다.
나무를 8번 찍었습니다.
나무를 9번 찍었습니다.
나무를 10번 찍었습니다.
나무 넘어갑니다.
```

```python
>>> prompt = """
... 1. Add
... 2. Del
... 3. List
... 4. Quit
...
... Enter number: """
>>> number = 0
>>> while number != 4:
...     print(prompt)
...     number = int(input())
...

1. Add
2. Del
3. List
4. Quit

Enter number:
```

위에서 봤듯이 while문은 조건문이 참이면 계속 while문 안의 내용을 반복적으로 수행하지만, 강제로 while문을 빠져나가고 싶으면? break문을 사용하면 된다. 무한히 반복되는 무한 루프를 돌 때, break문을 넣으면 while문을 빠져나가게 된다.

```python
coffee = 10
while True:
    money = int(input("돈을 넣어 주세요: "))
    # 파이썬 2.7에서는 raw_input("돈을 넣어 주세요: ")를 사용한다. 그리고 소스 코드 첫 번째 줄에 # -*- coding: utf-8 -*-를 넣어야 한다.
    if money == 300:
        print("커피를 줍니다.")
        coffee = coffee -1
    elif money > 300:
        print("거스름돈 %d를 주고 커피를 줍니다." % (money -300))
        coffee = coffee -1
    else:
        print("돈을 다시 돌려주고 커피를 주지 않습니다.")
        print("남은 커피의 양은 %d개 입니다." % coffee)
    if not coffee:
        print("커피가 다 떨어졌습니다. 판매를 중지 합니다.")
        break
```

만약에 while문을 빠져나가고 while문의 맨 처음(*조건문*)으로 다시 돌아가고 싶다면? 이 때는 continue문을 사용하면 된다.

```python
a = 0
while a < 10:
    a = a + 1
    if a % 2 == 0: continue
    # a를 2로 나누었을 때 나머지가 0인 경우
    print(a)
    # a가 짝수면 print(a)를 수행하지 않게 된다.
1
3
5
7
9
```

무한 루프는 간단하게 `while True:`로 구현할 수 있다. 다음 예를 보자.

```python
>>> while True:
...     print("Ctrl+C를 눌러야 while문을 빠져나갈 수 있습니다.")
...
Ctrl+C를 눌러야 while문을 빠져나갈 수 있습니다.
Ctrl+C를 눌러야 while문을 빠져나갈 수 있습니다.
Ctrl+C를 눌러야 while문을 빠져나갈 수 있습니다.
....
```

(*다음에 계속!*)
