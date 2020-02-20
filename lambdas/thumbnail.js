const AWS = require('aws-sdk')
const sharp = require('sharp')

AWS.config.update({ region: process.env.REGION })

const s3 = new AWS.S3({ apiVersion: '2006-03-01' })

exports.handler = async (event) => {

  try {

    const raw = await s3
      .getObject({
        Bucket: event.Bucket,
        Key: event.Key
      })
      .promise()
      .then(data => data.Body)

    return Promise
      .all(event.ResultAddToCollection)
      .then(faces => {
        return Promise.all(faces.map(async face => {
          return {
            Buffer: await extractImage(raw, face.BoundingBox),
            FaceId: face.FaceId
          }
        }))
      })
      .then(results => {
        return Promise.all(results.map(result => {
          return s3
            .putObject({
              Body: result.Buffer,
              Bucket: event.Bucket,
              Key: `thumbnails/${result.FaceId}.jpg`,
              ContentType: 'image/jpeg',
              ACL: 'public-read',
            })
            .promise()
        }))
      })

  } catch (err) {
    throw err
  }
}

function extractImage(buffer, boundingBox) {
  let image = sharp(buffer)

  return image
    .metadata()
    .then(metadata => {
      return image
        .extract({
          left: Math.round(boundingBox.Left * metadata.width),
          top: Math.round(boundingBox.Top * metadata.height),
          width: Math.round(boundingBox.Width * metadata.width),
          height: Math.round(boundingBox.Height * metadata.height)
        })
        .jpeg({
          quality: 90
        })
        .toBuffer()
    })
}