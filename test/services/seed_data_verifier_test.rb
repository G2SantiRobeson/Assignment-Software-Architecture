# frozen_string_literal: true

require "test_helper"

class SeedDataVerifierTest < ActiveSupport::TestCase
  test "raises with objective failures for an incomplete dataset" do
    Sale.delete_all
    Review.delete_all
    Book.delete_all
    Author.delete_all

    error = assert_raises(SeedDataVerifier::VerificationError) do
      SeedDataVerifier.verify!(minimum_authors: 1, minimum_books: 1, minimum_sale_years: 5)
    end

    assert_includes error.message, "authors 0 < 1"
    assert_includes error.message, "books 0 < 1"
  end
end
