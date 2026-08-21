require "test_helper"

class DomainSchemaTest < ActiveSupport::TestCase
  test "required domain columns are not nullable" do
    assert_not_nullable :authors, :name

    assert_not_nullable :books, :author_id, :name, :date_of_publication, :number_of_sales
    assert_not_nullable :reviews, :book_id, :review_text, :score, :up_votes
    assert_not_nullable :sales, :book_id, :year, :sales
  end

  test "parent relationships have database foreign keys" do
    assert_foreign_key :books, :authors, :author_id
    assert_foreign_key :reviews, :books, :book_id
    assert_foreign_key :sales, :books, :book_id
  end

  test "relationship and Open Library lookup indexes exist" do
    assert_index :authors, :open_library_key, unique: true
    assert_index :books, :author_id
    assert_index :books, :open_library_key, unique: true
    assert_index :reviews, :book_id
    assert_index :sales, :book_id
    assert_index :sales, [ :book_id, :year ], unique: true
  end

  test "all domain check constraints exist" do
    assert_check_constraints :authors, "authors_name_not_blank"
    assert_check_constraints :books,
      "books_name_not_blank",
      "books_number_of_sales_nonnegative"
    assert_check_constraints :reviews,
      "reviews_text_not_blank",
      "reviews_score_range",
      "reviews_up_votes_nonnegative"
    assert_check_constraints :sales,
      "sales_year_range",
      "sales_amount_nonnegative"
  end

  test "database check constraints reject invalid data that bypasses validations" do
    assert_constraint_violation do
      Author.insert!({ name: " ", created_at: Time.current, updated_at: Time.current })
    end

    author = Author.create!(name: "Constraint Test Author")
    book = Book.create!(
      author: author,
      name: "Constraint Test Book",
      date_of_publication: Date.new(2000, 1, 1)
    )

    assert_constraint_violation do
      Review.insert!({
        book_id: book.id,
        review_text: "Invalid score",
        score: 6,
        up_votes: 0,
        created_at: Time.current,
        updated_at: Time.current
      })
    end

    assert_constraint_violation do
      book.update_column(:number_of_sales, -1)
    end
  end

  private

  def connection
    ApplicationRecord.connection
  end

  def assert_not_nullable(table, *column_names)
    columns = connection.columns(table).index_by(&:name)

    column_names.each do |column_name|
      assert_not columns.fetch(column_name.to_s).null,
        "expected #{table}.#{column_name} to be NOT NULL"
    end
  end

  def assert_foreign_key(from_table, to_table, column)
    foreign_key = connection.foreign_keys(from_table).find do |candidate|
      candidate.to_table == to_table.to_s && candidate.column == column.to_s
    end

    assert foreign_key,
      "expected a foreign key from #{from_table}.#{column} to #{to_table}"
  end

  def assert_index(table, column_names, unique: false)
    expected_columns = Array(column_names).map(&:to_s)
    index = connection.indexes(table).find do |candidate|
      candidate.columns == expected_columns && candidate.unique == unique
    end

    assert index,
      "expected #{table}(#{expected_columns.join(', ')}) index with unique=#{unique}"
  end

  def assert_check_constraints(table, *constraint_names)
    actual_names = connection.check_constraints(table).map(&:name)

    constraint_names.each do |constraint_name|
      assert_includes actual_names, constraint_name
    end
  end

  def assert_constraint_violation(&block)
    assert_raises(ActiveRecord::StatementInvalid) do
      ApplicationRecord.transaction(requires_new: true, &block)
    end
  end
end
