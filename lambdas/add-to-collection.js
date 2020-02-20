const AWS = require('aws-sdk')

AWS.config.update({ region: process.env.REGION })

const rekognition = new AWS.Rekognition({ apiVersion: '2016-06-27' })
const dynamodb = new AWS.DynamoDB.DocumentClient()
const s3 = new AWS.S3({ apiVersion: '2006-03-01' })

exports.handler = async (event) => {

    try {

        let result = await indexFaces(event.Etag, event.Bucket, event.Key)
        await saveToDynamoDB(event.Etag, result)
        await saveToS3(event.Bucket, event.Noextname, result)

        // ignore babies, little children and low quality faces
        let keep = []
        let excluded = []
        for (let face of result.FaceRecords) {

            // console.log('face:', face)
            if (face.FaceDetail.AgeRange.Low >= 10
                && face.FaceDetail.Quality.Brightness >= 40
                && face.FaceDetail.Quality.Sharpness >= 40) {

                keep.push(face.Face)
            } else {
                excluded.push(face.Face.FaceId)
            }
        }

        if (excluded.length > 0) {
            let deleted = await deleteFaces(excluded)
            // console.log('deleted:', deleted)
        }

        // console.log('keep:', JSON.stringify(keep, null, 2))
        await saveKeepToDynamoDB(event.Etag, keep)
        await saveKeepToS3(event.Bucket, event.Noextname, keep)

        return keep

    } catch (err) {
        throw err
    }
}

async function indexFaces(etag, bucket, key) {

    return rekognition
        .indexFaces({
            CollectionId: process.env.REKOGNITION_COLLECTION_ID,
            DetectionAttributes: ['ALL'],
            ExternalImageId: etag,
            Image: {
                S3Object: {
                    Bucket: bucket,
                    Name: key
                }
            }
        })
        .promise()
}

// write JSON to S3 in /keep-faces
async function saveKeepToS3(bucket, noextname, data) {
    console.log('saveKeepToS3', bucket, noextname, data)
    return s3
        .putObject({
            Body: JSON.stringify(data, null, 2),
            Bucket: bucket,
            Key: `keep-faces/${noextname}.json`,
            ContentType: 'application/json'
        })
        .promise()
}

// save keep to dynamodb
async function saveKeepToDynamoDB(etag, data) {
    console.log('saveKeepToDynamoDB', etag, data)
    return dynamodb
        .update({
            TableName: process.env.DYNAMODB_TABLE_NAME,
            Key: { Etag: etag },
            UpdateExpression: 'set KeepFaces = :data',
            ExpressionAttributeValues: {
                ':data': data
            }
        })
        .promise()
}

// save to dynamodb
async function saveToDynamoDB(etag, data) {
    console.log('saveToDynamoDB', etag, data)
    return dynamodb
        .update({
            TableName: process.env.DYNAMODB_TABLE_NAME,
            Key: { Etag: etag },
            UpdateExpression: 'set IndexFaces = :data',
            ExpressionAttributeValues: {
                ':data': data
            }
        })
        .promise()
}

// write JSON to S3 in /index-faces
async function saveToS3(bucket, noextname, data) {
    console.log('saveToS3', bucket, noextname, data)
    return s3
        .putObject({
            Body: JSON.stringify(data, null, 2),
            Bucket: bucket,
            Key: `index-faces/${noextname}.json`,
            ContentType: 'application/json'
        })
        .promise()
}

async function deleteFaces(faceIds) {
    return rekognition
        .deleteFaces({
            CollectionId: process.env.REKOGNITION_COLLECTION_ID,
            FaceIds: faceIds
        })
        .promise()
}
