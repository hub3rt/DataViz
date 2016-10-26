Rails.application.routes.draw do

  resources :matches
  resources :championnats
	root 'welcome#index'

  get 'welcome/index'
  get '/show', to: 'welcome#show'
  get '/admin', to: 'admin#index'




  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end