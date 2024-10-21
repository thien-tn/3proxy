3proxy install script for Debian / Ubuntu VPS
======================================================

A simple script to install 3proxy on Ubuntu/Debian

**MANUAL :**

Install :

    wget https://raw.github.com/thien-tn/3proxy/master/3proxyinstall.sh -O 3proxyinstall.sh && bash 3proxyinstall.sh

Change authentication!!! 

    vim /etc/3proxy/.proxyauth
	
Sample .proxyauth

    johndoe:CL:johndoepassword123

Change HTTP/SOCKS port, default is 9999 (HTTP) and 8088 (SOCKS)

    vim /etc/3proxy/3proxy.cfg
    

Start service (or reboot as it's automatically start)

    /etc/init.d/3proxy start
Or
    service 3proxy start
	
Uninstall:

 	wget https://raw.github.com/thien-tn/3proxy/master/3proxyuninstall.sh -O 3proxyuninstall.sh && bash 3proxyuninstall.sh

**Script tested on 04.06.2017 on EC2 AMI :**

- Ubuntu 16.04 64bit

**Script will run on :**
- Debian 6 32bits
- Debian 7 32bits
- Ubuntu 12.10 32bits
- Ubuntu 12.04 32bits
- Ubuntu 14.04 and later
