yum install -y yum-utils  epel-release util-linux
yum clean all && yum makecache
yum install -y docker
cat > /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://vxxvan8b.mirror.aliyuncs.com"]
}
EOF
systemctl daemon-reload && systemctl start docker
docker info |tail -10

cat > /etc/docker/docker_enter  <<-'EOF'
alias docker-pid="docker inspect --format '{{.State.Pid}}'"
alias docker-ip="docker inspect --format '{{ .NetworkSettings.IPAddress }}'"

#the implementation refs from https://github.com/jpetazzo/nsenter/blob/master/docker-enter
function docker-enter() {
    if [ -e $(dirname "$0")/nsenter ]; then
                # with boot2docker, nsenter is not in the PATH but it is in the same folder
        NSENTER=$(dirname "$0")/nsenter
    else
        NSENTER=nsenter
    fi
    [ -z "$NSENTER" ] && echo "WARN Cannot find nsenter" && return

    if [ -z "$1" ]; then
        echo "Usage: `basename "$0"` CONTAINER [COMMAND [ARG]...]"
        echo ""
        echo "Enters the Docker CONTAINER and executes the specified COMMAND."
        echo "If COMMAND is not specified, runs an interactive shell in CONTAINER."
    else
        PID=$(sudo docker inspect --format "{{.State.Pid}}" "$1")
        if [ -z "$PID" ]; then
            echo "WARN Cannot find the given container"
            return
        fi
        shift

        OPTS="--target $PID --mount --uts --ipc --net --pid"

        if [ -z "$1" ]; then
            # No command given.
            # Use su to clear all host environment variables except for TERM,
            # initialize the environment variables HOME, SHELL, USER, LOGNAME, PATH,
            # and start a login shell.
            #sudo $NSENTER "$OPTS" su - root
            sudo $NSENTER --target $PID --mount --uts --ipc --net --pid su - root
        else
            # Use env to clear all host environment variables.
            sudo $NSENTER --target $PID --mount --uts --ipc --net --pid env -i $@
        fi
    fi
}
EOF

cat > /etc/docker/docker_utils <<-'EOF'
#docker_utils_alias 
alias  dimg='docker images'
alias  dps='docker ps'
alias  dpsa='docker ps -a'
alias  drm='docker rm'
alias  drmi='docker rmi'
alias  dexc='docker exec -it'
alias  dstart='docker start'
alias  dstop='docker stop'
alias  drestart='docker restart'
alias  dstats='docker stats --no-stream'
alias  denter='docker-enter'
alias  dlogs='docker logs'
alias  dtag='docker tag'
alias  drenm='docker rename'
alias  dpull='docker pull'
alias  dpush='docker push'
alias  dsch='docker search'
EOF

echo "
if [ -f /etc/docker/docker_enter ]; then
        . /etc/docker/docker_enter
fi
if [ -f /etc/docker/docker_utils ]; then
        . /etc/docker/docker_utils
fi
" >> /etc/bashrc 
source  /etc/bashrc
systemctl start  docker


