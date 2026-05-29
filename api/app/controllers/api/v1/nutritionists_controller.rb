module Api
  module V1
    class NutritionistsController < ApplicationController
      # GET /api/v1/nutritionists?q=&location=
      def index
        # `::` prefix avoids resolving to Api::V1::Nutritionists (the nested
        # controller namespace), which would shadow the query object.
        search = ::Nutritionists::Search.new(
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
