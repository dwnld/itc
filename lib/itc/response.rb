require 'active_support/all'

module Itc
  class Response
    attr_reader :data
    def initialize(body)
      @json = JSON.parse(body)
      @data = @json['data']
    end

    def raise_if_errors
      error_messages = errors
      raise ItunesError, error_messages if error_messages.present?
    end

    def errors
      # TODO Check which fields have a sectionErrorKey
      error_messages = []
      sectionErrorKeys = @data.try(:[], 'sectionErrorKeys').presence
      error_messages << sectionErrorKeys if sectionErrorKeys
      return if sectionErrorKeys.try(:first) =~ /You haven't made any changes./
      error_messages << @json['messages']['error'] if @json['messages'].try(:[], 'error').presence
      if error_messages.presence
        error_messages << sectionErrors
        error_messages
      end
    end

    def sectionErrors
      errors = {}
      data.each_with_parent do |parent, k, v|
        if k == 'errorKeys' && v.present?
          errors[parent] = v
        end
      end
      errors
    end

  end

  class ImageUploadResponse
    attr_reader :data
    def initialize(body)
      @data = JSON.parse(body)
    end
  end

  class ItunesError < StandardError; end
end
