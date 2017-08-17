---
layout: post
title: 파이선(Python) 기초
---

### 170817 (이어서)

파이썬도 요즘 사용하는 대부분의 언어들처럼 "이름" = "홍길동", "생일" = "몇 월 몇 일" 등으로 구분하는 대응 관계를 나타낼 수 있다. 이러한 관계를 나타내는 자료형을 보통 연관 배열(*Associative Array*) 또는 해시(*Hash*)라고 한다. 파이썬에서는 이를 딕셔너리(*Dictionary*)라고 한다. 딕셔너리는 리스트나 튜플처럼 순차적으로 해당 요소값을 구하지 않고, Key를 통해 Value를 얻는다. 아래 딕셔너리 예를 보자.

<br>
## 딕셔너리 자료형
<br>

```python
dic = {'name':'pey', 'phone':'0119993323', 'birth': '1118'}
# Key : Value 형태에서 Key에는 변하지 않는 값을 사용하고, Value에는 변하는 값과 변하지 않는 값 모두 사용할 수 있다.

a = { 'a': [1, 2, 3]}
# Value에 리스트도 넣을 수 있다.

a = {1: 'a'}
a[2] = 'b'
a
{2: 'b', 1: 'a'}
# 딕셔너리에 쌍을 추가할 수 있다. 예에서 알 수 있듯이 순서를 따지지 않고 추가된다.

del a[1]
a
{'name': 'pey', 3: [1, 2, 3], 2: 'b'}
# 딕셔너리 요소 삭제하기. del a[key]처럼 입력하면 지정한 key에 해당하는 {key : value} 쌍이 삭제된다.
```

리스트나 튜플, 문자열은 요소값을 얻어낼 때 인덱싱이나 슬라이싱 기법 중 하나를 사용했지만, 딕셔너리는 Key를 사용해서 Value를 얻어내는 방법 밖에 없다. 어떤 Key의 Value를 얻기 위해서는 '딕셔너리 변수[Key]'를 사용한다.

```python
grade = {'pey': 10, 'julliet': 99}
grade['pey']
10
grade['julliet']
99

a = {'a':1, 'b':2}
a['a']
1
a['b']
2
```

Key에는 리스트를 쓸 수 없지만 튜플은 Key로 쓸 수 있다. Key는 변하지 않는 값이므로 그 특성에 맞게 리스트가 아닌 튜플을 사용할 수 있는 것이다. 그렇다면 당연히 딕셔너리도 Key로 사용할 수 없다.

```python
a = {[1,2] : 'hi'}
```
```
Traceback (most recent call last):
File "", line 1, in ?
TypeError: unhashable type
```
> 딕셔너리를 만들 때 주의할 점은, Key는 고유한 값이므로 중복되는 Key 값을 설정해 놓으면 하나를 제외한 나머지 것들이 모두 무시된다. 어떤 것이 무시될 지 모르지만, 결론은 중복되는 Key를 사용하지 말자.

딕셔너리도 자체적으로 가지고 있는 관련 함수들이 있다.

```python
a = {'name': 'pey', 'phone': '0119993323', 'birth': '1118'}
a.keys()
dict_keys(['name', 'phone', 'birth'])
# Key 리스트 만들기. a.keys()는 딕셔너리 a의 Key만을 모아서 dict_keys라는 객체를 리턴한다. dict_keys 객체는 리스트를 사용하는 것처럼 쓸 수 있지만, 리스트 고유 함수인 append, insert, pop, remove, sort 등의 함수를 수행할 수 없다.
for k in a.keys():
...    print(k)
...
phone
birth
name

list(a.keys())
['phone', 'birth', 'name']
# dict_keys 객체를 리스트로 변환하려면 list()를 사용하면 된다.

a.values()
dict_values(['pey', '0119993323', '1118'])
# Value 리스트 만들기. dict_values 객체 역시 dict_keys 객체와 마찬가지로 리스트를 사용하는 것과 동일하게 사용하면 된다.

a.items()
dict_items([('name', 'pey'), ('phone', '0119993323'), ('birth', '1118')])
# Key, Value 쌍 얻기. items 함수는 Key와 Value의 쌍을 튜플로 묶은 값을 dict_items 객체로 돌려준다.

a.clear()
a
{}
# Key : Value 쌍 모두 지우기

a = {'name':'pey', 'phone':'0119993323', 'birth': '1118'}
a.get('name')
'pey'
a.get('phone')
'0119993323'
# Key로 Value 얻기. get(x) 함수는 x라는 Key에 대응되는 Value를 돌려준다. 참고로, 존재하지 않는 키(nokey)로 값을 가져오려고 할 경우, a['nokey']는 Key 오류를 발생시키고, a.get('nokey')는 None(거짓)을 리턴한다.

a.get('foo', 'bar')
'bar'
# 딕셔너리 안에 찾으려는 Key 값이 없을 경우 미리 정해 둔 디폴트 값을 대신 가져오게 할 수 있다. get(x, '디폴트 값')을 사용하면 된다.

a = {'name':'pey', 'phone':'0119993323', 'birth': '1118'}
'name' in a
True
'email' in a
False
# 해당 Key가 딕셔너리 안에 있는지 조사하기.
```

<br>
## 집합 자료형
<br>
