---
layout: post
title: USB 메모리에 Ubuntu Linux 설치하기
---

### 170908

USB 메모리에 Linux OS인 Ubuntu를 설치해서 언제 어디서나 USB 메모리만 있으면 다른 PC에서 USB 메모리에 설치된 Linux로 부팅할 수 있게 만들어 보자. 이 시스템의 장점은 공용 PC에서도 나만의 OS를 이용할 수 있기 때문에 보안 걱정을 덜할 수 있다. 물론 PC에 문제가 생기면 USB 메모리로 부팅할 수 있다.

- **필요 준비물**
  - [Ubuntu OS](https://www.ubuntu.com/download/desktop) (*32비트 or 64비트, 호환성을 위해 32비트 사용 권장*)
  - [Universal USB Installer](https://www.pendrivelinux.com/universal-usb-installer-easy-as-1-2-3/) (*USB 메모리에 설치하기 위한 tool*)

Ubuntu OS를 다운 받고 설치할 USB 메모리를 PC에 연결한 후, Universal USB Installer 프로그램을 실행시키자. 그러면 아래와 같이 설정하고 Create 버튼을 누르면 된다.

<p style="text-align:center;">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/prepare1.JPG" width="80%">
</p>
> Ubuntu OS 파일과 Universal USB Installer 프로그램

<p style="text-align:center;">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/install1.JPG" width="80%">
</p>
> Step 1: 설치하려는 OS(*Ubuntu*) 선택<br>
> Step 2: 다운받은 Ubuntu iso 파일을 지정<br>
> Step 3: Ubuntu를 설치하려는 USB 메모리 선택한다.<br>
> Step 4: Persistent file size를 조절하여 USB 메모리에서 Ubuntu를 실행했을 때 작업 내용이 저장되도록 한다.

USB 메모리에 설치가 모두 완료되면 끝! 이제 USB로 부팅하면 아래처럼 Ubuntu Linux가 실행될 것이다.

<p style="text-align:center;">
  <img src="https://raw.githubusercontent.com/henrychoi7/henrychoi7.github.io/master/img/install2.jpg" width="80%">
</p>
