---
layout: post
title: 아파치(Apache httpd)에 SSL(HTTPS) 적용하기
---

### 170919

지난 시간에 이어서 발급 받은 SSL 인증서로 Self-signed CA 구성이 끝났으면 SSL 모듈을 설치하자. 물론, 모든 과정은 Root 계정으로 로그인하고 진행한다.

<br>
## Apache 웹 서버에 SSL 적용

Apache Web Server 용 SSL 모듈인 `mod_ssl`을 설치한다.

```shell
yum install mod_ssl -y
```

SSL 인증서와 개인키는 /etc/pki/tls/certs/gachon.com.crt, /etc/pki/tls/private/gachon.com.key 라고 가정했을 때, 아래 파일을 수정해서 `NameVirtualHost *:443`을 추가한다.

```shell
vi /etc/httpd/conf.d/ssl.conf
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

마지막으로, `systemctl restart httpd`를 실행해서 Apache httpd 재시작 후, HTTPS 적용 여부 확인을 위해 브라우저에서 접속한다.
> httpd가 인증서나 개인키를 못 찾는 경우, SELinux context 문제다. restorecon 명령어로 context를 복구하자.

```
restorecon -R /etc/pki/tls/private/
restorecon -R /etc/pki/tls/certs
```

이제 구글 크롬과 같은 브라우저에 인증 정보를 추가할 수 있다. 그리고, [Wireshark](https://www.wireshark.org/download.html)를 설치해서 패킷을 확인하여 HTTPS에 쓰인 암호 알고리즘이 어떤 것인지 확인할 수 있다.
