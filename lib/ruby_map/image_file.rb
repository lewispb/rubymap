require "image_processing/vips"

module RubyMap
  # Saves organization images into app/assets/images/organizations as WebP:
  # a 600x350 photo for the top of the card and a 96x96 logo.
  class ImageFile
    DIRECTORY = Rails.root.join("app/assets/images/organizations")
    SIZES = {photo: [600, 350], logo: [96, 96]}

    def self.save(source, name:, kind:)
      filename = "#{name.parameterize}#{"-logo" if kind == :logo}.webp"
      width, height = SIZES.fetch(kind)

      pipeline = ImageProcessing::Vips.source(source.to_s)
      pipeline = (kind == :photo) ? pipeline.resize_to_fill(width, height, crop: :centre) : pipeline.resize_and_pad(width, height, background: [255, 255, 255], alpha: true)
      pipeline.convert("webp").saver(quality: 80, strip: true).call(destination: DIRECTORY.join(filename).to_s)

      filename
    end
  end
end
