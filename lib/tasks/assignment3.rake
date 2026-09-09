namespace :assignment3 do
  desc "Exercise real CRUD pages, Redis and OpenSearch; nonzero exit on incorrect results"
  task verify: :environment do
    Assignment3Verification.new.call
  end
end
