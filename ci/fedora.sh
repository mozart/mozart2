#/usr/bin/env bash
set -xe

if [ -n "$1" ]; then
    cmake -DCPACK_GENERATOR=RPM ..
    make -j4 package

    cp mozart2-*.rpm /mnt
else
    ci=$(realpath ${BASH_SOURCE%/*})
    docker build -f $ci/Dockerfile.fedora -t mozart2-fedora $ci/..
    docker run -v$ci/..:/mnt -it mozart2-fedora bash ../ci/fedora.sh compile
fi
