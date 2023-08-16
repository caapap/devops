#!/usr/bin/env bash
# Usage: Install kubernetes

# base 
BASE_DIR="/iflytek/.kube"
KUBE_HOME=${KUBE_HOME:-/iflytek/kube}
kube_override=${kube_override:-false}
kube_systctl=${kube_systctl:-1}

# rpm 
RPM_DIR="/iflytek/repo" 

# helm
REPO_URL="https://registry.kxdigit.com"

# docker 
DOCKER_LIB=${DOCKER_LIB:-${KUBE_HOME}/lib/docker} 
DOCKER_VERSION=${DOCKER_VERSION:-20.10.8}
DOCKER_LIVE_RESTORE=${DOCKER_LIVE_RESTORE:-false}
REPO_MIRRORS=${REPO_MIRRORS:-[\"https://registry.kxdigit.com\"]}
DOCKER_BRIDGE=${DOCKER_BRIDGE:-null}
PUBLIC_REPO=$REPO_URL
RELEASE_REPO=${BK_RELEASE_REPO:-$REPO_URL/blueking}

# k8s 
KUBELET_LIB=${KUBELET_LIB:-${KUBE_HOME}/lib/kubelet}
K8S_CTRL_IP=${K8S_CTRL_IP:-$LAN_IP}
K8S_VER=${K8S_VER:-1.22.12}
K8S_SVC_CIDR=${K8S_SVC_CIDR:-10.96.0.0/12}
K8S_POD_CIDR=${K8S_POD_CIDR:-10.244.0.0/16}
K8S_EXTRA_ARGS=${K8S_EXTRA_ARGS:-allowed-unsafe-sysctls: 'net.ipv4.tcp_tw_reuse'}
ETCD_LIB=${ETCD_LIB:-${KUBE_HOME}/lib/etcd}
KUBE_CP_WORKER=${KUBE_CP_WORKER:-0}
K8S_CNI=${K8S_CNI:-flannel}
join_cmd_b64=${join_cmd_b64:-null}
cluster_env=${cluster_env:-null}
master_join_cmd_b64=${master_join_cmd_b64:-null}

# safe mode 
set -euo pipefail

# reset PATH 
PATH=/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH

# Generic script framework variables
# 
#SELF_DIR=$(dirname "$(readlink -f "$0")")
#PROGRAM=$(basename "$0")
VERSION=1.0
EXITCODE=0
OP_TYPE=
LAN_IP=

# global variables 
PROJECTS=( kubenv op helm k8smaster k8snode )
PROJECT=
ON_CLOUD="bare-metal"

# error exit handler
err_trap_handler () {
    MYSELF="$0"
    LASTLINE="$1"
    LASTERR="$2"
    echo "${MYSELF}: line ${LASTLINE} with exit code ${LASTERR}" >&2
}
trap 'err_trap_handler ${LINENO} $?' ERR

usage () {
cat <<EOF
usage: 
kube.sh  [ -h --help -?      check help ]
        [ -i, --install     install module(${PROJECTS[*]}) ]
        [ -c, --clean       remove module(${PROJECTS[*]}) ]
            [ -r, --render      render or config module(${PROJECTS[*]}) ]
            [ -v, --version     [option] check script versin ]
EOF
}

usage_and_exit () {
    usage
    exit "$1"
}

log () {
    echo "[INFO]: $*"
}

warning () {
    echo "[WARN]: $*" 1>&2
    EXITCODE=$((EXITCODE + 1))
}

version () {
    echo "kube.sh version $VERSION"
}

highlight () {
    echo -e "\033[7m  $*  \033[0m"
}

error () {
    highlight "[ERROR]: $*" 1>&2
    usage_and_exit 1
}

ok_kube () {
    cat <<EOF

$(
    log "LAN_IP: $LAN_IP"
    highlight "Welcome to KUBE on $ON_CLOUD"
)
EOF
}

bye_kube () {
    cat <<EOF

$(
    highlight "Finish"
)
EOF
}

_retry () {
    local n=1
    local max=2
    local delay=1
    while true; do
        if "$@"; then
            break
        elif (( n < max )); then
            ((n++))
            log "Command failed. Attempt $n/$max:"
            sleep $delay;
        else
            error "The command $* has failed after $n attempts."
        fi
    done

}
 

# ***ops
install_op () {
    _install_common
    op_kubeadm
    op_kubectl
    op_minikube
    op_helm
    op_bkrepo "${REPO_URL}"
    log "Complete"
}

_install_common () {
    if ! rpm -q bash-completion &>/dev/null; then 
        yum -y install bash-completion || error "Install bash-completion Failed"
    fi
}

op_kubeadm () {
    if command -v kubeadm &>/dev/null; then
    sed -ri '/kube config begin for kubeadm/,/kube config end for kubeadm/d' "$KUBE_DIR/kube.env"
    cat >> "$KUBE_DIR/kube.env" << 'EOF'
# kube config begin for kubeadm
# kubeadm 命令补全
source <(kubeadm completion bash)
# kube config end for kubeadm
EOF
    fi
}

op_kubectl () {
    if command -v kubectl &>/dev/null; then
    sed -ri '/kube config begin for kubectl/,/kube config end for kubectl/d' "$KUBE_DIR/kube.env"
    cat >> "$KUBE_DIR/kube.env" << 'EOF'
# kube config begin for kubectl
# kubectl 命令补全
source <(kubectl completion bash)
# kube config end for kubectl
EOF
    fi
}

op_minikube () {
    if command -v minikube &>/dev/null; then
    sed -ri '/kube config begin for minikube/,/kube config end for minikube/d' "$KUBE_DIR/kube.env"
    cat >> "$KUBE_DIR/kube.env" << 'EOF'
# kube config begin for minikube
# minikube 命令补全
source <(minikube completion bash)
# kube config end for minikube
EOF
    fi
}

op_helm () {
    if command -v helm &>/dev/null; then
    sed -ri '/kube config begin for helm/,/kube config end for helm/d' "$KUBE_DIR/kube.env"
    cat >> "$KUBE_DIR/kube.env" << 'EOF'
# kube config begin for helm
# Helm 命令补全
source <(helm completion bash)
# Helm 激活对 OCI 的支持
export HELM_EXPERIMENTAL_OCI=1
# kube config end for helm
EOF
    fi
}

op_repo () {
    local REPO_URL="$1"
    if command -v helm &>/dev/null; then
        if [[ $REPO_URL == "null" ]]; then
            warning "REPO_URL is ${REPO_URL}, skipping"
            return 0
        fi
        highlight "Add repo: ${REPO_URL}"
        helm repo add k8s "${REPO_URL}"
        helm repo update
        log "k8srepo added"
    else
        warning "Add k8srepo: helm not found, skipping"
        return 0
    fi
}

clean_op () {
    helm repo remove k8s || warning "Remove k8srepo failed"
    clean_kubenv
}