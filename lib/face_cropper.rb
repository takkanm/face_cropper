require "face_cropper/version"
require "face_cropper/aws_rekognition_face_detector"
require 'mini_magick'
require 'aws-sdk'

class FaceCropper
  def initialize(params)
    @from_bucket = params[:from_bucket]
    @to_bucket   = params[:to_bucket]
    @image_key   = params[:image_key]
  end

  def crop_and_upload!
    faces = detect_faces!

    debug_print(faces)

    tmp_original_image_path = download_original_image!
    crop_faces!(faces, tmp_original_image_path)
  end

  private

  def debug_print(faces)
    pp faces if ENV['API_DEBUG']
  end

  def detect_faces!
    detector = AwsRekognitionFaceDetector.new(bucket: @from_bucket, image_key: @image_key)
    detector.dcetect!
  end

  def download_original_image!
    image_body = s3_client.get_object(bucket: @from_bucket, key: @image_key).body.read
    File.basename(@image_key).tap do |image_path|
      File.write(image_path, image_body)
    end
  end

  def crop_faces!(faces, image_path)
    faces.face_details.each_with_index do |detail, index|
      image = MiniMagick::Image.open(image_path)

      w = detail.bounding_box.width  * image.width
      h = detail.bounding_box.height * image.height
      x = detail.bounding_box.top    * image.height
      y = detail.bounding_box.left   * image.width
      crop_params = "#{w.to_i}x#{h.to_i}+#{y.to_i}+#{x.to_i}"

      image.crop(crop_params)
      crop_file = "#{crop_params}_#{@image_key}"
      image.write(crop_file)
      s3_client.put_object(bucket: @to_bucket, key: crop_file, body: File.read(crop_file))
    end
  end

  def s3_client
    @s3_client ||= Aws::S3::Client.new(region: 'us-east-1')
  end
end
