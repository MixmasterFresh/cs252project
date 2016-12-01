Rails.application.routes.draw do
  resources :servers
  root to: 'visitors#index'
  devise_for :users
  resources :users
  resources :server
  post '/filesystem_login', to: 'filesystem#login'
  post '/peek/:server', to: 'filesystem#peek'
  post '/open/:server', to: 'filesystem#open'
  post '/save/:server', to: 'filesystem#save'
end
