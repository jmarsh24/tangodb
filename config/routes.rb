Rails.application.routes.draw do
  root 'videos#index'

  resources :videos, only: :index
  get '/welcome/index'
end
