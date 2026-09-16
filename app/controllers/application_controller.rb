class ApplicationController < ActionController::Base
  add_flash_types :success
  before_action :identify_instance

  rescue_from ActiveRecord::RecordNotFound, with: :redirect_missing_record

  private

  def identify_instance
    response.set_header("X-App-Instance", ENV.fetch("HOSTNAME", "native"))
  end

  def redirect_missing_record(error)
    record_class = error.model.safe_constantize
    destination = record_class ? polymorphic_path(record_class) : root_path

    redirect_to destination,
      alert: "#{error.model} no longer exists.",
      status: :see_other
  end
end
