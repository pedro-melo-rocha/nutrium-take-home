module Api
  module V1
    class NutritionistsController < ApplicationController
      # GET /api/v1/nutritionists?q=&location=&page=&per_page=&lat=&lng=
      def index
        search = NutritionistSearch.new(
          q: params[:q],
          location: params[:location],
          page: params[:page],
          per_page: params[:per_page],
          lat: params[:lat],
          lng: params[:lng]
        )

        render json: {
          location: search.location,
          query: search.q,
          sorted_by: search.geo? ? "distance" : "name",
          results: search.results,
          pagination: search.pagination
        }
      end
    end
  end
end
