#!/bin/bash

HERE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

#Determine if we are running in background
#  Derived from https://unix.stackexchange.com/questions/118462/how-can-a-bash-script-detect-if-it-is-running-in-the-background
PROC=`cat /proc/$$/stat`
BG=false
if ! [ `echo $PROC | cut -d' ' -f4` = `echo $PROC | cut -d' ' -f8` ]; then BG=true; fi

#Determine ARCH
MY_ARCH=`uname -m | sed -e 's/x86_64/amd64/' -e 's/aarch64/arm64/'`                                           
ARCH=${ARCH:-${MY_ARCH}} 

#Build container requirements
#--id                   UID:GID of input user, if not specified 1000:1000 will be used
#--workdir              Workdir to use, default /home/developer
#--cmd                  Command to run after user is setup

#Variables for using GUI from docker, including X11 forwarding (TODO: there are more secure ways of doing this)
GUI_ENV="-p 22222:22222"
if [ -n "${DISPLAY}" ]; then
  xhost +local:root
  XAUTH=/tmp/.docker.xauth.$RANDOM
  touch ${XAUTH}
  xauth nlist ${DISPLAY} | sed -e 's/^..../ffff/' | xauth -f ${XAUTH} nmerge -
  chmod 777 ${XAUTH}
  GUI_ENV="--net host -e DISPLAY -e XAUTHORITY=${XAUTH} -v /tmp/.X11-unix:/tmp/.X11-unix -v ${XAUTH}:${XAUTH}"
fi

#Variables to add additional groups
DOCKER_GID=$(USER_ARG="`grep '^docker:' /etc/group | cut -d':' -f3`"; echo "$USER_ARG")
ADD_GROUP_DOCKER=$(if [ -n "${DOCKER_GID}" ]; then USER_ARG="docker:${DOCKER_GID}"; fi; echo "$USER_ARG")
COMBINE_GROUPS="${ADD_GROUP_DOCKER} ${ADD_GROUP_LIBVIRTD}"
ADD_GROUPS=$(if [ -n "`echo ${COMBINE_GROUPS} | sed 's/ //g'`" ]; then USER_ARG="--groupadd=${COMBINE_GROUPS}"; fi; echo "$USER_ARG" | sed 's/\(.\) \(.\)/\1,\2/g' )

BASE="`cat ${HERE}/BUILDER | cut -d':' -f1`-${ARCH}"
VER="`cat ${HERE}/BUILDER | cut -d':' -f2`"
DIMG="$(docker images | grep ${BASE,,} | head -1 | awk '{print $1":"$2}')"

ARGS=/bin/bash
if [ $# -gt 0 ]; then
  ARGS=$@
fi

docker run \
        --privileged \
        --rm \
        -t $(if tty -s && ! ${BG}; then printf -- "-i"; fi) \
        -e http_proxy \
        -e https_proxy \
        -e no_proxy \
        ${GUI_ENV} \
        -v ${HERE}/..:/home/developer/${BASE} \
        ${DIMG} \
          --workdir=/home/developer/${BASE} \
          --id $(id -u):$(id -g) \
          ${ADD_GROUPS} \
          --cmd "/bin/bash -c '${ARGS}'"

rm -f ${XAUTH}
