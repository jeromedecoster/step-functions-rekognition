#!/bin/bash

# the directory of this script file
dir="$(cd "$(dirname "$0")"; pwd)"
cd "$dir"

# echo $1 in underline green then $2 in yellow
log() {
    echo -e "\033[1;4;32m$1\033[0m \033[1;33m$2\033[0m"
}

BUCKET=$(terraform output \
    | grep ^bucket \
    | tr ' ' '\n' \
    | tail -1)

mkdir --parents datas/detect-faces datas/index-faces datas/keep-faces datas/thumbnails

log 'download' "files from $BUCKET/detect-faces"
aws s3 cp --recursive s3://$BUCKET/detect-faces/ ./datas/detect-faces

log 'download' "files from $BUCKET/index-faces"
aws s3 cp --recursive s3://$BUCKET/index-faces/ ./datas/index-faces

log 'download' "files from $BUCKET/keep-faces"
aws s3 cp --recursive s3://$BUCKET/keep-faces/ ./datas/keep-faces

log 'download' "files from $BUCKET/thumbnails"
aws s3 cp --recursive s3://$BUCKET/thumbnails/ ./datas/thumbnails