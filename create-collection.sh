#!/bin/bash

# the directory of this script file
dir="$(cd "$(dirname "$0")"; pwd)"
cd "$dir"

# echo $1 in underline green then $2 in yellow
log() {
   echo -e "\033[1;4;32m$1\033[0m \033[1;33m$2\033[0m"
}

OUTPUT=$(terraform output)

REGION=$(echo "$OUTPUT" \
    | grep ^region \
    | tr ' ' '\n' \
    | tail -1)
    
PROJECT_NAME=$(echo "$OUTPUT" \
    | grep ^project_name \
    | tr ' ' '\n' \
    | tail -1)

COLLECTION=$(aws rekognition list-collections \
    --region $REGION \
    --query "CollectionIds[?@ == '${PROJECT_NAME}']" \
    --output text)

if [[ -z "$COLLECTION" ]]; then
    log create "rekognition collection $PROJECT_NAME"
    aws rekognition create-collection \
        --region $REGION \
        --collection-id $PROJECT_NAME
fi