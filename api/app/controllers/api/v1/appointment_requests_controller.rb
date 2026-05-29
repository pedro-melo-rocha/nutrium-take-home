module Api
  module V1
    class AppointmentRequestsController < ApplicationController
      # POST /api/v1/appointment_requests
      #
      # Body: { appointment_request: { service_id, guest_name, guest_email, starts_at } }
      def create
        result = AppointmentRequests::Create.new.call(create_params.to_h.symbolize_keys)

        if result.success?
          render json: serialize(result.record), status: :created
        else
          render_error(result)
        end
      end

      # PATCH /api/v1/appointment_requests/:id
      #
      # Body: { decision: "accept" | "reject" }
      # (key is `decision`, not `action`, because Rails reserves `params[:action]`
      #  for the controller-action name)
      def update
        record = AppointmentRequest.find(params[:id])

        service =
          case params[:decision]
          when "accept" then AppointmentRequests::Accept.new
          when "reject" then AppointmentRequests::Reject.new
          else
            return render(
              json: { error: { code: "missing_decision", message: "Body must include `decision`: \"accept\" or \"reject\"." } },
              status: :unprocessable_entity
            )
          end

        result = service.call(record)
        if result.success?
          render json: serialize(result.record), status: :ok
        else
          render_error(result)
        end
      end

      # GET /api/v1/appointment_requests/lookup?guest_email=foo@bar.com
      #
      # Returns the guest's currently active (pending OR accepted) request if any.
      # Used by the frontend to show a confirmation dialog before superseding.
      #
      # Security note: spec is no-auth, so this endpoint reveals whether a given
      # email has an active request. Acceptable for take-home scope (the guest
      # who typed their own email is who's looking). See DECISIONS P3-001.
      def lookup
        email = params[:guest_email].to_s.strip.downcase.presence

        if email.nil?
          return render(
            json: { error: { code: "missing_guest_email", message: "guest_email is required" } },
            status: :unprocessable_entity
          )
        end

        active = AppointmentRequest
          .where(guest_email: email, status: [:pending, :accepted])
          .order(created_at: :desc)
          .first

        render json: { active: active ? serialize(active, include_service: true, include_nutritionist: true) : nil }
      end

      private

      def create_params
        params.require(:appointment_request).permit(:service_id, :guest_name, :guest_email, :starts_at)
      end

      def render_error(result)
        status =
          case result.error_code
          when :validation_failed       then :unprocessable_entity
          when :overlap_conflict        then :conflict
          when :concurrent_submission   then :conflict
          when :invalid_state           then :conflict
          else :unprocessable_entity
          end

        render json: { error: { code: result.error_code.to_s, message: result.error_message } }, status: status
      end

      def serialize(record, include_service: true, include_nutritionist: true)
        h = {
          id: record.id,
          status: record.status,
          starts_at: record.starts_at.iso8601,
          ends_at: record.ends_at.iso8601,
          guest_name: record.guest_name,
          guest_email: record.guest_email,
          created_at: record.created_at.iso8601
        }
        if include_service && record.service
          h[:service] = {
            id: record.service.id,
            name: record.service.name,
            price_cents: record.service.price_cents,
            location: record.service.location,
            duration_minutes: record.service.duration_minutes
          }
        end
        if include_nutritionist && record.nutritionist
          h[:nutritionist] = { id: record.nutritionist.id, name: record.nutritionist.name }
        end
        h
      end
    end
  end
end
