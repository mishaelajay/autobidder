# frozen_string_literal: true

# Base mailer class that all other mailers inherit from.
# Provides common configuration and functionality for email delivery.
class ApplicationMailer < ActionMailer::Base
  default from: 'from@example.com'
  layout 'mailer'
end
