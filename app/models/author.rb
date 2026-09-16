class Author < ApplicationRecord
  include MaintainsReadModels
  include HasImage
  has_one_attached :image
  has_many :books, dependent: :restrict_with_error, inverse_of: :author

  normalizes :open_library_key, with: ->(key) { key.strip.presence }

  validates :name, presence: true
  validates :open_library_key, uniqueness: true, allow_nil: true
end
