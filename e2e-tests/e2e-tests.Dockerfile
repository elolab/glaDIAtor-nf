FROM ubuntu:24.04

RUN apt update -y
RUN apt upgrade -y

# User

RUN apt-get install sudo -y
RUN echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu

# Nextflow

# NextFlow 22.10 fails with Java 25 and 21
RUN apt install openjdk-17-jre-headless -y
RUN apt install curl -y
RUN curl -s https://get.nextflow.io | bash
RUN mv nextflow /usr/local/bin/nextflow

# Apptainer

# add-apt-repository
RUN apt install software-properties-common -y
RUN add-apt-repository ppa:apptainer/ppa -y
RUN apt update -y
RUN apt install apptainer -y

# PyTest

RUN apt install python-is-python3 python3-venv -y

# VSCode

RUN apt install git -y

# Download of sample data

RUN apt install wget -y

USER ubuntu
