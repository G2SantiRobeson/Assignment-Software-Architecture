module ImagesHelper
  def uploaded_image_path(attachment)
    extension = { "image/png" => "png", "image/jpeg" => "jpg", "image/webp" => "webp" }.fetch(attachment.blob.content_type)
    "/uploads/#{attachment.blob.key}.#{extension}"
  end
end
