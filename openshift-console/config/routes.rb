Rails.application.routes.draw do
  openshift_console
  match 'logout' => 'console_index#logout', :via => :get, :as => 'logout'
  root :to => 'console_index#index'
end
