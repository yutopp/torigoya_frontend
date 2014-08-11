class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)
    # TODO: fix it!!!
    if user.email == 'yutopp@gmail.com'# || user.admin?
      can :manage, :all
    else
      # can :read, :all
    end
  end
end
