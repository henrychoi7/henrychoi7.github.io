---
layout: post
title: 아파치(Apache httpd)에 SSL(HTTPS) 적용하기
---

지난 시간에 이어서 발급 받은 SSL 인증서로 Self-signed CA 구성이 끝났으면 SSL 모듈을 설치하자. 물론, 모든 과정은 Root 계정으로 로그인하고 진행한다.

## Apache 웹 서버에 SSL 적용

Apache Web Server 용 SSL 모듈인 `mod_ssl`을 설치한다.

```shell
$yum install mod_ssl -y
```

SSL 인증서와 개인키는 `/etc/pki/tls/certs/gachon.com.crt`, `/etc/pki/tls/private/gachon.com.key` 라고 가정했을 때, 아래 파일을 수정해서 `NameVirtualHost *:443`을 추가한다.

```shell
$vi /etc/httpd/conf.d/ssl.conf
```

위 파일 맨 아래 줄에 SSL을 적용할 VirtualHost를 설정한다.

```
<VirtualHost *:443>
  ServerName gachon.com
  ServerAlias www.gachon.com

  SSLEngine on
  SSLProtocol all -SSLv2
  SSLCipherSuite ALL:!ADH:!EXPORT:!SSLv2:RC4+RSA:+HIGH:+MEDIUM:+LOW

  ## 위에서 생성한 SSL 인증서와 개인키
  SSLCertificateFile /etc/pki/tls/certs/gachon.com.crt
  SSLCertificateKeyFile /etc/pki/tls/private/gachon.com.key
  SSLCACertificateFile /etc/pki/tls/certs/gachon-rootca.crt

  ##
  <Files ~ "\.(cgi|shtml|phtml|php3?)$">
            SSLOptions +StdEnvVars
        </Files>
        <Directory "/var/www/cgi-bin">
            SSLOptions +StdEnvVars
        </Directory>
  SetEnvIf User-Agent ".*MSIE.*" nokeepalive ssl-unclean-shutdown
  ErrorLog logs/example.com-ssl_error_log
  TransferLog logs/example.com-ssl_access_log
  LogLevel warn
  CustomLog logs/example.com-ssl_request_log \
   "%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \"%r\" %b"
</VirtualHost>
```
> httpd가 인증서나 개인키를 못 찾는 경우, SELinux context 문제다. restorecon 명령어로 context를 복구하자.

```
$restorecon -R /etc/pki/tls/private/
$restorecon -R /etc/pki/tls/certs
```

마지막으로, `systemctl restart httpd`를 실행해서 Apache httpd 재시작 후, HTTPS 적용 여부 확인을 위해 브라우저에서 접속하면 아래와 같이 정상적으로 HTTPS가 적용된 것을 확인할 수 있다.
> 구글 크롬과 같은 브라우저에 Root CA 인증서를 추가하는 방법은 설정 -> 연결 -> 인증서 메뉴에 가서 불러오면 된다.

<p align="center">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/170919/gachon.png" width="80%">
</p>

그리고, [Wireshark](https://www.wireshark.org/download.html)를 설치하면, 패킷을 확인하여 HTTPS 연결에 쓰인 암호 알고리즘이 어떤 것인지 확인할 수 있다. 여기서는 서버 IP를 192.168.0.11, 클라이언트(*브라우저*) IP를 192.168.0.4로 가정한다. 워드프레스로 만든 웹사이트(*서버*)에 HTTPS 연결로 접속하면 아래 화면과 같이 캡처가 된다.

<p align="center">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/170919/wireshark1.png" width="80%">
</p>

SSL 프로토콜의 [Handshake](https://www.ibm.com/support/knowledgecenter/en/SSFKSJ_7.1.0/com.ibm.mq.doc/sy10660_.htm) 과정 중 Client Hello 단계의 패킷을 상세히 확인하면 아래와 같이 현재 TLS 1.2에서 사용할 수 있는 Cipher Suite가 보인다.

<p align="center">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/170919/wireshark2.png" width="80%">
</p>

동일한 방법으로 Server Hello 단계의 패킷을 보면 실제로 어떤 암호 알고리즘이 쓰였는지 확인할 수 있다. 아래 화면을 보면 현재 서버에서 `TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256`라는 Cipher Suite를 사용했다.

<p align="center">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/170919/wireshark3.png" width="80%">
</p>
> `ECDHE_RSA`는 서버와 클라이언트 사이 공개키 교환(*ECDHE*) 시 어떤 인증 알고리즘(*RSA*)을 사용할 것인지 뜻한다.

> `AES_128_GCM`은 공개키로 개인키를 암호화할 때, 어떤 알고리즘(*AES*)과 키 길이(*128비트*), 블록 암호화 모드(*GCM*)를 사용할 것인지 말한다. 참고로, 대칭키(*개인키*) 암호화는 공개키 암호화에 비해 상대적으로 느려서 키 길이를 늘려서 사용하기 힘들다.

> `SHA256`은 데이터가 중간에 변조될 가능성을 대비하여 어떤 해시 알고리즘(*SHA256*)이 쓰였는지 말한다. 참고로, 이 알고리즘은 PRF(*Pseudo-Random Function*)에도 쓰이며, 이 함수는 통신 사이 데이터 무결성을 위해 48비트 크기의 master secret을 만든다.
