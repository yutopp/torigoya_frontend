Rails.application.routes.draw do
  devise_for :users, :controllers => {
    :registrations => "registrations",
    :omniauth_callbacks => "users/omniauth_callbacks"
  }

  #
  root 'home#index'
  match 'home/index' => 'home#index', :via => [:get, :post]

  #
  match 'api/source' => 'api#post_source', :via => :post
  match 'api/entry/:entry_id' => 'api#get_entry', :via => :get
  match 'api/ticket/:ticket_id' => 'api#get_ticket', :via => :get

  #
  match 'entries' => 'entries#show_list', :via => :get
  match 'entries/:entry_id' => 'entries#show_entry', :via => :get
end
