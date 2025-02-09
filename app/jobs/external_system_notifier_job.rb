class ExternalSystemNotifierJob < ApplicationJob
  queue_as :external_notifications
  retry_on StandardError, wait: :exponentially_longer, attempts: 5

  def perform(event:, **payload)
    # Configure the external system API endpoint
    external_api_endpoint = Rails.configuration.external_api_endpoint

    # Make the API call to the external system
    response = HTTP.post(
      external_api_endpoint,
      json: {
        event: event,
        timestamp: Time.current.iso8601,
        payload: payload
      }
    )

    unless response.status.success?
      raise "External system notification failed: #{response.status} - #{response.body}"
    end
  end
end 