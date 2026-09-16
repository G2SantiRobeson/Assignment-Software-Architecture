require "rack/files"

# Shared by Rails (standalone) and the small static origin behind Traefik.
# Only validated public book/author images are exposed; never directory listings.
class UploadFiles
  TYPES = { "png" => "image/png", "jpg" => "image/jpeg", "webp" => "image/webp" }.freeze

  def initialize(app, root:)
    @app = app
    @root = root.to_s
    @files = Rack::Files.new(@root)
  end

  def call(env)
    return @app.call(env) unless env["PATH_INFO"].start_with?("/uploads/")
    return [ 405, { "allow" => "GET, HEAD" }, [] ] unless %w[GET HEAD].include?(env["REQUEST_METHOD"])

    match = %r{\A/uploads/([a-z0-9]{28,64})\.(png|jpg|webp)\z}.match(env["PATH_INFO"])
    return [ 404, {}, [] ] unless match

    key, extension = match.captures
    path = "/#{key[0, 2]}/#{key[2, 2]}/#{key}"
    status, headers, body = @files.call(env.merge("PATH_INFO" => path))
    if [ 200, 206, 304 ].include?(status)
      headers["content-type"] = TYPES.fetch(extension)
      headers["cache-control"] = "public, max-age=31536000, immutable"
      headers["x-content-type-options"] = "nosniff"
      headers["etag"] = %Q("#{key}")
      if env["HTTP_IF_NONE_MATCH"] == headers["etag"]
        body.close if body.respond_to?(:close)
        return [ 304, headers.except("content-length"), [] ]
      end
    end
    [ status, headers, body ]
  end
end
