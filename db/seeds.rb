author_target = [ ENV.fetch("SEED_AUTHOR_COUNT", 50).to_i, 50 ].max
book_target = [ ENV.fetch("SEED_BOOK_COUNT", 300).to_i, 300 ].max
sale_years = [ ENV.fetch("SEED_SALES_YEARS", 5).to_i, 5 ].max
random_seed = ENV.fetch("SEED_RANDOM_SEED", AssignmentDatasetBuilder::DEFAULT_RANDOM_SEED).to_i
open_library_enabled = !%w[0 false no off].include?(ENV.fetch("OPEN_LIBRARY_ENABLED", "true").downcase)

importer = OpenLibraryImporter.new(logger: Rails.logger) if open_library_enabled
puts(open_library_enabled ? "Open Library import started." : "Open Library import disabled; using local fallback data.")
build = AssignmentDatasetBuilder.new(
  importer: importer,
  author_target: author_target,
  book_target: book_target,
  sale_years: sale_years,
  random_seed: random_seed,
  logger: Rails.logger
).call(reset: true)

verified = SeedDataVerifier.verify!(
  minimum_authors: author_target,
  minimum_books: book_target,
  minimum_sale_years: sale_years
)

puts "Seed completed."
puts "Authors: #{verified[:authors]} (Open Library: #{build.open_library_authors}, fallback: #{build.fallback_authors})"
puts "Books: #{verified[:books]} (Open Library: #{build.open_library_books}, fallback: #{build.fallback_books})"
puts "Incomplete Open Library records skipped: #{build.skipped_open_library_records}"
puts "Reviews: #{verified[:reviews]}"
puts "Sales: #{verified[:sales]}"
puts "Reviews per book: #{verified[:minimum_reviews_per_book]}..#{verified[:maximum_reviews_per_book]}"
puts "Minimum sale years per book: #{verified[:minimum_sale_years_per_book]}"
puts "Validation: passed"
build.warnings.each { |warning| warn "Open Library: #{warning}" }
