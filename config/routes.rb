Rails.application.routes.draw do
  devise_for :users, :controllers => {
    :registrations => "registrations",
    :omniauth_callbacks => "users/omniauth_callbacks"
  }

  #
  root 'home#index'
  match 'home/index' => 'home#index', :via => [:get, :post]

  #
  match 'entries' => 'entries#show_list', :via => :get
  match 'entries/:entry_id' => 'entries#show_entry', :via => :get

  #
  match 'users' => 'users#index', :via => :get
  match 'users/codes' => 'users#show_my_codes', :via => :get

  #
  match 'api/source' => 'api#post_source', :via => :post
  match 'api/entry/:entry_id' => 'api#get_entry', :via => :get
  match 'api/ticket/:ticket_id' => 'api#get_ticket', :via => :get
  match 'api/nodes' => 'api#get_cage_nodes', :via => :get

  #
  # for master controller(like dashboard for admin)
  match 'master' => 'master#index', :via => :get
  match 'master/users' => 'master#list_users', :via => :get
  match 'master/users/:id' => 'master#delete_user', :via => :delete
  match 'master/update_proctable' => 'master#update_proctable', :via => :post
  match 'master/runner_node_addresses' => 'master#update_node_addresses', :via => :post
  match 'master/mask_proctable/:index' => 'master#mask_proctable', :via => :post
  match 'master/unmask_proctable/:index' => 'master#unmask_proctable', :via => :post

  #
  match 'feedback/send' => 'feedback#send_mail', :via => :post
end
