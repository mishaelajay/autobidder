# frozen_string_literal: true

# Background job responsible for notifying external systems about auction events.
# Handles communication with external APIs and services about auction status changes.
class ExternalSystemNotifierJob < ApplicationJob
  queue_as :external_notifications
  retry_on StandardError, wait: :exponentially_longer, attempts: 5

  def perform(event:, **payload)
    response = make_api_call(event, payload)
    handle_response(response)
  end

  private

  def make_api_call(event, payload)
    HTTP.post(
      api_endpoint,
      json: build_request_payload(event, payload)
    )
  end

  def handle_response(response)
    return if response.status.success?

    raise "External system notification failed: #{response.status} - #{response.body}"
  end

  def api_endpoint
    Rails.configuration.external_api_endpoint
  end

  def build_request_payload(event, payload)
    {
      event: event,
      timestamp: Time.current.iso8601,
      payload: payload
    }
  end
end
