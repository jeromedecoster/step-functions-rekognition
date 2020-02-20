#!/bin/bash

# the directory of this script file
dir="$(cd "$(dirname "$0")"; pwd)"
cd "$dir"

# echo $1 in underline green then $2 in yellow
log() {
   echo -e "\033[1;4;32m$1\033[0m \033[1;33m$2\033[0m"
}

ETAG=$(md5sum images/alice1.jpg \
    | cut --delimiter ' ' --fields 1)

OUTPUT=$(terraform output)

REGION=$(echo "$OUTPUT" \
    | grep ^region \
    | tr ' ' '\n' \
    | tail -1)

PROJECT_NAME=$(echo "$OUTPUT" \
    | grep ^project_name \
    | tr ' ' '\n' \
    | tail -1)

ITEM=$(aws dynamodb get-item \
    --region $REGION \
    --table-name $PROJECT_NAME-dynamodb-table \
    --key '{"Etag": {"S": "'$ETAG'"}}' \
    --output text)

if [[ -n "$ITEM" ]]; then
    log delete "dynamodb item Etag=$ETAG"
    aws dynamodb delete-item \
        --region $REGION \
        --table-name $PROJECT_NAME-dynamodb-table \
        --key '{"Etag": {"S": "'$ETAG'"}}'
fi