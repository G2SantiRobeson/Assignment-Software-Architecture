class Sale < ApplicationRecord
  belongs_to :book, inverse_of: :sales

  validates :year,
    numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 9999 },
    uniqueness: { scope: :book_id }
  validates :sales,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  after_save :synchronize_affected_book_totals, if: :sales_total_changed?
  after_destroy :synchronize_destroyed_book_total

  private

  def sales_total_changed?
    saved_change_to_sales? || saved_change_to_book_id?
  end

  def synchronize_affected_book_totals
    affected_book_ids = [ book_id ]
    affected_book_ids.concat(saved_change_to_book_id) if saved_change_to_book_id?

    Book.refresh_number_of_sales_for!(affected_book_ids)
  end

  def synchronize_destroyed_book_total
    Book.refresh_number_of_sales_for!(book_id)
  end
end
