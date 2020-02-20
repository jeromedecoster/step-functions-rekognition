const AWS = require('aws-sdk')

const s3 = new AWS.S3({ apiVersion: '2006-03-01' })

exports.handler = async (event) => {
    if (event.Throw) {

        // delete the uploaded image if `NoFaceError` or `FaceRequirementError`
        let error = event.Throw.Error
        if (error == 'NoFaceError' || error == 'FaceRequirementError') {
            console.log(`delete Key=${event.Key}`)
            await s3
                .deleteObject({
                    Bucket: event.Bucket,
                    Key: event.Key
                })
                .promise()
        }
    }
}