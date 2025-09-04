class Api::BaseController < ApplicationController
  protect_from_forgery with: :null_session

  before_action :set_default_format

  private

  def set_default_format
    request.format = :json
  end

  def render_json_error(message, status: :unprocessable_entity)
    render json: { error: message }, status: status
  end

  def render_json_success(data, message: nil)
    response = { data: data }
    response[:message] = message if message.present?
    render json: response
  end
end
