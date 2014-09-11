class Users::RegistrationsController < Devise::RegistrationsController
  ##########
  # Overrides
  ##########

  #
  def update
    @user = User.find( current_user.id )

    #raise params.to_s

    successfully_updated = if needs_password?( @user, params )
                             @user.update_with_password( devise_parameter_sanitizer.sanitize( :account_update ) )
                           else
                             # remove the virtual current_password attribute update_without_password
                             # doesn't know how to ignore it
                             params[:user].delete( :current_password )
                             @user.update_without_password( devise_parameter_sanitizer.sanitize( :account_update ) )
                           end

    if successfully_updated
      set_flash_message :notice, :updated
      # Sign in the user bypassing validation in case his password changed
      sign_in @user, :bypass => true
      redirect_to after_update_path_for(@user)

    else
      render "edit"
    end
  end

  ##########

  #
  def complete_link
    return force_cancel_linking() unless session.has_key?('incomplete_auth')
    return force_cancel_linking() unless session.has_key?('incomplete_auth.name')

    @name = session['incomplete_auth.name']

    build_resource({})
    respond_with self.resource
  end

  def create_link
    return force_cancel_linking() unless session.has_key?('incomplete_auth')
    return force_cancel_linking() unless session.has_key?('incomplete_auth.name')
    return force_cancel_linking() if user_signed_in?

    @name = session['incomplete_auth.name']

    build_resource(sign_up_params)
    self.resource.name = session['incomplete_auth.name']
    self.resource.password = Devise.friendly_token[0, 20]

    if self.resource.valid?(:email)
      # Succeeded!
      auth = session['incomplete_auth']
      user = User.create({
                           name: self.resource.name,
                           email: self.resource.email,
                           third_auth: [{ 'provider' => auth.provider, 'uid' => auth.uid }],
                           password: Devise.friendly_token[0, 20],
                           is_password_registered: false
                         })
      user.save!(:validate => false)

      set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_flashing_format?
      expire_data_after_sign_in!
      remove_incomplete_auth_session!

      respond_with resource, location: after_inactive_sign_up_path_for(resource)
      return
    end

    # failed to validate
    clean_up_passwords self.resource
    respond_with self.resource, action: 'complete_link'
  end

  private

  def remove_incomplete_auth_session!
    session["incomplete_auth"] = nil
    session["incomplete_auth.name"] = nil
  end

  def force_cancel_linking
    remove_incomplete_auth_session!
    redirect_to '/'
  end

  # check if we need password to update user data
  # ie if password or email was changed
  # extend this as needed
  def needs_password?( user, params )
    return user.is_password_registered == true &&
           ( user.email != params[:user][:email] || params[:user][:password].present? )
  end
end
