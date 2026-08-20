Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resources :authors
  resources :books
  resources :reviews
  resources :sales

  get "reports/author-statistics", to: "reports#author_statistics", as: :author_statistics
  get "reports/top-rated-books", to: "reports#top_rated_books", as: :top_rated_books
  get "reports/top-selling-books", to: "reports#top_selling_books", as: :top_selling_books
  get "book-search", to: "book_searches#index", as: :book_search

  root "books#index"
end
