FROM ubuntu:20.04

MAINTAINER GlaDIAtorAdmin
LABEL version="0.1.2"
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y apt-utils

RUN apt-get update \
    && apt-get -y install wget\
    && apt-get -y install git\
    && apt-get -y install build-essential\
    && apt-get -y install tandem-mass\
    && apt-get -y install openjdk-17-jdk\
    && apt-get -y install screen\
    && apt-get -y install xpra\
    && apt-get -y install g++\
    && apt-get -y install zlib1g-dev\
    && apt-get -y install libghc-bzlib-dev\
    && apt-get -y install gnuplot\
    && apt-get -y install unzip\
    && apt-get -y install locales\
    && apt-get -y install expat\
    && apt-get -y install libexpat1-dev\
    && apt-get -y install subversion\
    && apt-get -y install comet-ms\
    && apt-get -y install libfindbin-libs-perl\
    && apt-get -y install libxml-parser-perl\
    && apt-get -y install libtool-bin\
    && apt-get -y install curl\
    && apt-get -y install sudo \
    && apt-get -y install cmake\
    && apt-get -y install gfortran-multilib\
    && apt-get -y install python3-plotly\
    && apt-get -y install python3-pandas \
    && apt-get -y install python3-pandas-lib \
    && apt-get -y install python3-pip\
    && apt-get -y install python3-pymzml\
    && apt-get -y install python3-psutil\
    && apt-get -y install python3-virtualenv\
    && apt-get -y install python3-pyramid\
    && apt-get -y install python-numpy\
    && apt-get -y install npm \
    && apt-get -y install mono-complete \
    && apt-get -y install python3-biopython \
    && apt-get -y install libpwiz3 \
    && apt-get -y install libpwiz-dev \
    && apt-get -y install libpwiz-tools \
    && apt-get -y install openms \
    && apt-get -y install libgd-dev \
    && apt-get -y install cython3 \
    && apt-get -y install python-dev \
    && apt-get -y install libxml2-dev \
    && apt-get -y install libcurl4-openssl-dev

RUN apt-get -y purge r-base* r-recommended r-cran-*
RUN apt -y autoremove
RUN apt -y install software-properties-common
RUN apt update
RUN apt -y install dirmngr gpg --install-recommends
RUN wget -O -  'http://keyserver.ubuntu.com/pks/lookup?op=get&search=0xE298A3A825C0D65DFD57CBB651716619E084DAB9' | gpg --batch --no-tty --no-options --dearmor > /etc/apt/trusted.gpg.d/focal-cran40.gpg


RUN add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/'
RUN apt update
RUN apt -y install r-base r-base-core r-recommended r-base-dev
RUN apt-get -y install r-base-dev
#    && apt-get -y install r-cran-data.table\
#    && apt-get -y install r-bioc-biobase\
#    && apt-get -y install r-bioc-biocgenerics\
#    && apt-get -y install r-bioc-deseq2\
#    && apt-get -y install r-cran-randomforest\
#    && apt-get -y install r-cran-mvtnorm\
#    && apt-get -y install r-bioc-biocinstaller\
#    && apt-get -y install r-cran-ade4\
#    && apt-get -y install r-cran-minqa

RUN apt-get clean
RUN locale-gen en_US.UTF-8 en fi_FI.UTF-8

RUN mkdir /src


# INSTALL TPP
RUN mkdir -p /opt/tpp/
RUN mkdir /opt/tpp-data
WORKDIR /src/
RUN svn checkout svn://svn.code.sf.net/p/sashimi/code/tags/release_5-2-0
RUN echo "INSTALL_DIR = /opt/tpp\nBASE_URL = /tpp\nTPP_DATADIR = /opt/tpp-data" > release_5-2-0/site.mk
WORKDIR /src/release_5-2-0
COPY tpp-5.2-fix.diff /root/
RUN wget https://sourceforge.net/projects/comet-ms/files/comet_2019015.zip
RUN svn checkout svn://svn.code.sf.net/p/comet-ms/code/tags/release_2019015 comet-ms-code && \
    cd comet-ms-code && \
    zip -r comet_source_2019015.zip . && \
    mv comet_source_2019015.zip ../extern/
RUN cat /root/tpp-5.2-fix.diff |patch -p1
RUN make libgd
RUN make all
RUN make install
ENV PATH /opt/tpp/bin:$PATH

# INSTALL msproteomicstools.git
WORKDIR /src/
# RUN pip3 install msproteomicstools
WORKDIR /src/
RUN git clone https://github.com/msproteomicstools/msproteomicstools.git
WORKDIR /src/msproteomicstools
RUN git checkout v0.6.0
RUN python3 setup.py install

# Install Comet
RUN mkdir -p /opt/comet
WORKDIR /opt/comet
RUN wget https://sourceforge.net/projects/comet-ms/files/comet_2019015.zip
RUN unzip comet_2019015.zip
RUN ln -s comet.2019015.linux.exe comet-ms
RUN chmod ugo+x comet.2019015.linux.exe
ENV PATH /opt/comet:$PATH

# Install tandem
WORKDIR /opt
RUN wget ftp://ftp.thegpm.org/projects/tandem/source/tandem-linux-17-02-01-4.zip
RUN unzip tandem-linux-17-02-01-4.zip
RUN mv tandem-linux-17-02-01-4 tandem
RUN ln -s /opt/tandem/bin/static_link_ubuntu/tandem.exe /opt/tandem/tandem
RUN chmod ugo+x /opt/tandem/bin/static_link_ubuntu/tandem.exe
ENV PATH /opt/tandem:$PATH

# INSTALL Percolator
WORKDIR /opt
RUN wget https://github.com/percolator/percolator/releases/download/rel-3-01/ubuntu64_release.tar.gz
RUN tar xfv ubuntu64_release.tar.gz
RUN dpkg -i percolator-converters-v3-01-linux-amd64.deb percolator-v3-01-linux-amd64.deb

# INSTALL dia-umpire
RUN mkdir /opt/dia-umpire
WORKDIR /opt/dia-umpire
RUN wget https://github.com/Nesvilab/DIA-Umpire/releases/download/v2.2.8/DIA_Umpire_SE-2.2.8.jar
RUN ln -s DIA_Umpire_SE-2.2.8.jar DIA_Umpire_SE.jar

## Fetch gladiator and install needed R-packages
RUN mkdir /opt/gladiator
COPY  install-R-packages.R /opt/gladiator/
RUN mkdir /.Rcache
RUN mkdir /opt/Rlibs/
RUN chmod u+x /opt/gladiator/install-R-packages.R
RUN /opt/gladiator/install-R-packages.R
ENV R_LIBS_SITE /opt/Rlibs/

WORKDIR /

# libqt5 (used by openms's DecoyDatabase) uses renameat2
# This will result in ImportError: libQt5Core.so.5: cannot open shared object file: No such file or directory
# the following fixes it 
# https://stackoverflow.com/a/68897099
# TODO: I have to move this to the apt section after i'm done devving.
RUN strip --remove-section=.note.ABI-tag /usr/lib/x86_64-linux-gnu/libQt5Core.so.5

# we put this last for quicker development cycle

WORKDIR /workdir

