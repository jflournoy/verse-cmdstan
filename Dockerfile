FROM rocker/verse:4.0.4

WORKDIR /cmdstan

RUN apt-get update
RUN apt-get install --no-install-recommends -qq wget ca-certificates make g++

RUN wget --progress=dot:mega https://github.com/stan-dev/cmdstan/releases/download/v2.26.1/cmdstan-2.26.1.tar.gz
RUN tar -zxpf cmdstan-2.26.1.tar.gz
RUN ln -s cmdstan-2.26.1 cmdstan
RUN cd cmdstan; make build

RUN chmod a+w -R cmdstan

RUN cd cmdstan; echo "CmdStan home directory is" $PWD

ENV NAME verse-cmdstan 

RUN export http_proxy="http://rcproxy.rc.fas.harvard.edu:3128"
RUN export https_proxy="http://rcproxy.rc.fas.harvard.edu:3128"
RUN export no_proxy="localhost,cbscentral.rc.fas.harvard.edu,nrgcentral.rc.fas.harvard.edu,contecentral.rc.fas.harvard.edu,ncfcode.rc.fas.harvard.edu,nccentry.rc.fas.harvard.edu,ncftunnel.rc.fas.harvard.edu,dpdash.rc.fas.harvard.edu,gitlab-int.rc.fas.harvard.edu"
RUN export R_LIBS_USER=~/R_VERSE-CMDSTAN:$R_LIBS_USER
