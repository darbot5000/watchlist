Rails.application.routes.draw do
  root "watchlist_items#index"

  resources :watchlist_items do
    member do
      patch :toggle_status
    end
    collection do
      get :search
    end
  end

  # Telegram webhook
  post "/telegram/webhook", to: "telegram#webhook"

  # Health check
  get "/up", to: proc { [200, {}, ["OK"]] }
end
