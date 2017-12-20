---
layout: post
title: 워드프레스(WordPress)에 HTTP/2 적용시키기
---

CentOS 7에 워드프레스를 설치하면 기본적으로 HTTP 1.1을 사용하여 통신한다. 물론 웹 서버가 HTTP/2를 지원하고, 클라이언트 브라우저도 HTTP/2를 지원해도 말이다. 이를 수동으로 설정할 수 있다. 그럼 이 HTTP/2가 어떤 녀석인지 알아보자.

## HTTP/2란?

HTTP/2는 구글이 개발한 [SPDY](https://ko.wikipedia.org/wiki/SPDY) 프로토콜에 기반한 HTTP 프로토콜의 두 번째 버전이다. 1997년 RFC 2068로 표준이 된 HTTP 1.1을 개선한 것으로 2015년 5월, [RFC 7540](https://tools.ietf.org/html/rfc7540)으로 공개되었다. 이 녀석이 왜 나왔는지 궁금하지 않은가? 그럼 이 [기사](http://www.bloter.net/archives/210122)를 읽어보자. 핵심은 이거다.

> "클라이언트가 HTTP 1.1로 원하는 기능을 서버에 요청하고 응답을 받는 2번의 절차가 구조적으로 통신 속도를 느리게 만드는 요소다. 게다가 최근 웹사이트들이 쿠키를 많이 사용하면서 HTTP 헤더 크기가 너무 커졌다." *- 이응준 네이버랩스 개발자, 한국 웹20주년 국제 컨퍼런스에서*

그렇다면 HTTP 1.1과 HTTP/2의 차이점은 뭘까?

HTTP/2는 HTTP 1.1과 다르게 다음 4가지 특징을 가지고 있다.

- **HTTP 헤더 데이터 압축(*Header Compression*)**

허프만 코딩 또는 헤더 테이블을 활용하여 HTTP 헤더 크기를 기존 헤더 크기보다 3분의 1가량 줄였다고 한다. 쉽게 말해 더 적은 용량으로 파일을 더 빨리 웹에 보여줄 수 있다.

- **멀티플렉스 스트림(*Multiplexd Streams*)**

멀티플렉스 스트림은 새로운 메시지 구조를 사용한다고 한다. TCP 연결 하나를 열고, 클라이언트의 여러 요청(*HTML 문서 또는 PNG 파일 등*)을 한 번에 수행하여 기존보다 적은 TCP 연결로 여러 메시지를 주고받을 수 있다. 그래서 서버와 클라이언트 간 통신 시간(*RTT*)을 절반 가량 줄일 수 있다고 한다.

- **서버 푸시(*Server Push*)**

클라이언트가 요청하지 않은 리소스를 서버가 알아서 보내는 서버 푸시는 통신할 때 전체적인 처리 속도를 빨라지게 만들어 준다.

- **스트림 프라이어리티(*Stream Priority*)**

이는 중요한 요청에 우선순위를 부과하는 기술이다. 만약에 웹 페이지를 불러올 때 CSS와 그림 파일이 중요하다고 지정하면, 그림 파일이 CSS에 의존성이 있다고 알려주는 것이다. 결과적으로, 웹 브라우저가 중요한 파일을 빨리 불러내 CSS 문서가 가장 먼저 렌더링될 수 있게 만든다.

결론을 말하면, HTTP 1.1과 호환성이 유지되어 지금 당장 이걸 사용하지 않을 이유가 없다는 말이다(*지원하는 OS와 브라우저도 꾸준히 늘고 있으니..*).

## CentOS 7 + Apache httpd에 HTTP/2를 적용하기

CentOS 7에 Apache httpd로 설치한 워드프레스(*WordPress*)를 준비하고, HTTP/2를 직접 설정해 보자. 우선, 설치되어 있는 Apache httpd 버전을 확인할 필요가 있다. 만약에 낮은 버전이면 반드시 최신 버전으로 업데이트한다(*여기서는 Apache 2.4.29를 사용했으며 2.4.25부터 httpd에 HTTP/2가 기본적으로 내장되어 있다*). 업데이트하는 방법은 아래와 같다.

```bash
# 웹 서버에 대한 최신 소스를 받을 수 있는 CodeIT 같은 Custom Repository를 사용하면 됨
$sudo yum install -y epel-release
$cd /etc/yum.repos.d && wget https://repo.codeit.guru/codeit.el`rpm -q --qf "%{VERSION}" $(rpm -q --whatprovides redhat-release)`.repo

# 업데이트 가능한 Apache httpd 버전 확인
$yum info httpd

# 업데이트
$yum update
```

자, 이제 HTTP/2 모듈을 .conf 파일에 추가하면 된다(*여기서는 서버에 SSL을 적용했기 때문에 ssl.conf를 수정했다. 만약에 SSL을 사용하지 않는다면 httpd.conf를 수정하면 된다*).

```bash
$sudo vim /etc/httpd/conf.d/ssl.conf

<VirtualHost _default_:443>
...
# 아래 내용 추가
LoadModule http2_module modules/mod_http2.so
Protocols h2 http/1.1
```

그럼 끝! 웹 브라우저를 켜서 서버에 접속하면 브라우저 개발 도구를 통해 현재 사용 중인 네트워크 프로토콜인 h2(*HTTP/2*)라는 것을 확인할 수 있다(*여기서는 gachon.com을 도메인으로 사용했으며 Firefox 브라우저에서 HTTP/2.0으로 표시되는 것을 확인했다*).

<p align="center">
  <img
  src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/171127/http2.png"
  width="80%">
</p>
> Firefox 브라우저를 통한 HTTP/2 통신 확인

[참고자료]
- http://www.bloter.net/archives/210122
