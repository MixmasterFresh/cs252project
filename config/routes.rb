Rails.application.routes.draw do
  resources :servers
  root to: 'visitors#index'
  devise_for :users
  resources :users
  resources :server
  get '/login/:id', to: 'servers#login', as: 'login'
  post '/filesystem_login/:id', to: 'filesystem#login'
  get '/peek', to: 'filesystem#peek'
  post '/open', to: 'filesystem#open'
  post '/save', to: 'filesystem#save'
end
