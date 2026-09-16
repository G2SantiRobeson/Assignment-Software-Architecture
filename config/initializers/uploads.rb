require Rails.root.join("lib/upload_files")

if ENV.fetch("RAILS_SERVE_STATIC_FILES", "true") == "true"
  root = if Rails.env.test?
    Rails.root.join("tmp/storage")
  else
    ENV.fetch("UPLOADS_PATH") { Rails.root.join("storage") }
  end
  Rails.application.config.middleware.insert_before 0, UploadFiles, root: root
end
