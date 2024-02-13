#!/bin/bash
INIT_PATH=$1
info() { echo "$@" 1>&2; }
function getShasForFile() {
    md5=($(md5sum $1))
    info "Getting Hash for $1: $md5"
    for p in `grep -oP "#dependency:\s*\K.*" $1`; do
        downstream=$(getShasForFile "`dirname $1`/$p")
        md5="$md5:$downstream"
    done 
    echo $md5
}

function genHash() {
    fileHashes=$(getShasForFile $1)
    R=`echo $fileHashes | sha256sum | cut -b1-25 | tr -d "\n"`
    echo -n "{\"hash\":\"$R\",\"changed\":\"$TF_VAR_changed_var\"}"
}

info "Finding Tree From $INIT_PATH"
genHash $INIT_PATH
