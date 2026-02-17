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

# ========================================
# Node.js Installation (LTS version 22.x)
# ========================================
# Remove old Node.js packages from base image to avoid conflicts
RUN apt-get update \
 && apt-get remove -y nodejs libnode-dev libnode72 || true \
 && apt-get autoremove -y \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Install Node.js 22.x from NodeSource
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
 && apt-get install -y nodejs \
 && node --version \
 && npm --version \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Install global npm packages for development
RUN npm install -g \
    npm@latest \
    eslint \
    typescript \
    ts-node \
 && npm cache clean --force

# Ensure rstudio user can use npm global packages
ENV NPM_CONFIG_PREFIX=/home/rstudio/.npm-global
ENV PATH="/home/rstudio/.npm-global/bin:${PATH}"

# Create npm-global directory with proper permissions
RUN mkdir -p /home/rstudio/.npm-global \
 && chown -R rstudio:rstudio /home/rstudio/.npm-global

# ========================================
# VS Code Server / code-server (optional)
# ========================================
# Uncomment if you want code-server bundled in the image
# ENV CODE_SERVER_VERSION="4.96.2"
# RUN curl -fsSL https://code-server.dev/install.sh | sh \
#  && code-server --version

# ========================================
# TeX Live Configuration
# ========================================
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

# ========================================
# CmdStan Installation
# ========================================
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

# ========================================
# Quarto Installation
# ========================================
ENV QUARTO_VERSION="1.5.57"
RUN wget --no-check-certificate https://github.com/rocker-org/rocker-versioned2/raw/refs/heads/master/scripts/install_quarto.sh && \
    bash install_quarto.sh && \
    rm ./install_quarto.sh

# ========================================
# Git LFS
# ========================================
RUN curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash && \
    apt-get update && \
    apt-get install -qq git-lfs && \
    git lfs install && \
    rm -rf /var/lib/apt/lists/*

# ========================================
# GitHub CLI
# ========================================
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
 && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
 && apt-get update \
 && apt-get install -y gh \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# ========================================
# Additional R packages for development
# ========================================
RUN Rscript -e "\
  install.packages(c( \
    'testthat', \
    'devtools', \
    'covr', \
    'lintr', \
    'styler', \
    'usethis' \
  )); \
"

# ========================================
# Additional R packages for analysis
# ========================================

RUN Rscript -e "\
  install.packages(c( \
    'marginaleffects', \
    'data.table', \
    'lme4', \
    'glmmTMB', \
    'ggseg', \
    'ggsegGlasser' \
  )); \
"

# ========================================
# Environment & Path Setup
# ========================================
ENV NAME cmdstan-docker

# Ensure git is configured for safe directory access
# (Useful when mounting volumes)
RUN git config --system --add safe.directory '*'

# Set up workspace directory
RUN mkdir -p /home/rstudio/code \
 && chown -R rstudio:rstudio /home/rstudio/code

WORKDIR /home/rstudio

# ========================================
# VS Code Extensions (via CLI if needed)
# ========================================
# Note: Claude Code extension must be installed manually or via
# your VS Code settings sync. The extension ID is:
# anthropic.claude-code
#
# If using Remote-SSH, these will be installed on first connect.
# You can also use a .vscode/extensions.json in your project:
# {
#   "recommendations": [
#     "anthropic.claude-code",
#     "reditorsupport.r",
#     "quarto.quarto",
#     "ms-python.python"
#   ]
# }

# ========================================
# Healthcheck & Metadata
# ========================================
LABEL org.opencontainers.image.title="RStudio + CmdStan + Node.js Dev Environment"
LABEL org.opencontainers.image.description="R statistical computing with Stan, Quarto, Node.js, and VS Code development tools"
LABEL org.opencontainers.image.version="1.0.0"

# Final check that everything is installed
RUN echo "=== Environment Check ===" \
 && echo "R version: $(R --version | head -1)" \
 && echo "Node version: $(node --version)" \
 && echo "npm version: $(npm --version)" \
 && echo "Quarto version: $(quarto --version)" \
 && echo "GitHub CLI version: $(gh --version | head -1)" \
 && echo "CmdStan path: ${CMDSTAN}" \
 && echo "========================="
