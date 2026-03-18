FROM ubuntu:24.04

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
ENV LANGUAGE=en

RUN apt update -y
# RUN apt upgrade -y

# User

RUN apt-get install sudo -y
RUN echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu

RUN apt install graphviz python-is-python3 python3-venv -y

# VSCode

RUN apt install git -y

USER ubuntu
