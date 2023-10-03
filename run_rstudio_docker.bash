#!/bin/bash

export PASSWORD=$(openssl rand -base64 15)
readonly PORT=9210

login_file="$HOME/.rstudio_loc"

cat 1>&2 <<END > ${login_file}
Run Info
--------

1. Go here in your web browser: 

127.0.0.1:${PORT}

2. log in to RStudio Server using the following credentials:

   user: ${USER}
   password: ${PASSWORD}
END

export TMPDIR=$( mktemp -d -p $HOME/ -t rstudio-tmp.XXX )
echo "${TMPDIR}"
mkdir -p "$TMPDIR/tmp/rstudio-server"
uuidgen > "$TMPDIR/tmp/rstudio-server/secure-cookie-key"
chmod 0600 "$TMPDIR/tmp/rstudio-server/secure-cookie-key"
ls "$TMPDIR/tmp/"

mkdir -p "$TMPDIR/var/lib"
mkdir -p "$TMPDIR/var/run"
mkdir -p "$TMPDIR/etc/rstudio"

cat 1>&2 <<END > $TMPDIR/etc/rstudio/rsession-profile
.libPaths("/home/rstudio/R/x86_64-pc-linux-gnu-library/4.2")
END

XSOCK=/tmp/.X11-unix && XAUTH=/tmp/.docker.xauth && xauth nlist :0 | sed -e "s/^..../ffff/" | xauth -f $XAUTH nmerge - && \
docker run --rm --gpus all -p $PORT:8787 \
	-v $XSOCK:$XSOCK -v $XAUTH:$XAUTH -e XAUTHORITY=$XAUTH  -e DISPLAY=$DISPLAY \
	-v "$TMPDIR/var/lib:/var/lib/rstudio-server" \
	-v "$TMPDIR/var/run:/var/run/rstudio-server" \
	-v "$TMPDIR/tmp:/tmp" \
	-v "$TMPDIR/etc/rstudio/rsession-profile:/etc/rstudio/rsession-profile" \
    -v "$HOME/code:/home/rstudio/code" \
    -v "/data/jflournoy:/home/rstudio/data" \
    -v "$HOME/r_verse-cmdstan-4.3:/home/rstudio/R/x86_64-pc-linux-gnu-library/4.3" \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -e DISABLE_AUTH=true \
    jflournoy/verse-cmdstan:cuda

function cleanup {
	rm "${login_file}"
	rm -rf "${TMPDIR}"
	echo "Removed login file and temporary directory"
}

trap cleanup EXIT
