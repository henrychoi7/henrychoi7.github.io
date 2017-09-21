---
layout: post
title: Root CA 및 SSL 인증서 설치
---

### 170915

이제 OpenSSL로 인증서를 설치해보자. 인증서는 HTTPS를 적용하는 데 필요하며, 보통 발급에 비용이 발생하고, 실제 운영 서버가 아니면 부담이 될 수 있다. 이럴 때 OpenSSL을 이용해서 인증기관을 만들고, `Self-signed Certificate`을 생성하여 SSL 인증서를 무료로 발급할 수 있다.

> 인증서(*Digital Certificate*)는 개인키(*Private Key*) 소유자의 공개키(*Public Key*)에 인증기관(*Root CA*)의 개인키로 전자서명한 데이터다. 최상위에 있는 인증기관은 자신의 개인키로 자신의 인증서에 서명하여 최상위 인증기관 인증서를 만든다. 이 인증서를 `Self-signed Certificate`라고 부른다.

> Root CA 인증서를 브라우저에 등록하는 방법은 추후에 설명하겠다.

<br>
## Root CA 인증서 생성

OpenSSL로 Root CA의 개인키와 인증서를 만들기로 했다. 우선, CA가 사용할 RSA 키 쌍(*공개키, 개인키*)를 생성하자. 지금부터 하는 모든 작업은 Root 계정으로 작업하였다.

```shell
openssl genrsa -aes256 -out /etc/pki/tls/private/gachon-rootca.key 2048
```
> 개인키 분실에 대비해 AES 256bit 암호화를 적용한다. AES는 대칭키 알고리즘 중 하나로, 암호(*Pass Phrase*)를 분실하면 개인키를 얻을 수 없으니 조심하자.

```shell
chmod 600  /etc/pki/tls/private/gachon-rootca.key
```
> 개인키 유출 방지를 위해 group과 other의 권한을 모두 제거한다.

```
# CSR(Certificate Signing Request) 생성
vi rootca_openssl.conf

# 파일 내용
[ req ]
default_bits            = 2048
default_md              = sha1
default_keyfile         = gachon-rootca.key
distinguished_name      = req_distinguished_name
extensions              = v3_ca
req_extensions = v3_ca

[ v3_ca ]
basicConstraints       = critical, CA:TRUE, pathlen:0
subjectKeyIdentifier   = hash
##authorityKeyIdentifier = keyid:always, issuer:always
keyUsage               = keyCertSign, cRLSign
nsCertType             = sslCA, emailCA, objCA
[req_distinguished_name ]
countryName                     = Country Name (2 letter code)
countryName_default             = KR
countryName_min                 = 2
countryName_max                 = 2

# 회사명 입력
organizationName              = Organization Name (eg, company)
organizationName_default      = Gachon Univ.

# 부서 입력
#organizationalUnitName          = Organizational Unit Name (eg, section)
#organizationalUnitName_default  = Condor Project

# SSL 서비스할 domain 명 입력
commonName                      = Common Name (eg, your name or your server's hostname)
commonName_default             = Gachon's Self Signed CA
commonName_max                  = 64
```

이제 인증서를 요청하자.

```shell
openssl req -new -key /etc/pki/tls/private/gachon-rootca.key -out /etc/pki/tls/certs/gachon-rootca.csr -config rootca_openssl.conf
```
> 중간에 입력하는 부분은 출력 부분과 동일하게 입력하자.

10년짜리 Self-signed 인증서를 만든다.

```shell
openssl x509 -req \
-days 3650 \
-extensions v3_ca \
-set_serial 1 \
-in /etc/pki/tls/certs/gachon-rootca.csr \
-signkey /etc/pki/tls/private/gachon-rootca.key \
-out /etc/pki/tls/certs/gachon-rootca.crt \
-extfile rootca_openssl.conf
```
> 서명에 사용할 Hash 알고리즘을 변경하려면 -sha384, -sha512 옵션을 지정하면 된다. 기본값은 -sha256이다.

Root CA 인증서가 제대로 생성됐는지 확인을 위해 아래 명령어로 인증서 정보를 출력할 수 있다.

