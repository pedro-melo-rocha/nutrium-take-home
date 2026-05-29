module Api
  module V1
    module Nutritionists
      # GET /api/v1/nutritionists/:nutritionist_id/appointment_requests?status=
      # Backs the nutritionist queue page.
      class AppointmentRequestsController < ApplicationController
        VALID_STATUSES = %w[pending accepted rejected canceled].freeze

        def index
          nutritionist = ::Nutritionist.find(params[:nutritionist_id])

          scope = nutritionist
            .appointment_requests
            .includes(:service)
            .order(starts_at: :asc)

          status_filter = (params[:status] || "pending").to_s
          if VALID_STATUSES.include?(status_filter)
            scope = scope.where(status: status_filter)
          else
            return render(
              json: { error: { code: "invalid_status", message: "status must be one of #{VALID_STATUSES.join(', ')}" } },
              status: :unprocessable_content
            )
          end

          render json: { nutritionist: { id: nutritionist.id, name: nutritionist.name }, results: scope.map { |r| serialize(r) } }
        end

        private

        def serialize(record)
          {
            id: record.id,
            status: record.status,
            starts_at: record.starts_at.iso8601,
            ends_at: record.ends_at.iso8601,
            guest_name: record.guest_name,
            guest_email: record.guest_email,
            created_at: record.created_at.iso8601,
            service: {
              id: record.service.id,
              name: record.service.name,
              price_cents: record.service.price_cents,
              location: record.service.location,
              duration_minutes: record.service.duration_minutes
            }
          }
        end
      end
    end
  end
end
