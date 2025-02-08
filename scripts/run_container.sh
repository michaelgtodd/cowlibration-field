#!/bin/bash
#################################################
#run_container.sh
#Version 2023.04.28
#Authors: FRC Team 195
#################################################


BASEDIR=$(dirname "${0}")
source "${BASEDIR}/useful_scripts.sh"
if [[ $OSTYPE == 'darwin'* ]]; then
    INET_ONLINE=$(function timeout() { perl -e 'alarm shift; exec @ARGV' "$@"; } ; timeout 0.5s ping -c1 8.8.8.8 > /dev/null; echo ${?})
else
    INET_ONLINE=$(timeout 0.5s ping -c1 8.8.8.8 > /dev/null; echo ${?})
fi

if [ ! -f "${BASEDIR}/../.bash_completion" ]; then
    echo '#!/bin/bash' > "${BASEDIR}/../.bash_completion"
    echo -e "\n" >> "${BASEDIR}/../.bash_completion"
    cat "${BASEDIR}/bash_completion.sh" >> "${BASEDIR}/../.bash_completion"
    echo -e "\n" >> "${BASEDIR}/../.bash_completion"
    chmod +x "${BASEDIR}/../.bash_completion"
    infomsg "Installed bash completions"
else
    NEW_COMPLETIONS=$(<"${BASEDIR}/bash_completion.sh")
    CURR_COMPLETIONS=$(<"${BASEDIR}/../.bash_completion")
    if [[ ${CURR_COMPLETIONS} = *"${NEW_COMPLETIONS}"* ]];
    then
        infomsg "Bash completions already installed"
    else
        echo -e "\n" >> "${BASEDIR}/../.bash_completion"
        cat "${BASEDIR}/bash_completion.sh" >> "${BASEDIR}/../.bash_completion"
        echo -e "\n" >> "${BASEDIR}/../.bash_completion"
        infomsg "Bash completions installed to your already existing completion script"
    fi
fi

DETACHED_MODE=
DOCKER_CMD_VAR=
FORCED_LAUNCH=
SUDO_MODE=
DOCKER_RUNNING_CMD=1
DOCKER_ARCH=latest

CONTAINER_ID=$(docker ps -aql --filter "ancestor=michaelgtodd/cowlibration:${DOCKER_ARCH}" --filter "status=running")

usage() { infomsg "Usage: ${0} [-a] [-d] [-k] [-h] [-r] [-c <string>]\n\t-a Force arm64 docker container\n\t-i Force x86_64 docker container\n\t-d Run docker container in detached mode\n\t-k Kill running docker instance\n\t-r Sudo access mapping\n\t-c <string> Run a command in the docker container\n\t-h Display this help text \n\n" 1>&2; exit 1; }
while getopts "ac:dfhikr" o; do
    case "${o}" in
        a)
            DOCKER_ARCH=arm64
            if [ ${INET_ONLINE} -eq 0 ]; then
                docker pull michaelgtodd/cowlibration || true
            fi
            ;;
        d)
            DETACHED_MODE=-d
            ;;
        f)
            FORCED_LAUNCH=0
            ;;
        i)
            DOCKER_ARCH=amd64
            if [ ${INET_ONLINE} -eq 0 ]; then
                docker pull michaelgtodd/cowlibration || true
            fi
            ;;
        k)
            if [ ! -z "${CONTAINER_ID}" ]
            then
                infomsg "Stopping container..."
                docker stop ${CONTAINER_ID}
                infomsg "Exiting..."
                exit 0;
            fi
            errmsg "No docker container found to kill!" noexit
            usage
            ;;
        r)
            SUDO_MODE=--volume="/etc/sudoers:/etc/sudoers:ro"
            ;;
        c)
            DOCKER_RUNNING_CMD=0
            FORCED_LAUNCH=0
            DOCKER_CMD_VAR="${OPTARG}"
            DETACHED_MODE=-d
            ;;
        h | *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

CONTAINER_ID=$(docker ps -aql --filter "ancestor=michaelgtodd/cowlibration:${DOCKER_ARCH}" --filter "status=running")

if [ ! -z "${CONTAINER_ID}" ] && [ -z "${FORCED_LAUNCH}" ]
then
    infomsg "Docker container is already running! We will launch a new terminal to it instead..."
    infomsg "You can stop this container using ${0} -k"
    docker exec -it ${CONTAINER_ID} /bin/bash
    exit 0;
elif [ ! -z "${CONTAINER_ID}" ] && [ ! -z "${FORCED_LAUNCH}" ]
then
    infomsg "A docker instance is already running, but you have chosen to force launch a new instance. Hope you know what you're doing..."
fi

if ! command -v docker &> /dev/null
then
    UTIL_LIST="docker.io build-essential cmake parallel"
    if command -v apt &> /dev/null
    then
        infomsg "Installing utilities for Debian/Ubuntu..."
        sudo apt-get update
        sudo apt-get install -y ${UTIL_LIST}
    elif command -v yum &> /dev/null
    then
        infomsg "Installing utilities for yum package manager..."
        sudo yum install -y ${UTIL_LIST}
    elif command -v snap &> /dev/null
    then
        infomsg "Installing utilities for snap..."
        sudo snap install -y ${UTIL_LIST}
    fi
fi

xhost + > /dev/null

OS_NAME=$(uname -a)
XAUTH=/tmp/.docker.xauth
touch ${XAUTH}
XDISPL=$(xauth nlist ${DISPLAY})

if [ ! -z "${XDISPL}" ]
then
  xauth nlist ${DISPLAY} | sed -e 's/^..../ffff/' | xauth -f ${XAUTH} nmerge - > /dev/null
fi

chmod 777 ${XAUTH}

