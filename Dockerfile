FROM rocker/ml-verse:4.3.2
LABEL maintainer="John Flournoy <johnflournoy@gmail.com>"

WORKDIR /cmdstan

ENV CMDSTANVER="2.34.1"
RUN apt-get update
RUN apt-get install --no-install-recommends -qq wget ca-certificates make g++ htop libudunits2-dev libproj-dev libgdal-dev
RUN apt-get install -qq ocl-icd-libopencl1 opencl-headers ocl-icd-opencl-dev clinfo
RUN apt-get install -qq texlive-xetex
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

ENV NAME cmdstan-docker
