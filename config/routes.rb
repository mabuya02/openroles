Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Root route
  root "home#index"

  # Authentication routes
  namespace :auth do
    # Login routes
    get "login", to: "sessions#new", as: :new_session
    post "login", to: "sessions#create", as: :sessions
    get "logout", to: "sessions#logout_confirmation", as: :logout_confirmation
    delete "logout", to: "sessions#destroy", as: :destroy_session
    get "session/status", to: "sessions#status", as: :session_status

    # Registration routes
    get "register", to: "registrations#new", as: :new_registration
    post "register", to: "registrations#create", as: :registrations

    # Password reset routes
    get "password/forgot", to: "passwords#new", as: :new_password
    post "password/forgot", to: "passwords#create", as: :passwords
    get "password/reset/:token", to: "passwords#edit", as: :edit_password
    patch "password/reset/:token", to: "passwords#update", as: :password

    # New user password setup routes (for default password reset)
    get "password-reset/:user_id/:code", to: "password_resets#new", as: :password_reset
    patch "password-reset/:user_id/:code", to: "password_resets#update", as: :update_password_reset

    # Verification routes
    get "verify-email/:user_id/:code", to: "verifications#verify_email", as: :verify_email
    post "resend-email", to: "verifications#resend_email", as: :resend_email
    post "verify-phone", to: "verifications#verify_phone", as: :verify_phone
    post "resend-phone", to: "verifications#resend_phone", as: :resend_phone
  end

  # Convenience routes
  get "/login", to: "auth/sessions#new"
  get "/register", to: "auth/registrations#new"
  get "/logout", to: "auth/sessions#logout_confirmation"
  delete "/logout", to: "auth/sessions#destroy"

  # Profile routes
  resource :profile, only: [ :show, :edit, :update ], controller: "profiles" do
    delete :remove_attachment
  end

  # Job browsing routes
  resources :jobs, only: [ :index, :show ] do
    collection do
      get :search
      get :filter
      get :live_search
    end
  end

  # Company routes
  resources :companies, only: [ :index, :show ] do
    collection do
      get :search
    end
    member do
      get :jobs
    end
  end

  # Remote jobs routes
  resources :remote, only: [ :index ], controller: "remote_jobs", as: :remote_jobs do
    collection do
      get :search
      get :filter
      get :live_search
    end
  end

  # Alert routes (require authentication)
  resources :alerts, except: [ :destroy ] do
    member do
      patch :toggle_status
      post :test_alert
      get :unsubscribe_confirmation
      patch :unsubscribe_alert
    end
  end

  # Unsubscribe route (no authentication required)
  get "alerts/unsubscribe/:token", to: "alerts#unsubscribe", as: :unsubscribe_alert

  # API routes
  namespace :api do
    namespace :v1 do
      resources :companies, only: [ :index, :show ] do
        member do
          get :jobs
        end
      end
    end

    # Legacy API routes (for backward compatibility)
    resources :companies, only: [ :index, :show ] do
      member do
        get :jobs
      end
    end

    resource :job_fetcher, only: [] do
      post :fetch_all
      post :fetch_from_source
      get :recent
      get :status
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
