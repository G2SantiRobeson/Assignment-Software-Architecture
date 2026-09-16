require "test_helper"

class EdgeAndUploadsTest < ActionDispatch::IntegrationTest
  teardown do
    # Files are outside the transactional database used by these tests.
    @blobs&.each { |blob| blob.service.delete(blob.key) }
  end

  test "books and authors accept real images and serve immutable original bytes" do
    [ create_author, create_book ].each do |record|
      upload = Rack::Test::UploadedFile.new(Rails.root.join("public/icon.png"), "image/png")
      patch polymorphic_path(record), params: { record.model_name.param_key => { image: upload } }
      assert_response :redirect
      record.reload
      assert record.image.attached?
      (@blobs ||= []) << record.image.blob

      get polymorphic_path(record)
      assert_response :success
      path = css_select("img").first["src"]
      get path
      assert_response :success
      assert_equal File.binread(Rails.root.join("public/icon.png")), response.body.b
      assert_equal "image/png", response.media_type
      assert_includes response.headers["Cache-Control"], "immutable"
      etag = response.headers["ETag"]
      get path, headers: { "If-None-Match" => etag }
      assert_response :not_modified
      head path
      assert_response :success
      assert_empty response.body
    end
  end

  test "non image and oversized attachments do not replace an existing image" do
    book = create_book
    book.image.attach(io: File.open(Rails.root.join("public/icon.png")), filename: "cover.png", content_type: "image/png")
    @blobs = [ book.image.blob ]
    key = book.image.blob.key
    patch book_path(book), params: { book: { image: Rack::Test::UploadedFile.new(Rails.root.join("public/404.html"), "text/html") } }
    assert_response :unprocessable_entity
    assert_equal key, book.reload.image.blob.key

    book.image.attach(io: StringIO.new("x" * (5.megabytes + 1)), filename: "large.png", content_type: "image/png", identify: false)
    assert_not book.valid?
    assert_includes book.errors[:image], "is too large"
    assert_equal key, Book.find(book.id).image.blob.key
  end

  test "uploaded file handler rejects traversal, unknown files and writes" do
    %w[/uploads/../../config/database.yml /uploads/nope.png /uploads/aaaaaaaaaaaaaaaaaaaaaaaaaaaa.svg].each do |path|
      get path
      assert_response :not_found
    end
    post "/uploads/aaaaaaaaaaaaaaaaaaaaaaaaaaaa.png"
    assert_response :method_not_allowed
  end

  test "flash state is in PostgreSQL and survives a new application session" do
    assert_difference("ActiveRecord::SessionStore::Session.count") do
      post authors_path, params: { author: { name: "Shared session author" } }
    end
    destination = response.location
    second = open_session
    cookies.to_hash.each { |key, value| second.cookies[key] = value }
    second.get destination
    second.assert_response :success
    second.assert_select ".flash.notice", text: "Author was created successfully."
    second.get destination
    second.assert_select ".flash.notice", count: 0
  end

  test "readiness checks database and exposes instance identity" do
    get "/ready"
    assert_response :success
    assert_equal "ready", response.parsed_body["status"]
    get books_path
    assert_response :success
    assert response.headers["X-App-Instance"].present?
  end
end
