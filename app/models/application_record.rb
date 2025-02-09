# frozen_string_literal: true

# Base model class that all other models inherit from.
# Provides common functionality and configuration for ActiveRecord models.
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
