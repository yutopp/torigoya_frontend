module ApplicationHelper
  def navbar_home?
    return params[:controller] == "home"
  end

  def navbar_about?
    return params[:controller] == "about"
  end

  def navbar_master?
    return params[:controller] == "master"
  end

  def navbar_user?
    return params[:controller] == "users" ||
      ( params[:controller] == "users/registrations" && params[:action] == "edit" )
  end

  def navbar_register?
    return params[:controller] == "users/registrations" && params[:action] != "edit"
  end

  def navbar_login?
    return params[:controller] == "devise/sessions"
  end
end
