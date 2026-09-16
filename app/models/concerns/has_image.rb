module HasImage
  extend ActiveSupport::Concern

  included do
    validate :acceptable_image
  end

  private

  def acceptable_image
    return unless image.attached?

    unless %w[image/png image/jpeg image/webp].include?(image.blob.content_type)
      errors.add(:image, "must be a PNG, JPEG or WebP image")
    end
    if image.blob.byte_size > Integer(ENV.fetch("MAX_IMAGE_BYTES", 5.megabytes.to_s))
      errors.add(:image, "is too large")
    end
  end
end
