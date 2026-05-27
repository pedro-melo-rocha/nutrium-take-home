module Api
  module V1
    class NutritionistsController < ApplicationController
      # GET /api/v1/nutritionists?q=&location=
      #
      # Returns nutritionists whose service offering matches the search.
      # The response includes the resolved `location` so the client can
      # show "Showing results for Braga" when the default was applied.
      def index
        search = Nutritionists::Search.new(
          q: params[:q],
          location: params[:location]
        )

        render json: {
          location: search.location,
          query: search.q,
          results: search.results
        }
      end
    end
  end
end
