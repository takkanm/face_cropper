require "face_cropper/version"
require 'aws-sdk'
require 'mini_magick'

class FaceCropper
  def initialize(params)
    @from_bucket = params[:from_bucket]
    @to_bucket   = params[:to_bucket]
    @image_key   = params[:image_key]
  end

  def crop_and_upload!
    faces = detect_faces!

    tmp_original_image_path = download_original_image!
    upload_faces!(faces, tmp_original_image_path)
  end

  private

  def detect_faces!
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

  def download_original_image!
    image_body = s3_client.get_object(bucket: @from_bucket, key: @image_key).body.read
    File.basename(@image_key).tap do |image_path|
      File.write(image_path, image_body)
    end
  end

  def upload_faces!(faces, image_path)
    faces.face_details.each_with_index do |detail, index|
      image = MiniMagick::Image.open(image_path)

      w = detail.bounding_box.width  * image.width
      h = detail.bounding_box.height * image.height
      x = detail.bounding_box.top    * image.height
      y = detail.bounding_box.left   * image.width
      crop_params = "#{w.to_i}x#{h.to_i}+#{y.to_i}+#{x.to_i}"

      image.crop(crop_params)
      crop_file = "#{index}_#{@image_key}"
      image.write(crop_file)
      s3_client.put_object(bucket: @to_bucket, key: crop_file, body: File.read(crop_file))
    end
  end

  def s3_client
    @s3_client ||= Aws::S3::Client.new(region: 'us-east-1')
  end
end
