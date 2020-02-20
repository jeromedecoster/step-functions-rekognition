#!/bin/bash

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <object.key>" >&2
  exit 1
fi

# the directory of this script file
dir="$(cd "$(dirname "$0")"; pwd)"
cd "$dir"

# echo $1 in underline green then $2 in yellow
log() {
    echo -e "\033[1;4;32m$1\033[0m \033[1;33m$2\033[0m"
}

# echo $1 in underline magenta then $2 in cyan
err() {
    echo -e "\033[1;4;35m$1\033[0m \033[1;36m$2\033[0m" >&2
}

if [[ ! -f "images/$1" ]]; then
    err 'abort' "images/$1 is missing"
    exit 1
fi

# filename without the extension
NOEXTNAME=${1%.*}

if [[ ! -f "datas/keep-faces/${NOEXTNAME}.json" ]]; then
    err 'abort' "datas/keep-faces/${NOEXTNAME}.json is missing"
    exit 1
fi

if [[ $(uname) == 'Linux' ]]; then
    VIU=1
fi

log 'image' $1
[[ -n "$VIU" ]] && ./viu --height 40 images/$1

jq '.[].FaceId' --raw-output "datas/keep-faces/$NOEXTNAME.json" | while read id; do
    log 'face' $id
    [[ -n "$VIU" ]] && ./viu --height 20 datas/thumbnails/$id.jpg
done
