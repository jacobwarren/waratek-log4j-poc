FROM tomcat:8.0.36-jre8

# add keys required to install Python & git on unsupported Debian version
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys AA8E81B4331F7F50
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 648ACFD622F3D138
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0E98404D386FA1D9
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E1DD270288B4E6030699E45FA1715D88E1DF1F24

RUN echo "deb http://ppa.launchpad.net/git-core/ppa/ubuntu trusty main" > /etc/apt/sources.list.d/git.list
RUN echo "deb [check-valid-until=no] http://cdn-fastly.deb.debian.org/debian jessie main" > /etc/apt/sources.list.d/jessie.list
RUN echo "deb [check-valid-until=no] http://archive.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/jessie-backports.list

RUN sed -i '/deb http:\/\/deb.debian.org\/debian jessie-updates main/d' /etc/apt/sources.list
RUN apt-get -o Acquire::Check-Valid-Until=false update

RUN apt-get update -o Acquire::Check-Valid-Until=false && apt-get -y install sudo zsh fonts-powerline git python3 && apt-get -y clean && rm -rf /var/lib/apt/lists/*

# set default shell to zsh
RUN chsh -s $(which zsh)

# prepare the tomcat dir
RUN rm -rf /usr/local/tomcat/webapps/*
ADD target/log4shell-1.0-SNAPSHOT.war /usr/local/tomcat/webapps/ROOT.war

# transfer shell config for easy to read demo purposes
ADD oh-my-zsh /root/.oh-my-zsh
ADD zshrc /root/.zshrc

# Add Waratek agent
# RUN cd /usr/local/tomcat && ls -la
# RUN ls -la
ADD waratek /usr/local/tomcat/waratek
# RUN ls -la /usr/local/tomcat
# RUN ls -la /usr/local/tomcat/waratek

# add appropriate permissions to agent folder
RUN chmod -R o+x /usr/local/tomcat/waratek/agent

# set Waratek javaagent options
ENV JAVA_OPTS='-javaagent:"/usr/local/tomcat/waratek/agent/waratek.jar" -Dcom.waratek.WaratekProperties="/usr/local/tomcat/waratek/conf_1/waratek.properties"'

EXPOSE 80
EXPOSE 8080
CMD ["catalina.sh", "run"]
