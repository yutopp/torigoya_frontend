Rails.application.routes.draw do
  devise_for :users, :controllers => {
    :omniauth_callbacks => "users/omniauth_callbacks",
    :registrations => "users/registrations"
  }
  devise_scope :user do
    get '/users/complete_link', :to => 'users/registrations#complete_link'
    post '/users/complete_link', :to => 'users/registrations#create_link'
  end

  #
  root 'home#index'
  match '/home/index' => 'home#index', :via => [:get, :post]

  #
  match '/entries' => 'entries#show_list', :via => :get
  match '/entries/:entry_id' => 'entries#show_entry', :via => :get

  #
  match '/users' => 'users#index', :via => :get
  match '/users/codes' => 'users#show_my_codes', :via => :get

  # system
  match '/api/system/source' => 'api#post_source', :via => :post
  match '/api/system/entry/:entry_id' => 'api#get_entry', :via => :get
  match '/api/system/ticket/:ticket_id' => 'api#get_ticket', :via => :get

  # public api
  match '/api/nodes' => 'api#get_cage_nodes', :via => :get

  #
  match '/about' => 'about#index', :via => :get

  #
  # for master controller(like dashboard for admin)
  match '/master' => 'master#index', :via => :get
  match '/master/users' => 'master#list_users', :via => :get
  match '/master/users/:user_id' => 'master#delete_user', :via => :delete
  match '/master/update_proctable' => 'master#update_proctable', :via => :post
  match '/master/runner_node_addresses' => 'master#update_node_addresses', :via => :post
  match '/master/enable_langproc/:proc_id' => 'master#enable_langproc', :via => :post
  match '/master/disable_langproc/:proc_id' => 'master#disable_langproc', :via => :post

  #
  match '/feedback/send' => 'feedback#send_mail', :via => :post
end
