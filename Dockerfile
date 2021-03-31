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

ENV NAME cmdstan-docker
