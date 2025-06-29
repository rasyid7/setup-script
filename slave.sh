#!/bin/sh

# general
sudo apt update
sudo apt upgrade -y
# java
sudo apt install -y openjdk-17-jdk
# update java
# sudo apt install openjdk-17-jdk
# sudo update-alternatives --config java
# python-pip
sudo apt install -y python3-pip
# nvm
curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
nvm install 18
# google-chrome
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt --fix-broken install -y ./google-chrome-stable_current_amd64.deb

# =======================================
# android-studio
sudo add-apt-repository ppa:maarten-fonville/android-studio
sudo apt install -y android-studio
# bashrc
# export ANDROID_HOME=/home/jenkins/Android/Sdk
# export PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator

# appium
npm install -g appium
# =======================================

# vnc-server
sudo apt install -y xfce4 xfce4-goodies
sudo apt install -y tightvncserver
# terminal commands
# vncserver
# vncserver -kill :1
# vim ~/.vnc/xstartup
# chmod +x ~/.vnc/xstartup
# vncserver -geometry 1280x720

# =======================================
# jenkins slave setup
sudo useradd -m -s /bin/bash jenkins
sudo adduser jenkins sudo
sudo cp -R /home/$USER/.ssh/ /home/jenkins/
sudo passwd jenkins
sudo su jenkins
