require "face_cropper/version"
require "face_cropper/aws_rekognition_face_detector"
require "face_cropper/face_box"
require 'aws-sdk'

class FaceCropper
  def initialize(params)
    @from_bucket = params[:from_bucket]
    @to_bucket   = params[:to_bucket]
    @image_key   = params[:image_key]
    @face_boxis  = params[:face_details]
  end

  def crop_and_upload!
    faces = @face_boxis || detect_faces!

    tmp_original_image_path = download_original_image!
    crop_faces!(faces, tmp_original_image_path)
  end

  private

  def debug_print(faces)
    pp faces if ENV['API_DEBUG']
  end

  def detect_faces!
    detector = AwsRekognitionFaceDetector.new(bucket: @from_bucket, image_key: @image_key)
    detector.dcetect!.tap {|r| debug_print(r) }
  end

  def download_original_image!
    image_body = s3_client.get_object(bucket: @from_bucket, key: @image_key).body.read
    File.basename(@image_key).tap do |image_path|
      File.write(image_path, image_body)
    end
  end

  def crop_faces!(faces, image_path)
    faces.face_details.each_with_index do |detail, index|
      face_box = FaceBox.new(
        width:  detail.bounding_box.width,
        height: detail.bounding_box.height,
        top:    detail.bounding_box.top,
        left:   detail.bounding_box.left
      )
      crop_file = face_box.crop_face!(image_path)

      if @to_bucket
        s3_client.put_object(bucket: @to_bucket, key: crop_file, body: File.read(crop_file))
        File.unlink crop_file
      end
    end
  end

  def s3_client
    @s3_client ||= Aws::S3::Client.new(region: 'us-east-1')
  end
end
