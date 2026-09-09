class Book < ApplicationRecord
  include MaintainsReadModels
  belongs_to :author, inverse_of: :books

  has_many :reviews, dependent: :restrict_with_error, inverse_of: :book
  has_many :sales, dependent: :restrict_with_error, inverse_of: :book

  normalizes :open_library_key, with: ->(key) { key.strip.presence }

  validates :name, presence: true
  validates :date_of_publication, presence: true
  validates :number_of_sales,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :open_library_key, uniqueness: true, allow_nil: true

  def self.refresh_number_of_sales_for!(*book_ids)
    ids = book_ids.flatten.compact.uniq.sort

    where(id: ids).order(:id).each(&:refresh_number_of_sales!)
  end

  def average_score
    return self[:average_score] if has_attribute?(:average_score)

    ReadCache.fetch(CacheKeys.average(id)) { reviews.average(:score) || BigDecimal("0") }
  end

  def refresh_number_of_sales!
    # Sale inserts hold a foreign-key KEY SHARE lock on this row. NO KEY UPDATE
    # still serializes total refreshes without the lock-upgrade deadlock caused
    # by requesting FOR UPDATE from concurrent insert transactions.
    with_lock("FOR NO KEY UPDATE") do
      calculated_total = sales.sum(:sales)
      update_column(:number_of_sales, calculated_total) unless number_of_sales == calculated_total
    end
  end
end
