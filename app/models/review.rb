class Review < ApplicationRecord
  belongs_to :book, inverse_of: :reviews

  validates :review_text, presence: true
  validates :score,
    numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }
  validates :up_votes,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
