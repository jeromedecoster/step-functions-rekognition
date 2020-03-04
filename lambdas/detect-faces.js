const AWS = require('aws-sdk')

const rekognition = new AWS.Rekognition({ apiVersion: '2016-06-27' })
const dynamodb = new AWS.DynamoDB.DocumentClient()
const s3 = new AWS.S3({ apiVersion: '2006-03-01' })

exports.handler = async (event) => {

    try {

        await checkEtag(event.Etag)
        let result = await detectFaces(event.Bucket, event.Key)
        await saveToDynamoDB(event.Etag, event.Basename, result)
        await saveToS3(event.Bucket, event.Noextname, result)

        if (result.FaceDetails.length == 0) {
            throw new NoFaceError(`No face detected in the image ${event.Key}`)
        }

        // ignore babies, little children and low quality faces
        let filtered = result.FaceDetails.filter(face => {
            return face.AgeRange.Low >= 10
                && face.Quality.Brightness >= 40
                && face.Quality.Sharpness >= 40
        })
        if (filtered.length == 0) {
            if (result.FaceDetails.length == 1) {
                throw new FaceRequirementError('The face detected does not meet the requirements')
            } else {
                throw new FaceRequirementError(`None of the ${result.FaceDetails.length} faces detected meet the requirements`)
            }
        }

        return result

    } catch (err) {
        throw err
    }
}

async function checkEtag(etag) {
    let result = await dynamodb
        .get({
            TableName: process.env.DYNAMODB_TABLE_NAME,
            Key: {
                Etag: etag
            }
        })
        .promise()

    if (result.Item) {
        throw new EtagError(`The etag ${etag} already exists`)
    }
}

async function detectFaces(bucket, key) {

    return rekognition
        .detectFaces({
            Image: {
                S3Object: {
                    Bucket: bucket,
                    Name: key
                }
            },
            Attributes: ['ALL']
        }).promise()
}

// save to dynamodb
async function saveToDynamoDB(etag, basename, data) {

    return dynamodb
        .put({
            TableName: process.env.DYNAMODB_TABLE_NAME,
            Item: {
                Etag: etag,
                Basename: basename,
                DetectFaces: data
            }
        })
        .promise()
}

// write JSON to S3 in /detect-faces
async function saveToS3(bucket, noextname, data) {

    return s3
        .putObject({
            Body: JSON.stringify(data, null, 2),
            Bucket: bucket,
            Key: `detect-faces/${noextname}.json`,
            ContentType: 'application/json'
        })
        .promise()
}

class EtagError extends Error {
    name = 'EtagError'
}

class NoFaceError extends Error {
    name = 'NoFaceError'
}

class FaceRequirementError extends Error {
    name = 'FaceRequirementError'
}
