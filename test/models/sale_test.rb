require "test_helper"
require "timeout"

class SaleTest < ActiveSupport::TestCase
  setup do
    author = Author.create!(name: "Gabriel Garcia Marquez")
    @book = create_book(author: author, name: "One Hundred Years of Solitude")
    @other_book = create_book(author: author, name: "Love in the Time of Cholera")
  end

  test "requires a book" do
    sale = Sale.new(year: 2020, sales: 10)

    assert_not sale.valid?
    assert_includes sale.errors[:book], "must exist"
  end

  test "requires a year between one and 9999" do
    [ nil, 0, 10_000, 2020.5 ].each do |year|
      sale = Sale.new(book: @book, year: year, sales: 10)

      assert_not sale.valid?, "expected year #{year.inspect} to be invalid"
    end
  end

  test "requires a nonnegative integer sales amount" do
    [ nil, -1, 1.5 ].each do |amount|
      sale = Sale.new(book: @book, year: 2020, sales: amount)

      assert_not sale.valid?, "expected sales #{amount.inspect} to be invalid"
    end
  end

  test "requires each book and year pair to be unique" do
    Sale.create!(book: @book, year: 2020, sales: 10)
    duplicate = Sale.new(book: @book, year: 2020, sales: 20)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:year], "has already been taken"
    assert Sale.new(book: @other_book, year: 2020, sales: 20).valid?
  end

  test "synchronizes lifetime sales after creating yearly sales" do
    Sale.create!(book: @book, year: 2019, sales: 10)
    Sale.create!(book: @book, year: 2020, sales: 25)

    assert_equal 35, @book.reload.number_of_sales
  end

  test "synchronizes lifetime sales after changing a sales amount" do
    sale = Sale.create!(book: @book, year: 2020, sales: 10)

    sale.update!(sales: 40)

    assert_equal 40, @book.reload.number_of_sales
  end

  test "synchronizes lifetime sales after destroying a yearly sale" do
    Sale.create!(book: @book, year: 2019, sales: 10)
    sale = Sale.create!(book: @book, year: 2020, sales: 25)

    sale.destroy!

    assert_equal 10, @book.reload.number_of_sales
  end

  test "synchronizes both lifetime totals when reassigning a sale" do
    Sale.create!(book: @book, year: 2019, sales: 10)
    sale = Sale.create!(book: @book, year: 2020, sales: 25)
    Sale.create!(book: @other_book, year: 2021, sales: 7)

    sale.update!(book: @other_book)

    assert_equal 10, @book.reload.number_of_sales
    assert_equal 32, @other_book.reload.number_of_sales
  end

  test "database unique index rejects duplicate book and year pairs" do
    Sale.create!(book: @book, year: 2020, sales: 10)

    assert_raises(ActiveRecord::RecordNotUnique) do
      Sale.transaction(requires_new: true) do
        Sale.insert!({
          book_id: @book.id,
          year: 2020,
          sales: 20,
          created_at: Time.current,
          updated_at: Time.current
        })
      end
    end
  end

  test "database check constraints reject invalid values" do
    assert_database_constraint do
      Sale.insert!({
        book_id: @book.id,
        year: 0,
        sales: -1,
        created_at: Time.current,
        updated_at: Time.current
      })
    end
  end

  private

  def create_book(author:, name:)
    Book.create!(
      author: author,
      name: name,
      date_of_publication: Date.new(1967, 1, 1)
    )
  end

  def assert_database_constraint(&block)
    assert_raises(ActiveRecord::StatementInvalid) do
      Sale.transaction(requires_new: true, &block)
    end
  end
end

class ConcurrentSaleTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup do
    @author = Author.create!(name: "Concurrent Sales Author #{SecureRandom.hex(4)}")
    @book = Book.create!(
      author: @author,
      name: "Concurrent Sales Book #{SecureRandom.hex(4)}",
      date_of_publication: Date.new(2020, 1, 1)
    )
  end

  teardown do
    Sale.where(book_id: @book&.id).delete_all
    Book.where(id: @book&.id).delete_all
    Author.where(id: @author&.id).delete_all
  end

  test "concurrent creates for one book both commit and synchronize the exact total" do
    ready = Queue.new
    release = Queue.new
    errors = Queue.new
    threads = []
    singleton_class = Book.singleton_class
    original_refresh = singleton_class.instance_method(:refresh_number_of_sales_for!)
    synchronized_refresh = lambda do |*book_ids|
      ready << true
      release.pop
      original_refresh.bind_call(Book, *book_ids)
    end

    singleton_class.define_method(:refresh_number_of_sales_for!, synchronized_refresh)
    begin
      threads = [ [ 2020, 10 ], [ 2021, 25 ] ].map do |year, amount|
        Thread.new do
          ApplicationRecord.connection_pool.with_connection do
            Sale.create!(book_id: @book.id, year: year, sales: amount)
          end
        rescue StandardError => error
          errors << error
        end
      end

      Timeout.timeout(10) { 2.times { ready.pop } }
      2.times { release << true }
      Timeout.timeout(10) { threads.each(&:join) }
    ensure
      2.times { release << true }
      threads.each do |thread|
        thread.join(1)
        thread.kill if thread.alive?
      end
      singleton_class.define_method(:refresh_number_of_sales_for!, original_refresh)
    end

    assert_predicate errors, :empty?, "concurrent sale errors: #{errors.size}"
    assert_equal 2, @book.sales.count
    assert_equal 35, @book.reload.number_of_sales
    assert_equal @book.sales.sum(:sales), @book.number_of_sales
  end
end
