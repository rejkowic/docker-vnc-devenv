# docker build -t rejkowic/docker-vnc-devenv --build-arg DIST_VERSION=artful .
# docker run \
#        -v /dev/shm:/dev/shm \
#        -v `readlink -f home`:/home \
#        -v `readlink -f root`:/root \
#        -v `readlink -f fs`:/var/fs \ 
#        --cap-add=SYS_PTRACE \
#        --security-opt seccomp=unconfined \
#        -p 9998:5901 \
#        -p 9997:5801 \
#        -it rejkowic/docker-vnc-devenv \


ARG DIST=ubuntu
ARG DIST_VERSION=latest
FROM ${DIST}:${DIST_VERSION}

ARG http_proxy
ENV http_proxy=${http_proxy}
ARG https_proxy
ENV https_proxy=${https_proxy}
ARG ftp_proxy
ENV ftp_proxy=${ftp_proxy}
ARG no_proxy
ENV no_proxy=${no_proxy}
ARG HTTP_PROXY
ENV HTTP_PROXY=${HTTPS_PROXY}
ARG HTTPS_PROXY
ENV HTTPS_PROXY=${HTTPS_PROXY}
ARG FTP_PROXY
ENV FTP_PROXY=${FTP_PROXY}
ARG NO_PROXY
ENV NO_PROXY=${NO_PROXY}

WORKDIR /tmp

ENV DEBIAN_FRONTEND noninteractive

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

RUN apt-get update && apt-get install -y \
	apt-transport-https \
	ca-certificates \
	curl \
	gnupg \
	locales 

RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
	&& locale-gen en_US.utf8 \
	&& /usr/sbin/update-locale LANG=en_US.UTF-8

RUN apt-get update && apt-get install -y \
	apt-utils \
	wget \
	gdebi-core

ARG WM=lxde
RUN apt install -y ${WM} xinit

ARG TVNC_VERSION=2.1.2
ARG TVNC_DEB=turbovnc_${TVNC_VERSION}_amd64.deb
RUN wget https://netcologne.dl.sourceforge.net/project/turbovnc/${TVNC_VERSION}/${TVNC_DEB} && \
	gdebi -n ${TVNC_DEB} && rm ${TVNC_DEB}

RUN curl -sSL https://packagecloud.io/slacktechnologies/slack/gpgkey | apt-key add -
RUN echo "deb https://packagecloud.io/slacktechnologies/slack/debian/ jessie main" > /etc/apt/sources.list.d/slacktechnologies_slack.list

RUN apt-get update && apt-get -y install \
	libasound2 \
	libx11-xcb1 \
	libxkbfile1 \
	slack-desktop

RUN curl -sSL https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
	&& echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list \
	&& apt-get update && apt-get install -y \
	google-chrome-stable

ARG GO=1.9.3
ARG GO_TAR=go${GO}.linux-amd64.tar.gz
RUN wget https://dl.google.com/go/${GO_TAR} && tar -C /usr/local -xzf ${GO_TAR} && rm ${GO_TAR} && cp /usr/local/go/bin/* /usr/local/bin

RUN apt install -y ubuntu-make vim htop default-jre p7zip pkg-config git lsof inetutils-ping 

RUN curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg && \
	mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg && \
	echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list && \
	apt update && apt install -y code

RUN apt install -y qt5-default qtdeclarative5-dev build-essential ccache valgrind ssh-askpass meld kcachegrind
RUN apt install -y libqtermwidget5-0-dev cmake qml-module-qtquick-controls 
ARG QTCREATOR=4.5.0a
RUN wget -q https://github.com/rejkowic/qt-creator/releases/download/v${QTCREATOR}/${QTCREATOR}.tar.gz && tar -C /usr/local -xzf ${QTCREATOR}.tar.gz

ARG QTERM=v1.0
RUN wget -q https://github.com/rejkowic/qt-creator-terminalplugin/releases/download/${QTERM}/${QTERM}.tar.gz && tar -C /usr/local -xzf ${QTERM}.tar.gz

