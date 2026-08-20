class CreateBookReviewDomain < ActiveRecord::Migration[8.0]
  def change
    create_table :authors do |t|
      t.string :name, null: false
      t.date :date_of_birth
      t.string :country_of_origin
      t.text :short_description
      t.string :open_library_key

      t.timestamps
    end

    add_index :authors, :open_library_key, unique: true
    add_check_constraint :authors, "char_length(btrim(name)) > 0", name: "authors_name_not_blank"

    create_table :books do |t|
      t.references :author, null: false, foreign_key: true
      t.string :name, null: false
      t.text :summary
      t.date :date_of_publication, null: false
      t.bigint :number_of_sales, null: false, default: 0
      t.string :open_library_key

      t.timestamps
    end

    add_index :books, :open_library_key, unique: true
    add_check_constraint :books, "char_length(btrim(name)) > 0", name: "books_name_not_blank"
    add_check_constraint :books, "number_of_sales >= 0", name: "books_number_of_sales_nonnegative"

    create_table :reviews do |t|
      t.references :book, null: false, foreign_key: true
      t.text :review_text, null: false
      t.integer :score, null: false
      t.bigint :up_votes, null: false, default: 0

      t.timestamps
    end

    add_check_constraint :reviews, "char_length(btrim(review_text)) > 0", name: "reviews_text_not_blank"
    add_check_constraint :reviews, "score BETWEEN 1 AND 5", name: "reviews_score_range"
    add_check_constraint :reviews, "up_votes >= 0", name: "reviews_up_votes_nonnegative"

    create_table :sales do |t|
      t.references :book, null: false, foreign_key: true
      t.integer :year, null: false
      t.bigint :sales, null: false, default: 0

      t.timestamps
    end

    add_index :sales, [ :book_id, :year ], unique: true
    add_check_constraint :sales, "year BETWEEN 1 AND 9999", name: "sales_year_range"
    add_check_constraint :sales, "sales >= 0", name: "sales_amount_nonnegative"
  end
end
