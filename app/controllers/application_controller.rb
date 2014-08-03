class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_filter :configure_permitted_parameters, if: :devise_controller?
  before_filter :set_proc_table

  def set_proc_table
    unless self.controller_name == "api"
      gon.proc_table = Cages.get_proc_table()
    end
  end
end