RUN apt install -y npm && npm install -g create-react-app

RUN  wget -q https://app.hubstaff.com/download/linux && mv linux Hubstaff && chmod +x Hubstaff

RUN apt install -y bashdb apache2-utils inotify-tools rsync

ARG USER=rejkowic
ARG USER_PW=123
RUN useradd -m -s /bin/bash ${USER} && \
    adduser ${USER} sudo && \
    (echo ${USER_PW} && echo ${USER_PW}) | passwd ${USER} && \
    (echo ${USER_PW} && echo ${USER_PW}) | passwd


ENV TVNC_WM=startlxde
USER ${USER}
ARG TVNC_PW=123890
RUN (echo ${TVNC_PW} && echo ${TVNC_PW} && echo n) | /opt/TurboVNC/bin/vncserver :1 && rm -f /tmp/.X1-lock

RUN code --install-extension msjsdiag.debugger-for-chrome
RUN code --install-extension lukehoban.go
RUN code --install-extension ms-python.python
RUN code --install-extension rogalmic.bash-debug 

ARG NAME="Pawel Rejkowicz"
ARG EMAIL="pawel@rejkowicz.pl"
RUN git config --global user.name "${NAME}" && \
    git config --global user.email ${EMAIL} && \
    git config --global push.default current && \
    git config --global alias.co checkout && \
    git config --global alias.ci commit && \
    git config --global alias.rh "reset --hard"


USER root
RUN mv /home/${USER} ./

RUN echo http_proxy=$http_proxy > /etc/environment && \
    echo https_proxy=$https_proxy >> /etc/environment && \
    echo ftp_proxy=$ftp_proxy >> /etc/environment && \
    echo no_proxy=$no_proxy >> /etc/environment && \
    echo HTTP_PROXY=$HTTP_PROXY >> /etc/environment && \
    echo HTTPS_PROXY=$HTTPS_PROXY >> /etc/environment && \
    echo FTP_PROXY=$FTP_PROXY >> /etc/environment && \
    echo NO_PROXY=$NO_PROXY >> /etc/environment && \
    echo TVNC_WM=$TVNC_WM >> /etc/environment && \
    echo >> /etc/environment

RUN rm /etc/xdg/autostart/light-locker.desktop

RUN echo "Generating scripts v001"
RUN echo "#!/bin/bash" > init.sh && chmod +x init.sh && \
    echo "ls /home/${USER} || mv ${USER} /home/" >> init.sh && \
    echo "mkdir -p /root/.config/QtProject && cp -r /var/fs/QtProject  /root/.config/" >> uinit.sh && \
    echo "cat /var/fs/panel > /etc/xdg/lxpanel/LXDE/panels/panel" >> init.sh && \
    echo "sed 's/%.//' /usr/share/applications/slack.desktop > /etc/xdg/autostart/slack.desktop" >> init.sh && \
    echo "su -c/tmp/uinit.sh -l ${USER}" >> init.sh && \
    echo "/bin/bash" >> init.sh && \
    echo "find /home/$USER -type s -exec rm {} \;" >> init.sh 

RUN echo "#!/bin/bash" > uinit.sh && chmod +x uinit.sh && \
    echo "cd" >> uinit.sh && \
    echo "mkdir -p .config/QtProject && cp -r /var/fs/QtProject  .config/" >> uinit.sh && \
    echo "mkdir -p .config/clipit && cp /var/fs/clipitrc .config/clipit/" >> uinit.sh && \
    echo "mkdir -p .config/lxsession/LXDE && echo '@lxpanel --profile LXDE' > .config/lxsession/LXDE/autostart" >> uinit.sh && \
    echo "/opt/TurboVNC/bin/vncserver :1" >> uinit.sh && \
    echo "" >> uinit.sh 

VOLUME ["/home", "/root"]
ENTRYPOINT ["/tmp/init.sh"]
