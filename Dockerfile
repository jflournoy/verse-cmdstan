FROM rocker/ml-verse:4.3.2
LABEL maintainer="John Flournoy <jcflournoyphd@pm.me>"

ENV CMDSTANVER="2.35.0" \
    DEBIAN_FRONTEND="noninteractive" \
    NVIDIA_VISIBLE_DEVICES="all" \
    NVIDIA_DRIVER_CAPABILITIES="compute,utility"

WORKDIR /cmdstan

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends software-properties-common \
 && add-apt-repository -y universe \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    wget ca-certificates perl xz-utils tar make g++ htop \
    libudunits2-dev libproj-dev libgdal-dev \
    ocl-icd-libopencl1 opencl-headers ocl-icd-opencl-dev clinfo \
    fonts-dejavu-core fonts-dejavu-extra fonts-firacode \
    liblapacke-dev libopenblas-dev \
    curl gnupg fontconfig gettext-base \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Use bash for all subsequent RUNs (safer for && chains and pipefail)
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# TeX Live location & PATH
ENV TL_YEAR=2025
ENV TL_ROOT="/usr/local/texlive/${TL_YEAR}"
ENV PATH="${TL_ROOT}/bin/x86_64-linux:${PATH}"

# Provide the TeX Live profile as a tracked file
# (Create this file in your repo next to the Dockerfile)
COPY texlive.profile /tmp/texlive.profile.in

# Install upstream TeX Live and core packages via tlmgr
RUN set -eux \
 && wget -qO /tmp/install-tl-unx.tar.gz https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz \
 && mkdir -p /tmp/install-tl \
 && tar -xzf /tmp/install-tl-unx.tar.gz -C /tmp/install-tl --strip-components=1 \
 && envsubst < /tmp/texlive.profile.in > /tmp/texlive.profile \
 && /tmp/install-tl/install-tl -profile /tmp/texlive.profile \
 && rm -rf /tmp/install-tl* /tmp/install-tl-unx.tar.gz \
 && ln -sf ${TL_ROOT}/bin/x86_64-linux/* /usr/local/bin/ \
 && tlmgr option repository ctan \
 && tlmgr update --self --all \
 && tlmgr install \
      latexmk csquotes \
      standalone \
      siunitx physics \
      adjustbox collectbox \
      titlesec tabu \
      libertinus-fonts inconsolata newtx \
 && mktexlsr

# Give rstudio permission to update the system TeX Live tree
RUN groupadd -r texlive \
 && usermod -a -G texlive rstudio \
 && chgrp -R texlive ${TL_ROOT} \
 && find ${TL_ROOT} -type d -exec chmod 2775 {} + \
 && find ${TL_ROOT} -type f -exec chmod g+rw {} +


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
