FROM ghcr.io/rocker/ml-verse:4.3.2
LABEL maintainer="John Flournoy <johnflournoy@gmail.com>"

WORKDIR /cmdstan

ENV CMDSTANVER="2.34.1"
RUN apt-get update
RUN apt-get install --no-install-recommends -qq wget ca-certificates make g++ htop libudunits2-dev libproj-dev libgdal-dev
RUN apt-get install -qq ocl-icd-libopencl1 opencl-headers ocl-icd-opencl-dev clinfo
RUN apt-get install -qq `sudo apt --assume-no install texlive-full | \
		awk '/The following additional packages will be installed/{f=1;next} /Suggested packages/{f=0} f' | \
		tr ' ' '\n' | \
        grep -vP 'doc$' | \
        grep -vP 'texlive-lang' | \
        grep -vP 'latex-cjk' | \
        tr '\n' ' '` && apt-get install -qq texlive-lang-english
RUN apt-get install -qq fonts-firacode
RUN mkdir -p /etc/OpenCL/vendors && \
    echo "libnvidia-opencl.so.1" > /etc/OpenCL/vendors/nvidia.icd
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
RUN Rscript -e "if (!requireNamespace('remotes')) { \
  install.packages('remotes') \
}; \
remotes::install_github('paul-buerkner/brms'); \
install.packages(\"posterior\"); \
install.packages(\"cmdstanr\", repos = c(\"https://mc-stan.org/r-packages/\", getOption(\"repos\"))); \
cmdstanr::install_cmdstan(\"/cmdstan\", version = \"${CMDSTANVER}\", cores = 4); \
cmdstanr::cmdstan_path();"
ENV CMDSTAN /cmdstan/cmdstan-${CMDSTANVER}
COPY make_local ${CMDSTAN}/make/local
RUN Rscript -e "file <- file.path(cmdstanr::cmdstan_path(), \"examples\", \"bernoulli\", \"bernoulli.stan\");mod <- cmdstanr::cmdstan_model(file)"
RUN Rscript -e "file <- file.path(cmdstanr::cmdstan_path(), \"examples\", \"bernoulli\", \"bernoulli.stan\");mod <- cmdstanr::cmdstan_model(file, threads = TRUE)"
RUN Rscript -e "file <- file.path(cmdstanr::cmdstan_path(), \"examples\", \"bernoulli\", \"bernoulli.stan\");mod <- cmdstanr::cmdstan_model(file, cpp_options = list(stan_opencl = TRUE))"
RUN chmod a+w -R ${CMDSTAN}

RUN wget --no-check-certificate https://github.com/rocker-org/rocker-versioned2/raw/refs/heads/master/scripts/install_quarto.sh
ENV QUARTO_VERSION="1.5.57"
RUN sh install_quarto.sh

ENV NAME cmdstan-docker
