require "rack"
require_relative "../../lib/upload_files"

not_found = ->(_env) { [ 404, { "content-type" => "text/plain" }, [ "Not found" ] ] }
uploads = UploadFiles.new(not_found, root: ENV.fetch("UPLOADS_PATH"))
public_files = Rack::Files.new(File.expand_path("../../public", __dir__), {
  "cache-control" => "public, max-age=31536000, immutable"
})

run lambda { |env|
  path = env["PATH_INFO"]
  result = if path == "/up"
    [ 200, { "content-type" => "text/plain" }, [ "ok" ] ]
  elsif path.start_with?("/uploads/")
    uploads.call(env)
  elsif path.start_with?("/assets/") && !path.split("/").include?("..") && !path.include?("%")
    public_files.call(env)
  else
    not_found.call(env)
  end
  result[1]["x-static-origin"] = "edge-files"
  result
}
