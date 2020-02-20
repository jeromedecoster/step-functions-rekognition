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

# check all arguments
for arg in "$@"
do
    if [[ ! -f "$dir/images/$arg" ]]; then
        err 'abort' "images/$arg is missing"
        exit 1
    fi
done

mkdir --parents payloads/on-upload

OUTPUT=$(terraform output)

REGION=$(echo "$OUTPUT" \
    | grep ^region \
    | tr ' ' '\n' \
    | tail -1)

BUCKET=$(echo "$OUTPUT" \
    | grep ^bucket \
    | tr ' ' '\n' \
    | tail -1)

ON_UPLOAD_FUNCTION=$(echo "$OUTPUT" \
    | grep ^on_upload_function \
    | tr ' ' '\n' \
    | tail -1)

JSON=""

for arg in "$@"
do
    # filename without the extension
    NOEXTNAME=${arg%.*}

    # create the JSON payload file for the image
    if [[ ! -f "payloads/on-upload/$NOEXTNAME.json" ]]; then
        log 'create' "payloads/$NOEXTNAME.json"
        
        OBJECT=$(aws s3api list-objects-v2 \
            --bucket $BUCKET \
            --query "Contents[?Key == 'uploads/$arg']" \
            --output json)
        
        if [[ $(echo "$OBJECT" | wc --lines) -lt 2 ]]; then
            err 'abort' "object not found. Bucket=$BUCKET Key=uploads/$arg"
            exit 1
        fi

        KEY=$(echo "$OBJECT" | jq '.[0].Key' --raw-output)
        SIZE=$(echo "$OBJECT" | jq '.[0].Size' --raw-output)
        ETAG=$(echo "$OBJECT" | jq '.[0].ETag' --raw-output | sed 's|"||g')
        EVENT_TIME=$(echo "$OBJECT" | jq '.[0].LastModified' --raw-output)
        # echo "$KEY"
        # echo "$SIZE"
        # echo "$ETAG"
        # echo "$EVENT_TIME"

        cat > "payloads/on-upload/$NOEXTNAME.json" <<EOF
{
    "eventVersion": "2.0",
    "eventSource": "aws:s3",
    "awsRegion": "${REGION}",
    "eventTime": "${EVENT_TIME}",
    "eventName": "ObjectCreated:Put",
    "userIdentity": {
        "principalId": "EXAMPLE"
    },
    "requestParameters": {
        "sourceIPAddress": "127.0.0.1"
    },
    "responseElements": {
        "x-amz-request-qid": "EXAMPLE123456789",
        "x-amz-id-2": "EXAMPLE123/5678abcdefghijklambdaisawesome/mnopqrstuvwxyzABCDEFGH"
    },
    "s3": {
        "s3SchemaVersion": "1.0",
        "configurationId": "testConfigRule",
        "bucket": {
            "name": "${BUCKET}",
            "ownerIdentity": {
                "principalId": "EXAMPLE"
            },
            "arn": "arn:aws:s3:::${BUCKET}"
        },
        "object": {
            "key": "${KEY}",
            "size": "${SIZE}",
            "eTag": "${ETAG}",
            "sequencer": "0A1B2C3D4E5F678901"
        }
    }
}
EOF
    fi

    EVENT=$(cat "payloads/on-upload/$NOEXTNAME.json")

    JSON="${JSON}${EVENT},"
done

# create the final JSON payload (remove the trailing comma with '::-1')
PAYLOAD=$(echo "{ \"Records\": [ ${JSON::-1} ] }")

log 'invoke' "$ON_UPLOAD_FUNCTION"
aws lambda invoke \
    --region $REGION \
    --function-name $ON_UPLOAD_FUNCTION \
    --payload "$PAYLOAD" \
    invokes-on-upload.json