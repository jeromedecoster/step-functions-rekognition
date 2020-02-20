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

OUTPUT=$(terraform output)

REGION=$(echo "$OUTPUT" \
    | grep ^region \
    | tr ' ' '\n' \
    | tail -1)

PROJECT_NAME=$(echo "$OUTPUT" \
    | grep ^project_name \
    | tr ' ' '\n' \
    | tail -1)

# filename without the extension
NOEXTNAME=${1%.*}

mkdir --parents searchs/$NOEXTNAME

if [[ $(uname) == 'Linux' ]]; then
    VIU=1
fi

jq '.[].FaceId' --raw-output "datas/keep-faces/$NOEXTNAME.json" | while read id; do
    log 'search-face' $id
    # skip search-faces if already done (save money)
    if [[ ! -f "searchs/$NOEXTNAME/$id.json" ]]; then
        aws rekognition search-faces \
            --region $REGION \
            --collection-id $PROJECT_NAME \
            --face-id $id \
            > searchs/$NOEXTNAME/$id.json
    fi

    mkdir --parents searchs/$NOEXTNAME/$id
    cp images/$1 searchs/$NOEXTNAME/$id/

    jq '.FaceMatches[] | "\(.Face.FaceId) \(.Similarity)"' \
        --raw-output \
        searchs/$NOEXTNAME/$id.json | while read result; do
            FACE_ID=$(echo "$result" | cut --delimiter ' ' --fields 1)
            SIMILARITY=$(echo "$result" | cut --delimiter ' ' --fields 2)
            log face-id $FACE_ID
            log similarity $SIMILARITY
            [[ -n "$VIU" ]] && ./viu --height 20 datas/thumbnails/$FACE_ID.jpg

            cp datas/thumbnails/$FACE_ID.jpg searchs/$NOEXTNAME/$id/$SIMILARITY.jpg
        done
done
