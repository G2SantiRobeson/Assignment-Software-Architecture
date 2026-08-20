ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

module TestRecordFactory
  def create_author(attributes = {})
    Author.create!({
      name: "Author #{SecureRandom.hex(4)}",
      date_of_birth: Date.new(1970, 1, 1),
      country_of_origin: "Test country",
      short_description: "A test author."
    }.merge(attributes))
  end

  def create_book(author: create_author, **attributes)
    Book.create!({
      author: author,
      name: "Book #{SecureRandom.hex(4)}",
      summary: "A searchable test summary about architecture.",
      date_of_publication: Date.new(2000, 1, 1)
    }.merge(attributes))
  end
end

class ActiveSupport::TestCase
  include TestRecordFactory
end

class ActionDispatch::IntegrationTest
  include TestRecordFactory
end