DISPLAY_FLAGS="-e DISPLAY=${DISPLAY}"
RENDERING_FLAGS="--device=/dev/dri:/dev/dri"
DCUDA_FLAGS=""

#Running on macOS
if [[ ${OS_NAME} == *"Darwin"* ]]; then
    DISPLAY_FLAGS="-e DISPLAY=host.docker.internal:0"
fi

#Running on Chromebook
if [[ "${OS_NAME}" == *"penguin"* ]]; then
    infomsg "Chrome OS detected... Disabling rendering passthru!"
    RENDERING_FLAGS=""
fi

cp "${HOME}/.gitconfig" "$(pwd)"

mkdir -p "$(pwd)/.parallel"
touch "$(pwd)/.parallel/will-cite"

if [ ${INET_ONLINE} -eq 0 ]; then
    infomsg "Checking for container updates..."
    docker pull michaelgtodd/cowlibration:${DOCKER_ARCH} || true
fi

if [ ! -z "${DETACHED_MODE}" ];
then
    infomsg "Launching a detached container of this docker instance:"
else
    #clear terminal without destroying scrollback buffer
    printf "\033[2J\033[0;0H"
fi

COMMAND_NEEDS_LAUNCH=1
if [[ "${DOCKER_RUNNING_CMD}" -eq 0 && ${CONTAINER_ID} == "" ]]; then
    COMMAND_NEEDS_LAUNCH=0
fi

if [[ "${DOCKER_RUNNING_CMD}" -eq 1 || "${COMMAND_NEEDS_LAUNCH}" -eq 0 ]]; then
    CURR_ARCH=$(get_arch)
    ARCHPATH=
    case "${CURR_ARCH}" in
    arm64)
        ARCHPATH=arm64
        ;;
    amd64)
        ARCHPATH=x64
        ;;
    *)
        ;;
    esac

    WKSP_DIR=$(pwd)

    mkdir -p "$(pwd)/tmptraj"
    mkdir -p "$(pwd)/.config"
    mkdir -p "$(pwd)/.xdgtmp"
    chmod 700 "$(pwd)/.xdgtmp"

    flatten_trajectories

    TRAJ_CMD=
    if [[ "${TRAJ_DIR}" != 0 ]]; then
        TRAJ_CMD=--volume="$(pwd)/tmptraj:/robot/trajectories:ro"
    fi


    CURR_WORKING_DIR=$(pwd)

    if [[ $OSTYPE == 'darwin'* ]]; then
	USER_FLAGS="-e USER=root --user=root"
        #Note: Make sure XQuartz app settings allow connection from network clients
        open -gj -a XQuartz &
        VOLFLAGS=""
        USER_HOME_MAPPING_FLAGS="-v ${HOME}/.ssh:/root/.ssh"
    else
        VOLFLAGS=""
        USER_FLAGS="--user=$(id -u):$(id -g)"
        case "$(id -u)" in
        1000)
            USER_HOME_MAPPING_FLAGS+=" -v ${HOME}/.ssh:/home/ubuntu/.ssh "
            ;;
        1001)
            USER_HOME_MAPPING_FLAGS+=" -v ${HOME}/.ssh:/home/ubuntu1/.ssh "
            ;;
        1002)
            USER_HOME_MAPPING_FLAGS+=" -v ${HOME}/.ssh:/home/ubuntu2/.ssh "
            ;;
        1003)
            USER_HOME_MAPPING_FLAGS+=" -v ${HOME}/.ssh:/home/ubuntu3/.ssh "
            ;;
        1004)
            USER_HOME_MAPPING_FLAGS+=" -v ${HOME}/.ssh:/home/ubuntu4/.ssh "
            ;;
        1005)
            USER_HOME_MAPPING_FLAGS+=" -v ${HOME}/.ssh:/home/ubuntu5/.ssh "
            ;;
        *)
            ;;
        esac

    fi

    USER_HOME_MAPPING_FLAGS+=" -v ${HOME}/.ssh:/mnt/working/.ssh "

    docker run -it ${DETACHED_MODE} --rm \
        ${DISPLAY_FLAGS} \
        ${RENDERING_FLAGS} \
        ${USER_FLAGS} \
        --ipc="host" \
        --name="cowlibration_docker" \
        -e XAUTHORITY=${XAUTH} \
        -e XDG_RUNTIME_DIR="/tmp/.xdgtmp" \
        -v /etc/localtime:/etc/localtime:ro \
        -v $(pwd):/mnt/working \
        -v /tmp/.X11-unix:/tmp/.X11-unix \
        -v "$(pwd)/.xdgtmp":"/tmp/.xdgtmp" \
        ${USER_HOME_MAPPING_FLAGS} \
        -v ${XAUTH}:${XAUTH} \
        ${DCUDA_FLAGS} \
        --privileged=true \
        ${VOLFLAGS} \
	    --volume="/dev/video0:/dev/video0:ro" \
        ${TRAJ_CMD} \
        --net=host \
        -e HOME=/mnt/working \
        michaelgtodd/cowlibration:${DOCKER_ARCH} \
        /bin/bash

    CONTAINER_ID=$(docker ps -aql --filter "ancestor=michaelgtodd/cowlibration:latest" --filter "status=running")
fi

if [[ "${DOCKER_RUNNING_CMD}" -eq 0 ]]; then
    infomsg "Running command in container..."
    docker exec -it ${CONTAINER_ID} /bin/bash -ci "${DOCKER_CMD_VAR}" || true
    if [[ "${COMMAND_NEEDS_LAUNCH}" -eq 0 ]]; then
        infomsg "Stopping temporary container..."
        docker stop ${CONTAINER_ID} > /dev/null
    fi
    infomsg "Done!"
fi
