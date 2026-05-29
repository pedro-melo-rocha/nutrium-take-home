module Api
  module V1
    class NutritionistsController < ApplicationController
      # GET /api/v1/nutritionists?q=&location=
      def index
        search = ::Nutritionists::Search.new(
          q: params[:q],
          location: params[:location],
          page: params[:page],
          per_page: params[:per_page]
        )

        render json: {
          location: search.location,
          query: search.q,
          results: search.results,
          pagination: search.pagination
        }
      end
    end
  end
end
