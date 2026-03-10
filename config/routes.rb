Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  get "styleguide", to: "pages#styleguide"
  get "loans", to: "pages#loans", as: :loans
  get "lenders", to: "pages#lenders", as: :lenders
  get "invest", to: "pages#invest", as: :invest

  # Public blog / knowledge base
  resources :knowledge, only: [:index, :show], controller: "knowledge"

  # Admin
  namespace :admin do
    get "/", to: "dashboard#index", as: :dashboard
    resources :blogs do
      member do
        post :publish
        post :unpublish
      end
    end
    resources :categories

    resources :loans do
      member do
        post :generate_statement
      end
      resources :loan_ledger_entries, only: [:create] do
        member do
          post :reverse
        end
      end
      resources :payments, except: [:index, :show]
      resources :loan_statements, only: [:show, :destroy]
      resources :loan_draws, except: [:index, :show] do
        member do
          post :fund
          post :approve
          post :reject
        end
      end
      resources :loan_fees, except: [:index, :show] do
        member do
          post :mark_paid
        end
      end
      resources :loan_documents, only: [:create, :destroy]
      resources :loan_extensions, only: [:new, :create, :destroy]
    end
  end

  root "pages#home"
end
