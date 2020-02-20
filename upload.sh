#!/bin/bash

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <object.key> ..." >&2
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

BUCKET=$(terraform output \
    | grep ^bucket \
    | tr ' ' '\n' \
    | tail -1)

for arg in "$@"
do
    if [[ -f "$dir/images/$arg" ]]; then
        log 'upload' "images/$arg" 
        aws s3 cp images/$arg s3://$BUCKET/uploads/
    else
        err 'skip' "images/$arg is missing"
    fi
done
