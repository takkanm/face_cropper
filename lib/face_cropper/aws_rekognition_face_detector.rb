require 'aws-sdk'
require 'pp'

class FaceCropper
  class AwsRekognitionFaceDetector
    def initialize(bucket:, image_key:, region:)
      @bucket     = bucket
      @imaget_key = image_key
      @region     = region
    end

    def dcetect!
      rekognition = Aws::Rekognition::Client.new(region: @region)

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
