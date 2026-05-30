module Api
  module V1
    module Nutritionists
      # Nutritionist queue + accept/reject, scoped to :nutritionist_id.
      #   GET   /api/v1/nutritionists/:nutritionist_id/appointment_requests?status=
      #   PATCH /api/v1/nutritionists/:nutritionist_id/appointment_requests/:id
      class AppointmentRequestsController < ApplicationController
        VALID_STATUSES = %w[pending accepted rejected].freeze

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

        # PATCH /api/v1/nutritionists/:nutritionist_id/appointment_requests/:id
        # Body: { decision: "accept" | "reject" }.
        # Key is `decision` (not `action`) — Rails reserves `params[:action]`.
        # Request is looked up THROUGH the nutritionist, so one belonging to a
        # different professional 404s (enforces "answered by the same nutritionist").
        def update
          nutritionist = ::Nutritionist.find(params[:nutritionist_id])
          record = nutritionist.appointment_requests.find(params[:id])

          service =
            case params[:decision]
            when "accept" then AppointmentRequests::Accept.new
            when "reject" then AppointmentRequests::Reject.new
            else
              return render(
                json: { error: { code: "missing_decision", message: "Body must include `decision`: \"accept\" or \"reject\"." } },
                status: :unprocessable_content
              )
            end

          result = service.call(record)
          if result.success?
            render json: serialize(result.record), status: :ok
          else
            render_error(result)
          end
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
