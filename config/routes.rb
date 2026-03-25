Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" }
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

  # About & Contact
  get "about", to: "contact#show", as: :contact
  post "about", to: "contact#create"

  # Client dashboard (requires login)
  get "dashboard", to: "dashboard#show", as: :dashboard

  # Client loan views
  namespace :client, path: "" do
    resources :loans, only: [:show], path: "my-loans" do
      resources :loan_statements, only: [:show], path: "statements"
    end
  end

  # Public document upload (no auth required)
  get "upload", to: "uploads#new", as: :upload
  post "upload", to: "uploads#create"
  get "upload/success", to: "uploads#success", as: :upload_success

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
    resources :contact_submissions, only: [:index, :show], path: "messages" do
      member do
        post :mark_read
        post :archive
      end
    end
    resources :client_uploads, only: [:index, :show], path: "documents" do
      member do
        post :assign
        post :reject
      end
    end

    resources :users do
      member do
        post :toggle_admin
        post :toggle_godpowers
        post :resend_invite
        post :send_reset
        post :add_loan_role
        delete :remove_loan_role
      end
    end

    resources :loans do
      member do
        post :generate_statement
        post :send_welcome_email
      end
      resources :loan_ledger_entries, only: [:index, :create, :destroy, :update] do
        collection do
          post :accrue_interest
        end
        member do
          post :reverse
        end
      end
      resources :payments, except: [:index, :show]
      resources :loan_statements, only: [:show, :destroy] do
        post :send_to_client, on: :member
      end
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
      resources :loan_reserves, only: [:create, :update, :destroy] do
        member do
          post :draw
          post :release
          post :forfeit
        end
      end
    end
  end

  root "pages#home"
end
