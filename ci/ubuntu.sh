#/usr/bin/env bash
set -xe

if [ -n "$1" ]; then
    cmake -DCPACK_GENERATOR=DEB ..
    make -j4 package

    cp mozart2-*.deb /mnt
else
    ci=$(dirname $(realpath $BASH_SOURCE))
    docker build -f $ci/Dockerfile.ubuntu -t mozart2-ubuntu $ci/..
    docker run -v$ci/..:/mnt -it mozart2-ubuntu bash ../ci/ubuntu.sh compile
fi
