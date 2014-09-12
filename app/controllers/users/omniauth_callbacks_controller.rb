class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  #
  # used github
  #
  def github
    @user = auth_filter(request.env["omniauth.auth"]) do |auth|
      next {
        name: auth.info.name,
        email: auth.info.email
      }
    end

    # already
    if @user.persisted?
      set_flash_message(:notice, :success, :kind => "Github") if is_navigational_format?
      sign_in_and_redirect @user, :event => :authentication #this will throw if @user is not activated

    else
      # session["devise.github_data"] = request.env["omniauth.auth"]
      # redirect_to new_user_registration_url
      redirect_to '/'
    end
  end

  #
  # used twitter
  #
  def twitter
    @user = incomplete_auth_filter(request.env["omniauth.auth"])

    unless @user.nil?
      # already
      if @user.persisted?
        set_flash_message(:notice, :success, :kind => "Twitter") if is_navigational_format?
        sign_in_and_redirect @user, :event => :authentication #this will throw if @user is not activated

      else
        # session["devise.twitter_data"] = request.env["omniauth.auth"]
        # redirect_to new_user_registration_url
        redirect_to '/'
      end

    else
      # new user
      # make session and delegate process to registration_controller
      session["incomplete_auth"] = request.env["omniauth.auth"].except('extra')
      session["incomplete_auth.name"] = session["incomplete_auth"].info.nickname

      set_flash_message(:notice, :success, :kind => "Twitter") if is_navigational_format?
      flash[:notice] += " Please complete registration."

      redirect_to '/users/complete_link'
    end
  end

  #
  def after_sign_in_path_for(resource)
    if resource.email.present?
      super resource
    else
      finish_signup_path(resource)
    end
  end

  #
  #
  #
  private
  def find_user_by_authinfo(auth)
    # get user registered by same provider
    users = User.where({ 'third_auth.provider' => auth.provider, 'third_auth.uid' => auth.uid })
    if users.length >= 2
      # TODO: critial error...
    end

    return users.first
  end

  #
  def auth_filter(auth, &block)
    user = find_user_by_authinfo(auth)

    if user_signed_in?
      # user is ALREADY signed in, so this authentication is user unifying
      return link_service_to_current_user(user, auth)

    else
      ### normal authentication
      # already user existed( has same uid, same provider )
      return user unless user.nil?
    end

    # There is no user
    # create new user data(registerd via provider)!

    # get provider sensitive information
    argument = unless block.nil? then block.call(auth) else {} end

    # create
    user = User.new(argument.merge({
                                     third_auth: [{
                                                    'provider' => auth.provider,
                                                    'uid' => auth.uid,
                                                    'credentials' => auth.credentials
                                                  }],
                                     password: Devise.friendly_token[0, 20],
                                     is_password_registered: false
                                   })
                    )
    user.skip_confirmation!
    user.save!(:validate => false)

    return user
  end

  #
  def incomplete_auth_filter(auth)
    user = find_user_by_authinfo(auth)

    if user_signed_in?
      # user is ALREADY signed in, so this authentication is user unifying
      return link_service_to_current_user(user, auth)

    else
      ### normal authentication
      # already user existed( has same uid, same provider )
      return user unless user.nil?
    end

    # user is not registered
    return nil
  end

  ##########
  #
  def link_service_to_current_user(user, auth)
    raise "under construction..." # current_user.to_s

    if user.nil?
      # add provider data to 'current_user'

    else
      # user data was already created with other providor
      # so, delete existance user data and unify into 'current_user'
=begin
      user.third_auth = [] if user.third_auth.nil?

      # if user exist that has same email address, tie account information
      user.name = auth.info.nickname if user.name == ''
      user.third_auth << { 'provider' => auth.provider, 'uid' => auth.uid }
=end
    end

    return nil
  end
end
