Rails.application.routes.draw do
  resources :servers
  root to: 'visitors#index'
  devise_for :users
  resources :users
  resources :server
  post '/filesystem_login', to: 'filesystem#login'
  post '/peek/:id', to: 'filesystem#peek'
  post '/open/:id', to: 'filesystem#open'
  post '/save/:id', to: 'filesystem#save'
end
