#!/bin/bash

HERE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

MY_ARCH=`uname -m | sed -e 's/x86_64/amd64/' -e 's/aarch64/arm64/'`
ARCH=${ARCH:-${MY_ARCH}}

FROM_IMG="ubuntu:18.04"
if [ "${ARCH}" = "arm64" ]; then
  FROM_IMG="arm64v8/ubuntu:18.04"
  sudo apt-get install qemu binfmt-support qemu-user-static
  docker run --rm --privileged multiarch/qemu-user-static --reset -p yes --credential yes
fi

( 
  cd ${HERE}
  sed -e "s@#FROM_IMG#@${FROM_IMG}@" < Dockerfile_template > Dockerfile
  NAME="`cat ${HERE}/BUILDER | cut -d':' -f1`"
  VER="`cat ${HERE}/BUILDER | cut -d':' -f2`"
  IMG_NAME="${NAME}-${ARCH}:${VER}"
  docker build --build-arg http_proxy --build-arg https_proxy --build-arg no_proxy -t ${IMG_NAME} .
  rm ${HERE}/Dockerfile
)