```shell
openssl x509 -text -in /etc/pki/tls/certs/gachon-rootca.crt
```

<br>
## SSL 인증서 생성

위에서 만든 Root CA 서명키로 SSL 인증서를 발급하자. 우선, SSL 호스트에서 사용할 RSA 키 쌍(*공개키, 개인키*)를 생성한다.

```shell
openssl genrsa -aes256 -out /etc/pki/tls/private/gachon.com.key 2048
```
> 여기서도 위 Root CA 때와 마찬가지로 2048bit짜리 개인키를 생성한다.

개인키를 보호하기 위해 키 자체가 암호화되어 있지만, SSL에 사용할 키가 암호가 걸려있으면 httpd 구동 때마다 암호(*Pass Phrase*)를 입력해야 하므로, 암호를 제거한다.

```shell
cp  /etc/pki/tls/private/gachon.com.key  /etc/pki/tls/private/gachon.com.key.enc
openssl rsa -in  /etc/pki/tls/private/gachon.com.key.enc -out  /etc/pki/tls/private/gachon.com.key
```

그리고, Root CA 때와 마찬가지로 개인키 유출 방지를 위해 group과 other의 권한을 모두 제거한다.

```shell
chmod 600  /etc/pki/tls/private/gachon.com.key*
```

```
# CSR(Certificate Signing Request) 생성
vi host_openssl.conf

[ req ]
default_bits            = 2048
default_md              = sha1
default_keyfile         = gachon-rootca.key
distinguished_name      = req_distinguished_name
extensions              = v3_user
## 인증서 요청 시에도 extension이 들어가면 authorityKeyIdentifier를 찾지 못해 에러가 나므로 막아둔다.
## req_extensions = v3_user

[ v3_user ]
# Extensions to add to a certificate request
basicConstraints = CA:FALSE
authorityKeyIdentifier = keyid,issuer
subjectKeyIdentifier = hash
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
## SSL 용 확장키 필드
extendedKeyUsage = serverAuth,clientAuth
subjectAltName          = @alt_names
[ alt_names]
## Subject AltName의 DNSName field에 SSL Host의 도메인 이름을 적어준다.
## 멀티 도메인일 경우 *.gachon.com 처럼 쓸 수 있다.
DNS.1   = www.gachon.com
DNS.2   = gachon.com
DNS.3   = *.gachon.com

[req_distinguished_name ]
countryName                     = Country Name (2 letter code)
countryName_default             = KR
countryName_min                 = 2
countryName_max                 = 2

# 회사명 입력
organizationName              = Organization Name (eg, company)
organizationName_default      = Gachon Univ.

# 부서 입력
organizationalUnitName          = Organizational Unit Name (eg, section)
organizationalUnitName_default  = Gachon SSL Project

# SSL 서비스할 domain 명 입력
commonName                      = Common Name (eg, your name or your server's hostname)
commonName_default              = gachon.com
commonName_max                  = 64
```

파일 내용을 작성 후 저장하고, SSL 인증서를 요청하자.

```shell
openssl req -new  -key /etc/pki/tls/private/gachon.com.key -out /etc/pki/tls/certs/gachon.com.csr -config host_openssl.conf
```

5년짜리 gachon.com 용 SSL 인증서를 발급한다. 서명 시 Root CA 개인키로 서명한다.

```shell
openssl x509 -req -days 1825 -extensions v3_user -in /etc/pki/tls/certs/gachon.com.csr \
-CA /etc/pki/tls/certs/gachon-rootca.crt -CAcreateserial \
-CAkey  /etc/pki/tls/private/gachon-rootca.key \
-out /etc/pki/tls/certs/gachon.com.crt  -extfile host_openssl.conf
```

모든 작업이 끝나면, SSL 인증서가 제대로 발급됐는지 확인을 위해 인증서 정보를 출력하자.

```shell
openssl x509 -text -in /etc/pki/tls/certs/gachon.com.crt
```

다음 시간에는 이어서 Apache httpd에 SSL을 적용하겠다.
