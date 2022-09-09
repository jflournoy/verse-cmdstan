FROM rocker/verse:4.2.1
MAINTAINER "John Flournoy" <johnflournoy@gmail.com>

WORKDIR /cmdstan

ENV CMDSTANVER="2.30.1"
RUN apt-get update
RUN apt-get install --no-install-recommends -qq wget ca-certificates make g++ htop libudunits2-dev libproj-dev libgdal-dev
RUN Rscript -e "if (!requireNamespace(\"remotes\")) {
  install.packages(\"remotes\")
}
remotes::install_github(\"paul-buerkner/brms\")"
RUN Rscript -e "install.packages(\"cmdstanr\", repos = c(\"https://mc-stan.org/r-packages/\", getOption(\"repos\")))"
RUN Rscript -e "cmdstanr::install_cmdstan(\"/cmdstan\"); cmdstanr::cmdstan_path()"
ENV CMDSTAN /cmdstan/cmdstan-${CMDSTANVER}
COPY make_local ${CMDSTAN}/make/local
RUN Rscript -e "file <- file.path(cmdstanr::cmdstan_path(), \"examples\", \"bernoulli\", \"bernoulli.stan\");mod <- cmdstanr::cmdstan_model(file)"
RUN Rscript -e "file <- file.path(cmdstanr::cmdstan_path(), \"examples\", \"bernoulli\", \"bernoulli.stan\");mod <- cmdstanr::cmdstan_model(file, threads = TRUE)"
RUN chmod a+w -R ${CMDSTAN}

ENV NAME cmdstan-docker
