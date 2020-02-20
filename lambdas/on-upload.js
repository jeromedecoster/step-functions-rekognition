const AWS = require('aws-sdk')
const path = require('path')

AWS.config.update({ region: process.env.REGION })

const stepfunc = new AWS.StepFunctions({ apiVersion: '2016-11-23' })

exports.handler = async (event) => {
    let execs = startExecutions(event.Records)

    await Promise.all(execs)
}

// Transform the `event.records` array in an array of Promises.
// Each Promise is a pending `StepFunctions.startExecution` instance
function startExecutions(records) {
    return records.map(record => {
        let Key = record.s3.object.key
        let Dirname = path.dirname(Key)
        let Basename = path.basename(Key)
        let Extname = path.extname(Key)
        let Noextname = path.basename(Key, Extname)

        let params = {
            stateMachineArn: process.env.STATE_MACHINE_ARN,
            input: JSON.stringify({
                Region: record.awsRegion,
                Bucket: record.s3.bucket.name,
                Etag: record.s3.object.eTag,
                Key,
                Dirname,
                Basename,
                Extname,
                Noextname
            })
        }

        return stepfunc
            .startExecution(params)
            .promise()
    })
}