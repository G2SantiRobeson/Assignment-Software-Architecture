class CreateCacheRevisions < ActiveRecord::Migration[8.0]
  def change
    create_table :cache_revisions, id: false do |t|
      t.string :key, null: false, primary_key: true
      t.bigint :version, null: false, default: 0
    end
  end
end
