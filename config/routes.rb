# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :api do
    resources :orders, only: [:index] do
      collection do
        post :upload
      end
    end
  end
end
