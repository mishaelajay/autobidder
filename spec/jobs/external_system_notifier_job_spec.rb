require 'rails_helper'

RSpec.describe ExternalSystemNotifierJob, type: :job do
  include ActiveJob::TestHelper

  let(:event) { 'auction_completed' }
  let(:payload) { 
    {
      auction_id: 1,
      winner_id: 2,
      winning_amount: 100.00,
      completed_at: Time.current
    }
  }

  before do
    allow(Rails.configuration).to receive(:external_api_endpoint)
      .and_return('https://api.example.com/events')
  end

  describe '#perform' do
    let(:expected_request_body) do
      {
        event: event,
        timestamp: anything,
        payload: payload
      }
    end

    context 'when the external system responds successfully' do
      before do
        stub_request(:post, Rails.configuration.external_api_endpoint)
          .with(body: hash_including(expected_request_body))
          .to_return(status: 200)
      end

      it 'sends the notification to the external system' do
        perform_enqueued_jobs { 
          described_class.perform_later(event: event, **payload) 
        }

        expect(WebMock).to have_requested(:post, Rails.configuration.external_api_endpoint)
          .with(body: hash_including(expected_request_body))
      end
    end

    context 'when the external system responds with an error' do
      before do
        stub_request(:post, Rails.configuration.external_api_endpoint)
          .to_return(status: 500, body: 'Internal Server Error')
      end

      it 'raises an error' do
        expect {
          perform_enqueued_jobs {
            described_class.perform_later(event: event, **payload)
          }
        }.to raise_error(/External system notification failed: 500/)
      end

      it 'retries the job' do
        expect {
          perform_enqueued_jobs {
            described_class.perform_later(event: event, **payload)
          }
        }.to have_performed_job(described_class)
          .exactly(:once)
          .with(event: event, **payload)
      end
    end

    context 'when the external system is unreachable' do
      before do
        stub_request(:post, Rails.configuration.external_api_endpoint)
          .to_raise(HTTP::ConnectionError)
      end

      it 'retries the job' do
        expect {
          perform_enqueued_jobs {
            described_class.perform_later(event: event, **payload)
          }
        }.to have_performed_job(described_class)
          .exactly(:once)
          .with(event: event, **payload)
      end
    end
  end
end 