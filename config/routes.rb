Rails.application.routes.draw do
  resources :servers
  root to: 'visitors#index'
  devise_for :users
  resources :users
  resources :server
  post '/filesystem_login/:id', to: 'filesystem#login'
  post '/peek', to: 'filesystem#peek'
  post '/open', to: 'filesystem#open'
  post '/save', to: 'filesystem#save'
end
