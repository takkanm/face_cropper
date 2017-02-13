require 'aws-sdk'
require 'pp'

class FaceCropper
  class AwsRekognitionFaceDetector
    def initialize(bucket:, image_key:)
      @bucket     = bucket
      @imaget_key = image_key
    end

    def dcetect!
      rekognition = Aws::Rekognition::Client.new(region: 'us-east-1')

      rekognition.detect_faces(
        image: {
          s3_object: {
            bucket: @from_bucket,
            name:   @image_key
          }
        }
      )
    end
  end
end
