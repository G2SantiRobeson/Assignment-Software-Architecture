require "net/http"
require "uri"
require "json"
require "nokogiri"
require "securerandom"

# Real HTTP/CSRF/uploads, usable against Compose and Kubernetes alike.
class EdgeVerification
  def initialize
    @base = URI(ENV.fetch("BASE_URL"))
    @cookies = {}
    @instances = Hash.new(0)
    @results = []
  end

  def request(method, path, fields: nil, headers: {})
    uri = URI.join(@base.to_s, path)
    connection = Net::HTTP.new(uri.host, uri.port)
    connection.use_ssl = uri.scheme == "https"
    connection.ca_file = ENV.fetch("TLS_CA") if connection.use_ssl?
    connection.open_timeout = 5
    connection.read_timeout = 30
    req = Net::HTTP.const_get(method.to_s.capitalize).new(uri.request_uri)
    req["Cookie"] = @cookies.map { |key, value| "#{key}=#{value}" }.join("; ")
    headers.each { |key, value| req[key] = value }
    req.set_form(fields, "multipart/form-data") if fields
    response = connection.request(req)
    response.get_fields("set-cookie").to_a.each do |cookie|
      key, value = cookie.split(";", 2).first.split("=", 2)
      @cookies[key] = value
    end
    @instances[response["x-app-instance"]] += 1 if response["x-app-instance"]
    @results << { method: method, path: path, status: response.code.to_i, instance: response["x-app-instance"] }
    response
  end

  def check(condition, description)
    raise "FAIL: #{description}" unless condition
    puts "PASS: #{description}"
  end

  def token(response)
    Nokogiri::HTML(response.body).at_css('input[name="authenticity_token"]')["value"]
  end

  def run
    %w[/up /ready /books /authors /reports/author-statistics /reports/top-rated-books /reports/top-selling-books].each do |path|
      check(request(:get, path).code == "200", "GET #{path}")
    end
    author_form = request(:get, "/authors/new")
    image = File.open(File.expand_path("../public/icon.png", __dir__), "rb")
    created = request(:post, "/authors", fields: [ [ "authenticity_token", token(author_form) ], [ "author[name]", "Edge verification #{SecureRandom.hex(5)}" ], [ "author[image]", image, { content_type: "image/png" } ] ])
    check(created.code == "302", "author multipart upload with CSRF")
    author_path = URI(created["location"]).path
    author_id = author_path.split("/").last
    author = request(:get, author_path)
    check(author.body.include?("Author was created successfully."), "shared flash session across redirect")
    author_image = Nokogiri::HTML(author.body).at_css('img[src^="/uploads/"]')["src"]
    check(request(:get, author_image).body.b == File.binread(image.path), "author image bytes")

    book_form = request(:get, "/books/new")
    image.rewind
    book = request(:post, "/books", fields: [ [ "authenticity_token", token(book_form) ], [ "book[name]", "Edge verification book" ], [ "book[author_id]", author_id ], [ "book[summary]", "Architecture verification distributed systems" ], [ "book[date_of_publication]", "2000-01-01" ], [ "book[image]", image, { content_type: "image/png" } ] ])
    check(book.code == "302", "book cover upload with CSRF")
    if ENV.fetch("EXPECT_REPLICAS", "1").to_i > 1
      check(author_form["x-app-instance"] != created["x-app-instance"] || book_form["x-app-instance"] != book["x-app-instance"], "CSRF session accepted across different replicas")
    end
    book_path = URI(book["location"]).path
    detail = request(:get, book_path)
    image_path = Nokogiri::HTML(detail.body).at_css('img[src^="/uploads/"]')["src"]
    static = request(:get, image_path)
    check(static.code == "200" && static.body.b == File.binread(image.path), "book cover bytes")
    check(static["cache-control"].include?("immutable"), "image HTTP cache headers")
    check(request(:get, image_path, headers: { "If-None-Match" => static["etag"] }).code == "304", "image conditional cache hit")
    if ENV["EXPECT_EDGE"] == "true"
      check(static["x-static-origin"] == "edge-files" && static["x-app-instance"].nil?, "image served by static origin through Traefik")
    end
    css = Nokogiri::HTML(detail.body).at_css('link[rel="stylesheet"]')["href"]
    css_response = request(:get, css)
    check(css_response.code == "200", "compiled CSS")
    check(css_response["x-static-origin"] == "edge-files", "CSS through static origin") if ENV["EXPECT_EDGE"] == "true"
    search = request(:get, "/book-search?q=Architecture")
    check(search.code == "200", "search page")
    check(search["x-search-backend"] == ENV.fetch("EXPECT_SEARCH", "postgresql"), "expected search backend")

    30.times { check(request(:get, book_path).code == "200", "dynamic detail") }
    check(@instances.size >= ENV.fetch("EXPECT_REPLICAS", "1").to_i, "traffic distribution #{@instances}")
    puts JSON.generate(results: @results, instances: @instances, book_path: book_path, image_path: image_path)
    # Keep the records for the subsequent failover/read test and load-test target.
  ensure
    image&.close
  end
end

EdgeVerification.new.run
