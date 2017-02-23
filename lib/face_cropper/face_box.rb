require 'mini_magick'

class FaceCropper
  class FaceBox
    attr_reader :top, :left, :height, :width

    def initialize(top: , left: , height: , width:, margin: 0)
      @top    = top
      @left   = left
      @height = height
      @width  = width
      @margin = margin
    end

    def crop_face!(image_path)
      image = MiniMagick::Image.open(image_path)
      position = calculate_position(image_width: image.width, image_height: image.height)

      crop_params = "#{position[:width]}x#{position[:height]}+#{position[:y]}+#{position[:x]}"

      image.crop(crop_params)
      crop_file = "#{crop_params}_#{@image_key}"
      image.write(crop_file)

      crop_file
    end

    def calculate_position(image_width: , image_height:)
      {
        width:  (@width  * image_width).to_i  + @margin,
        height: (@height * image.height).to_i + @margin,
        x:      [(@top   * image.height).to_i - @margin, 0].min,
        y:      [(@left  * image.width).to_i  - @margin, 0].min
      }
    end
  end
end
