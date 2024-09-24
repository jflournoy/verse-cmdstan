FROM rocker/ml-verse:4.3.2
LABEL maintainer="John Flournoy <jcflournoyphd@pm.me>"

WORKDIR /cmdstan

ENV CMDSTANVER="2.35.0"
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
RUN apt-get install -qq liblapacke-dev libopenblas-dev
RUN apt-get install -qq fonts-firacode
RUN mkdir -p /etc/OpenCL/vendors && \
    echo "libnvidia-opencl.so.1" > /etc/OpenCL/vendors/nvidia.icd
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
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
cmdstanr::cmdstan_path();"
ENV CMDSTAN /cmdstan/cmdstan-${CMDSTANVER}
COPY make_local ${CMDSTAN}/make/local
RUN Rscript -e "remotes::install_github('paul-buerkner/brms'); \
install.packages(\"posterior\"); "
RUN Rscript -e "file <- file.path(cmdstanr::cmdstan_path(), \"examples\", \"bernoulli\", \"bernoulli.stan\");mod <- cmdstanr::cmdstan_model(file)"
RUN Rscript -e "file <- file.path(cmdstanr::cmdstan_path(), \"examples\", \"bernoulli\", \"bernoulli.stan\");mod <- cmdstanr::cmdstan_model(file, threads = TRUE)"
RUN Rscript -e "file <- file.path(cmdstanr::cmdstan_path(), \"examples\", \"bernoulli\", \"bernoulli.stan\");mod <- cmdstanr::cmdstan_model(file, cpp_options = list(stan_opencl = TRUE))"
RUN chmod a+w -R ${CMDSTAN}

ENV NAME cmdstan-docker
