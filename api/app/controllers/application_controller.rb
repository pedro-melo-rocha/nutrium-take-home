class ApplicationController < ActionController::API
  private

  def render_error(result)
    status =
      case result.error_code
      when :overlap_conflict, :concurrent_submission, :invalid_state then :conflict
      else :unprocessable_content
      end

    render json: { error: { code: result.error_code.to_s, message: result.error_message } }, status: status
  end
end
