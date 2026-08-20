# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_08_12_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "authors", force: :cascade do |t|
    t.string "name", null: false
    t.date "date_of_birth"
    t.string "country_of_origin"
    t.text "short_description"
    t.string "open_library_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["open_library_key"], name: "index_authors_on_open_library_key", unique: true
    t.check_constraint "char_length(btrim(name::text)) > 0", name: "authors_name_not_blank"
  end

  create_table "books", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.string "name", null: false
    t.text "summary"
    t.date "date_of_publication", null: false
    t.bigint "number_of_sales", default: 0, null: false
    t.string "open_library_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_books_on_author_id"
    t.index ["open_library_key"], name: "index_books_on_open_library_key", unique: true
    t.check_constraint "char_length(btrim(name::text)) > 0", name: "books_name_not_blank"
    t.check_constraint "number_of_sales >= 0", name: "books_number_of_sales_nonnegative"
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.text "review_text", null: false
    t.integer "score", null: false
    t.bigint "up_votes", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id"], name: "index_reviews_on_book_id"
    t.check_constraint "char_length(btrim(review_text)) > 0", name: "reviews_text_not_blank"
    t.check_constraint "score >= 1 AND score <= 5", name: "reviews_score_range"
    t.check_constraint "up_votes >= 0", name: "reviews_up_votes_nonnegative"
  end

  create_table "sales", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.integer "year", null: false
    t.bigint "sales", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id", "year"], name: "index_sales_on_book_id_and_year", unique: true
    t.index ["book_id"], name: "index_sales_on_book_id"
    t.check_constraint "sales >= 0", name: "sales_amount_nonnegative"
    t.check_constraint "year >= 1 AND year <= 9999", name: "sales_year_range"
  end

  add_foreign_key "books", "authors"
  add_foreign_key "reviews", "books"
  add_foreign_key "sales", "books"
end
