FROM rocker/verse:4.1.1
MAINTAINER "John Flournoy" <johnflournoy@gmail.com>

WORKDIR /cmdstan

ENV CMDSTANVER="2.29.2"
RUN apt-get update
RUN apt-get install htop
RUN apt-get install --no-install-recommends -qq wget ca-certificates make g++
RUN Rscript -e "install.packages(\"cmdstanr\", repos = c(\"https://mc-stan.org/r-packages/\", getOption(\"repos\")))"
RUN Rscript -e "cmdstanr::install_cmdstan(\"/cmdstan\"); cmdstanr::cmdstan_path()"
ENV CMDSTAN /cmdstan/cmdstan-${CMDSTANVER}
COPY make_local ${CMDSTAN}/make/local
RUN Rscript -e "file <- file.path(cmdstanr::cmdstan_path(), \"examples\", \"bernoulli\", \"bernoulli.stan\");mod <- cmdstanr::cmdstan_model(file)"
RUN chmod a+w -R ${CMDSTAN}
RUN echo "CMDSTAN=/cmdstan/cmdstan-${CMDSTANVER}" >> ${R_HOME}/etc/Renviron

ENV NAME cmdstan-docker
