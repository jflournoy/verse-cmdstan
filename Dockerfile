FROM rocker/ml-verse:4.3.2
LABEL maintainer="John Flournoy <jcflournoyphd@pm.me>"

ENV CMDSTANVER="2.35.0" \
    DEBIAN_FRONTEND="noninteractive" \
    NVIDIA_VISIBLE_DEVICES="all" \
    NVIDIA_DRIVER_CAPABILITIES="compute,utility"

WORKDIR /cmdstan

RUN apt-get update \
 && apt-get install -y --no-install-recommends software-properties-common \
 && add-apt-repository -y universe \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
    wget ca-certificates make g++ htop libudunits2-dev libproj-dev libgdal-dev \
    ocl-icd-libopencl1 opencl-headers ocl-icd-opencl-dev clinfo \
    texlive-base \
    texlive-latex-base \
    texlive-latex-recommended \
    texlive-latex-extra \
    texlive-bibtex-extra \
    texlive-fonts-recommended \
    texlive-lang-english \
    texlive-xetex \
    texlive-fonts-extra \
    biber \
    fonts-dejavu-core \
    fonts-dejavu-extra \
    liblapacke-dev libopenblas-dev \
    fonts-firacode \
    curl gnupg 
# && rm -rf /var/lib/apt/lists/* 


RUN mkdir -p /etc/OpenCL/vendors && \
    echo "libnvidia-opencl.so.1" > /etc/OpenCL/vendors/nvidia.icd
RUN Rscript -e "if (!requireNamespace('remotes')) { \
  install.packages('remotes') \
}; \
cpp_options <- list( \
    \"STAN_CPP_OPTIMS=true\", \
    \"CXXFLAGS+= -O3 -march=native -mtune=native\", \
    \"CXXFLAGS+= -DEIGEN_USE_BLAS -DEIGEN_USE_LAPACKE\", \
    \"LDLIBS += -lblas -llapack -llapacke\" \
); \
install.packages(\"cmdstanr\", repos = c(\"https://mc-stan.org/r-packages/\", getOption(\"repos\"))); \
cmdstanr::install_cmdstan(\"/cmdstan\", version = \"${CMDSTANVER}\", cores = 4, cpp_options = cpp_options); \
cmdstanr::cmdstan_path(); \
"

ENV CMDSTAN /cmdstan/cmdstan-${CMDSTANVER}
COPY make_local ${CMDSTAN}/make/local
RUN chmod a+w -R ${CMDSTAN}
RUN Rscript -e "remotes::install_github('paul-buerkner/brms'); \
install.packages(\"posterior\"); \
file <- file.path(cmdstanr::cmdstan_path(), \"examples\", \"bernoulli\", \"bernoulli.stan\"); \
mod <- cmdstanr::cmdstan_model(file); \
mod <- cmdstanr::cmdstan_model(file, threads = TRUE); \
mod <- cmdstanr::cmdstan_model(file, cpp_options = list(stan_opencl = TRUE)); \
"

ENV QUARTO_VERSION="1.5.57"
RUN wget --no-check-certificate https://github.com/rocker-org/rocker-versioned2/raw/refs/heads/master/scripts/install_quarto.sh && \
    bash install_quarto.sh && \
    rm ./install_quarto.sh

RUN curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash && \
    apt-get update && \
    apt-get install -qq git-lfs && \
    git lfs install && \
    rm -rf /var/lib/apt/lists/*

ENV NAME cmdstan-docker
