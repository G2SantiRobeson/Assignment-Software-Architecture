module MaintainsReadModels
  extend ActiveSupport::Concern

  included do
    after_save :schedule_read_model_changes
    after_destroy :schedule_read_model_changes
  end

  private

  def schedule_read_model_changes
    # Capture each mutation, including multiple relationship changes in one
    # transaction. Rails promotes callbacks through savepoints and discards
    # them on rollback. No external I/O happens before the outer commit.
    CacheInvalidation.record_changed(self)
    if is_a?(Book) || is_a?(Review)
      model_name, record_id = self.class.name, id
      self.class.current_transaction.after_commit do
        Search::Indexer.new.synchronize(model_name, record_id)
      end
    end
  end
end
