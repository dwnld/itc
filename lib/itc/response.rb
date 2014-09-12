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
      error_messages.presence
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
