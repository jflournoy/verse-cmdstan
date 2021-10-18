FROM rocker/verse:4.0.4

WORKDIR /cmdstan

RUN apt-get update
RUN apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
RUN echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update
RUN apt-get install -y docker-ce docker-ce-cli containerd.io

RUN apt-get install --no-install-recommends -qq wget ca-certificates make g++
RUN wget --progress=dot:mega https://github.com/stan-dev/cmdstan/releases/download/v2.26.1/cmdstan-2.26.1.tar.gz
RUN tar -zxpf cmdstan-2.26.1.tar.gz
RUN ln -s cmdstan-2.26.1 cmdstan
RUN cd cmdstan; make build

RUN chmod a+w -R cmdstan

RUN cd cmdstan; echo "CmdStan home directory is" $PWD

ENV NAME cmdstan-docker
