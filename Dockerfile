FROM rocker/verse:4.1.1
MAINTAINER "John Flournoy" <johnflournoy@gmail.com>

WORKDIR /cmdstan

RUN apt-get update
RUN apt-get install htop
RUN apt-get install --no-install-recommends -qq wget ca-certificates make g++
RUN wget --progress=dot:mega https://github.com/stan-dev/cmdstan/releases/download/v2.28.0/cmdstan-2.28.0.tar.gz
RUN tar -zxpf cmdstan-2.28.0.tar.gz
RUN ln -s cmdstan-2.28.0 cmdstan
RUN cd cmdstan; make build

RUN chmod a+w -R cmdstan

RUN cd cmdstan; echo "CmdStan home directory is" $PWD

ENV NAME cmdstan-docker
ENV CMDSTAN /cmdstan/cmdstan
