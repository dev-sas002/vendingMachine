require 'sidekiq/web'

Rails.application.routes.draw do
  # Unauthenticated liveness probe; used by the container healthcheck.
  get '/health', to: 'health#show'

  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  mount Sidekiq::Web => '/jobmonitor'

  # Read-only HTML view of the products. There is no HTML sign-in flow, so no
  # write actions are exposed here - use the /api/v1 endpoints for those.
  # Numeric-only ids, so /products/new does not quietly fall through to #show.
  resources :products, only: %i[index show], constraints: { id: /\d+/ }

  mount_devise_token_auth_for 'User', at: '/api/v1/users', controllers: {
    registrations: 'api/v1/registrations',
    sessions: 'api/v1/sessions',
    passwords: 'api/v1/passwords',
    token_validations: 'api/v1/token_validations'
  }, skip: %i[omniauth_callbacks registrations]

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resource :user, only: %i[show update destroy] do
        collection do
          get :all
        end
      end
      resources :products, only: %i[index show create update destroy],
                           constraints: { id: /\d+/ }
      post :buy, controller: :vending_machine
      post :deposit, controller: :vending_machine
      post :reset, controller: :vending_machine

      devise_scope :user do
        resources :users, only: [] do
          controller :registrations do
            post :create, on: :collection
          end
        end
      end
    end
  end
end
