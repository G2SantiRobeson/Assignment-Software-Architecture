class ApplicationController < ActionController::Base
  add_flash_types :success

  rescue_from ActiveRecord::RecordNotFound, with: :redirect_missing_record

  private

  def redirect_missing_record(error)
    record_class = error.model.safe_constantize
    destination = record_class ? polymorphic_path(record_class) : root_path

    redirect_to destination,
      alert: "#{error.model} no longer exists.",
      status: :see_other
  end
end
