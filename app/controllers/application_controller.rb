class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_filter :configure_permitted_parameters, if: :devise_controller?
  before_filter :set_proc_table

  unless Rails.env.development?
    rescue_from Exception, with: :error_50x
  end

  #
  def configure_permitted_parameters
    #
    devise_parameter_sanitizer.for(:sign_up) do |u|
      u.permit(:name, :email, :password, :password_confirmation)
    end

    #
    devise_parameter_sanitizer.for(:account_update) do |u|
      u.permit(:name, :email, :password, :password_confirmation, :current_password)
    end
  end

  #
  def set_proc_table
    unless self.controller_name == "api"
      gon.proc_table = Cages.get_proc_table()
    end
  end

  #
  def error_404(error = nil)
    log_errors(error)
    render :template => "errors/404", :status => 404, :layout => 'errors', :content_type => 'text/html'
  end

  #
  def error_422(error = nil)
    log_errors(error)
    render :template => "errors/422", :status => 422, :layout => 'errors', :content_type => 'text/html'
  end

  #
  def error_50x(error = nil)
    log_errors(error)

    @status_code = 500
    render :template => "errors/50x", :status => @status_code, :layout => 'errors', :content_type => 'text/html'
  end

  #
  private
  def log_errors(error)
    return if error.nil?

    Rails.logger.error "=" * 40
    Rails.logger.error " Exception!!"
    Rails.logger.error "=" * 40

    Rails.logger.error "= Message =>"
    Rails.logger.error error.message

    Rails.logger.error "= Backtrace =>"
    error.backtrace.each do |b|
      Rails.logger.error b
    end
  end
end
